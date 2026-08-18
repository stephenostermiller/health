SELECT IF(EXISTS(
  SELECT 1 FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'metric_fact'
    AND COLUMN_NAME = 'end_timestamp'
), 1, 0);
