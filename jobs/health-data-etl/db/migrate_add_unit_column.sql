-- One-time migration to add unit column and rename metrics to eliminate unit-in-name
-- Run this against an existing database before deploying the updated schema.sql changes

-- Step 1: Add unit column to all tables with default empty string
ALTER TABLE csv_metric_stage ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE metric_fact ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE metric_aggregate_day ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE metric_aggregate_week ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE metric_aggregate_month ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE metric_aggregate_year ADD COLUMN unit VARCHAR(32) NOT NULL DEFAULT '';

-- Step 2: Backfill metric renames and units
-- Apply to all six tables: csv_metric_stage, metric_fact, and the four aggregate tables
-- (aggregates are updated directly here; a full refresh_aggregates.sql will be required after migration)

-- Body weight: convert from grams to pounds
UPDATE csv_metric_stage SET value = value / 453.6, metric = 'weight', unit = 'lb' WHERE metric = 'weight.weight_grams';
UPDATE metric_fact SET value = value / 453.6, metric = 'weight', unit = 'lb' WHERE metric = 'weight.weight_grams';
UPDATE metric_aggregate_day SET `min` = `min` / 453.6, `max` = `max` / 453.6, `mean` = `mean` / 453.6, `sum` = `sum` / 453.6, metric = 'weight', unit = 'lb' WHERE metric = 'weight.weight_grams';
UPDATE metric_aggregate_week SET `min` = `min` / 453.6, `max` = `max` / 453.6, `mean` = `mean` / 453.6, `sum` = `sum` / 453.6, metric = 'weight', unit = 'lb' WHERE metric = 'weight.weight_grams';
UPDATE metric_aggregate_month SET `min` = `min` / 453.6, `max` = `max` / 453.6, `mean` = `mean` / 453.6, `sum` = `sum` / 453.6, metric = 'weight', unit = 'lb' WHERE metric = 'weight.weight_grams';
UPDATE metric_aggregate_year SET `min` = `min` / 453.6, `max` = `max` / 453.6, `mean` = `mean` / 453.6, `sum` = `sum` / 453.6, metric = 'weight', unit = 'lb' WHERE metric = 'weight.weight_grams';

-- Body fat percentage: drop the redundant "percentage" segment
UPDATE csv_metric_stage SET metric = 'body_fat', unit = '%' WHERE metric = 'body_fat.body_fat_percentage';
UPDATE metric_fact SET metric = 'body_fat', unit = '%' WHERE metric = 'body_fat.body_fat_percentage';
UPDATE metric_aggregate_day SET metric = 'body_fat', unit = '%' WHERE metric = 'body_fat.body_fat_percentage';
UPDATE metric_aggregate_week SET metric = 'body_fat', unit = '%' WHERE metric = 'body_fat.body_fat_percentage';
UPDATE metric_aggregate_month SET metric = 'body_fat', unit = '%' WHERE metric = 'body_fat.body_fat_percentage';
UPDATE metric_aggregate_year SET metric = 'body_fat', unit = '%' WHERE metric = 'body_fat.body_fat_percentage';

-- Body composition: impedance (ohms), body_fat_1/2 and covariance (raw, no units to extract)
UPDATE csv_metric_stage SET unit = 'ohms' WHERE metric = 'body_composition.impedance';
UPDATE metric_fact SET unit = 'ohms' WHERE metric = 'body_composition.impedance';
UPDATE metric_aggregate_day SET unit = 'ohms' WHERE metric = 'body_composition.impedance';
UPDATE metric_aggregate_week SET unit = 'ohms' WHERE metric = 'body_composition.impedance';
UPDATE metric_aggregate_month SET unit = 'ohms' WHERE metric = 'body_composition.impedance';
UPDATE metric_aggregate_year SET unit = 'ohms' WHERE metric = 'body_composition.impedance';

UPDATE csv_metric_stage SET unit = 'raw' WHERE metric = 'body_composition.body_fat_1';
UPDATE metric_fact SET unit = 'raw' WHERE metric = 'body_composition.body_fat_1';
UPDATE metric_aggregate_day SET unit = 'raw' WHERE metric = 'body_composition.body_fat_1';
UPDATE metric_aggregate_week SET unit = 'raw' WHERE metric = 'body_composition.body_fat_1';
UPDATE metric_aggregate_month SET unit = 'raw' WHERE metric = 'body_composition.body_fat_1';
UPDATE metric_aggregate_year SET unit = 'raw' WHERE metric = 'body_composition.body_fat_1';

