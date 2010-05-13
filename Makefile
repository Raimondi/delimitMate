PLUGIN=delimitMate
VIMFOLDER=~/.vim

install:
	install -m 755 -d ${VIMFOLDER}
	install -m 755 -d ${VIMFOLDER}/plugin/
	install -m 755 -d ${VIMFOLDER}/autoload/
	install -m 755 -d ${VIMFOLDER}/doc/
	cp -f doc/${PLUGIN}.txt      ${VIMFOLDER}/doc/${PLUGIN}.txt
	cp -f plugin/${PLUGIN}.vim   ${VIMFOLDER}/plugin/${PLUGIN}.vim
	cp -f autoload/${PLUGIN}.vim ${VIMFOLDER}/autoload/${PLUGIN}.vim
	cp -f autoload/${PLUGIN}Tests.vim ${VIMFOLDER}/autoload/${PLUGIN}Tests.vim

doc_update: install
	/usr/bin/vim -u NONE -c ':helptags ${VIMFOLDER}/doc' -c ':q'

zip:
	zip -r ${PLUGIN}.zip doc plugin autoload
	zip ${PLUGIN}.zip -d \*.sw\?
	zip ${PLUGIN}.zip -d autoload/${PLUGIN}Tests.vim

vimball: install
	echo doc/${PLUGIN}.txt > vimball.txt
	echo plugin/${PLUGIN}.vim >> vimball.txt
	echo autoload/${PLUGIN}.vim >> vimball.txt
	/usr/bin/vim  -c 'e vimball.txt' -c '%MkVimball! ${PLUGIN}' -c 'q'

gzip: vimball
	gzip -f ${PLUGIN}.vba

uninstall:
	rm -f ${VIMFOLDER}/plugin/${PLUGIN}.vim
	rm -f ${VIMFOLDER}/autoload/${PLUGIN}.vim
	rm -f ${VIMFOLDER}/doc/${PLUGIN}.txt
	rm -f ${VIMFOLDER}/autoload/${PLUGIN}Tests.txt
