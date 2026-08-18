-- Fix aggregate table PRIMARY KEYs to include unit column
ALTER TABLE metric_aggregate_day DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_day ADD PRIMARY KEY (day_date, metric, unit, user_id);

ALTER TABLE metric_aggregate_week DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_week ADD PRIMARY KEY (week_start_date, metric, unit, user_id);

ALTER TABLE metric_aggregate_month DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_month ADD PRIMARY KEY (month_start_date, metric, unit, user_id);

ALTER TABLE metric_aggregate_year DROP PRIMARY KEY;
ALTER TABLE metric_aggregate_year ADD PRIMARY KEY (year_number, metric, unit, user_id);
