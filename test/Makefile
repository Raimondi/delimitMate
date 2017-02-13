all: build/runVimTests
	time build/runVimTests/bin/runVimTests.sh -0 .

build/runVimTests: build/VimTAP
	git clone https://github.com/inkarkat/runVimTests $@

# Use VimTAP as directory name, as used with runVimTestsSetup.vim.
build/VimTAP:
	git clone https://github.com/inkarkat/vimtap $@

test_files := $(filter-out _setup.vim,$(wildcard *.vim))

.PHONY: $(test_files)

$(test_files):
	time build/runVimTests/bin/runVimTests.sh -0 $@
