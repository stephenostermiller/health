DATABASE ?= $(MYSQL_DATABASE)

define mysql_cmd
bash -c 'mysql --defaults-extra-file="../../.my.cnf" "$(DATABASE)" $(1)'
endef

.PHONY: schema
schema:
	$(call mysql_cmd,< ../../db/schema/schema.sql)

.PHONY: test
test:
	prove -lr t
