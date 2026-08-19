SELECT IF(COUNT(*) > 0, 0, 1) FROM metric_fact WHERE user_id = 12345;