UPDATE csv_metric_stage SET unit = 'raw' WHERE metric = 'body_composition.body_fat_2';
UPDATE metric_fact SET unit = 'raw' WHERE metric = 'body_composition.body_fat_2';
UPDATE metric_aggregate_day SET unit = 'raw' WHERE metric = 'body_composition.body_fat_2';
UPDATE metric_aggregate_week SET unit = 'raw' WHERE metric = 'body_composition.body_fat_2';
UPDATE metric_aggregate_month SET unit = 'raw' WHERE metric = 'body_composition.body_fat_2';
UPDATE metric_aggregate_year SET unit = 'raw' WHERE metric = 'body_composition.body_fat_2';

UPDATE csv_metric_stage SET unit = 'raw' WHERE metric = 'body_composition.covariance';
UPDATE metric_fact SET unit = 'raw' WHERE metric = 'body_composition.covariance';
UPDATE metric_aggregate_day SET unit = 'raw' WHERE metric = 'body_composition.covariance';
UPDATE metric_aggregate_week SET unit = 'raw' WHERE metric = 'body_composition.covariance';
UPDATE metric_aggregate_month SET unit = 'raw' WHERE metric = 'body_composition.covariance';
UPDATE metric_aggregate_year SET unit = 'raw' WHERE metric = 'body_composition.covariance';

-- Daily resting heart rate: drop the "beats_per_minute" segment
UPDATE csv_metric_stage SET metric = 'daily_resting_heart_rate', unit = 'beats_per_minute' WHERE metric = 'daily_resting_heart_rate.beats_per_minute';
UPDATE metric_fact SET metric = 'daily_resting_heart_rate', unit = 'beats_per_minute' WHERE metric = 'daily_resting_heart_rate.beats_per_minute';
UPDATE metric_aggregate_day SET metric = 'daily_resting_heart_rate', unit = 'beats_per_minute' WHERE metric = 'daily_resting_heart_rate.beats_per_minute';
UPDATE metric_aggregate_week SET metric = 'daily_resting_heart_rate', unit = 'beats_per_minute' WHERE metric = 'daily_resting_heart_rate.beats_per_minute';
UPDATE metric_aggregate_month SET metric = 'daily_resting_heart_rate', unit = 'beats_per_minute' WHERE metric = 'daily_resting_heart_rate.beats_per_minute';
UPDATE metric_aggregate_year SET metric = 'daily_resting_heart_rate', unit = 'beats_per_minute' WHERE metric = 'daily_resting_heart_rate.beats_per_minute';

-- Daily oxygen saturation: split metric name vs. unit (note: Metrics.pm uses .avg but real data is .average_percentage, fix now)
UPDATE csv_metric_stage SET metric = 'daily_oxygen_saturation.average', unit = '%' WHERE metric LIKE 'daily_oxygen_saturation.average%';
UPDATE metric_fact SET metric = 'daily_oxygen_saturation.average', unit = '%' WHERE metric LIKE 'daily_oxygen_saturation.average%';
UPDATE metric_aggregate_day SET metric = 'daily_oxygen_saturation.average', unit = '%' WHERE metric LIKE 'daily_oxygen_saturation.average%';
UPDATE metric_aggregate_week SET metric = 'daily_oxygen_saturation.average', unit = '%' WHERE metric LIKE 'daily_oxygen_saturation.average%';
UPDATE metric_aggregate_month SET metric = 'daily_oxygen_saturation.average', unit = '%' WHERE metric LIKE 'daily_oxygen_saturation.average%';
UPDATE metric_aggregate_year SET metric = 'daily_oxygen_saturation.average', unit = '%' WHERE metric LIKE 'daily_oxygen_saturation.average%';

-- Daily VO2 max: split metric name vs. unit
UPDATE csv_metric_stage SET metric = 'daily_vo2_max.cardio_fitness', unit = 'score' WHERE metric = 'daily_vo2_max.cardio_fitness_score';
UPDATE metric_fact SET metric = 'daily_vo2_max.cardio_fitness', unit = 'score' WHERE metric = 'daily_vo2_max.cardio_fitness_score';
UPDATE metric_aggregate_day SET metric = 'daily_vo2_max.cardio_fitness', unit = 'score' WHERE metric = 'daily_vo2_max.cardio_fitness_score';
UPDATE metric_aggregate_week SET metric = 'daily_vo2_max.cardio_fitness', unit = 'score' WHERE metric = 'daily_vo2_max.cardio_fitness_score';
UPDATE metric_aggregate_month SET metric = 'daily_vo2_max.cardio_fitness', unit = 'score' WHERE metric = 'daily_vo2_max.cardio_fitness_score';
UPDATE metric_aggregate_year SET metric = 'daily_vo2_max.cardio_fitness', unit = 'score' WHERE metric = 'daily_vo2_max.cardio_fitness_score';

