SELECT IF(EXISTS(
  SELECT 1 FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'csv_metric_stage'
), 1, 0);
