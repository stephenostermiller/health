# Health Data ETL

This project imports weight and body fat metrics from Google Takeout archives into MySQL.

## Quick Start

1. **Export your data from Google Takeout:**
   - Go to https://takeout.google.com/
   - Select only "Google Health" (deselect all other products)
   - Choose `.tgz` format
   - Click "Create export"

2. **Download the archive** — Google will email you when it's ready (usually within a few hours)

3. **Initialize the database schema** (required, run once):
   ```sh
   make schema
   ```

4. **Import the data:**
   ```sh
   cat ~/Downloads/takeout-*.tgz | jobs/health-data-etl/script/etl.pl
   ```

The script extracts and imports:
- **User profile**: name, birthdate, gender, initials
- **Weight metrics**: in grams, converted to pounds (lb)
- **Body fat metrics**: in percentage (%)

All data is loaded directly into the database. Aggregate tables are refreshed automatically.

## Project Layout

- `lib/HealthDataEtl/` — Perl library modules:
  - `Normalize.pm` — Normalizes CSV rows into fact structures
  - `Archive.pm` — Extracts metric files from Takeout `.tgz` archives
  - `DB.pm` — Database connection and fact loading
- `script/etl.pl` — Main ETL orchestrator
- `t/` — Unit tests

The schema, migrations, and SQL utilities are in the top-level `db/` directory (organized into `schema/`, `migrations/`, and `utilities/` subdirectories).

## Prerequisites

- Perl 5.14+ with core modules: `DBI`, `DBD::mysql`, `Archive::Tar`, `IO::Uncompress::Gunzip`
- MySQL 8.x
- Environment variables: `MYSQL_USER`, `MYSQL_PWD`, `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_DATABASE`, and optionally `PRIMARY_USER_ID`

## Import Workflow

### 1. Initialize Database Schema (required)

```sh
make schema
```

Creates tables, applies any pending migrations from `db/migrations/`, and creates the stored procedures needed for aggregate refresh. **This must be run before importing data.**

### 2. Import Takeout Archive

Import user profile and metrics from a Google Takeout export:

```sh
jobs/health-data-etl/script/etl.pl /path/to/takeout-export.tgz
```

Or pipe the archive on stdin:

```sh
cat /path/to/takeout-export.tgz | jobs/health-data-etl/script/etl.pl
```

The script extracts the following files from within the archive:

**User Profile:**
- `User Profile_GoogleData/user_profile.csv` — User name, birthdate, gender, etc.

**Metrics:**
- `Physical Activity_GoogleData/weight.csv` — weight in grams
- `Physical Activity_GoogleData/body_fat_YYYY-MM-DD.csv` — body fat percentage (one file per month)

Files are matched by **both directory name and filename** to avoid false positives (e.g., differently-shaped `weight.csv` files in other directories are safely ignored).

**User Profile Fields:**
- Name (first name, max 20 characters)
- User name (email address)
- Birthdate
- Gender (male/female/unknown)
- Initials (derived from first and last name)

#### Data Normalization

**Weight:**
- Input: grams (e.g., `103840`)
- Output: pounds (e.g., `228.924162`), rounded to 6 decimal places
- Unit: `lb`

**Body Fat:**
- Input: percentage (e.g., `30.087`)
- Output: percentage, unchanged
- Unit: `%`

**Timestamps:**
- Input: UTC ISO-8601 with `Z` suffix (e.g., `2016-01-22T19:20:40Z`)
- Output: MySQL DATETIME format (e.g., `2016-01-22 19:20:40`)

**Data Source:**
- Blank values are stored as `NULL` in the database
- Non-blank values are preserved as-is (e.g., `Aria`)

### 3. Database Load

Facts are inserted directly into the `metric_fact` table via `INSERT ... ON DUPLICATE KEY UPDATE`, which deduplicates and updates existing rows (same timestamp/metric/user_id).

Aggregate tables (`metric_aggregate_day`, `metric_aggregate_week`, `metric_aggregate_month`, `metric_aggregate_year`) are refreshed automatically after loading via the `refresh_metric_aggregates()` stored procedure (full TRUNCATE+rebuild).

## Testing

Run unit tests:

```sh
make test
```

Or from the repo root:

```sh
make etl-test
```

Tests verify:
- User profile normalization (name truncation, gender conversion, initials derivation)
- Timestamp parsing (ISO-8601 with/without `Z`)
- Unit conversions (grams to pounds)
- Blank/invalid field handling
- CSV parsing edge cases
- Archive extraction (correct files matched, decoys excluded)

## Schema Documentation

See `db/readme.md` for table definitions and aggregate refresh procedures. See `db/migrations/readme.md` for information about adding schema changes.
