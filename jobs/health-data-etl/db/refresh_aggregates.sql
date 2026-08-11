DROP PROCEDURE IF EXISTS refresh_metric_aggregates;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_year;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_month;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_week;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_day;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_day_bucket;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_week_bucket;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_month_bucket;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_year_bucket;

DELIMITER //

CREATE PROCEDURE refresh_metric_aggregate_day()
BEGIN
    TRUNCATE TABLE metric_aggregate_day;

    INSERT INTO metric_aggregate_day (day_date, metric, unit, user_id, `min`, `max`, `mean`, `count`, refreshed_at)
    WITH ordered AS (
        SELECT
            DATE(`timestamp`) AS day_date,
            metric,
            unit,
            user_id,
            value,
            ROW_NUMBER() OVER (
                PARTITION BY DATE(`timestamp`), metric, user_id
                ORDER BY value
            ) AS row_number_in_bucket,
            COUNT(*) OVER (
                PARTITION BY DATE(`timestamp`), metric, user_id
            ) AS bucket_count
        FROM metric_fact
    ),
    stats AS (
        SELECT
            DATE(`timestamp`) AS day_date,
            metric,
            unit,
            user_id,
            MIN(value) AS `min`,
            MAX(value) AS `max`,
            AVG(value) AS `mean`,
            COUNT(*) AS `count`
        FROM metric_fact
        GROUP BY DATE(`timestamp`), metric, unit, user_id
    )
    SELECT
        stats.day_date,
        stats.metric,
        stats.unit,
        stats.user_id,
        stats.`min`,
        stats.`max`,
        stats.`mean`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats;
END //

CREATE PROCEDURE refresh_metric_aggregate_week()
BEGIN
    TRUNCATE TABLE metric_aggregate_week;

    INSERT INTO metric_aggregate_week (week_start_date, metric, unit, user_id, `min`, `max`, `mean`, `count`, refreshed_at)
    WITH ordered AS (
        SELECT
            DATE_SUB(DATE(`timestamp`), INTERVAL WEEKDAY(DATE(`timestamp`)) DAY) AS week_start_date,
            metric,
            unit,
            user_id,
            value,
            ROW_NUMBER() OVER (
                PARTITION BY DATE_SUB(DATE(`timestamp`), INTERVAL WEEKDAY(DATE(`timestamp`)) DAY), metric, user_id
                ORDER BY value
            ) AS row_number_in_bucket,
            COUNT(*) OVER (
                PARTITION BY DATE_SUB(DATE(`timestamp`), INTERVAL WEEKDAY(DATE(`timestamp`)) DAY), metric, user_id
            ) AS bucket_count
        FROM metric_fact
    ),
    stats AS (
        SELECT
            DATE_SUB(DATE(`timestamp`), INTERVAL WEEKDAY(DATE(`timestamp`)) DAY) AS week_start_date,
            metric,
            unit,
            user_id,
            MIN(value) AS `min`,
            MAX(value) AS `max`,
            AVG(value) AS `mean`,
            COUNT(*) AS `count`
        FROM metric_fact
        GROUP BY DATE_SUB(DATE(`timestamp`), INTERVAL WEEKDAY(DATE(`timestamp`)) DAY), metric, unit, user_id
    )
    SELECT
        stats.week_start_date,
        stats.metric,
        stats.unit,
        stats.user_id,
        stats.`min`,
        stats.`max`,
        stats.`mean`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats;
END //

CREATE PROCEDURE refresh_metric_aggregate_month()
BEGIN
    TRUNCATE TABLE metric_aggregate_month;

    INSERT INTO metric_aggregate_month (month_start_date, metric, unit, user_id, `min`, `max`, `mean`, `count`, refreshed_at)
    WITH ordered AS (
        SELECT
            DATE_FORMAT(`timestamp`, '%Y-%m-01') AS month_start_date,
            metric,
            unit,
            user_id,
            value,
            ROW_NUMBER() OVER (
                PARTITION BY DATE_FORMAT(`timestamp`, '%Y-%m-01'), metric, user_id
                ORDER BY value
            ) AS row_number_in_bucket,
            COUNT(*) OVER (
                PARTITION BY DATE_FORMAT(`timestamp`, '%Y-%m-01'), metric, user_id
            ) AS bucket_count
        FROM metric_fact
    ),
    stats AS (
        SELECT
            DATE_FORMAT(`timestamp`, '%Y-%m-01') AS month_start_date,
            metric,
            unit,
            user_id,
            MIN(value) AS `min`,
            MAX(value) AS `max`,
            AVG(value) AS `mean`,
            COUNT(*) AS `count`
        FROM metric_fact
        GROUP BY DATE_FORMAT(`timestamp`, '%Y-%m-01'), metric, unit, user_id
    )
    SELECT
        CAST(stats.month_start_date AS DATE),
        stats.metric,
        stats.unit,
        stats.user_id,
        stats.`min`,
        stats.`max`,
        stats.`mean`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats;
