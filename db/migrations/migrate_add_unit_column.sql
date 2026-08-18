-- Add unit column to all tables with default empty string
ALTER TABLE csv_metric_stage ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE metric_fact ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE metric_aggregate_day ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE metric_aggregate_week ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE metric_aggregate_month ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE metric_aggregate_year ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';