-- Other CSV-only metrics: extract units from column names where they exist
UPDATE csv_metric_stage SET metric = 'altitude.gain', unit = '' WHERE metric = 'altitude.gain';
UPDATE metric_fact SET metric = 'altitude.gain', unit = '' WHERE metric = 'altitude.gain';

UPDATE csv_metric_stage SET metric = 'body_temperature.temperature', unit = 'c' WHERE metric = 'body_temperature.temperature_celsius';
UPDATE metric_fact SET metric = 'body_temperature.temperature', unit = 'c' WHERE metric = 'body_temperature.temperature_celsius';
UPDATE metric_aggregate_day SET metric = 'body_temperature.temperature', unit = 'c' WHERE metric = 'body_temperature.temperature_celsius';
UPDATE metric_aggregate_week SET metric = 'body_temperature.temperature', unit = 'c' WHERE metric = 'body_temperature.temperature_celsius';
UPDATE metric_aggregate_month SET metric = 'body_temperature.temperature', unit = 'c' WHERE metric = 'body_temperature.temperature_celsius';
UPDATE metric_aggregate_year SET metric = 'body_temperature.temperature', unit = 'c' WHERE metric = 'body_temperature.temperature_celsius';

UPDATE csv_metric_stage SET metric = 'daily_heart_rate_variability.average_heart_rate_variability', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.average_heart_rate_variability_milliseconds';
UPDATE metric_fact SET metric = 'daily_heart_rate_variability.average_heart_rate_variability', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.average_heart_rate_variability_milliseconds';
UPDATE metric_aggregate_day SET metric = 'daily_heart_rate_variability.average_heart_rate_variability', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.average_heart_rate_variability_milliseconds';
UPDATE metric_aggregate_week SET metric = 'daily_heart_rate_variability.average_heart_rate_variability', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.average_heart_rate_variability_milliseconds';
UPDATE metric_aggregate_month SET metric = 'daily_heart_rate_variability.average_heart_rate_variability', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.average_heart_rate_variability_milliseconds';
UPDATE metric_aggregate_year SET metric = 'daily_heart_rate_variability.average_heart_rate_variability', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.average_heart_rate_variability_milliseconds';

UPDATE csv_metric_stage SET metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';
UPDATE metric_fact SET metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';
UPDATE metric_aggregate_day SET metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';
UPDATE metric_aggregate_week SET metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';
UPDATE metric_aggregate_month SET metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';
UPDATE metric_aggregate_year SET metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'daily_heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';

UPDATE csv_metric_stage SET metric = 'daily_respiratory_rate', unit = 'breaths_per_minute' WHERE metric = 'daily_respiratory_rate.breaths_per_minute';
UPDATE metric_fact SET metric = 'daily_respiratory_rate', unit = 'breaths_per_minute' WHERE metric = 'daily_respiratory_rate.breaths_per_minute';
UPDATE metric_aggregate_day SET metric = 'daily_respiratory_rate', unit = 'breaths_per_minute' WHERE metric = 'daily_respiratory_rate.breaths_per_minute';
UPDATE metric_aggregate_week SET metric = 'daily_respiratory_rate', unit = 'breaths_per_minute' WHERE metric = 'daily_respiratory_rate.breaths_per_minute';
UPDATE metric_aggregate_month SET metric = 'daily_respiratory_rate', unit = 'breaths_per_minute' WHERE metric = 'daily_respiratory_rate.breaths_per_minute';
UPDATE metric_aggregate_year SET metric = 'daily_respiratory_rate', unit = 'breaths_per_minute' WHERE metric = 'daily_respiratory_rate.breaths_per_minute';

UPDATE csv_metric_stage SET metric = 'daily_sleep_temperature_derivations.nightly_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.nightly_temperature_celsius';
UPDATE metric_fact SET metric = 'daily_sleep_temperature_derivations.nightly_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.nightly_temperature_celsius';
UPDATE metric_aggregate_day SET metric = 'daily_sleep_temperature_derivations.nightly_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.nightly_temperature_celsius';
UPDATE metric_aggregate_week SET metric = 'daily_sleep_temperature_derivations.nightly_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.nightly_temperature_celsius';
UPDATE metric_aggregate_month SET metric = 'daily_sleep_temperature_derivations.nightly_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.nightly_temperature_celsius';
UPDATE metric_aggregate_year SET metric = 'daily_sleep_temperature_derivations.nightly_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.nightly_temperature_celsius';

