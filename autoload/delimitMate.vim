" ============================================================================
" File:        autoload/delimitMate.vim
" Version:     2.4.1
" Modified:    2010-07-31
" Description: This plugin provides auto-completion for quotes, parens, etc.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
" Manual:      Read ":help delimitMate".

" Utilities {{{

function! delimitMate#option_init(name, default) "{{{
	let b = exists("b:delimitMate_" . a:name)
	let g = exists("g:delimitMate_" . a:name)
	let prefix = "_l_delimitMate_"

	if !b && !g
		let sufix = a:default
	elseif !b && g
		exec "let sufix = g:delimitMate_" . a:name
	else
		exec "let sufix = b:delimitMate_" . a:name
	endif
	if exists("b:" . prefix . a:name)
		exec "unlockvar! b:" . prefix . a:name
	endif
	exec "let b:" . prefix . a:name . " = " . string(sufix)
	exec "lockvar! b:" . prefix . a:name
endfunction "}}}

function! delimitMate#Init() "{{{
" Initialize variables:

	" autoclose
	call delimitMate#option_init("autoclose", 1)

	" matchpairs
	call delimitMate#option_init("matchpairs", string(&matchpairs)[1:-2])
	call delimitMate#option_init("matchpairs_list", split(b:_l_delimitMate_matchpairs, ','))
	call delimitMate#option_init("left_delims", split(b:_l_delimitMate_matchpairs, ':.,\='))
	call delimitMate#option_init("right_delims", split(b:_l_delimitMate_matchpairs, ',\=.:'))

	" quotes
	call delimitMate#option_init("quotes", "\" ' `")
	call delimitMate#option_init("quotes_list", split(b:_l_delimitMate_quotes))

	" nesting_quotes
	call delimitMate#option_init("nesting_quotes", [])

	" excluded_regions
	call delimitMate#option_init("excluded_regions", "Comment")
	call delimitMate#option_init("excluded_regions_list", split(b:_l_delimitMate_excluded_regions, ',\s*'))
	let enabled = len(b:_l_delimitMate_excluded_regions_list) > 0
	call delimitMate#option_init("excluded_regions_enabled", enabled)

	" visual_leader
	let leader = exists('b:maplocalleader') ? b:maplocalleader :
					\ exists('g:mapleader') ? g:mapleader : "\\"
	call delimitMate#option_init("visual_leader", leader)

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
	call delimitMate#option_init("expand_space", 0)

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
	if (&backspace !~ 'eol' || &backspace !~ 'start') &&
				\ ((exists('b:delimitMate_expand_cr') && b:delimitMate_expand_cr == 1) ||
				\ (exists('g:delimitMate_expand_cr') && g:delimitMate_expand_cr == 1))
		echom "delimitMate: In order to use the <CR> expansion, you need to have 'eol' and 'start' in your backspace option. Read :help 'backspace'."
		let b:delimitMate_expand_cr = 0
	endif
	call delimitMate#option_init("expand_cr", 0)

	" smart_quotes
	call delimitMate#option_init("smart_quotes", 1)

	" apostrophes
	call delimitMate#option_init("apostrophes", "")
	call delimitMate#option_init("apostrophes_list", split(b:_l_delimitMate_apostrophes, ":\s*"))

	" tab2exit
	call delimitMate#option_init("tab2exit", 1)

	" balance_matchpairs
	call delimitMate#option_init("balance_matchpairs", 0)

	let b:_l_delimitMate_buffer = []

	let b:loaded_delimitMate = 1

endfunction "}}} Init()

function! delimitMate#Map() "{{{
	" Set mappings:
	try
		let save_cpo = &cpo
		let save_keymap = &keymap
		let save_iminsert = &iminsert
		let save_imsearch = &imsearch
		set keymap=
		set cpo&vim
		if b:_l_delimitMate_autoclose
			call delimitMate#AutoClose()
		else
			call delimitMate#NoAutoClose()
		endif
		call delimitMate#VisualMaps()
		call delimitMate#ExtraMappings()
	finally
		let &cpo = save_cpo
		let &keymap = save_keymap
		let &iminsert = save_iminsert
		let &imsearch = save_imsearch
	endtry

	let b:delimitMate_enabled = 1