END //

CREATE PROCEDURE refresh_metric_aggregate_year()
BEGIN
    TRUNCATE TABLE metric_aggregate_year;

    INSERT INTO metric_aggregate_year (year_number, metric, unit, user_id, `min`, `max`, `mean`, `count`, refreshed_at)
    WITH ordered AS (
        SELECT
            YEAR(`timestamp`) AS year_number,
            metric,
            unit,
            user_id,
            value,
            ROW_NUMBER() OVER (
                PARTITION BY YEAR(`timestamp`), metric, user_id
                ORDER BY value
            ) AS row_number_in_bucket,
            COUNT(*) OVER (
                PARTITION BY YEAR(`timestamp`), metric, user_id
            ) AS bucket_count
        FROM metric_fact
    ),
    stats AS (
        SELECT
            YEAR(`timestamp`) AS year_number,
            metric,
            unit,
            user_id,
            MIN(value) AS `min`,
            MAX(value) AS `max`,
            AVG(value) AS `mean`,
            COUNT(*) AS `count`
        FROM metric_fact
        GROUP BY YEAR(`timestamp`), metric, unit, user_id
    )
    SELECT
        stats.year_number,
        stats.metric,
        stats.unit,
        stats.user_id,
        stats.`min`,
        stats.`max`,
        stats.`mean`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats;
END //

CREATE PROCEDURE refresh_metric_aggregate_day_bucket(
    IN p_user_id BIGINT UNSIGNED, IN p_metric VARCHAR(191), IN p_unit VARCHAR(32), IN p_sample_timestamp DATETIME
)
BEGIN
    INSERT INTO metric_aggregate_day (day_date, metric, unit, user_id, `min`, `max`, `mean`, `count`, refreshed_at)
    WITH ordered AS (
        SELECT
            value,
            ROW_NUMBER() OVER (ORDER BY value) AS row_number_in_bucket,
            COUNT(*) OVER () AS bucket_count
        FROM metric_fact
        WHERE user_id = p_user_id AND metric = p_metric AND DATE(`timestamp`) = DATE(p_sample_timestamp)
    ),
    stats AS (
        SELECT
            MIN(value) AS `min`,
            MAX(value) AS `max`,
            AVG(value) AS `mean`,
            COUNT(*) AS `count`
        FROM metric_fact
        WHERE user_id = p_user_id AND metric = p_metric AND DATE(`timestamp`) = DATE(p_sample_timestamp)
    )
    SELECT
        DATE(p_sample_timestamp),
        p_metric,
        p_unit,
        p_user_id,
        stats.`min`,
        stats.`max`,
        stats.`mean`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats
    ON DUPLICATE KEY UPDATE
        unit = VALUES(unit),
        `min` = VALUES(`min`),
        `max` = VALUES(`max`),
        `mean` = VALUES(`mean`),
        `count` = VALUES(`count`),
        refreshed_at = VALUES(refreshed_at);
END //

CREATE PROCEDURE refresh_metric_aggregate_week_bucket(
    IN p_user_id BIGINT UNSIGNED, IN p_metric VARCHAR(191), IN p_unit VARCHAR(32), IN p_sample_timestamp DATETIME
)
BEGIN
    INSERT INTO metric_aggregate_week (week_start_date, metric, unit, user_id, `min`, `max`, `mean`, `count`, refreshed_at)
    WITH ordered AS (
        SELECT
            value,
            ROW_NUMBER() OVER (ORDER BY value) AS row_number_in_bucket,
            COUNT(*) OVER () AS bucket_count
        FROM metric_fact
        WHERE user_id = p_user_id AND metric = p_metric
            AND DATE_SUB(DATE(`timestamp`), INTERVAL WEEKDAY(DATE(`timestamp`)) DAY) = DATE_SUB(DATE(p_sample_timestamp), INTERVAL WEEKDAY(DATE(p_sample_timestamp)) DAY)
    ),
    stats AS (
        SELECT
            MIN(value) AS `min`,
            MAX(value) AS `max`,
            AVG(value) AS `mean`,
            COUNT(*) AS `count`
        FROM metric_fact
        WHERE user_id = p_user_id AND metric = p_metric
            AND DATE_SUB(DATE(`timestamp`), INTERVAL WEEKDAY(DATE(`timestamp`)) DAY) = DATE_SUB(DATE(p_sample_timestamp), INTERVAL WEEKDAY(DATE(p_sample_timestamp)) DAY)
    )
    SELECT
        DATE_SUB(DATE(p_sample_timestamp), INTERVAL WEEKDAY(DATE(p_sample_timestamp)) DAY),
        p_metric,
        p_unit,
        p_user_id,
        stats.`min`,
        stats.`max`,
        stats.`mean`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats
    ON DUPLICATE KEY UPDATE
        unit = VALUES(unit),
        `min` = VALUES(`min`),
        `max` = VALUES(`max`),
        `mean` = VALUES(`mean`),
        `count` = VALUES(`count`),
        refreshed_at = VALUES(refreshed_at);