UPDATE csv_metric_stage SET metric = 'daily_sleep_temperature_derivations.baseline_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.baseline_temperature_celsius';
UPDATE metric_fact SET metric = 'daily_sleep_temperature_derivations.baseline_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.baseline_temperature_celsius';
UPDATE metric_aggregate_day SET metric = 'daily_sleep_temperature_derivations.baseline_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.baseline_temperature_celsius';
UPDATE metric_aggregate_week SET metric = 'daily_sleep_temperature_derivations.baseline_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.baseline_temperature_celsius';
UPDATE metric_aggregate_month SET metric = 'daily_sleep_temperature_derivations.baseline_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.baseline_temperature_celsius';
UPDATE metric_aggregate_year SET metric = 'daily_sleep_temperature_derivations.baseline_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.baseline_temperature_celsius';

UPDATE csv_metric_stage SET metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_celsius';
UPDATE metric_fact SET metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_celsius';
UPDATE metric_aggregate_day SET metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_celsius';
UPDATE metric_aggregate_week SET metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_celsius';
UPDATE metric_aggregate_month SET metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_celsius';
UPDATE metric_aggregate_year SET metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_temperature', unit = 'c' WHERE metric = 'daily_sleep_temperature_derivations.relative_nightly_stddev_30d_celsius';

UPDATE csv_metric_stage SET metric = 'height', unit = 'mm' WHERE metric = 'height.height_millimeters';
UPDATE metric_fact SET metric = 'height', unit = 'mm' WHERE metric = 'height.height_millimeters';
UPDATE metric_aggregate_day SET metric = 'height', unit = 'mm' WHERE metric = 'height.height_millimeters';
UPDATE metric_aggregate_week SET metric = 'height', unit = 'mm' WHERE metric = 'height.height_millimeters';
UPDATE metric_aggregate_month SET metric = 'height', unit = 'mm' WHERE metric = 'height.height_millimeters';
UPDATE metric_aggregate_year SET metric = 'height', unit = 'mm' WHERE metric = 'height.height_millimeters';

UPDATE csv_metric_stage SET metric = 'heart_rate', unit = 'beats_per_minute' WHERE metric = 'heart_rate.beats_per_minute';
UPDATE metric_fact SET metric = 'heart_rate', unit = 'beats_per_minute' WHERE metric = 'heart_rate.beats_per_minute';
UPDATE metric_aggregate_day SET metric = 'heart_rate', unit = 'beats_per_minute' WHERE metric = 'heart_rate.beats_per_minute';
UPDATE metric_aggregate_week SET metric = 'heart_rate', unit = 'beats_per_minute' WHERE metric = 'heart_rate.beats_per_minute';
UPDATE metric_aggregate_month SET metric = 'heart_rate', unit = 'beats_per_minute' WHERE metric = 'heart_rate.beats_per_minute';
UPDATE metric_aggregate_year SET metric = 'heart_rate', unit = 'beats_per_minute' WHERE metric = 'heart_rate.beats_per_minute';

UPDATE csv_metric_stage SET metric = 'heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';
UPDATE metric_fact SET metric = 'heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';
UPDATE metric_aggregate_day SET metric = 'heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';
UPDATE metric_aggregate_week SET metric = 'heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';
UPDATE metric_aggregate_month SET metric = 'heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';
UPDATE metric_aggregate_year SET metric = 'heart_rate_variability.root_mean_square_of_successive_differences', unit = 'ms' WHERE metric = 'heart_rate_variability.root_mean_square_of_successive_differences_milliseconds';

UPDATE csv_metric_stage SET metric = 'heart_rate_variability.standard_deviation', unit = 'ms' WHERE metric = 'heart_rate_variability.standard_deviation_milliseconds';
UPDATE metric_fact SET metric = 'heart_rate_variability.standard_deviation', unit = 'ms' WHERE metric = 'heart_rate_variability.standard_deviation_milliseconds';
UPDATE metric_aggregate_day SET metric = 'heart_rate_variability.standard_deviation', unit = 'ms' WHERE metric = 'heart_rate_variability.standard_deviation_milliseconds';
UPDATE metric_aggregate_week SET metric = 'heart_rate_variability.standard_deviation', unit = 'ms' WHERE metric = 'heart_rate_variability.standard_deviation_milliseconds';
UPDATE metric_aggregate_month SET metric = 'heart_rate_variability.standard_deviation', unit = 'ms' WHERE metric = 'heart_rate_variability.standard_deviation_milliseconds';
UPDATE metric_aggregate_year SET metric = 'heart_rate_variability.standard_deviation', unit = 'ms' WHERE metric = 'heart_rate_variability.standard_deviation_milliseconds';