endfunction "}}} Map()

function! delimitMate#ShouldJump() "{{{
	" Returns 1 if the next character is a closing delimiter.
	let col = col('.')
	let lcol = col('$')
	let char = getline('.')[col - 1]

	" Closing delimiter on the right.
	for cdel in b:_l_delimitMate_right_delims + b:_l_delimitMate_quotes_list
		if char == cdel
			return 1
		endif
	endfor

	" Closing delimiter with space expansion.
	let nchar = getline('.')[col]
	if b:_l_delimitMate_expand_space && char == " "
		for cdel in b:_l_delimitMate_right_delims + b:_l_delimitMate_quotes_list
			if nchar == cdel
				return 1
			endif
		endfor
	endif

	" Closing delimiter with CR expansion.
	let uchar = getline(line('.') + 1)[0]
	if b:_l_delimitMate_expand_cr && char == ""
		for cdel in b:_l_delimitMate_right_delims + b:_l_delimitMate_quotes_list
			if uchar == cdel
				return 1
			endif
		endfor
	endif

	return 0
endfunction "}}}

function! delimitMate#Visual(del) " {{{
	if len(getline('.')) == 0
		" This for proper wrap of empty lines.
		let @" = "\n"
	endif

	" Let's find which kind of delimiter we got:
	let index = index(b:_l_delimitMate_left_delims, a:del)
	if index >= 0
		let ld = a:del
		let rd = b:_l_delimitMate_right_delims[index]
	endif

	let index = index(b:_l_delimitMate_right_delims, a:del)
	if index >= 0
		let ld = b:_l_delimitMate_left_delims[index]
		let rd = a:del
	endif

	if index(b:_l_delimitMate_quotes_list, a:del) >= 0
		let ld = a:del
		let rd = ld
	endif

	let mode = mode()
	if mode == "\<C-V>"
		" Block-wise visual
		return "I" . ld . "\<Esc>gv\<Right>A" . rd . "\<Esc>"
	elseif mode ==# "V"
		let dchar = "\<BS>"
	else
		let dchar = ""
	endif

	" Store unnamed register values for later use in delimitMate#RestoreRegister().
	let b:save_reg = getreg('"')
	let b:save_reg_mode = getregtype('"')

	return "s" . ld . "\<C-R>\"" . dchar . rd . "\<Esc>:call delimitMate#RestoreRegister()\<CR>"
endfunction " }}}

function! delimitMate#IsEmptyPair(str) "{{{
	for pair in b:_l_delimitMate_matchpairs_list
		if a:str == join( split( pair, ':' ),'' )
			return 1
		endif
	endfor
	for quote in b:_l_delimitMate_quotes_list
		if a:str == quote . quote
			return 1
		endif
	endfor
	return 0
endfunction "}}}

function! delimitMate#IsCRExpansion() " {{{
	let nchar = getline(line('.')-1)[-1:]
	let schar = getline(line('.')+1)[:0]
	let isEmpty = getline('.') == ""
	if index(b:_l_delimitMate_left_delims, nchar) > -1 &&
				\ index(b:_l_delimitMate_left_delims, nchar) == index(b:_l_delimitMate_right_delims, schar) &&
				\ isEmpty
		return 1
	elseif index(b:_l_delimitMate_quotes_list, nchar) > -1 &&
				\ index(b:_l_delimitMate_quotes_list, nchar) == index(b:_l_delimitMate_quotes_list, schar) &&
				\ isEmpty
		return 1
	else
		return 0
	endif
endfunction " }}} delimitMate#IsCRExpansion()

