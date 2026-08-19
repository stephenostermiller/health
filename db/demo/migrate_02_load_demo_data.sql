LOAD DATA LOCAL INFILE './db/demo/demo_metrics.csv'
INTO TABLE metric_fact
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(timestamp, metric, unit, user_id, value, data_source);

CALL refresh_metric_aggregates();
