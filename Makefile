PLUGIN=$(shell basename "$$PWD")
SCRIPT=$(wildcard plugin/*.vim)
#AUTOL=$(wildcard autoload/*.vim)
AUTOL=autoload/$(PLUGIN).vim
DOC=$(wildcard doc/*.txt)
TESTS=$(wildcard autoload/*Tests.vim)
VERSION=$(shell perl -ne 'if (/\*\sCurrent\srelease:/) {s/^\s+(\d+\.\d+).*$$/\1/;print}' $(DOC))
VIMFOLDER=~/.vim
DATE=`date '+%F'`
VIM=/usr/bin/vim

.PHONY: $(PLUGIN).vba README

all: uninstall vimball install README

vimball: $(PLUGIN).vba

clean:
	@echo clean
	rm -f *.vba */*.orig *.~* .VimballRecord *.zip *.gz

dist-clean: clean

install: vimball
	@echo install
	$(VIM) -N -c ':so %' -c':q!' $(PLUGIN)-$(VERSION).vba
	cp -f autoload/$(PLUGIN)Tests.vim $(VIMFOLDER)/autoload/$(PLUGIN)Tests.vim

uninstall:
	@echo uninstall
	$(VIM) -N -c':RmVimball' -c':q!' $(PLUGIN)-$(VERSION).vba
	rm -f $(VIMFOLDER)/autoload/$(PLUGIN)Tests.txt

undo:
	for i in **/*.orig; do mv -f "$$i" "$${i%.*}"; done

README:
	@echo README
	cp -f $(DOC) README

$(PLUGIN).vba:
	@echo $(PLUGIN).vba
	rm -f $(PLUGIN)-$(VERSION).vba
	$(VIM) -N -c 'ru! vimballPlugin.vim' -c ':call append("0", [ "$(SCRIPT)", "$(AUTOL)", "$(DOC)"])' -c '$$d' -c ":%MkVimball $(PLUGIN)-$(VERSION)  ." -c':q!'
	ln -f $(PLUGIN)-$(VERSION).vba $(PLUGIN).vba

zip:
	@echo zip
	zip -r $(PLUGIN).zip doc plugin autoload
	zip $(PLUGIN).zip -d \*.sw\?
	zip $(PLUGIN).zip -d autoload/$(PLUGIN)Tests.vim

gzip: vimball
	@echo vimball
	gzip -f $(PLUGIN).vba

release: version all

version:
	@echo version: $(VERSION)
	perl -i.orig -pne 'if (/^"\sVersion:/) {s/(\d+\.\d+)/$(VERSION)/e}' $(SCRIPT) $(AUTOL)
	perl -i.orig -pne 'if (/let\sdelimitMate_version/) {s/(\d+\.\d+)/$(VERSION)/e}' $(SCRIPT)
	perl -i.orig -pne 'if (/beasts/) {s/(v\d+\.\d+)/v.$(VERSION)/e}' $(DOC)
	perl -i.orig -pne 'if (/^"\sModified:/) {s/(\d+-\d+-\d+)/sprintf("%s", `date "+%F"`)/e}' $(SCRIPT) $(AUTOL)
	perl -i.orig -pne 'if (/^\s+$(VERSION)\s+\d+-\d+-\d+\s+\*/) {s/(\d+-\d+-\d+)/$(DATE)/e}' $(DOC)
	@echo Version: $(VERSION)

echo:
