INSERT INTO metric_fact (
    `timestamp`,
    metric,
    unit,
    user_id,
    value,
    data_source,
    end_timestamp,
    loaded_at
)
SELECT
    s.`timestamp`,
    s.metric,
    s.unit,
    45016898 AS user_id,
    s.value,
    NULLIF(s.data_source, ''),
    s.end_timestamp,
    CURRENT_TIMESTAMP
FROM csv_metric_stage AS s
ON DUPLICATE KEY UPDATE
    unit = VALUES(unit),
    value = VALUES(value),
    data_source = VALUES(data_source),
    end_timestamp = VALUES(end_timestamp),
    loaded_at = CURRENT_TIMESTAMP;