UPDATE csv_metric_stage SET metric = 'oxygen_saturation', unit = '%' WHERE metric = 'oxygen_saturation.oxygen_saturation_percentage';
UPDATE metric_fact SET metric = 'oxygen_saturation', unit = '%' WHERE metric = 'oxygen_saturation.oxygen_saturation_percentage';
UPDATE metric_aggregate_day SET metric = 'oxygen_saturation', unit = '%' WHERE metric = 'oxygen_saturation.oxygen_saturation_percentage';
UPDATE metric_aggregate_week SET metric = 'oxygen_saturation', unit = '%' WHERE metric = 'oxygen_saturation.oxygen_saturation_percentage';
UPDATE metric_aggregate_month SET metric = 'oxygen_saturation', unit = '%' WHERE metric = 'oxygen_saturation.oxygen_saturation_percentage';
UPDATE metric_aggregate_year SET metric = 'oxygen_saturation', unit = '%' WHERE metric = 'oxygen_saturation.oxygen_saturation_percentage';

UPDATE csv_metric_stage SET metric = 'respiratory_rate_sleep_summary.deep_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.deep_sleep_stats___milli_breaths_per_minute';
UPDATE metric_fact SET metric = 'respiratory_rate_sleep_summary.deep_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.deep_sleep_stats___milli_breaths_per_minute';
UPDATE metric_aggregate_day SET metric = 'respiratory_rate_sleep_summary.deep_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.deep_sleep_stats___milli_breaths_per_minute';
UPDATE metric_aggregate_week SET metric = 'respiratory_rate_sleep_summary.deep_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.deep_sleep_stats___milli_breaths_per_minute';
UPDATE metric_aggregate_month SET metric = 'respiratory_rate_sleep_summary.deep_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.deep_sleep_stats___milli_breaths_per_minute';
UPDATE metric_aggregate_year SET metric = 'respiratory_rate_sleep_summary.deep_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.deep_sleep_stats___milli_breaths_per_minute';

UPDATE csv_metric_stage SET metric = 'respiratory_rate_sleep_summary.deep_sleep_stats_standard_deviation', unit = 'ms' WHERE metric = 'respiratory_rate_sleep_summary.deep_sleep_stats___standard_deviation_milliseconds';
UPDATE metric_fact SET metric = 'respiratory_rate_sleep_summary.deep_sleep_stats_standard_deviation', unit = 'ms' WHERE metric = 'respiratory_rate_sleep_summary.deep_sleep_stats___standard_deviation_milliseconds';

UPDATE csv_metric_stage SET metric = 'respiratory_rate_sleep_summary.light_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.light_sleep_stats___milli_breaths_per_minute';
UPDATE metric_fact SET metric = 'respiratory_rate_sleep_summary.light_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.light_sleep_stats___milli_breaths_per_minute';

UPDATE csv_metric_stage SET metric = 'respiratory_rate_sleep_summary.light_sleep_stats_standard_deviation', unit = 'ms' WHERE metric = 'respiratory_rate_sleep_summary.light_sleep_stats___standard_deviation_milliseconds';
UPDATE metric_fact SET metric = 'respiratory_rate_sleep_summary.light_sleep_stats_standard_deviation', unit = 'ms' WHERE metric = 'respiratory_rate_sleep_summary.light_sleep_stats___standard_deviation_milliseconds';

UPDATE csv_metric_stage SET metric = 'respiratory_rate_sleep_summary.rem_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.rem_sleep_stats___milli_breaths_per_minute';
UPDATE metric_fact SET metric = 'respiratory_rate_sleep_summary.rem_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.rem_sleep_stats___milli_breaths_per_minute';

