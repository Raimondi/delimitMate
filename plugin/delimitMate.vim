" File:        plugin/delimitMate.vim
" Version:     2.7
" Modified:    2013-07-15
" Description: This plugin provides auto-completion for quotes, parens, etc.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
" Manual:      Read ":help delimitMate".
" ============================================================================

" Initialization: {{{

if exists("g:loaded_delimitMate") || &cp
	" User doesn't want this plugin or compatible is set, let's get out!
	finish
endif
let g:loaded_delimitMate = 1
let save_cpo = &cpo
set cpo&vim

if v:version < 700
	echoerr "delimitMate: this plugin requires vim >= 7!"
	finish
endif

let s:loaded_delimitMate = 1
let delimitMate_version = "2.7"

function! s:option_init(name, default) "{{{
	let b = exists("b:delimitMate_" . a:name)
	let g = exists("g:delimitMate_" . a:name)
	" Find value to use.
	if !b && !g
		let value = a:default
	elseif b
		exec "let value = b:delimitMate_" . a:name
	else
		exec "let value = g:delimitMate_" . a:name
	endif
	call s:s(a:name, value)
endfunction "}}}

function! s:init() "{{{
" Initialize variables:
	" autoclose
	call s:option_init("autoclose", 1)
	" matchpairs
	call s:option_init("matchpairs", string(&matchpairs)[1:-2])
	call s:option_init("matchpairs_list", map(split(s:g('matchpairs'), ','), 'split(v:val, '':'')'))
	let pairs = s:g('matchpairs_list')
	if len(filter(pairs, 'v:val[0] ==# v:val[1]'))
		echohl ErrorMsg
		echom 'delimitMate: each member of a pair in delimitMate_matchpairs must be different from each other.'
		echom 'delimitMate: invalid pairs: ' . join(map(pairs, 'join(v:val, ":")'), ', ')
		echohl Normal
		return 0
	endif
	call s:option_init("left_delims", map(copy(s:g('matchpairs_list')), 'v:val[0]'))
	call s:option_init("right_delims", map(copy(s:g('matchpairs_list')), 'v:val[1]'))
	" quotes
	call s:option_init("quotes", "\" ' `")
	call s:option_init("quotes_list",split(s:g('quotes'), '\s\+'))
	" nesting_quotes
	call s:option_init("nesting_quotes", [])
	" excluded_regions
	call s:option_init("excluded_regions", "Comment")
	call s:option_init("excluded_regions_list", split(s:g('excluded_regions'), ',\s*'))
	let enabled = len(s:g('excluded_regions_list')) > 0
	call s:option_init("excluded_regions_enabled", enabled)
	" excluded filetypes
	call s:option_init("excluded_ft", "")
	" expand_space
	if exists("b:delimitMate_expand_space") && type(b:delimitMate_expand_space) == type("")
		echom "b:delimitMate_expand_space is '".b:delimitMate_expand_space."' but it must be either 1 or 0!"
		echom "Read :help 'delimitMate_expand_space' for more details."
		unlet b:delimitMate_expand_space
		let b:delimitMate_expand_space = 1
	endif
	if exists("g:delimitMate_expand_space") && type(g:delimitMate_expand_space) == type("")
		echom "delimitMate_expand_space is '".g:delimitMate_expand_space."' but it must be either 1 or 0!"
		echom "Read :help 'delimitMate_expand_space' for more details."
		unlet g:delimitMate_expand_space
		let g:delimitMate_expand_space = 1
	endif
	call s:option_init("expand_space", 0)
	" expand_cr
	if exists("b:delimitMate_expand_cr") && type(b:delimitMate_expand_cr) == type("")
		echom "b:delimitMate_expand_cr is '".b:delimitMate_expand_cr."' but it must be either 1 or 0!"
		echom "Read :help 'delimitMate_expand_cr' for more details."
		unlet b:delimitMate_expand_cr
		let b:delimitMate_expand_cr = 1
	endif
	if exists("g:delimitMate_expand_cr") && type(g:delimitMate_expand_cr) == type("")
		echom "delimitMate_expand_cr is '".g:delimitMate_expand_cr."' but it must be either 1 or 0!"
		echom "Read :help 'delimitMate_expand_cr' for more details."
		unlet g:delimitMate_expand_cr
		let g:delimitMate_expand_cr = 1
	endif
	if ((&backspace !~ 'eol' || &backspace !~ 'start') && &backspace != 2) &&
				\ ((exists('b:delimitMate_expand_cr') && b:delimitMate_expand_cr == 1) ||
				\ (exists('g:delimitMate_expand_cr') && g:delimitMate_expand_cr == 1))
		echom "delimitMate: There seems to be some incompatibility with your settings that may interfer with the expansion of <CR>. See :help 'delimitMate_expand_cr' for details."
	endif
	call s:option_init("expand_cr", 0)
	" expand_in_quotes
	call s:option_init('expand_inside_quotes', 0)
	" jump_expansion
	call s:option_init("jump_expansion", 0)
	" smart_matchpairs
	call s:option_init("smart_matchpairs", '^\%(\w\|\!\|£\|\$\|_\|["'']\s*\S\)')
	" smart_quotes
	call s:option_init("smart_quotes", 1)
	" apostrophes
	call s:option_init("apostrophes", "")
	call s:option_init("apostrophes_list", split(s:g('apostrophes'), ":\s*"))
	" tab2exit
	call s:option_init("tab2exit", 1)
	" balance_matchpairs
	call s:option_init("balance_matchpairs", 0)
	" eol marker
	call s:option_init("eol_marker", "")
	" Everything is fine.
	return 1
