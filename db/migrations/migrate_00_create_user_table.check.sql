-- Check if user table exists
SELECT IF(EXISTS(
  SELECT 1 FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user'
), 0, 1);
