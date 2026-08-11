CREATE TABLE IF NOT EXISTS csv_metric_stage (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    source_file VARCHAR(255) NOT NULL,
    source_row BIGINT UNSIGNED NOT NULL,
    `timestamp` DATETIME NOT NULL,
    end_timestamp DATETIME NULL,
    data_source VARCHAR(191) NULL,
    metric VARCHAR(191) NOT NULL,
    unit VARCHAR(32) NOT NULL DEFAULT '',
    value DECIMAL(20,6) NOT NULL,
    raw_row_json JSON NOT NULL,
    loaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_csv_metric_stage_row (source_file, source_row, metric),
    KEY idx_csv_metric_stage_metric_time (metric, `timestamp`),
    KEY idx_csv_metric_stage_source (source_file)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS metric_fact (
    `timestamp` DATETIME NOT NULL,
    metric VARCHAR(191) NOT NULL,
    unit VARCHAR(32) NOT NULL DEFAULT '',
    user_id BIGINT UNSIGNED NOT NULL,
    value DECIMAL(20,6) NOT NULL,
    data_source VARCHAR(191) NULL,
    source_file VARCHAR(255) NOT NULL,
    source_row BIGINT UNSIGNED NOT NULL,
    end_timestamp DATETIME NULL,
    loaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`timestamp`, metric, user_id, source_file, source_row),
    KEY idx_metric_fact_metric_time (metric, `timestamp`),
    KEY idx_metric_fact_time (`timestamp`),
    KEY idx_metric_fact_source (data_source),
    KEY idx_metric_fact_user_metric_time (user_id, metric, `timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS metric_aggregate_day (
    day_date DATE NOT NULL,
    metric VARCHAR(191) NOT NULL,
    unit VARCHAR(32) NOT NULL DEFAULT '',
    user_id BIGINT UNSIGNED NOT NULL,
    `min` DECIMAL(20,6) NOT NULL,
    `max` DECIMAL(20,6) NOT NULL,
    `mean` DECIMAL(20,6) NOT NULL,
    `sum` DECIMAL(20,6) NOT NULL,
    `count` BIGINT UNSIGNED NOT NULL,
    refreshed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (day_date, metric, user_id),
    KEY idx_metric_aggregate_day_metric (metric)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS metric_aggregate_week (
    week_start_date DATE NOT NULL,
    metric VARCHAR(191) NOT NULL,
    unit VARCHAR(32) NOT NULL DEFAULT '',
    user_id BIGINT UNSIGNED NOT NULL,
    `min` DECIMAL(20,6) NOT NULL,
    `max` DECIMAL(20,6) NOT NULL,
    `mean` DECIMAL(20,6) NOT NULL,
    `sum` DECIMAL(20,6) NOT NULL,
    `count` BIGINT UNSIGNED NOT NULL,
    refreshed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (week_start_date, metric, user_id),
    KEY idx_metric_aggregate_week_metric (metric)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS metric_aggregate_month (
    month_start_date DATE NOT NULL,
    metric VARCHAR(191) NOT NULL,
    unit VARCHAR(32) NOT NULL DEFAULT '',
    user_id BIGINT UNSIGNED NOT NULL,
    `min` DECIMAL(20,6) NOT NULL,
    `max` DECIMAL(20,6) NOT NULL,
    `mean` DECIMAL(20,6) NOT NULL,
    `sum` DECIMAL(20,6) NOT NULL,
    `count` BIGINT UNSIGNED NOT NULL,
    refreshed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (month_start_date, metric, user_id),
    KEY idx_metric_aggregate_month_metric (metric)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS metric_aggregate_year (
    year_number SMALLINT UNSIGNED NOT NULL,
    metric VARCHAR(191) NOT NULL,
    unit VARCHAR(32) NOT NULL DEFAULT '',
    user_id BIGINT UNSIGNED NOT NULL,
    `min` DECIMAL(20,6) NOT NULL,
    `max` DECIMAL(20,6) NOT NULL,
    `mean` DECIMAL(20,6) NOT NULL,
    `sum` DECIMAL(20,6) NOT NULL,
    `count` BIGINT UNSIGNED NOT NULL,
    refreshed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (year_number, metric, user_id),
    KEY idx_metric_aggregate_year_metric (metric)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
