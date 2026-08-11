.PHONY: test
test: collector-test dashboard-test

.PHONY: collector-test
collector-test:
	$(MAKE) -C apps/fitbit-collector test

.PHONY: dashboard-test
dashboard-test:
	$(MAKE) -C apps/health-dashboard test

.PHONY: install
install: collector-install

.PHONY: collector-install
collector-install:
	$(MAKE) -C apps/fitbit-collector install

.PHONY: etl-normalize
etl-normalize:
	$(MAKE) -C jobs/health-data-etl normalize

.PHONY: etl-load
etl-load:
	$(MAKE) -C jobs/health-data-etl load

.PHONY: etl-refresh
etl-refresh:
	$(MAKE) -C jobs/health-data-etl refresh
