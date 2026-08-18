# Fitbit Collector

This project is the Perl CGI collector for Fitbit Aria uploads. It accepts device requests, parses the binary payload, writes metrics directly to MySQL, and keeps aggregate tables up to date.

## Project Layout

- `htdocs/` — CGI entrypoint and Apache rewrite config.
- `lib/` — request handling and binary parsing modules.
- `script/` — Apache install and data-directory setup helpers.
- `t/` — collector tests and fixtures.

## Installation

### DNS Spoofing `www.fitbit.com`

For the Aria to reach this collector, your network must resolve `www.fitbit.com` to the machine serving this project instead of Fitbit's real servers.

### Apache Setup

From this project root:

```sh
sudo make install
```

Assumptions:

- Apache is installed, running, and listening on port 80.
- Configuration is written to `/etc/apache2/sites-available/fitbit-spoof.conf`.
- `a2ensite` and `service` are available.
- Apache runs as `www-data:www-data`.

## Environment

The collector writes to MySQL and requires a `.env` file in the project root with:

```
MYSQL_USER=your_username
MYSQL_PWD=your_password
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=health
```

These can alternatively be set as Apache environment variables (via `SetEnv` in the vhost config) or as OS environment variables, which take precedence over the `.env` file.

## Collected Data

Each Aria weigh-in generates five metric facts per reading:

- `weight` — measured weight in pounds (converted from the device's raw grams reading)
- `body_composition.impedance` — raw impedance from the scale
- `body_composition.body_fat_1`, `body_fat_2`, `covariance` — raw body composition sensor readings

These are written to the `metric_fact` table and aggregate tables are automatically updated for quick dashboard queries.

## Tests

Unit tests (no database required):

```sh
make test
```

Smoke test (requires a live, schema-loaded MySQL database):

```sh
make smoke
```
