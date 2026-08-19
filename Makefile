.PHONY: test
test: collector-test dashboard-test etl-test

.PHONY: collector-test
collector-test:
	$(MAKE) -C apps/fitbit-collector test

.PHONY: dashboard-test
dashboard-test:
	$(MAKE) -C apps/health-dashboard test

.PHONY: etl-test
etl-test:
	$(MAKE) -C jobs/health-data-etl test

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
	./db/db-init.sh

.PHONY: aggregates
aggregates:
	./db/refresh-aggregates.sh
