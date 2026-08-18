# Fitbit CSV MySQL Schema

This directory contains the MySQL 8 schema, migrations, and utilities for storing Fitbit metrics.

## Tables

- `csv_metric_stage`: normalized staging rows ready to promote into the fact table.
- `metric_fact`: one row per timestamped metric sample.
- `metric_aggregate_day`, `metric_aggregate_week`, `metric_aggregate_month`, `metric_aggregate_year`: materialized summary tables with `metric`, `min`, `max`, `mean`, and `count`, plus a period key.

All metric tables include a `user_id` column to support multiple users' measurements. The `metric_fact` table's primary key is `(timestamp, metric, user_id, source_file, source_row)` and each aggregate table's key is `(period_key, metric, user_id)`.

## Aggregate Refresh Procedures

The schema provides full-rebuild procedures (`refresh_metric_aggregate_day`, `refresh_metric_aggregate_week`, `refresh_metric_aggregate_month`, `refresh_metric_aggregate_year`) that truncate and recompute all aggregate buckets from the raw fact rows in `metric_fact`. Run these via `CALL refresh_metric_aggregates();` (which calls all four) to rebuild the entire set of aggregates after loading or modifying metric facts.

## Scope Notes

- The schema covers both CSV imports (via `csv_metric_stage` and `load_stage.sql`) and direct Fitbit Aria writes (via Collector.pm).
- Aggregate refreshes read directly from `metric_fact` to avoid double-aggregation errors.

## Migrations

Migrations are incremental schema changes that modify the database structure over time. Each migration is a SQL file in `migrations/` that runs at most once via a check-file system: before running, a corresponding `.check.sql` file determines whether the migration has already been applied. This ensures that running schema initialization multiple times is safe and idempotent.

Migrations are applied automatically when you run `make schema` or `./db/db-init.sh`. For details on creating new migrations, understanding check files, and troubleshooting, see [migrations/readme.md](migrations/readme.md).