END //

CREATE PROCEDURE refresh_metric_aggregate_month_bucket(
    IN p_user_id BIGINT UNSIGNED, IN p_metric VARCHAR(191), IN p_unit VARCHAR(32), IN p_sample_timestamp DATETIME
)
BEGIN
    INSERT INTO metric_aggregate_month (month_start_date, metric, unit, user_id, `min`, `max`, `mean`, `count`, refreshed_at)
    WITH ordered AS (
        SELECT
            value,
            ROW_NUMBER() OVER (ORDER BY value) AS row_number_in_bucket,
            COUNT(*) OVER () AS bucket_count
        FROM metric_fact
        WHERE user_id = p_user_id AND metric = p_metric
            AND DATE_FORMAT(`timestamp`, '%Y-%m-01') = DATE_FORMAT(p_sample_timestamp, '%Y-%m-01')
    ),
    stats AS (
        SELECT
            MIN(value) AS `min`,
            MAX(value) AS `max`,
            AVG(value) AS `mean`,
            COUNT(*) AS `count`
        FROM metric_fact
        WHERE user_id = p_user_id AND metric = p_metric
            AND DATE_FORMAT(`timestamp`, '%Y-%m-01') = DATE_FORMAT(p_sample_timestamp, '%Y-%m-01')
    )
    SELECT
        CAST(DATE_FORMAT(p_sample_timestamp, '%Y-%m-01') AS DATE),
        p_metric,
        p_unit,
        p_user_id,
        stats.`min`,
        stats.`max`,
        stats.`mean`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats
    ON DUPLICATE KEY UPDATE
        unit = VALUES(unit),
        `min` = VALUES(`min`),
        `max` = VALUES(`max`),
        `mean` = VALUES(`mean`),
        `count` = VALUES(`count`),
        refreshed_at = VALUES(refreshed_at);
END //

CREATE PROCEDURE refresh_metric_aggregate_year_bucket(
    IN p_user_id BIGINT UNSIGNED, IN p_metric VARCHAR(191), IN p_unit VARCHAR(32), IN p_sample_timestamp DATETIME
)
BEGIN
    INSERT INTO metric_aggregate_year (year_number, metric, unit, user_id, `min`, `max`, `mean`, `count`, refreshed_at)
    WITH ordered AS (
        SELECT
            value,
            ROW_NUMBER() OVER (ORDER BY value) AS row_number_in_bucket,
            COUNT(*) OVER () AS bucket_count
        FROM metric_fact
        WHERE user_id = p_user_id AND metric = p_metric AND YEAR(`timestamp`) = YEAR(p_sample_timestamp)
    ),
    stats AS (
        SELECT
            MIN(value) AS `min`,
            MAX(value) AS `max`,
            AVG(value) AS `mean`,
            COUNT(*) AS `count`
        FROM metric_fact
        WHERE user_id = p_user_id AND metric = p_metric AND YEAR(`timestamp`) = YEAR(p_sample_timestamp)
    )
    SELECT
        YEAR(p_sample_timestamp),
        p_metric,
        p_unit,
        p_user_id,
        stats.`min`,
        stats.`max`,
        stats.`mean`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats
    ON DUPLICATE KEY UPDATE
        unit = VALUES(unit),
        `min` = VALUES(`min`),
        `max` = VALUES(`max`),
        `mean` = VALUES(`mean`),
        `count` = VALUES(`count`),
        refreshed_at = VALUES(refreshed_at);
END //

CREATE PROCEDURE refresh_metric_aggregates()
BEGIN
    CALL refresh_metric_aggregate_day();
    CALL refresh_metric_aggregate_week();
    CALL refresh_metric_aggregate_month();
    CALL refresh_metric_aggregate_year();
END //

DELIMITER ;

CALL refresh_metric_aggregates();
