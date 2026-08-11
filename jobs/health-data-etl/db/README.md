# Fitbit CSV MySQL Schema

This directory contains a MySQL 8 schema and load/refresh helpers for the data exported under `csv/`. Run the commands below from the `jobs/health-data-etl/` project root.

## Tables

- `csv_metric_stage`: normalized staging rows ready to promote into the fact table.
- `metric_fact`: one row per timestamped metric sample.
- `metric_aggregate_day`, `metric_aggregate_week`, `metric_aggregate_month`, `metric_aggregate_year`: materialized summary tables with `metric`, `min`, `max`, `mean`, `median`, and `count`, plus a period key.

## Metric Naming

The loader expands numeric CSV columns into metric names based on the file family and header:

- `weight.csv` -> `weight.weight_grams`
- `body_fat_2020-03-01.csv` -> `body_fat.body_fat_percentage`
- `daily_resting_heart_rate.csv` -> `daily_resting_heart_rate.beats_per_minute`
- `active_minutes_2023-01-01.csv` -> `active_minutes.light`, `active_minutes.moderate`, `active_minutes.very`
- `active_zone_minutes_2023-01-01.csv` -> `active_zone_minutes.total_minutes.heart_rate_zone.cardio`
- `time_in_heart_rate_zone_2022-05-01.csv` -> `time_in_heart_rate_zone.heart_rate_zone_type.light` with a value of `1`
- `sedentary_period_2023-01-23.csv` -> `sedentary_period.duration_seconds`

Units stay embedded in the metric name instead of moving into a separate dimension table.

## Load Workflow

1. Create the tables.

   ```sh
   mysql --database your_database < db/schema.sql
   ```

2. Normalize the source CSV exports into a tab-separated stage file.

   ```sh
   python3 script/normalize_csv_metrics.py csv --output /tmp/fitbit-metric-stage.tsv
   ```

   By default this omits the highest-volume and zone-related families: `heart_rate`, `body_temperature`, `active_minutes`, `time_in_heart_rate_zone`, `active_zone_minutes`, `calories_in_heart_rate_zone`, `daily_heart_rate_zones`, `calories`, `gps_location`, `live_pace`, and `activity_level`. Pass `--include-excluded-families` to include them.

3. Load the stage file into MySQL.

   ```sh
    mysql --local-infile=1 --database your_database -e "
    LOAD DATA LOCAL INFILE '/tmp/fitbit-metric-stage.tsv'
    INTO TABLE csv_metric_stage
    FIELDS TERMINATED BY 0x09
    ESCAPED BY 0x5C
    LINES TERMINATED BY 0x0A
    (source_file, source_row, @ts_text, @end_ts_text, data_source, metric, value, raw_row_json)
    SET
       timestamp = STR_TO_DATE(@ts_text, '%Y-%m-%dT%H:%i:%sZ'),
       end_timestamp = IF(@end_ts_text = '', NULL, STR_TO_DATE(@end_ts_text, '%Y-%m-%dT%H:%i:%sZ'));
    "
   ```

4. Promote the stage rows into the fact table.

   ```sh
   mysql --database your_database < db/load_stage.sql
   ```

5. Refresh the aggregates.

   ```sh
   mysql --database your_database < db/refresh_aggregates.sql
   ```

## Multi-user Support

The schema includes a `user_id` column in all metric tables to support multiple users' measurements. The `metric_fact` table's primary key is `(timestamp, metric, user_id, source_file, source_row)` and each aggregate table's key is `(period_key, metric, user_id)`.

When deploying this schema update to an existing database, run the migration script:

```sh
mysql --database your_database < db/migrate_add_user_id.sql
```

This adds the `user_id` column, backfills existing rows with a default user ID (45016898), and updates the primary keys. After migration, re-run the refresh procedures:

```sh
mysql --database your_database < db/refresh_aggregates.sql
```

## Aggregate Refresh Procedures

The schema provides full-rebuild procedures (`refresh_metric_aggregate_day/week/month/year`) and incremental bucket procedures (`refresh_metric_aggregate_day_bucket/week_bucket/month_bucket/year_bucket`) that take `(user_id, metric, timestamp)` parameters. The full-rebuild procedures truncate and recompute from all fact rows; the bucket procedures upsert only the period bucket containing the given timestamp. Fitbit Collector uses the bucket procedures after each write for performance.

## Scope Notes

- The schema covers both CSV imports (via `csv_metric_stage` and `load_stage.sql`) and direct Fitbit Aria writes (via Collector.pm).
- The normalizer preserves `data_source`, source filename, and source row number so dedupe stays deterministic.
- The normalizer omits `heart_rate`, `body_temperature`, `active_minutes`, `time_in_heart_rate_zone`, `active_zone_minutes`, `calories_in_heart_rate_zone`, `daily_heart_rate_zones`, `calories`, `gps_location`, `live_pace`, and `activity_level` by default because those high-frequency and zone-related families dominate the staged row count.
- Aggregate refreshes read directly from `metric_fact` to avoid double-aggregation errors.
- The median implementation requires MySQL 8 window functions.
