" ============================================================================
" File:        plugin/delimitMate.vim
" Version:     2.1
" Description: This plugin provides auto-completion for quotes, parens, etc.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
" Manual:      Read ":help delimitMate".

" Initialization: {{{
if exists("g:loaded_delimitMate") "{{{
	" User doesn't want this plugin, let's get out!
	finish
endif
let g:loaded_delimitMate = 1

if exists("s:loaded_delimitMate") && !exists("g:delimitMate_testing")
	" Don't define the functions if they already exist: just do the work
	" (unless we are testing):
	call s:DelimitMateDo()
	finish
endif

if v:version < 700
	echoerr "delimitMate: this plugin requires vim >= 7!"
	finish
endif

let s:loaded_delimitMate = 1 " }}}
let delimitMate_version = '2.1'

"}}}

" Tools: {{{
function! s:Init() "{{{

	let b:loaded_delimitMate = 1

	" delimitMate_autoclose {{{
	if !exists("b:delimitMate_autoclose") && !exists("g:delimitMate_autoclose")
		let b:delimitMate_autoclose = 1
	elseif !exists("b:delimitMate_autoclose") && exists("g:delimitMate_autoclose")
		let b:delimitMate_autoclose = g:delimitMate_autoclose
	else
		" Nothing to do.
	endif " }}}

	" delimitMate_matchpairs {{{
	if !exists("b:delimitMate_matchpairs") && !exists("g:delimitMate_matchpairs")
		let s:matchpairs_temp = &matchpairs
	elseif exists("b:delimitMate_matchpairs")
		let s:matchpairs_temp = b:delimitMate_matchpairs
	else
		let s:matchpairs_temp = g:delimitMate_matchpairs
	endif " }}}

	" delimitMate_quotes {{{
	if exists("b:delimitMate_quotes")
		let s:quotes = split(b:delimitMate_quotes)
	elseif exists("g:delimitMate_quotes")
		let s:quotes = split(g:delimitMate_quotes)
	else
		let s:quotes = split("\" ' `")
	endif
	let b:delimitMate_quotes_list = s:quotes " }}}

	" delimitMate_excluded_regions {{{
	if exists("b:delimitMate_excluded_regions")
		let s:excluded_regions = b:delimitMate_excluded_regions
	elseif exists("g:delimitMate_excluded_regions")
		let s:excluded_regions = g:delimitMate_excluded_regions
	else
		let s:excluded_regions = "Comment"
	endif
	let b:delimitMate_excluded_regions_list = split(s:excluded_regions, ',\s*')
	let b:delimitMate_excluded_regions_enabled = len(b:delimitMate_excluded_regions_list) " }}}

	" delimitMate_visual_leader {{{
	if !exists("b:delimitMate_visual_leader") && !exists("g:delimitMate_visual_leader")
		let b:delimitMate_visual_leader = exists('b:maplocalleader') ? b:maplocalleader :
					\ exists('g:mapleader') ? g:mapleader : "\\"
	elseif !exists("b:delimitMate_visual_leader") && exists("g:delimitMate_visual_leader")
		let b:delimitMate_visual_leader = g:delimitMate_visual_leader
	else
		" Nothing to do.
	endif " }}}

	" delimitMate_expand_space {{{
	if !exists("b:delimitMate_expand_space") && !exists("g:delimitMate_expand_space")
		let b:delimitMate_expand_space = 0
	elseif !exists("b:delimitMate_expand_space") && exists("g:delimitMate_expand_space")
		let b:delimitMate_expand_space = g:delimitMate_expand_space
	else
		" Nothing to do.
	endif " }}}

	" delimitMate_expand_cr {{{
	if !exists("b:delimitMate_expand_cr") && !exists("g:delimitMate_expand_cr")
		let b:delimitMate_expand_cr = 0
	elseif !exists("b:delimitMate_expand_cr") && exists("g:delimitMate_expand_cr")
		let b:delimitMate_expand_cr = g:delimitMate_expand_cr
	else
		" Nothing to do.
	endif " }}}

	" delimitMate_smart_quotes {{{
	if !exists("b:delimitMate_smart_quotes") && !exists("g:delimitMate_smart_quotes")
		let b:delimitMate_smart_quotes = 1
	elseif !exists("b:delimitMate_smart_quotes") && exists("g:delimitMate_smart_quotes")
		let b:delimitMate_smart_quotes = split(g:delimitMate_smart_quotes)
	else
		" Nothing to do.
	endif " }}}

	" delimitMate_apostrophes {{{
	if !exists("b:delimitMate_apostrophes") && !exists("g:delimitMate_apostrophes")
		"let s:apostrophes = split("n't:'s:'re:'m:'d:'ll:'ve:s'",':')
		let s:apostrophes = []
	elseif !exists("b:delimitMate_apostrophes") && exists("g:delimitMate_apostrophes")
		let s:apostrophes = split(g:delimitMate_apostrophes)
	else
		let s:apostrophes = split(b:delimitMate_apostrophes)
	endif
		let b:delimitMate_apostrophes_list = s:apostrophes " }}}

	" delimitMate_tab2exit {{{
	if !exists("b:delimitMate_tab2exit") && !exists("g:delimitMate_tab2exit")
		let b:delimitMate_tab2exit = 1
	elseif !exists("b:delimitMate_tab2exit") && exists("g:delimitMate_tab2exit")
		let b:delimitMate_tab2exit = g:delimitMate_tab2exit
	else
		" Nothing to do.
	endif " }}}

	let b:delimitMate_matchpairs_list = split(s:matchpairs_temp, ',')
	let b:delimitMate_left_delims = split(s:matchpairs_temp, ':.,\=')
	let b:delimitMate_right_delims = split(s:matchpairs_temp, ',\=.:')

	let b:delimitMate_buffer = []

	call delimitMate#UnMap()
	if b:delimitMate_autoclose
		call delimitMate#AutoClose()
	else
		call delimitMate#NoAutoClose()
	endif
	call delimitMate#VisualMaps()
	call delimitMate#ExtraMappings()

