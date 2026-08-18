# Health Dashboard

This project is a Perl CGI web app that reads the ETL MySQL schema and renders health charts with Chart.js.

## Project Layout

- `htdocs/index.cgi` — HTML shell for the dashboard UI.
- `htdocs/api/series.cgi` — JSON endpoint for chart data.
- `htdocs/static/` — CSS, application JavaScript, and vendored Chart.js.
- `lib/HealthDashboard/` — DB, query, metric, and app modules.
- `apache/` — Apache vhost template.
- `script/` — smoke-test and setup helpers.
- `t/` — module-level tests.

## Environment

The dashboard reads a `.env` file in the project root (or environment variables) for:

- `MYSQL_USER` — database user
- `MYSQL_PWD` — database password
- `MYSQL_HOST` — database host
- `MYSQL_PORT` — database port
- `MYSQL_DATABASE` — database name
- `PRIMARY_USER_ID` (default: 45016898) — the Aria profile ID to display metrics for
- `DASHBOARD_SECRET_KEY` — **required** — 32+ character hex string for signing authentication cookies. Generate with `openssl rand -hex 32`.

Example `.env`:

```
MYSQL_USER=your_username
MYSQL_PWD=your_password
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=health
PRIMARY_USER_ID=45016898
DASHBOARD_SECRET_KEY=dbf3e4e7b00b3dfc64031a1dd17cc6c0e1115cd49da30cd4d235b94cb3b76377
```

Environment variables (from Apache `SetEnv`, OS environment, etc.) take precedence over `.env` file values.

## Routes

- `/` — dashboard page
- `/api/series.cgi?metric=weight&granularity=day` — JSON chart data

## Development

```sh
make test
make smoke
```

The dashboard expects the ETL schema to be loaded first.
