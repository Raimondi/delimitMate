.DEFAULT: test

test_files := $(filter-out _setup.vim,$(wildcard test/*.vim))

.PHONY: all test $(test_files)

test:
	$(MAKE) -C test

$(test_files):
	$(MAKE) -C test $(patsubst test/%,%,$@)
