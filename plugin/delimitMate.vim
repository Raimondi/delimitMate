if exists("g:loaded_delimitMate") || &cp || !exists('##InsertCharPre')
  finish
endif
let g:loaded_delimitMate = 1
let save_cpo = &cpo
set cpo&vim

command! -bar -bang DelimitMateSwitch call delimitMate#ex_cmd(<bang>0, 'switch' )
command! -bar -bang DelimitMateOn     call delimitMate#ex_cmd(<bang>0, 'enable' )
command! -bar -bang DelimitMateOff    call delimitMate#ex_cmd(<bang>0, 'disable')

augroup delimitMate
  au!
  au InsertCharPre * call delimitMate#InsertCharPre(v:char)
  au TextChangedI  * call delimitMate#TextChangedI()
  au InsertEnter   * call delimitMate#InsertEnter()
  au CursorMovedI  * call delimitMate#CursorMovedI()
augroup END

let &cpo = save_cpo
" GetLatestVimScripts: 2754 1 :AutoInstall: delimitMate.vim
" vim: sw=2 et
