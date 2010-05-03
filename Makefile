PLUGIN=delimitMate

install:
	install -m 755 -d ~/.vim
	install -m 755 -d ~/.vim/plugin/
	install -m 755 -d ~/.vim/autoload/
	install -m 755 -d ~/.vim/doc/
	cp -f doc/${PLUGIN}.txt      ~/.vim/doc/${PLUGIN}.txt
	cp -f plugin/${PLUGIN}.vim   ~/.vim/plugin/${PLUGIN}.vim
	cp -f autoload/${PLUGIN}.vim ~/.vim/autoload/${PLUGIN}.vim

doc_update: install
	/usr/bin/vim -u NONE -c ':helptags ~/.vim/doc' -c ':q'

zip:
	zip -r ${PLUGIN}.zip doc plugin autoload
	zip ${PLUGIN}.zip -d \*.sw\?

vimball: install
	echo doc/${PLUGIN}.txt > vimball.txt
	echo plugin/${PLUGIN}.vim >> vimball.txt
	echo autoload/${PLUGIN}.vim >> vimball.txt
	/usr/bin/vim  -c 'e vimball.txt' -c '%MkVimball! ${PLUGIN}' -c 'q'

gzip: vimball
	gzip -f ${PLUGIN}.vba

