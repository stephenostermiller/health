.PHONY: test
test: collector-test dashboard-test

.PHONY: collector-test
collector-test:
	$(MAKE) -C apps/fitbit-collector test

.PHONY: dashboard-test
dashboard-test:
	$(MAKE) -C apps/health-dashboard test

.PHONY: install
install: collector-install dashboard-install

.PHONY: collector-install
collector-install:
	$(MAKE) -C apps/fitbit-collector install

.PHONY: dashboard-install
dashboard-install:
	$(MAKE) -C apps/health-dashboard install

.PHONY: schema
schema:
	@. ./.env && mysql --host=$${MYSQL_HOST} --user=$${MYSQL_USER} --password=$${MYSQL_PASSWORD} $${MYSQL_DATABASE} < jobs/health-data-etl/db/schema.sql
	@. ./.env && for f in jobs/health-data-etl/db/migrate_*.sql; do echo "Running $$f..."; mysql --host=$${MYSQL_HOST} --user=$${MYSQL_USER} --password=$${MYSQL_PASSWORD} $${MYSQL_DATABASE} < $$f; done

.PHONY: etl-normalize
etl-normalize:
	$(MAKE) -C jobs/health-data-etl normalize

.PHONY: etl-load
etl-load:
	$(MAKE) -C jobs/health-data-etl load

.PHONY: etl-refresh
etl-refresh:
	$(MAKE) -C jobs/health-data-etl refresh
