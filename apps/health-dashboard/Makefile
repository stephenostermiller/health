.PHONY: test
test: test-perl test-js

.PHONY: test-perl
test-perl:
	prove -lr t

.PHONY: test-js
test-js:
	for f in t-js/*.js; do node "$$f" || exit 1; done

.PHONY: smoke
smoke:
	./script/smoke_test.sh

.PHONY: install
install:
	./script/install_apache_conf.sh