endfunction "}}} Init()

"}}}

" Functions: {{{

function! s:g(...) " {{{
	return call('delimitMate#Get', a:000)
endfunction " }}}

function! s:s(...) " {{{
	return call('delimitMate#Set', a:000)
endfunction " }}}

function! s:Map() "{{{
	" Set mappings:
	try
		let save_keymap = &keymap
		let save_iminsert = &iminsert
		let save_imsearch = &imsearch
		let save_cpo = &cpo
		set keymap=
		set cpo&vim
		if s:g('autoclose')
			call s:AutoClose()
		else
			call s:NoAutoClose()
		endif
		call s:ExtraMappings()
	finally
		let &cpo = save_cpo
		let &keymap = save_keymap
		let &iminsert = save_iminsert
		let &imsearch = save_imsearch
	endtry

	let b:delimitMate_enabled = 1

endfunction "}}} Map()

function! s:Unmap() " {{{
	let imaps =
				\ s:g('right_delims') +
				\ s:g('left_delims') +
				\ s:g('quotes_list') +
				\ s:g('apostrophes_list') +
				\ ['<BS>', '<C-h>', '<S-BS>', '<Del>', '<CR>', '<Space>', '<S-Tab>', '<Esc>'] +
				\ ['<Up>', '<Down>', '<Left>', '<Right>', '<LeftMouse>', '<RightMouse>'] +
				\ ['<C-Left>', '<C-Right>'] +
				\ ['<Home>', '<End>', '<PageUp>', '<PageDown>', '<S-Down>', '<S-Up>', '<C-G>g']

	for map in imaps
		if maparg(map, "i") =~? 'delimitMate'
			if map == '|'
				let map = '<Bar>'
			endif
			exec 'silent! iunmap <buffer> ' . map
		endif
	endfor
	let b:delimitMate_enabled = 0
endfunction " }}} s:Unmap()

function! s:TestMappingsDo() "{{{
	if &modified
		let confirm = input("Modified buffer, type \"yes\" to write and proceed "
					\ . "with test: ") ==? 'yes'
		if !confirm
			return
		endif
	endif
	call delimitMate#TestMappings()
	g/\%^$/d
	0
endfunction "}}}

