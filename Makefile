PLUGIN=delimitMate

install:
	cp -f doc/* ~/.vim/doc/${PLUGIN}.txt
	cp -f plugin/* ~/.vim/plugin/${PLUGIN}.vim
	vim -u NONE -c 'helptags ~/.vim/doc' -c 'q'

zip:
	zip -r ${PLUGIN}.zip doc plugin
	zip ${PLUGIN}.zip -d \*.sw\?

vimball: install
	echo doc/${PLUGIN}.txt > vimball.txt
	echo plugin/${PLUGIN}.vim >> vimball.txt
	vim  -c 'e vimball.txt' -c '%MkVimball! ${PLUGIN}' -c 'q'
