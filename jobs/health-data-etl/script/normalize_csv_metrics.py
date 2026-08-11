#!/usr/bin/env python3

import argparse
import csv
import json
import re
import sys
from datetime import datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path


DATE_SUFFIX_RE = re.compile(r"_(\d{4}-\d{2}-\d{2})$")
TIMESTAMP_COLUMNS = ("timestamp", "start time")
END_TIMESTAMP_COLUMN = "end time"
DATA_SOURCE_COLUMN = "data source"
META_COLUMNS = set(TIMESTAMP_COLUMNS) | {END_TIMESTAMP_COLUMN, DATA_SOURCE_COLUMN}
DEFAULT_EXCLUDED_FAMILIES = {
    "active_minutes",
    "active_zone_minutes",
    "activity_level",
    "body_temperature",
    "calories",
    "calories_in_heart_rate_zone",
    "daily_heart_rate_zones",
    "gps_location",
    "heart_rate",
    "live_pace",
    "time_in_heart_rate_zone",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Normalize Fitbit CSV exports into stage rows for MySQL loading."
    )
    parser.add_argument(
        "inputs",
        nargs="+",
        help="CSV files or directories containing CSV files.",
    )
    parser.add_argument(
        "--output",
        default="-",
        help="Write tab-separated output to this file. Use '-' for stdout.",
    )
    parser.add_argument(
        "--include-excluded-families",
        action="store_true",
        help="Include the default high-frequency and zone-related families that are otherwise omitted.",
    )
    return parser.parse_args()


def slugify(value: str) -> str:
    text = value.strip().lower()
    text = text.replace("%", " percent ")
    text = re.sub(r"[^a-z0-9]+", "_", text)
    text = re.sub(r"_+", "_", text)
    return text.strip("_")


def family_name(path: Path) -> str:
    stem = path.stem
    return DATE_SUFFIX_RE.sub("", stem)


def iter_csv_files(raw_inputs):
    seen = set()
    for raw_input in raw_inputs:
        path = Path(raw_input)
        if path.is_dir():
            for csv_path in sorted(path.rglob("*.csv")):
                resolved = csv_path.resolve()
                if resolved not in seen:
                    seen.add(resolved)
                    yield csv_path
        elif path.suffix.lower() == ".csv" and path.exists():
            resolved = path.resolve()
            if resolved not in seen:
                seen.add(resolved)
                yield path
        else:
            raise FileNotFoundError(f"CSV input not found: {raw_input}")


def parse_decimal(value: str):
    text = value.strip()
    if text == "":
        return None
    try:
        return Decimal(text)
    except InvalidOperation:
        return None


def parse_timestamp(value: str) -> datetime:
    return datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ")


def open_output(path: str):
    if path == "-":
        return sys.stdout
    return open(path, "w", encoding="utf-8", newline="")


def split_unit(numeric_column_slug: str) -> tuple[str, str]:
    """Extract unit suffix from a numeric column slug.

    Returns (remaining_slug, unit_code) where unit_code is the full suffix token
    (e.g. 'beats_per_minute', 'milliseconds', 'c') or '' if no unit found.
    Longest-match-first on underscore-delimited tokens.
    """
    unit_suffixes = [
        ("milli_breaths_per_minute", "milli_breaths_per_minute"),
        ("breaths_per_minute", "breaths_per_minute"),
        ("beats_per_minute", "beats_per_minute"),
        ("milliseconds", "ms"),
        ("millimeters", "mm"),
        ("percentage", "%"),
        ("percent", "%"),
        ("celsius", "c"),
        ("minutes", "min"),
        ("seconds", "s"),
        ("kcal", "kcal"),
        ("grams", "g"),
        ("score", "score"),
    ]

    for suffix, unit in unit_suffixes:
        suffix_tokens = suffix.split("_")
        slug_tokens = numeric_column_slug.split("_")
        if len(slug_tokens) >= len(suffix_tokens):
            if slug_tokens[-len(suffix_tokens):] == suffix_tokens:
                remaining = "_".join(slug_tokens[:-len(suffix_tokens)])
                return (remaining, unit)

    return (numeric_column_slug, "")