function! s:DelimitMateDo(...) "{{{
	" First, remove all magic, if needed:
	if exists("b:delimitMate_enabled") && b:delimitMate_enabled == 1
		call s:Unmap()
	endif
	" Check if this file type is excluded:
	if exists("g:delimitMate_excluded_ft") &&
				\ index(split(g:delimitMate_excluded_ft, ','), &filetype, 0, 1) >= 0
		" Finish here:
		return 1
	endif
	" Check if user tried to disable using b:loaded_delimitMate
	if exists("b:loaded_delimitMate")
		return 1
	endif
	" Initialize settings:
	if ! s:init()
		" Something went wrong.
		return
	endif
	" Now, add magic:
	if !exists("g:delimitMate_offByDefault") || !g:delimitMate_offByDefault
		call s:Map()
	endif
	if a:0 > 0
		echo "delimitMate has been reset."
	endif
endfunction "}}}

function! s:DelimitMateSwitch() "{{{
	if exists("b:delimitMate_enabled") && b:delimitMate_enabled
		call s:Unmap()
		echo "delimitMate has been disabled."
	else
		call s:Unmap()
		call s:init()
		call s:Map()
		echo "delimitMate has been enabled."
	endif
endfunction "}}}
"}}}

" Mappers: {{{
function! s:TriggerAbb() "{{{
	if v:version < 703
		    \ || ( v:version == 703 && !has('patch489') )
		    \ || pumvisible()
		return ''
	endif
	return "\<C-]>"
endfunction "}}}

function! s:NoAutoClose() "{{{
	" inoremap <buffer> ) <C-R>=delimitMate#SkipDelim('\)')<CR>
	for delim in s:g('right_delims') + s:g('quotes_list')
		if delim == '|'
			let delim = '<Bar>'
		endif
		exec 'inoremap <silent> <Plug>delimitMate' . delim . ' <C-R>=<SID>TriggerAbb().delimitMate#SkipDelim("' . escape(delim,'"') . '")<CR>'
		exec 'silent! imap <unique> <buffer> '.delim.' <Plug>delimitMate'.delim
	endfor
endfunction "}}}

function! s:AutoClose() "{{{
	" Add matching pair and jump to the midle:
	" inoremap <silent> <buffer> ( ()<Left>
	let i = 0
	while i < len(s:g('matchpairs_list'))
		let ld = s:g('left_delims')[i] == '|' ? '<bar>' : s:g('left_delims')[i]
		let rd = s:g('right_delims')[i] == '|' ? '<bar>' : s:g('right_delims')[i]
		exec 'inoremap <expr><silent> <Plug>delimitMate' . ld
								\. ' <SID>TriggerAbb().delimitMate#ParenDelim("' . escape(rd, '|') . '")'
		exec 'silent! imap <unique> <buffer> '.ld
								\.' <Plug>delimitMate'.ld
		let i += 1
	endwhile

	" Exit from inside the matching pair:
	for delim in s:g('right_delims')
		let delim = delim == '|' ? '<bar>' : delim
		exec 'inoremap <expr><silent> <Plug>delimitMate' . delim
								\. ' <SID>TriggerAbb().delimitMate#JumpOut("\' . delim . '")'
		exec 'silent! imap <unique> <buffer> ' . delim
								\. ' <Plug>delimitMate'. delim
	endfor

	" Add matching quote and jump to the midle, or exit if inside a pair of matching quotes:
	" inoremap <silent> <buffer> " <C-R>=delimitMate#QuoteDelim("\"")<CR>
	for delim in s:g('quotes_list')
		if delim == '|'
			let delim = '<Bar>'
		endif
		exec 'inoremap <expr><silent> <Plug>delimitMate' . delim
								\. ' <SID>TriggerAbb()."<C-R>=delimitMate#QuoteDelim(\"\\\' . delim . '\")<CR>"'
		exec 'silent! imap <unique> <buffer> ' . delim
								\. ' <Plug>delimitMate' . delim
	endfor

	" Try to fix the use of apostrophes (kept for backward compatibility):
	" inoremap <silent> <buffer> n't n't
	for map in s:g('apostrophes_list')
		exec "inoremap <silent> " . map . " " . map
		exec 'silent! imap <unique> <buffer> ' . map . ' <Plug>delimitMate' . map
	endfor
