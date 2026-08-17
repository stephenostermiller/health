DROP PROCEDURE IF EXISTS refresh_metric_aggregates;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_year;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_month;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_week;
DROP PROCEDURE IF EXISTS refresh_metric_aggregate_day;

DELIMITER //

CREATE PROCEDURE refresh_metric_aggregate_day()
BEGIN
    TRUNCATE TABLE metric_aggregate_day;

    INSERT INTO metric_aggregate_day (day_date, metric, unit, user_id, `min`, `max`, `mean`, `sum`, `count`, refreshed_at)
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
            SUM(value) AS `sum`,
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
        stats.`sum`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats;
END //

CREATE PROCEDURE refresh_metric_aggregate_week()
BEGIN
    TRUNCATE TABLE metric_aggregate_week;

    INSERT INTO metric_aggregate_week (week_start_date, metric, unit, user_id, `min`, `max`, `mean`, `sum`, `count`, refreshed_at)
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
            SUM(value) AS `sum`,
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
        stats.`sum`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats;
END //

CREATE PROCEDURE refresh_metric_aggregate_month()
BEGIN
    TRUNCATE TABLE metric_aggregate_month;

    INSERT INTO metric_aggregate_month (month_start_date, metric, unit, user_id, `min`, `max`, `mean`, `sum`, `count`, refreshed_at)
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
            SUM(value) AS `sum`,
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
        stats.`sum`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats;
END //

CREATE PROCEDURE refresh_metric_aggregate_year()
BEGIN
    TRUNCATE TABLE metric_aggregate_year;

    INSERT INTO metric_aggregate_year (year_number, metric, unit, user_id, `min`, `max`, `mean`, `sum`, `count`, refreshed_at)
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
            SUM(value) AS `sum`,
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
        stats.`sum`,
        stats.`count`,
        CURRENT_TIMESTAMP
    FROM stats;
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
