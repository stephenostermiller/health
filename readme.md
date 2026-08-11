# Fitbit-Spoof Monorepo

This repository contains three projects:

- `apps/fitbit-collector/` — a Perl CGI app that receives Fitbit Aria uploads and writes metrics directly to MySQL.
- `jobs/health-data-etl/` — the CSV-to-MySQL ETL job that normalizes exported health data into fact and aggregate tables.
- `apps/health-dashboard/` — a Perl CGI dashboard app that reads from MySQL and renders charts with Chart.js.

## Layout

```text
apps/
	fitbit-collector/
	health-dashboard/
jobs/
	health-data-etl/
Takeout/
```

## Setup Order

1. Run `jobs/health-data-etl/` to create the MySQL analytics schema and load any existing CSV exports.
2. Set up `apps/fitbit-collector/` to ingest Fitbit Aria device uploads directly into the database.
3. Configure `apps/health-dashboard/` to read from the same MySQL database and visualize metrics.

## Common Commands

From the repository root:

```sh
make test
make install
make etl-normalize
make etl-load
make etl-refresh
```

Project-specific details live in each project README.
