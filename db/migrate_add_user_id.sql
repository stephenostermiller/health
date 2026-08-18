-- One-time migration to add user_id column and add sum column to aggregates
-- Run this against an existing database before deploying the schema.sql changes

ALTER TABLE metric_fact ADD COLUMN user_id BIGINT UNSIGNED NOT NULL DEFAULT 45016898;
ALTER TABLE metric_fact DROP PRIMARY KEY;
ALTER TABLE metric_fact ADD PRIMARY KEY (`timestamp`, metric, user_id);
ALTER TABLE metric_fact ADD KEY idx_metric_fact_user_metric_time (user_id, metric, `timestamp`);

ALTER TABLE metric_aggregate_day DROP COLUMN IF EXISTS median;
ALTER TABLE metric_aggregate_day ADD COLUMN `sum` DECIMAL(20,6) NOT NULL DEFAULT 0;
ALTER TABLE metric_aggregate_day ADD COLUMN user_id BIGINT UNSIGNED NOT NULL DEFAULT 45016898;
ALTER TABLE metric_aggregate_day DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_day ADD PRIMARY KEY (day_date, metric, user_id);

ALTER TABLE metric_aggregate_week DROP COLUMN IF EXISTS median;
ALTER TABLE metric_aggregate_week ADD COLUMN `sum` DECIMAL(20,6) NOT NULL DEFAULT 0;
ALTER TABLE metric_aggregate_week ADD COLUMN user_id BIGINT UNSIGNED NOT NULL DEFAULT 45016898;
ALTER TABLE metric_aggregate_week DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_week ADD PRIMARY KEY (week_start_date, metric, user_id);

ALTER TABLE metric_aggregate_month DROP COLUMN IF EXISTS median;
ALTER TABLE metric_aggregate_month ADD COLUMN `sum` DECIMAL(20,6) NOT NULL DEFAULT 0;
ALTER TABLE metric_aggregate_month ADD COLUMN user_id BIGINT UNSIGNED NOT NULL DEFAULT 45016898;
ALTER TABLE metric_aggregate_month DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_month ADD PRIMARY KEY (month_start_date, metric, user_id);

ALTER TABLE metric_aggregate_year DROP COLUMN IF EXISTS median;
ALTER TABLE metric_aggregate_year ADD COLUMN `sum` DECIMAL(20,6) NOT NULL DEFAULT 0;
ALTER TABLE metric_aggregate_year ADD COLUMN user_id BIGINT UNSIGNED NOT NULL DEFAULT 45016898;
ALTER TABLE metric_aggregate_year DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_year ADD PRIMARY KEY (year_number, metric, user_id);