endfunction "}}}

function! s:ExtraMappings() "{{{
	" If pair is empty, delete both delimiters:
	inoremap <silent> <Plug>delimitMateBS <C-R>=delimitMate#BS()<CR>
	if !hasmapto('<Plug>delimitMateBS','i')
	  if maparg('<BS>'. 'i') == ''
      silent! imap <unique> <buffer> <BS> <Plug>delimitMateBS
    endif
	  if maparg('<C-h>'. 'i') == ''
      silent! imap <unique> <buffer> <C-h> <Plug>delimitMateBS
    endif
	endif
	" If pair is empty, delete closing delimiter:
	inoremap <silent> <expr> <Plug>delimitMateS-BS delimitMate#WithinEmptyPair() ? "\<Del>" : "\<S-BS>"
	if !hasmapto('<Plug>delimitMateS-BS','i') && maparg('<S-BS>', 'i') == ''
		silent! imap <unique> <buffer> <S-BS> <Plug>delimitMateS-BS
	endif
	" Expand return if inside an empty pair:
	inoremap <expr><silent> <Plug>delimitMateCR <SID>TriggerAbb()."\<C-R>=delimitMate#ExpandReturn()\<CR>"
	if s:g('expand_cr') && !hasmapto('<Plug>delimitMateCR', 'i') && maparg('<CR>', 'i') == ''
		silent! imap <unique> <buffer> <CR> <Plug>delimitMateCR
	endif
	" Expand space if inside an empty pair:
	inoremap <expr><silent> <Plug>delimitMateSpace <SID>TriggerAbb()."\<C-R>=delimitMate#ExpandSpace()\<CR>"
	if s:g('expand_space') && !hasmapto('<Plug>delimitMateSpace', 'i') && maparg('<Space>', 'i') == ''
		silent! imap <unique> <buffer> <Space> <Plug>delimitMateSpace
	endif
	" Jump over any delimiter:
	inoremap <expr><silent> <Plug>delimitMateS-Tab <SID>TriggerAbb()."\<C-R>=delimitMate#JumpAny()\<CR>"
	if s:g('tab2exit') && !hasmapto('<Plug>delimitMateS-Tab', 'i') && maparg('<S-Tab>', 'i') == ''
		silent! imap <unique> <buffer> <S-Tab> <Plug>delimitMateS-Tab
	endif
	" Jump over next delimiters
	inoremap <expr><buffer> <Plug>delimitMateJumpMany <SID>TriggerAbb()."\<C-R>=delimitMate#JumpMany()\<CR>"
	if !hasmapto('<Plug>delimitMateJumpMany', 'i') && maparg("<C-G>g", 'i') == ''
		imap <silent> <buffer> <C-G>g <Plug>delimitMateJumpMany
	endif
endfunction "}}}

"}}}

" Commands: {{{

call s:DelimitMateDo()

" Let me refresh without re-loading the buffer:
command! -bar DelimitMateReload call s:DelimitMateDo(1)

" Quick test:
command! -bar DelimitMateTest call s:TestMappingsDo()

" Switch On/Off:
command! -bar DelimitMateSwitch call s:DelimitMateSwitch()
"}}}

" Autocommands: {{{

augroup delimitMate
	au!
	" Run on file type change.
	"autocmd VimEnter * autocmd FileType * call <SID>DelimitMateDo()
	autocmd FileType * call <SID>DelimitMateDo()

	" Run on new buffers.
	autocmd BufNewFile,BufRead,BufEnter *
				\ if !exists('b:delimitMate_was_here') |
				\   call <SID>DelimitMateDo() |
				\   let b:delimitMate_was_here = 1 |
				\ endif
augroup END

"}}}

let &cpo = save_cpo
" GetLatestVimScripts: 2754 1 :AutoInstall: delimitMate.vim
" vim:foldmethod=marker:foldcolumn=4:ts=2:sw=2
