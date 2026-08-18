# Health Data ETL

This project normalizes CSV health exports into MySQL fact and aggregate tables.

## Project Layout

- `csv/` — source CSV exports.
- `script/` — CSV normalization scripts.

The schema, migrations, and SQL utilities are in the top-level `db/` directory (organized into `schema/`, `migrations/`, and `utilities/` subdirectories).

## Prerequisites

- MySQL 8.x
- Environment variables for `MYSQL_USER`, `MYSQL_PWD`, `MYSQL_HOST`, `MYSQL_PORT`, and `MYSQL_DATABASE`

## Load Workflow

1. **Initialize database schema** (runs once, idempotent via migrations):
   ```sh
   make schema
   ```
   Creates tables, applies any pending migrations from `db/migrations/`.

2. **Normalize CSV exports** into a tab-separated stage file:
   ```sh
   make normalize
   ```
   Runs `script/normalize_csv_metrics.py csv --output /tmp/fitbit-metric-stage.tsv`
   
   By default this omits high-frequency families: `heart_rate`, `body_temperature`, `active_minutes`, `time_in_heart_rate_zone`, `active_zone_minutes`, `calories_in_heart_rate_zone`, `daily_heart_rate_zones`, `calories`, `gps_location`, `live_pace`, and `activity_level`. These families dominate the staged row count and can be included via `--include-excluded-families` if needed.

3. **Load stage file into MySQL**:
   ```sh
   make load
   ```
   - Truncates aggregate and fact tables
   - Loads normalized CSV into `csv_metric_stage` table
   - Promotes rows from stage to `metric_fact` table via `db/utilities/load_stage.sql`

4. **Refresh aggregate tables**:
   ```sh
   make refresh
   ```
   Rebuilds `metric_aggregate_day`, `metric_aggregate_week`, `metric_aggregate_month`, `metric_aggregate_year` from fact rows.

### Quick Start

```sh
make normalize
make schema
make load
make refresh
```

## Metric Naming

The normalizer expands numeric CSV columns into metric names based on the file family and header:

- `weight.csv` -> `weight.weight_grams`
- `body_fat_2020-03-01.csv` -> `body_fat.body_fat_percentage`
- `daily_resting_heart_rate.csv` -> `daily_resting_heart_rate.beats_per_minute`
- `active_minutes_2023-01-01.csv` -> `active_minutes.light`, `active_minutes.moderate`, `active_minutes.very`
- `active_zone_minutes_2023-01-01.csv` -> `active_zone_minutes.total_minutes.heart_rate_zone.cardio`
- `time_in_heart_rate_zone_2022-05-01.csv` -> `time_in_heart_rate_zone.heart_rate_zone_type.light` with a value of `1`
- `sedentary_period_2023-01-23.csv` -> `sedentary_period.duration_seconds`

Units stay embedded in the metric name instead of moving into a separate dimension table.

## Schema Documentation

See `db/readme.md` for table definitions, metric naming conventions, and aggregate refresh procedures. See `db/migrations/readme.md` for information about adding schema changes.
