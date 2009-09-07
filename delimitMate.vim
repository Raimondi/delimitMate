" ============================================================================
" File:        delimitMate.vim
" Version:     1.1
" Description: This plugin tries to emulate the auto-completion of delimiters
"              that TextMate provides.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
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

if exists("g:loaded_delimitMate") "{{{1
	" User doesn't want this plugin, let's get out!
	finish
endif

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

let s:loaded_delimitMate = 1

function! s:Init() "{{{1

	if !exists("g:delimitMate_autoclose")
		let s:autoclose = 1
	else
		let s:autoclose = g:delimitMate_autoclose
	endif

	if !exists("b:delimitMate_matchpairs")
		if s:ValidMatchpairs(&matchpairs) == 1
			let s:matchpairs_temp = &matchpairs
		else
			echoerr "delimitMate: There seems to be a problem with 'matchpairs', read ':help matchpairs' and fix it or notify the maintainer of this script if this is a bug."
			finish
		endif
	else
		if s:ValidMatchpairs(b:delimitMate_matchpairs) || b:delimitMate_matchpairs == ""
			let s:matchpairs_temp = b:delimitMate_matchpairs
		else
			echoerr "delimitMate: Invalid format in 'b:delimitMate_matchpairs', falling back to matchpairs. Fix the error and use the command :DelimitMateReload to try again."
			if s:ValidMatchpairs(&matchpairs) == 1
				let s:matchpairs_temp = &matchpairs
			else
				echoerr "delimitMate: There seems to be a problem with 'matchpairs', read ':help matchpairs' and fix it or notify the maintainer of this script if this is a bug."
				let s:matchpairs_temp = ""
			endif
		endif
	endif

	if exists("b:delimitMate_quotes")
		if b:delimitMate_quotes =~ '^\(\S\)\(\s\S\)*$' || b:delimitMate_quotes == ""
			let s:quotes = split(b:delimitMate_quotes)
		else
			let s:quotes = split("\" ' `")
			echoerr "delimitMate: There is a problem with the format of 'b:delimitMate_quotes', it should be a string of single characters separated by spaces. Falling back to default values."
		endif
	else
		let s:quotes = split("\" ' `")
	endif

	if !exists("g:delimitMate_visual_leader")
		if !exists("g:mapleader")
			let s:visual_leader = "\\"
		else
			let s:visual_leader = g:mapleader
		endif
	else
		let s:visual_leader = g:delimitMate_visual_leader
	endif

	if !exists("b:delimitMate_expand_space")
		let s:expand_space = "\<Space>"
	elseif b:delimitMate_expand_space == ""
		let s:expand_space = "\<Space>"
	else
		let s:expand_space = b:delimitMate_expand_space
	endif

	if !exists("b:delimitMate_expand_cr")
		let s:expand_return = "\<CR>"
	elseif b:delimitMate_expand_cr == ""
		let s:expand_return = "\<CR>"
	else
		let s:expand_return = b:delimitMate_expand_cr
	endif

	let s:matchpairs = split(s:matchpairs_temp, ',')
	let s:left_delims = split(s:matchpairs_temp, ':.,\=')
	let s:right_delims = split(s:matchpairs_temp, ',\=.:')
	let s:VMapMsg = "delimitMate: delimitMate is disabled on blockwise visual mode."

endfunction

function! s:ValidMatchpairs(str) "{{{1
	if a:str !~ '^\(.:.\)\+\(,.:.\)*$'
		return 0
	endif
	for pair in split(a:str,',')
		if strpart(pair, 0, 1) == strpart(pair, 2, 1) || strlen(pair) != 3
			return 0
		endif
	endfor
	return 1
endfunc

function! s:IsEmptyPair(str) "{{{1
	for pair in s:matchpairs
		if a:str == join( split( pair, ':' ),'' )
			return 1
		endif
	endfor
	for quote in s:quotes
		if a:str == quote . quote
			return 1
		endif
	endfor
	return 0
