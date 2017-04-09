test_files := $(wildcard *.test)

.PHONY: all monitor $(test_files)

all:
	time tclsh all.tcl

$(test_files):
	time tclsh $@
	printf "\a"

monitor:
	fswatch -o ../autoload/*.vim ../plugin/*.vim *.test \
		| xargs -n1 -I\{\} time tclsh all.tcl || printf "\a"
