" ============================================================================
" File:        delimitMate.vim
" Version:     2.0
" Description: This plugin tries to emulate the auto-completion of delimiters
"              that TextMate provides.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
" Manual:      Read ":help delimitMate".
" Credits:     Some of the code is modified or just copied from the following:
"
"              - Ian McCracken
"           	 Post titled: Vim, Part II: Matching Pairs:
"           	 http://concisionandconcinnity.blogspot.com/
"
"              - Aristotle Pagaltzis
"           	 From the comments on the previous blog post and from:
"           	 http://gist.github.com/144619
"
"              - Vim Scripts:
"           	 http://www.vim.org/scripts/

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
let delimitMate_version = '2.0'

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
		let s:excluded_regions = split("Comment")
	endif
	let b:delimitMate_excluded_regions_list = s:excluded_regions " }}}

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

	call s:UnMap()
	if b:delimitMate_autoclose
		call delimitMate#AutoClose()
	else
		call delimitMate#NoAutoClose()
	endif
	call delimitMate#VisualMaps()
	call delimitMate#ExtraMappings()

endfunction "}}} Init()
"}}}

" Tools: {{{
function! s:UnMap() " {{{
	" No Autoclose Mappings:
	for char in b:delimitMate_right_delims + b:delimitMate_quotes_list
		if maparg(char,"i") =~? 'SkipDelim'
			exec 'silent! iunmap <buffer> ' . char
			"echomsg 'iunmap <buffer> ' . char
		endif
	endfor

	" Autoclose Mappings:
	let i = 0
	let l = len(b:delimitMate_matchpairs_list)
	while i < l
		if maparg(b:delimitMate_left_delims[i],"i") =~? 'JumpIn'
			exec 'silent! iunmap <buffer> ' . b:delimitMate_left_delims[i]
			"echomsg 'iunmap <buffer> ' . b:delimitMate_left_delims[i]
		endif
		let i += 1
	endwhile
	for char in b:delimitMate_quotes_list
		if maparg(char, "i") =~? 'QuoteDelim'
			exec 'silent! iunmap <buffer> ' . char
			"echomsg 'iunmap <buffer> ' . char
		endif
	endfor
	for char in b:delimitMate_right_delims
		if maparg(char, "i") =~? 'JumpOut'
			exec 'silent! iunmap <buffer> ' . char
			"echomsg 'iunmap <buffer> ' . char
		endif
	endfor
	for map in b:delimitMate_apostrophes_list
		exec "silent! iunmap <buffer> " . map
	endfor

	" Visual Mappings:
	for char in b:delimitMate_right_delims + b:delimitMate_left_delims + b:delimitMate_quotes_list
		if maparg(b:delimitMate_visual_leader . char,"v") =~? 'IsBlock'
			exec 'silent! vunmap <buffer> ' . b:delimitMate_visual_leader . char
			"echomsg 'vunmap <buffer> ' . b:delimitMate_visual_leader . char
		endif
	endfor

	" Expansion Mappings:
	if maparg('<BS>', "i") =~? 'WithinEmptyPair'
		silent! iunmap <buffer> <BS>
		"echomsg "silent! iunmap <buffer> <BS>"
	endif
	if maparg('<S-BS>', "i") =~? 'WithinEmptyPair'
		silent! iunmap <buffer> <BS>
		"echomsg "silent! iunmap <buffer> <BS>"
	endif
	if maparg('<CR>',"i") =~? 'DelimitMate_ExpandReturn'
		silent! iunmap <buffer> <CR>
		"echomsg "silent! iunmap <buffer> <CR>"
	endif
	if maparg('<Space>',"i") =~? 'DelimitMate_ExpandSpace'
		silent! iunmap <buffer> <Space>
		"echomsg "silent! iunmap <buffer> <Space>"
	endif
	if maparg('<S-Tab>', "i") =~? 'ShouldJump'
		silent! iunmap <buffer> <S-Tab>
		"echomsg "silent! iunmap <buffer> <S-Tab>"
	endif
endfunction " }}} s:ExtraMappings()

function! s:TestMappingsDo() "{{{
	if !exists("g:delimitMate_testing")
		call delimitMate#TestMappings()
	else
		let temp_varsDM = [b:delimitMate_expand_space, b:delimitMate_expand_cr, b:delimitMate_autoclose]
		for i in [0,1]
			let b:delimitMate_expand_space = i
			let b:delimitMate_expand_cr = i
			for a in [0,1]
				let b:delimitMate_autoclose = a
				call s:Init()
				exec "normal i b:delimitMate_autoclose: " . b:delimitMate_autoclose . "\<CR>"
				exec "normal i b:delimitMate_expand_space: " . b:delimitMate_expand_space . "\<CR>"
				exec "normal i b:delimitMate_expand_cr: " . b:delimitMate_expand_cr . "\<CR>\<CR>"
				call delimitMate#TestMappings()
				exec "normal i\<CR>"
			endfor
		endfor
		let b:delimitMate_expand_space = temp_varsDM[0]
		let b:delimitMate_expand_cr = temp_varsDM[1]
		let b:delimitMate_autoclose = temp_varsDM[2]
		unlet temp_varsDM
		normal gg
	endif
endfunction "}}}


function! s:DelimitMateDo() "{{{
	if exists("g:delimitMate_excluded_ft")
		" Check if this file type is excluded:
		for ft in split(g:delimitMate_excluded_ft,',')
			if ft ==? &filetype
				if !exists("b:delimitMate_quotes_list")
					return 1
				endif
				"echomsg "excluded"
				call s:UnMap()
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
       let save_keymap = &keymap
       set keymap=
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

" Run on file type events.
"autocmd VimEnter * autocmd FileType * call <SID>DelimitMateDo()
autocmd FileType * call <SID>DelimitMateDo()

" Run on new buffers.
autocmd BufNewFile,BufRead,BufEnter * if !exists("b:loaded_delimitMate") | call <SID>DelimitMateDo() | endif

"}}}

" GetLatestVimScripts: 2754 1 :AutoInstall: delimitMate.vim
" vim:foldmethod=marker:foldcolumn=4