endfunc

function! s:WithinEmptyPair() "{{{1
	let cur = strpart( getline('.'), col('.')-2, 2 )
	return s:IsEmptyPair( cur )
endfunc

function! s:SkipDelim(char) "{{{1
	let cur = strpart( getline('.'), col('.')-2, 3 )
	if cur[0] == "\\"
		return a:char
	elseif cur[1] == a:char
		return "\<Right>"
	elseif cur[1] == ' ' && cur[2] == a:char
		" I'm leaving this in case someone likes it.
		return "\<Right>\<Right>"
	elseif s:IsEmptyPair( cur[0] . a:char )
		return a:char . "\<Left>"
	else
		return a:char
	endif
endfunc

function! s:QuoteDelim(char) "{{{1
	let line = getline('.')
	let col = col('.')
	if line[col - 2] == "\\"
		"Inserting a quoted quotation mark into the string
		return a:char
	elseif line[col - 1] == a:char
		"Escaping out of the string
		return "\<Right>"
	else
		"Starting a string
		return a:char.a:char."\<Left>"
	endif
endf

function! s:ClosePair(char) "{{{1
	if getline('.')[col('.') - 1] == a:char
		return "\<Right>"
	else
		return a:char
	endif
endf

function! s:ResetMappings() "{{{1
	for delim in s:right_delims + s:left_delims + s:quotes
		silent! exec 'iunmap <buffer> ' . delim
		silent! exec 'vunmap <buffer> ' . s:visual_leader . delim
	endfor
	silent! iunmap <buffer> <CR>
	silent! iunmap <buffer> <Space>
endfunction

function! s:MapMsg(msg) "{{{1
	redraw
	echomsg a:msg
	return ""
endfunction

