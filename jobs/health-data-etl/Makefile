OUTPUT ?= /tmp/fitbit-metric-stage.tsv
DATABASE ?= $(MYSQL_DATABASE)

.PHONY: normalize
normalize:
	python3 script/normalize_csv_metrics.py csv --output $(OUTPUT)

.PHONY: schema
schema:
	mysql -u "$(MYSQL_USER)" -p"$(MYSQL_PASSWORD)" -h "$(MYSQL_HOST)" --port "$(MYSQL_PORT)" "$(DATABASE)" < db/schema.sql

.PHONY: load
load:
	mysql -u "$(MYSQL_USER)" -p"$(MYSQL_PASSWORD)" -h "$(MYSQL_HOST)" --port "$(MYSQL_PORT)" "$(DATABASE)" -e "TRUNCATE TABLE metric_aggregate_day; TRUNCATE TABLE metric_aggregate_week; TRUNCATE TABLE metric_aggregate_month; TRUNCATE TABLE metric_aggregate_year; TRUNCATE TABLE metric_fact; TRUNCATE TABLE csv_metric_stage; LOAD DATA LOCAL INFILE '$(OUTPUT)' INTO TABLE csv_metric_stage FIELDS TERMINATED BY 0x09 ESCAPED BY 0x5C LINES TERMINATED BY 0x0A (source_file, source_row, @ts_text, @end_ts_text, data_source, metric, value, raw_row_json) SET timestamp = STR_TO_DATE(@ts_text, '%Y-%m-%dT%H:%i:%sZ'), end_timestamp = IF(@end_ts_text = '', NULL, STR_TO_DATE(@end_ts_text, '%Y-%m-%dT%H:%i:%sZ'));"
	mysql -u "$(MYSQL_USER)" -p"$(MYSQL_PASSWORD)" -h "$(MYSQL_HOST)" --port "$(MYSQL_PORT)" "$(DATABASE)" < db/load_stage.sql

.PHONY: refresh
refresh:
	mysql -u "$(MYSQL_USER)" -p"$(MYSQL_PASSWORD)" -h "$(MYSQL_HOST)" --port "$(MYSQL_PORT)" "$(DATABASE)" < db/refresh_aggregates.sql