function! delimitMate#IsSpaceExpansion() " {{{
	let line = getline('.')
	let col = col('.')-2
	if col > 0
		let pchar = line[col - 1]
		let nchar = line[col + 2]
		let isSpaces = (line[col] == line[col+1] && line[col] == " ")

		if index(b:_l_delimitMate_left_delims, pchar) > -1 &&
				\ index(b:_l_delimitMate_left_delims, pchar) == index(b:_l_delimitMate_right_delims, nchar) &&
				\ isSpaces
			return 1
		elseif index(b:_l_delimitMate_quotes_list, pchar) > -1 &&
				\ index(b:_l_delimitMate_quotes_list, pchar) == index(b:_l_delimitMate_quotes_list, nchar) &&
				\ isSpaces
			return 1
		endif
	endif
	return 0
endfunction " }}} IsSpaceExpansion()

function! delimitMate#WithinEmptyPair() "{{{
	let cur = strpart( getline('.'), col('.')-2, 2 )
	return delimitMate#IsEmptyPair( cur )
endfunction "}}}

function! delimitMate#WriteBefore(str) "{{{
	let len = len(a:str)
	let line = getline('.')
	let col = col('.')-2
	if col < 0
		call setline('.',line[(col+len+1):])
	else
		call setline('.',line[:(col)].line[(col+len+1):])
	endif
	return a:str
endfunction " }}}

function! delimitMate#WriteAfter(str) "{{{
	let len = len(a:str)
	let line = getline('.')
	let col = col('.')-2
	if (col) < 0
		call setline('.',a:str.line)
	else
		call setline('.',line[:(col)].a:str.line[(col+len):])
	endif
	return ''
endfunction " }}}

function! delimitMate#RestoreRegister() " {{{
	" Restore unnamed register values stored in delimitMate#Visual().
	call setreg('"', b:save_reg, b:save_reg_mode)
	echo ""
endfunction " }}}

function! delimitMate#GetSyntaxRegion(line, col) "{{{
	return synIDattr(synIDtrans(synID(a:line, a:col, 1)), 'name')
endfunction " }}}

function! delimitMate#GetCurrentSyntaxRegion() "{{{
	let col = col('.')
	if  col == col('$')
		let col = col - 1
	endif
	return delimitMate#GetSyntaxRegion(line('.'), col)
endfunction " }}}

function! delimitMate#GetCurrentSyntaxRegionIf(char) "{{{
	let col = col('.')
	let origin_line = getline('.')
	let changed_line = strpart(origin_line, 0, col - 1) . a:char . strpart(origin_line, col - 1)
	call setline('.', changed_line)
	let region = delimitMate#GetSyntaxRegion(line('.'), col)
	call setline('.', origin_line)
	return region
endfunction "}}}

