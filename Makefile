PLUGIN=$(shell basename "$$PWD")
SCRIPT=$(wildcard plugin/*.vim)
#AUTOL=$(wildcard autoload/*.vim)
AUTOL=autoload/$(PLUGIN).vim
DOC=$(wildcard doc/*.txt)
TESTS=$(wildcard autoload/*Tests.vim)
VERSION=$(shell perl -ne 'if (/\*\sCurrent\srelease:/) {s/^\s+(\d+\.\S+)\s.*$$/\1/;print}' $(DOC))
VIMFOLDER=~/.vim/
VIM=/usr/bin/vim

.PHONY: $(PLUGIN).vba README

all: vimball README zip gzip

vimball: $(PLUGIN).vba

clean:
	@echo clean
	rm -f *.vba */*.orig *.~* .VimballRecord *.zip *.gz

dist-clean: clean

undo:
	for i in */*.orig; do mv -f "$$i" "$${i%.*}"; done

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
	rm -f *.zip
	zip -r $(PLUGIN).zip doc plugin autoload
	zip $(PLUGIN).zip -d \*.sw\? || echo 1
	zip $(PLUGIN).zip -d \*.un\? || echo 1
	zip $(PLUGIN).zip -d \*.orig || echo 1
	zip $(PLUGIN).zip -d \*tags  || echo 1
	zip $(PLUGIN).zip -d $(TESTS)
	ln -f $(PLUGIN).zip $(PLUGIN)-$(VERSION).zip

gzip: vimball
	@echo vimball
	gzip -f $(PLUGIN).vba

release: version all

version:
	@echo version: $(VERSION)
	perl -i.orig -pne 'if (/^"\sVersion:/) {s/(\d+\.\S+)/$(VERSION)/}' $(SCRIPT) $(AUTOL)
	perl -i.orig -pne 'if (/let\sdelimitMate_version/) {s/"(\d+\.\S+)"/"$(VERSION)"/}' $(SCRIPT)
	perl -i.orig -pne 'if (/beasts/) {s/(v\d+\.\S+)/v$(VERSION)/}' $(DOC)
	perl -i.orig -MPOSIX -pne 'if (/^"\sModified:/) {$$now_string = strftime "%F", localtime; s/(\d+-\d+-\d+)/$$now_string/e}' $(SCRIPT) $(AUTOL)
	perl -i.orig -MPOSIX -pne 'if (/^\s+$(VERSION)\s+\d+-\d+-\d+\s+\*/) {$$now_string = strftime "%F", localtime; s/(\d+-\d+-\d+)/$$now_string/}' $(DOC)
	@echo Version: $(VERSION)

echo:
