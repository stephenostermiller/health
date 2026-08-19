SELECT IF(EXISTS(
  SELECT 1 FROM information_schema.ROUTINES
  WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'refresh_metric_aggregates'
), 0, 1);