function! delimitMate#IsForbidden(char) "{{{
	if b:_l_delimitMate_excluded_regions_enabled == 0
		return 0
	endif
	"let result = index(b:_l_delimitMate_excluded_regions_list, delimitMate#GetCurrentSyntaxRegion()) >= 0
	if index(b:_l_delimitMate_excluded_regions_list, delimitMate#GetCurrentSyntaxRegion()) >= 0
		"echom "Forbidden 1!"
		return 1
	endif
	let region = delimitMate#GetCurrentSyntaxRegionIf(a:char)
	"let result = index(b:_l_delimitMate_excluded_regions_list, region) >= 0
	"return result || region == 'Comment'
	"echom "Forbidden 2!"
	return index(b:_l_delimitMate_excluded_regions_list, region) >= 0
endfunction "}}}

function! delimitMate#FlushBuffer() " {{{
	let b:_l_delimitMate_buffer = []
	return ''
endfunction " }}}

function! delimitMate#BalancedParens(char) "{{{
	" Returns:
	" = 0 => Parens balanced.
	" > 0 => More opening parens.
	" < 0 => More closing parens.

	let line = getline('.')
	let col = col('.') - 2
	let col = col >= 0 ? col : 0
	let list = split(line, '\zs')
	let left = b:_l_delimitMate_left_delims[index(b:_l_delimitMate_right_delims, a:char)]
	let right = a:char
	let opening = 0
	let closing = 0

	" If the cursor is not at the beginning, count what's behind it.
	if col > 0
		  " Find the first opening paren:
		  let start = index(list, left)
		  " Must be before cursor:
		  let start = start < col ? start : col - 1
		  " Now count from the first opening until the cursor, this will prevent
		  " extra closing parens from being counted.
		  let opening = count(list[start : col - 1], left)
		  let closing = count(list[start : col - 1], right)
		  " I don't care if there are more closing parens than opening parens.
		  let closing = closing > opening ? opening : closing
	endif

	" Evaluate parens from the cursor to the end:
	let opening += count(list[col :], left)
	let closing += count(list[col :], right)

	"echom "–––––––––"
	"echom line
	"echom col
	""echom left.":".a:char
	"echom string(list)
	"echom string(list[start : col - 1]) . " : " . string(list[col :])
	"echom opening . " - " . closing . " = " . (opening - closing)

	" Return the found balance:
	return opening - closing
endfunction "}}}

" }}}

" Doers {{{
function! delimitMate#SkipDelim(char) "{{{
	if delimitMate#IsForbidden(a:char)
		return a:char
	endif
	let col = col('.') - 1
	let line = getline('.')
	if col > 0
		let cur = line[col]
		let pre = line[col-1]
	else
		let cur = line[col]
		let pre = ""
	endif
	if pre == "\\"
		" Escaped character
		return a:char
	elseif cur == a:char
		" Exit pair
		"return delimitMate#WriteBefore(a:char)
		return a:char . delimitMate#Del()
	elseif delimitMate#IsEmptyPair( pre . a:char )
		" Add closing delimiter and jump back to the middle.
		call insert(b:_l_delimitMate_buffer, a:char)
		return delimitMate#WriteAfter(a:char)
	else
		" Nothing special here, return the same character.
		return a:char
	endif
endfunction "}}}

function! delimitMate#ParenDelim(char) " {{{
	if delimitMate#IsForbidden(a:char)
		return ''
	endif
	if b:_l_delimitMate_balance_matchpairs &&
				\ delimitMate#BalancedParens(a:char) <= 0
		return ''
	endif
	let line = getline('.')
	let col = col('.')-2
	if (col) < 0
		call setline('.',a:char.line)
		call insert(b:_l_delimitMate_buffer, a:char)
	else
		"echom string(col).':'.line[:(col)].'|'.line[(col+1):]
		call setline('.',line[:(col)].a:char.line[(col+1):])
		call insert(b:_l_delimitMate_buffer, a:char)
	endif
	return ''
endfunction " }}}

function! delimitMate#QuoteDelim(char) "{{{
	if delimitMate#IsForbidden(a:char)
		return a:char
	endif
	let line = getline('.')
	let col = col('.') - 2
	if line[col] == "\\"
		" Seems like a escaped character, insert one quotation mark.
		return a:char
	elseif line[col + 1] == a:char &&
				\ index(b:_l_delimitMate_nesting_quotes, a:char) < 0
		" Get out of the string.
		return a:char . delimitMate#Del()
	elseif (line[col] =~ '[[:alnum:]]' && a:char == "'") ||
				\ (b:_l_delimitMate_smart_quotes &&
				\ (line[col] =~ '[[:alnum:]]' ||
				\ line[col + 1] =~ '[[:alnum:]]'))
		" Seems like an apostrophe or a smart quote case, insert a single quote.
		return a:char
	elseif (line[col] == a:char && line[col + 1 ] != a:char) && b:_l_delimitMate_smart_quotes
		" Seems like we have an unbalanced quote, insert one quotation mark and jump to the middle.
		call insert(b:_l_delimitMate_buffer, a:char)
		return delimitMate#WriteAfter(a:char)
	else
		" Insert a pair and jump to the middle.
		call insert(b:_l_delimitMate_buffer, a:char)
		call delimitMate#WriteAfter(a:char)
		return a:char
	endif
endfunction "}}}

function! delimitMate#JumpOut(char) "{{{
	if delimitMate#IsForbidden(a:char)
		return a:char
	endif
	let line = getline('.')
	let col = col('.')-2
	if line[col+1] == a:char
		return a:char . delimitMate#Del()
	else
		return a:char
	endif
endfunction " }}}

function! delimitMate#JumpAny(key) " {{{
	if delimitMate#IsForbidden('')
		return a:key
	endif
	if !delimitMate#ShouldJump()
		return a:key
	endif
	" Let's get the character on the right.
	let char = getline('.')[col('.')-1]
	if char == " "
		" Space expansion.
		"let char = char . getline('.')[col('.')] . delimitMate#Del()
		return char . getline('.')[col('.')] . delimitMate#Del() . delimitMate#Del()
		"call delimitMate#RmBuffer(1)
	elseif char == ""
		" CR expansion.
		"let char = "\<CR>" . getline(line('.') + 1)[0] . "\<Del>"
		let b:_l_delimitMate_buffer = []
		return "\<CR>" . getline(line('.') + 1)[0] . "\<Del>"
	else
		"call delimitMate#RmBuffer(1)
		return char . delimitMate#Del()
	endif
endfunction " delimitMate#JumpAny() }}}

function! delimitMate#MapMsg(msg) "{{{
	redraw
	echomsg a:msg
	return ""
endfunction "}}}

function! delimitMate#ExpandReturn() "{{{
	if delimitMate#IsForbidden("")
		return "\<CR>"
	endif
	if delimitMate#WithinEmptyPair()
		" Expand:
		call delimitMate#FlushBuffer()
		"return "\<Esc>a\<CR>x\<CR>\<Esc>k$\"_xa"
		return "\<CR>\<UP>\<Esc>o"
	else
		return "\<CR>"
	endif
endfunction "}}}

function! delimitMate#ExpandSpace() "{{{
	if delimitMate#IsForbidden("\<Space>")
		return "\<Space>"
	endif
	if delimitMate#WithinEmptyPair()
		" Expand:
		call insert(b:_l_delimitMate_buffer, 's')
		return delimitMate#WriteAfter(' ') . "\<Space>"
	else
		return "\<Space>"
	endif
endfunction "}}}

function! delimitMate#BS() " {{{
	if delimitMate#IsForbidden("")
		return "\<BS>"
	endif
	if delimitMate#WithinEmptyPair()
		"call delimitMate#RmBuffer(1)
		return "\<BS>" . delimitMate#Del()
"        return "\<Right>\<BS>\<BS>"
	elseif delimitMate#IsSpaceExpansion()
		"call delimitMate#RmBuffer(1)
		return "\<BS>" . delimitMate#Del()
	elseif delimitMate#IsCRExpansion()
		return "\<BS>\<Del>"
	else
		return "\<BS>"
	endif
endfunction " }}} delimitMate#BS()

function! delimitMate#Del() " {{{
	if len(b:_l_delimitMate_buffer) > 0
		let line = getline('.')
		let col = col('.') - 2
		call delimitMate#RmBuffer(1)
		call setline('.', line[:col] . line[col+2:])
		return ''
	else
		return "\<Del>"
	endif
endfunction " }}}

function! delimitMate#Finish() " {{{
	let len = len(b:_l_delimitMate_buffer)
	if len > 0
		let buffer = join(b:_l_delimitMate_buffer, '')
		" Reset buffer:
		let b:_l_delimitMate_buffer = []
		let line = getline('.')
		let col = col('.') -2
		"echom 'col: ' . col . '-' . line[:col] . "|" . line[col+len+1:] . '%' . buffer
		if col < 0
			call setline('.', line[col+len+1:])
		else
			call setline('.', line[:col] . line[col+len+1:])
		endif
		let i = 1
		let lefts = "\<Left>"
		while i < len
			let lefts = lefts . "\<Left>"
			let i += 1
		endwhile
		return substitute(buffer, "s", "\<Space>", 'g') . lefts
	endif
	return ''
endfunction " }}}

function! delimitMate#RmBuffer(num) " {{{
	if len(b:_l_delimitMate_buffer) > 0
	   call remove(b:_l_delimitMate_buffer, 0, (a:num-1))
	endif
	return ""
endfunction " }}}

" }}}

" Mappers: {{{
function! delimitMate#NoAutoClose() "{{{
	" inoremap <buffer> ) <C-R>=delimitMate#SkipDelim('\)')<CR>
	for delim in b:_l_delimitMate_right_delims + b:_l_delimitMate_quotes_list
		exec 'inoremap <silent> <buffer> ' . delim . ' <C-R>=delimitMate#SkipDelim("' . escape(delim,'"\|') . '")<CR>'
	endfor
endfunction "}}}

function! delimitMate#AutoClose() "{{{
	" Add matching pair and jump to the midle:
	" inoremap <silent> <buffer> ( ()<Left>
	let i = 0
	while i < len(b:_l_delimitMate_matchpairs_list)
		let ld = b:_l_delimitMate_left_delims[i]
		let rd = b:_l_delimitMate_right_delims[i]
		exec 'inoremap <silent> <buffer> ' . ld . ' ' . ld . '<C-R>=delimitMate#ParenDelim("' . rd . '")<CR>'
		let i += 1
	endwhile

	" Exit from inside the matching pair:
	for delim in b:_l_delimitMate_right_delims
		exec 'inoremap <silent> <buffer> ' . delim . ' <C-R>=delimitMate#JumpOut("\' . delim . '")<CR>'
	endfor

	" Add matching quote and jump to the midle, or exit if inside a pair of matching quotes:
	" inoremap <silent> <buffer> " <C-R>=delimitMate#QuoteDelim("\"")<CR>
	for delim in b:_l_delimitMate_quotes_list
		exec 'inoremap <silent> <buffer> ' . delim . ' <C-R>=delimitMate#QuoteDelim("\' . delim . '")<CR>'
	endfor

	" Try to fix the use of apostrophes (de-activated by default):
	" inoremap <silent> <buffer> n't n't
	for map in b:_l_delimitMate_apostrophes_list
		exec "inoremap <silent> <buffer> " . map . " " . map
	endfor
endfunction "}}}

function! delimitMate#VisualMaps() " {{{
	let VMapMsg = "delimitMate: delimitMate is disabled on blockwise visual mode."
	let vleader = b:_l_delimitMate_visual_leader
	" Wrap the selection with matching pairs, but do nothing if blockwise visual mode is active:
	for del in b:_l_delimitMate_right_delims + b:_l_delimitMate_left_delims + b:_l_delimitMate_quotes_list
		exec "vnoremap <silent> <buffer> <expr> " . vleader . del . ' delimitMate#Visual("' . escape(del, '")') . '")'
	endfor
endfunction "}}}

function! delimitMate#ExtraMappings() "{{{
	" If pair is empty, delete both delimiters:
	inoremap <silent> <buffer> <BS> <C-R>=delimitMate#BS()<CR>

	" If pair is empty, delete closing delimiter:
	inoremap <silent> <buffer> <expr> <S-BS> delimitMate#WithinEmptyPair() ? "\<C-R>=delimitMate#Del()\<CR>" : "\<S-BS>"

	" Expand return if inside an empty pair:
	if b:_l_delimitMate_expand_cr != 0
		inoremap <silent> <buffer> <CR> <C-R>=delimitMate#ExpandReturn()<CR>
	endif

	" Expand space if inside an empty pair:
	if b:_l_delimitMate_expand_space != 0
		inoremap <silent> <buffer> <Space> <C-R>=delimitMate#ExpandSpace()<CR>
	endif

	" Jump out ot any empty pair:
	if b:_l_delimitMate_tab2exit
		inoremap <silent> <buffer> <S-Tab> <C-R>=delimitMate#JumpAny("\<S-Tab>")<CR>
	endif

	" Fix the re-do feature:
	inoremap <silent> <buffer> <Esc> <C-R>=delimitMate#Finish()<CR><Esc>

	" Flush the char buffer on mouse click:
	inoremap <silent> <buffer> <LeftMouse> <C-R>=delimitMate#Finish()<CR><LeftMouse>
	inoremap <silent> <buffer> <RightMouse> <C-R>=delimitMate#Finish()<CR><RightMouse>

	" Flush the char buffer on key movements:
	inoremap <silent> <buffer> <Left> <C-R>=delimitMate#Finish()<CR><Left>
	inoremap <silent> <buffer> <Right> <C-R>=delimitMate#Finish()<CR><Right>
	inoremap <silent> <buffer> <Up> <C-R>=delimitMate#Finish()<CR><Up>
	inoremap <silent> <buffer> <Down> <C-R>=delimitMate#Finish()<CR><Down>
	inoremap <silent> <buffer> <Home> <C-R>=delimitMate#Finish()<CR><Home>
	inoremap <silent> <buffer> <End> <C-R>=delimitMate#Finish()<CR><End>

	inoremap <silent> <buffer> <Del> <C-R>=delimitMate#Del()<CR>

	" The following simply creates an ambiguous mapping so vim fully processes
	" the escape sequence for terminal keys, see 'ttimeout' for a rough
	" explanation, this just forces it to work
	if !has('gui_running')
		imap <silent> <C-[>OC <RIGHT>
	endif
endfunction "}}}

function! delimitMate#UnMap() " {{{
	let imaps =
				\ b:_l_delimitMate_right_delims +
				\ b:_l_delimitMate_left_delims +
				\ b:_l_delimitMate_quotes_list +
				\ b:_l_delimitMate_apostrophes_list +
				\ ['<BS>', '<S-BS>', '<Del>', '<CR>', '<Space>', '<S-Tab>', '<Esc>'] +
				\ ['<Up>', '<Down>', '<Left>', '<Right>', '<LeftMouse>', '<RightMouse>']

	let vmaps =
				\ b:_l_delimitMate_right_delims +
				\ b:_l_delimitMate_left_delims +
				\ b:_l_delimitMate_quotes_list

	for map in imaps
		if maparg(map, "i") =~? 'delimitMate'
			exec 'silent! iunmap <buffer> ' . map
		endif
	endfor

	if !exists("b:_l_delimitMate_visual_leader")
		let vleader = ""
	else
		let vleader = b:_l_delimitMate_visual_leader
	endif
	for map in vmaps
		if maparg(vleader . map, "v") =~? "delimitMate"
			exec 'silent! vunmap <buffer> ' . vleader . map
		endif
	endfor

	if !has('gui_running')
		silent! iunmap <C-[>OC
	endif

	let b:delimitMate_enabled = 0
endfunction " }}} delimitMate#UnMap()

"}}}

" Tools: {{{
function! delimitMate#TestMappings() "{{{
	exec "normal i*b:_l_delimitMate_autoclose = " . b:_l_delimitMate_autoclose . "\<Esc>o"
	exec "normal i*b:_l_delimitMate_expand_space = " . b:_l_delimitMate_expand_space . "\<Esc>o"
	exec "normal i*b:_l_delimitMate_expand_cr = " . b:_l_delimitMate_expand_cr . "\<Esc>o\<Esc>o"
	echom b:_l_delimitMate_autoclose.b:_l_delimitMate_expand_space.b:_l_delimitMate_expand_cr
	if b:_l_delimitMate_autoclose
		" {{{
		for i in range(len(b:_l_delimitMate_left_delims))
			exec "normal GGoOpen & close: " . b:_l_delimitMate_left_delims[i]. "|"
			exec "normal oDelete: " . b:_l_delimitMate_left_delims[i] . "\<BS>|"
			exec "normal oExit: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . "|"
			exec "normal oSpace: " . b:_l_delimitMate_left_delims[i] . " |"
			exec "normal oDelete space: " . b:_l_delimitMate_left_delims[i] . " \<BS>|"
			exec "normal GGoVisual-L: v\<Esc>v" . b:_l_delimitMate_visual_leader . b:_l_delimitMate_left_delims[i]
			exec "normal oVisual-R: v\<Esc>v" . b:_l_delimitMate_visual_leader . b:_l_delimitMate_right_delims[i]
			exec "normal oCar return: " . b:_l_delimitMate_left_delims[i] . "\<CR>|"
			exec "normal GGoDelete car return: " . b:_l_delimitMate_left_delims[i] . "\<CR>\<BS>|\<Esc>GGA\<Esc>o\<Esc>o"
		endfor
		for i in range(len(b:_l_delimitMate_quotes_list))
			exec "normal GGAOpen & close: " . b:_l_delimitMate_quotes_list[i]	. "|"
			exec "normal oDelete: "
			exec "normal oExit: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "|"
			exec "normal oSpace: " . b:_l_delimitMate_quotes_list[i] . " |"
			exec "normal oDelete space: " . b:_l_delimitMate_quotes_list[i] . " \<BS>|"
			exec "normal GGoVisual: v\<Esc>v" . b:_l_delimitMate_visual_leader . b:_l_delimitMate_quotes_list[i]
			exec "normal oCar return: " . b:_l_delimitMate_quotes_list[i] . "\<CR>|"
			exec "normal GGoDelete car return: " . b:_l_delimitMate_quotes_list[i] . "\<CR>\<BS>|\<Esc>GGA\<Esc>o\<Esc>o"
		endfor
		"}}}
	else
		"{{{
		for i in range(len(b:_l_delimitMate_left_delims))
			exec "normal GGoOpen & close: " . b:_l_delimitMate_left_delims[i]	. b:_l_delimitMate_right_delims[i] . "|"
			exec "normal oDelete: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . "\<BS>|"
			exec "normal oExit: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . b:_l_delimitMate_right_delims[i] . "|"
			exec "normal oSpace: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . " |"
			exec "normal oDelete space: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . " \<BS>|"
			exec "normal GGoVisual-L: v\<Esc>v" . b:_l_delimitMate_visual_leader . b:_l_delimitMate_left_delims[i]
			exec "normal oVisual-R: v\<Esc>v" . b:_l_delimitMate_visual_leader . b:_l_delimitMate_right_delims[i]
			exec "normal oCar return: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . "\<CR>|"
			exec "normal GGoDelete car return: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . "\<CR>\<BS>|\<Esc>GGA\<Esc>o\<Esc>o"
		endfor
		for i in range(len(b:_l_delimitMate_quotes_list))
			exec "normal GGoOpen & close: " . b:_l_delimitMate_quotes_list[i]	. b:_l_delimitMate_quotes_list[i] . "|"
			exec "normal oDelete: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "\<BS>|"
			exec "normal oExit: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "|"
			exec "normal oSpace: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . " |"
			exec "normal oDelete space: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . " \<BS>|"
			exec "normal GGoVisual: v\<Esc>v" . b:_l_delimitMate_visual_leader . b:_l_delimitMate_quotes_list[i]
			exec "normal oCar return: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "\<CR>|"
			exec "normal GGoDelete car return: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "\<CR>\<BS>|\<Esc>GGA\<Esc>o\<Esc>o"
		endfor
	endif "}}}
	exec "normal \<Esc>i"
endfunction "}}}

"}}}

" vim:foldmethod=marker:foldcolumn=4
