# Database Migrations

This directory contains schema migrations that update the database incrementally. Migrations are run automatically by `script/db-init.sh` when initializing the database.

## Directory Structure

- `schema/schema.sql` — Core table schema, run once at database initialization.
- `migrations/` — Incremental schema changes, each run at most once.
- `utilities/` — Reusable SQL procedures (load_stage.sql, refresh_aggregates.sql).

## How Migrations Work

Migrations are SQL files in `migrations/` that modify the database schema. Each migration runs at most once via a check file system:

1. The init script reads each `migrate_*.sql` file in filename order.
2. Before running, it checks if a corresponding `.check.sql` file exists.
3. If the check file exists:
   - The script runs the check query and reads the result (0 or 1).
   - Result `1` = run the migration; result `0` = skip it (already applied).
4. If no check file exists, the migration is assumed to need running every time.

## Check Files

A check file is a SQL query that returns `1` (should run) or `0` (skip). It determines whether the migration has already been applied to the database.

### Example: Checking if a Column Exists

```sql
-- migrate_add_email_column.check.sql
SELECT IF(EXISTS(
  SELECT 1 FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user'
    AND COLUMN_NAME = 'email'
), 0, 1);
```

This returns `1` if the `email` column does NOT exist (run the migration), and `0` if it does (skip it).

### Example: Checking if a Table Exists

```sql
-- migrate_create_audit_log.check.sql
SELECT IF(EXISTS(
  SELECT 1 FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'audit_log'
), 0, 1);
```

## Creating a New Migration

1. Create a migration file with a descriptive name:
   ```
   migrate_add_email_column.sql
   ```

2. Write your ALTER TABLE or CREATE TABLE statements:
   ```sql
   ALTER TABLE user ADD COLUMN email VARCHAR(255) NULL;
   ```

3. Create a corresponding check file to avoid re-running:
   ```sql
   -- migrate_add_email_column.check.sql
   SELECT IF(EXISTS(
     SELECT 1 FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'user'
       AND COLUMN_NAME = 'email'
   ), 0, 1);
   ```

4. Migrations are applied in alphabetical order, so name them with a meaningful prefix or number if order matters.

## Best Practices

- **Always idempotent**: Use `ALTER TABLE ... IF NOT EXISTS`, `CREATE TABLE IF NOT EXISTS`, or rely on check files to ensure migrations are idempotent.
- **Always provide a check file**: Without one, migrations run every time, which can be wasteful or dangerous.
- **Test locally first**: Run `make schema` locally to verify the migration applies correctly.
- **Document the change**: Add a comment at the top of the migration explaining why the change was made.
- **Atomic operations**: Keep each migration focused on a single logical change.

## Running Migrations

Migrations run automatically during database initialization:

```sh
# From project root
make schema
```

Or manually:

```sh
./script/db-init.sh
```

## Troubleshooting

### Migration keeps running every time

The check file is missing or returning the wrong value. Verify:
1. The check file exists (e.g., `migrate_*.check.sql`)
2. The query returns `1` if the migration is needed, `0` if already applied
3. Test the check query manually in MySQL

### Migration fails

1. Check the SQL syntax with `mysql` directly
2. Verify the table/column name matches
3. Test in a disposable database first

### Wrong order of execution

Migrations run in alphabetical order. If one migration depends on another, ensure the filename sorts correctly (e.g., use numbered prefixes like `001_`, `002_`).