def build_metric_name(family: str, numeric_column: str = "", categories=None) -> tuple[str, str]:
    """Build metric name and extract unit.

    Returns (metric_name, unit_code).
    If numeric_column is present, applies split_unit rules:
      - If unit='g' (only for weight family), swap to unit='lb' (will convert value separately)
      - If remaining is empty after stripping unit, drop the numeric segment entirely
      - If remaining equals family, also drop the segment (avoid redundancy like weight.weight)
    """
    parts = [slugify(family)]
    unit = ""

    if numeric_column:
        slug = slugify(numeric_column)
        remaining, unit = split_unit(slug)

        # Special case: weight in grams → convert to pounds
        if unit == "g" and family.lower() == "weight":
            unit = "lb"

        # Add numeric column to metric name only if something remains after unit extraction
        # and it's not redundant with the family name
        if remaining and remaining != slugify(family):
            parts.append(remaining)

    for column_name, value in categories or []:
        parts.append(slugify(column_name))
        parts.append(slugify(value))

    metric = ".".join(part for part in parts if part)
    return (metric, unit)


def tsv_escape(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("\t", "\\t")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
    )


def emit_record(output_handle, source_file: str, source_row: int, timestamp: str, end_timestamp: str, data_source: str, metric: str, unit: str, value: Decimal, raw_row):
    fields = [
        source_file,
        str(source_row),
        timestamp,
        end_timestamp,
        data_source,
        metric,
        unit,
        format(value, "f"),
        json.dumps(raw_row, separators=(",", ":"), ensure_ascii=True),
    ]
    output_handle.write("\t".join(tsv_escape(field) for field in fields))
    output_handle.write("\n")


def normalize_file(path: Path, output_handle, include_excluded_families: bool) -> tuple[int, int]:
    emitted = 0
    skipped = 0
    family = family_name(path)

    if not include_excluded_families and family in DEFAULT_EXCLUDED_FAMILIES:
        return emitted, skipped

    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames:
            return emitted, skipped

        timestamp_column = next((name for name in TIMESTAMP_COLUMNS if name in reader.fieldnames), None)
        if timestamp_column is None:
            return emitted, skipped + 1

        for source_row, row in enumerate(reader, start=2):
            timestamp = (row.get(timestamp_column) or "").strip()
            if timestamp == "":
                skipped += 1
                continue

            end_timestamp = (row.get(END_TIMESTAMP_COLUMN) or "").strip()
            data_source = (row.get(DATA_SOURCE_COLUMN) or "").strip()

            numeric_columns = []
            categorical_columns = []
            for column_name in reader.fieldnames:
                if column_name in META_COLUMNS:
                    continue

                raw_value = (row.get(column_name) or "").strip()
                if raw_value == "":
                    continue

                decimal_value = parse_decimal(raw_value)
                if decimal_value is None:
                    categorical_columns.append((column_name, raw_value))
                else:
                    numeric_columns.append((column_name, decimal_value))

            if numeric_columns:
                for column_name, decimal_value in numeric_columns:
                    metric, unit = build_metric_name(family, column_name, categorical_columns)
                    value_to_emit = decimal_value
                    # Special case: weight in grams → convert to pounds
                    if unit == "lb" and family == "weight":
                        value_to_emit = decimal_value / Decimal("453.6")
                    emit_record(
                        output_handle,
                        path.name,
                        source_row,
                        timestamp,
                        end_timestamp,
                        data_source,
                        metric,
                        unit,
                        value_to_emit,
                        row,
                    )
                    emitted += 1
                continue

            if categorical_columns:
                for column_name, raw_value in categorical_columns:
                    metric, unit = build_metric_name(family, "", [(column_name, raw_value)])
                    emit_record(
                        output_handle,
                        path.name,
                        source_row,
                        timestamp,
                        end_timestamp,
                        data_source,
                        metric,
                        unit,
                        Decimal("1"),
                        row,
                    )
                    emitted += 1
                continue

            if end_timestamp:
                duration_seconds = Decimal(
                    str(int((parse_timestamp(end_timestamp) - parse_timestamp(timestamp)).total_seconds()))
                )
                metric, unit = build_metric_name(family, "duration_seconds")
                emit_record(
                    output_handle,
                    path.name,
                    source_row,
                    timestamp,
                    end_timestamp,
                    data_source,
                    metric,
                    unit,
                    duration_seconds,
                    row,
                )
                emitted += 1
                continue

            skipped += 1

    return emitted, skipped


def main() -> int:
    args = parse_args()
    total_emitted = 0
    total_skipped = 0

    with open_output(args.output) as output_handle:
        for csv_path in iter_csv_files(args.inputs):
            emitted, skipped = normalize_file(
                csv_path,
                output_handle,
                args.include_excluded_families,
            )
            total_emitted += emitted
            total_skipped += skipped

    print(
        f"Emitted {total_emitted} rows and skipped {total_skipped} rows.",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        raise SystemExit(0)