endfunction "}}} Init()

function! s:TestMappingsDo() "{{{
	if !exists("g:delimitMate_testing")
		silent call delimitMate#TestMappings()
	else
		let temp_varsDM = [b:delimitMate_expand_space, b:delimitMate_expand_cr, b:delimitMate_autoclose]
		for i in [0,1]
			let b:delimitMate_expand_space = i
			let b:delimitMate_expand_cr = i
			for a in [0,1]
				let b:delimitMate_autoclose = a
				call s:Init()
				call delimitMate#TestMappings()
				exec "normal i\<CR>"
			endfor
		endfor
		let b:delimitMate_expand_space = temp_varsDM[0]
		let b:delimitMate_expand_cr = temp_varsDM[1]
		let b:delimitMate_autoclose = temp_varsDM[2]
		unlet temp_varsDM
	endif
	normal gg
endfunction "}}}

function! s:DelimitMateDo() "{{{
	if exists("g:delimitMate_excluded_ft")
		" Check if this file type is excluded:
		for ft in split(g:delimitMate_excluded_ft,',')
			if ft ==? &filetype
				"echomsg "excluded"
				call delimitMate#UnMap()
				return 1
			endif
		endfor
	endif
	try
		"echomsg "included"
		let save_cpo = &cpo
		let save_keymap = &keymap
		set keymap=
		set cpo&vim
		call s:Init()
	finally
		let &cpo = save_cpo
		let &keymap = save_keymap
	endtry
endfunction "}}}
"}}}

" Commands: {{{
call s:DelimitMateDo()

" Let me refresh without re-loading the buffer:
command! DelimitMateReload call s:DelimitMateDo()

" Quick test:
command! DelimitMateTest call s:TestMappingsDo()

"command! DelimitMateRegions echo s:excluded_regions
" Turn

" Run on file type events.
"autocmd VimEnter * autocmd FileType * call <SID>DelimitMateDo()
autocmd FileType * call <SID>DelimitMateDo()

" Run on new buffers.
autocmd BufNewFile,BufRead,BufEnter * if !exists("b:loaded_delimitMate") | call <SID>DelimitMateDo() | endif

" Flush the char buffer:
autocmd InsertEnter * call delimitMate#FlushBuffer()
autocmd BufEnter * if mode() == 'i' | call delimitMate#FlushBuffer() | endif

"function! s:GetSynRegion () | echo synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name') | endfunction

"}}}

" GetLatestVimScripts: 2754 1 :AutoInstall: delimitMate.vim
" vim:foldmethod=marker:foldcolumn=4
