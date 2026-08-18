OUTPUT ?= /tmp/fitbit-metric-stage.tsv
DATABASE ?= $(MYSQL_DATABASE)

define mysql_cmd
bash -c 'mysql --defaults-extra-file="../../.my.cnf" "$(DATABASE)" $(1)'
endef

.PHONY: normalize
normalize:
	python3 script/normalize_csv_metrics.py csv --output $(OUTPUT)

.PHONY: schema
schema:
	$(call mysql_cmd,< ../../db/schema/schema.sql)

.PHONY: load
load:
	$(call mysql_cmd,-e "TRUNCATE TABLE metric_aggregate_day; TRUNCATE TABLE metric_aggregate_week; TRUNCATE TABLE metric_aggregate_month; TRUNCATE TABLE metric_aggregate_year; TRUNCATE TABLE metric_fact; TRUNCATE TABLE csv_metric_stage; LOAD DATA LOCAL INFILE '$(OUTPUT)' INTO TABLE csv_metric_stage FIELDS TERMINATED BY 0x09 ESCAPED BY 0x5C LINES TERMINATED BY 0x0A (source_file, source_row, @ts_text, @end_ts_text, data_source, metric, value, raw_row_json) SET timestamp = STR_TO_DATE(@ts_text, '%Y-%m-%dT%H:%i:%sZ'), end_timestamp = IF(@end_ts_text = '', NULL, STR_TO_DATE(@end_ts_text, '%Y-%m-%dT%H:%i:%sZ'));")
	$(call mysql_cmd,< ../../db/utilities/load_stage.sql)

.PHONY: refresh
refresh:
	$(call mysql_cmd,< ../../db/utilities/refresh_aggregates.sql)
