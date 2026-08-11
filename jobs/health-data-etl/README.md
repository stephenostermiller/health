# Health Data ETL

This project normalizes CSV health exports into MySQL fact and aggregate tables.

## Project Layout

- `csv/` — source CSV exports.
- `db/` — schema, fact-load, and aggregate-refresh SQL.
- `script/` — CSV normalization scripts.

## Prerequisites

- MySQL 8.x
- Environment variables for `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_HOST`, `MYSQL_PORT`, and `MYSQL_DATABASE`

## Typical Flow

```sh
make normalize
make schema
make load
make refresh
```

The detailed schema and load workflow are documented in `db/README.md`.
