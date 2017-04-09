.DEFAULT: test

test_files := $(wildcard test/*.test)
short_targets := $(patsubst test/%,%,$(test_files))

.PHONY: monitor test $(test_files) $(short_targets)

test:
	$(MAKE) -C test

monitor:
	$(MAKE) -C test monitor

$(test_files) $(short_targets):
	$(MAKE) -C test $(patsubst test/%,%,$@)