UPDATE csv_metric_stage SET metric = 'respiratory_rate_sleep_summary.rem_sleep_stats_standard_deviation', unit = 'ms' WHERE metric = 'respiratory_rate_sleep_summary.rem_sleep_stats___standard_deviation_milliseconds';
UPDATE metric_fact SET metric = 'respiratory_rate_sleep_summary.rem_sleep_stats_standard_deviation', unit = 'ms' WHERE metric = 'respiratory_rate_sleep_summary.rem_sleep_stats___standard_deviation_milliseconds';

UPDATE csv_metric_stage SET metric = 'respiratory_rate_sleep_summary.full_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.full_sleep_stats___milli_breaths_per_minute';
UPDATE metric_fact SET metric = 'respiratory_rate_sleep_summary.full_sleep_stats_milli_breaths_per_minute', unit = 'milli_breaths_per_minute' WHERE metric = 'respiratory_rate_sleep_summary.full_sleep_stats___milli_breaths_per_minute';

UPDATE csv_metric_stage SET metric = 'respiratory_rate_sleep_summary.full_sleep_stats_standard_deviation', unit = 'ms' WHERE metric = 'respiratory_rate_sleep_summary.full_sleep_stats___standard_deviation_milliseconds';
UPDATE metric_fact SET metric = 'respiratory_rate_sleep_summary.full_sleep_stats_standard_deviation', unit = 'ms' WHERE metric = 'respiratory_rate_sleep_summary.full_sleep_stats___standard_deviation_milliseconds';

UPDATE csv_metric_stage SET metric = 'sedentary_period.duration', unit = 's' WHERE metric = 'sedentary_period.duration_seconds';
UPDATE metric_fact SET metric = 'sedentary_period.duration', unit = 's' WHERE metric = 'sedentary_period.duration_seconds';
UPDATE metric_aggregate_day SET metric = 'sedentary_period.duration', unit = 's' WHERE metric = 'sedentary_period.duration_seconds';
UPDATE metric_aggregate_week SET metric = 'sedentary_period.duration', unit = 's' WHERE metric = 'sedentary_period.duration_seconds';
UPDATE metric_aggregate_month SET metric = 'sedentary_period.duration', unit = 's' WHERE metric = 'sedentary_period.duration_seconds';
UPDATE metric_aggregate_year SET metric = 'sedentary_period.duration', unit = 's' WHERE metric = 'sedentary_period.duration_seconds';

-- Metrics with no unit text in the CSV column header (no renaming, empty unit)
UPDATE csv_metric_stage SET unit = '' WHERE metric IN ('active_minutes.light', 'active_minutes.moderate', 'active_minutes.very');
UPDATE metric_fact SET unit = '' WHERE metric IN ('active_minutes.light', 'active_minutes.moderate', 'active_minutes.very');

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'active_zone_minutes.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'active_zone_minutes.%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'activity_level.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'activity_level.%';

UPDATE csv_metric_stage SET unit = '' WHERE metric = 'calories.calories';
UPDATE metric_fact SET unit = '' WHERE metric = 'calories.calories';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'calories_in_heart_rate_zone.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'calories_in_heart_rate_zone.%';

UPDATE csv_metric_stage SET unit = '' WHERE metric = 'distance.distance';
UPDATE metric_fact SET unit = '' WHERE metric = 'distance.distance';

UPDATE csv_metric_stage SET unit = '' WHERE metric = 'floors.floors';
UPDATE metric_fact SET unit = '' WHERE metric = 'floors.floors';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'gps_location.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'gps_location.%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'live_pace.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'live_pace.%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'steps%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'steps%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'swim_lengths_data.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'swim_lengths_data.%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'time_in_heart_rate_zone.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'time_in_heart_rate_zone.%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'vo2_max.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'vo2_max.%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'run_vo2max.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'run_vo2max.%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'demographic_vo2max.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'demographic_vo2max.%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'daily_vo2_max.%' AND metric != 'daily_vo2_max.cardio_fitness';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'daily_vo2_max.%' AND metric != 'daily_vo2_max.cardio_fitness';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE '%entropy%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE '%entropy%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE '%signal_to_noise%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE '%signal_to_noise%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'hydration_log.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'hydration_log.%';

UPDATE csv_metric_stage SET unit = '' WHERE metric LIKE 'nutrition_log.%';
UPDATE metric_fact SET unit = '' WHERE metric LIKE 'nutrition_log.%';

-- Note: After running this migration, refresh_aggregates.sql MUST be re-run (not just as a best practice,
-- but as a correctness requirement) because the weight metric aggregates are now numerically wrong
-- (still gram-scaled, not pound-scaled). The full re-build will recompute them correctly from the
-- now-corrected metric_fact values.
