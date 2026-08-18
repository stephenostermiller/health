-- Migration to fix aggregate table PRIMARY KEYs to include unit column
-- This fixes an issue where metrics with different units were conflicting on inserts
-- because the PRIMARY KEY was (day_date, metric, user_id) but GROUP BY included unit

-- Step 1: Drop and recreate metric_aggregate_day with corrected PRIMARY KEY
ALTER TABLE metric_aggregate_day DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_day ADD PRIMARY KEY (day_date, metric, unit, user_id);

-- Step 2: Drop and recreate metric_aggregate_week with corrected PRIMARY KEY
ALTER TABLE metric_aggregate_week DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_week ADD PRIMARY KEY (week_start_date, metric, unit, user_id);

-- Step 3: Drop and recreate metric_aggregate_month with corrected PRIMARY KEY
ALTER TABLE metric_aggregate_month DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_month ADD PRIMARY KEY (month_start_date, metric, unit, user_id);

-- Step 4: Drop and recreate metric_aggregate_year with corrected PRIMARY KEY
ALTER TABLE metric_aggregate_year DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_year ADD PRIMARY KEY (year_number, metric, unit, user_id);