function! s:NoAutoClose() "{{{1
	" imap <buffer> ) <C-R>=<SID>SkipDelim('\)')<CR>
	for delim in s:right_delims + s:quotes
		exec 'imap <buffer> ' . delim . ' <C-R>=<SID>SkipDelim("' . escape(delim,'"') . '")<CR>'
	endfor

	" Wrap the selection with delimiters, but do nothing if blockwise visual mode is active:
	for i in range(len(s:matchpairs))
		" Map left delimiter:
		" vmap <buffer> <expr> q( visualmode() == "<C-V>" ? <SID>MapMsg(VMapMsg) : "s(\<C-R>\")\<Esc>"
		exec 'vmap <buffer> <expr> ' . s:visual_leader . s:left_delims[i] . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . s:left_delims[i] . '\<C-R>\"' . s:right_delims[i] . '\<Esc>"'

		" Map right delimiter:
		" vmap <buffer> <expr> q) visualmode() == "<C-V>" ? <SID>MapMsg(VMapMsg) : "s(\<C-R>\")\<Esc>"
		exec 'vmap <buffer> <expr> ' . s:visual_leader . s:right_delims[i] . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . s:left_delims[i] . '\<C-R>\"' . s:right_delims[i] . '"'
	endfor

	for quote in s:quotes
		" vmap <buffer> <expr> q" visualmode() == "<C-V>" ? <SID>MapMsg(VMapMsg) : "s'\<C-R>\"'\<Esc>"
		exec 'vmap <buffer> <expr> ' . s:visual_leader . quote . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . escape(quote,'"') . '\<C-R>\"' . escape(quote,'"') . '\<Esc>"'
	endfor
endfunction

function! s:AutoClose() "{{{1
	" Add matching pair and jump to the midle:
	" imap <buffer> ( ()<Left>
	let s:i = 0
	while s:i < len(s:matchpairs)
		exec 'imap <buffer> ' . s:left_delims[s:i] . ' ' . s:left_delims[s:i] . '_<Left>' . s:right_delims[s:i] . '<Del><Left>'
		let s:i += 1
	endwhile

	" Add matching quote and jump to the midle, or exit if inside a pair of matching quotes:
	" imap <buffer> " <C-R>=<SID>QuoteDelim("\"")<CR>
	for delim in s:quotes
		exec 'imap <buffer> ' . delim . ' <C-R>=<SID>QuoteDelim("\' . delim . '")<CR>'
	endfor

	" Exit from inside the matching pair:
	" imap <buffer> ) <C-R>=<SID>ClosePair(')')<CR>
	for delim in s:right_delims
		exec 'imap <buffer> ' . delim . ' <C-R>=<SID>ClosePair("\' . delim . '")<CR>'
	endfor

	" Wrap the selection with matching pairs, but do nothing if blockwise visual mode is active:
	let s:i = 0
	while s:i < len(s:matchpairs)
		" Map left delimiter:
		" vmap <buffer> <expr> q( visualmode() == "<C-V>" ? <SID>MapMsg("Message") : "s(\<C-R>\"\<Esc>"
		exec 'vmap <buffer> <expr> ' . s:visual_leader . s:left_delims[s:i] . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . s:left_delims[s:i] . '\<C-R>\"\<Esc>"'

		" Map right delimiter:
		" vmap <buffer> <expr> q) visualmode() == "<C-V>" ? <SID>MapMsg("Message") : "s(\<C-R>\""\<Esc>"
		exec 'vmap <buffer> <expr> ' . s:visual_leader . s:right_delims[s:i] . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . s:left_delims[s:i] . '\<C-R>\""'
		let s:i += 1
	endwhile

	" Wrap the selection with matching quotes, but do nothing if blockwise visual mode is active:
	for quote in s:quotes
		" vmap <buffer> <expr> q' visualmode() == "<C-V>" ? <SID>MapMsg("Message") : "s'\<C-R>\"'\<Esc>"
		exec 'vmap <buffer> <expr> ' . s:visual_leader . quote . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . escape(quote,'"') .'\<C-R>\"' . escape(quote,'"') . '\<Esc>"'
	endfor
endfunction

function! s:ExpandReturn() "{{{1
	if s:WithinEmptyPair()
		return s:expand_return
	else
		return "\<CR>"
	endif
endfunction

function! s:ExpandSpace() "{{{1
	if s:WithinEmptyPair()
		return s:expand_space
	else
		return "\<Space>"
	endif
endfunction

function! s:ExtraMappings() "{{{1
	" If pair is empty, delete both delimiters:
	imap <buffer> <expr> <BS> <SID>WithinEmptyPair() ? "\<Left>\<Del>\<Del>" : "\<BS>"

	" Expand return if inside an empty pair:
	imap <buffer> <CR> <C-R>=<SID>ExpandReturn()<CR>

	" Expand space if inside an empty pair:
	imap <buffer> <Space> <C-R>=<SID>ExpandSpace()<CR>
endfunction

function! s:TestMappings() "{{{1
	if s:autoclose
		 exec "normal i* AUTOCLOSE:\<CR>"
		for i in range(len(s:left_delims))
			exec "normal GGAOpen & close: " . s:left_delims[i]. "|"
			exec "normal A\<CR>Delete: " . s:left_delims[i] . "\<BS>|"
			exec "normal A\<CR>Exit: " . s:left_delims[i] . s:right_delims[i] . "|"
			exec "normal A\<CR>Space: " . s:left_delims[i] . " |"
			exec "normal GGA\<CR>Visual-L: v\<Esc>v" . s:visual_leader . s:left_delims[i]
			exec "normal A\<CR>Visual-R: v\<Esc>v" . s:visual_leader . s:right_delims[i]
			exec "normal A\<CR>Car return: " . s:left_delims[i] . "\<CR>|\<Esc>GGA\<CR>\<CR>"
		endfor
		for i in range(len(s:quotes))
			exec "normal GGAOpen & close: " . s:quotes[i]	. "|"
			exec "normal A\<CR>Delete: " . s:quotes[i] . "\<BS>|"
			exec "normal A\<CR>Exit: " . s:quotes[i] . s:quotes[i] . "|"
			exec "normal A\<CR>Space: " . s:quotes[i] . " |"
			exec "normal GGA\<CR>Visual: v\<Esc>v" . s:visual_leader . s:quotes[i]
			exec "normal A\<CR>Car return: " . s:quotes[i] . "\<CR>|\<Esc>GGA\<CR>\<CR>"
		endfor
	else
		exec "normal i* NO AUTOCLOSE:\<CR>"
		for i in range(len(s:left_delims))
			exec "normal GGAOpen & close: " . s:left_delims[i]	. s:right_delims[i] . "|"
			exec "normal A\<CR>Delete: " . s:left_delims[i] . s:right_delims[i] . "\<BS>|"
			exec "normal A\<CR>Exit: " . s:left_delims[i] . s:right_delims[i] . s:right_delims[i] . "|"
			exec "normal A\<CR>Space: " . s:left_delims[i] . s:right_delims[i] . " |"
			exec "normal GGA\<CR>Visual-L: v\<Esc>v" . s:visual_leader . s:left_delims[i]
			exec "normal A\<CR>Visual-R: v\<Esc>v" . s:visual_leader . s:right_delims[i]
			exec "normal A\<CR>Car return: " . s:left_delims[i] . s:right_delims[i] . "\<CR>|\<Esc>GGA\<CR>\<CR>"
		endfor
		for i in range(len(s:quotes))
			exec "normal GGAOpen & close: " . s:quotes[i]	. s:quotes[i] . "|"
			exec "normal A\<CR>Delete: " . s:quotes[i] . s:quotes[i] . "\<BS>|"
			exec "normal A\<CR>Exit: " . s:quotes[i] . s:quotes[i] . s:quotes[i] . "|"
			exec "normal A\<CR>Space: " . s:quotes[i] . s:quotes[i] . " |"
			exec "normal GGA\<CR>Visual: v\<Esc>v" . s:visual_leader . s:quotes[i]
			exec "normal A\<CR>Car return: " . s:quotes[i] . s:quotes[i] . "\<CR>|\<Esc>GGA\<CR>\<CR>"
		endfor
	endif
	exec "normal \<Esc>"
endfunction

function! s:SwitchAutoclose() "{{{1
	if !exists("g:delimitMate_autoclose")
		let g:delimitMate_autoclose = 1
	elseif g:delimitMate_autoclose == 1
		let g:delimitMate_autoclose = 0
	else
		let g:delimitMate_autoclose = 1
	endif
	DelimitMateReload
endfunction

function! s:TestMappingsDo() "{{{1
	if !exists("g:delimitMate_testing")
		call s:DelimitMateDo()
		call s:TestMappings()
	else
		call s:SwitchAutoclose()
		call s:TestMappings()
		exec "normal i\<CR>"
		call s:SwitchAutoclose()
		call s:TestMappings()
	endif
endfunction

function! s:DelimitMateDo() "{{{1
	try
		let s:save_cpo = &cpo
		set cpo&vim
		call s:Init()
		call s:ResetMappings()
		if s:autoclose
			call s:AutoClose()
		else
			call s:NoAutoClose()
		endif
		call s:ExtraMappings()
		let b:loaded_delimitMate = 1
	finally
		let &cpo = s:save_cpo
	endtry
endfunction

" Do the real work: {{{1
call s:DelimitMateDo()

" Let me refresh without re-loading the buffer:
command! DelimitMateReload call s:DelimitMateDo()

" Quick test:
command! DelimitMateTest call s:TestMappingsDo()

autocmd BufNewFile,BufRead,BufEnter * if !exists("b:loaded_delimitMate") | call <SID>DelimitMateDo() | endif

" GetLatestVimScripts: 2754 1 :AutoInstall: delimitMate.vim
" vim:foldmethod=marker:foldcolumn=2
