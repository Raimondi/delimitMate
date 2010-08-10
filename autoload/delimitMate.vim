" ============================================================================
" File:        autoload/delimitMate.vim
" Version:     2.4.1
" Modified:    2010-07-31
" Description: This plugin provides auto-completion for quotes, parens, etc.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
" Manual:      Read ":help delimitMate".

let delimitMate_loaded = 1
" Utilities {{{

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

" Tools: {{{
function! delimitMate#TestMappings() "{{{
	exec "normal GGi*b:_l_delimitMate_autoclose = " . b:_l_delimitMate_autoclose . "\<Esc>o"
	exec "normal GGi*b:_l_delimitMate_expand_space = " . b:_l_delimitMate_expand_space . "\<Esc>o"
	exec "normal GGi*b:_l_delimitMate_expand_cr = " . b:_l_delimitMate_expand_cr . "\<Esc>o\<Esc>o"
	echom b:_l_delimitMate_autoclose.b:_l_delimitMate_expand_space.b:_l_delimitMate_expand_cr
	if b:_l_delimitMate_autoclose
		" {{{
		for i in range(len(b:_l_delimitMate_left_delims))
			exec "normal GGoOpen: " . b:_l_delimitMate_left_delims[i]. "|"
			exec "normal oDelete: " . b:_l_delimitMate_left_delims[i] . "\<BS>|"
			exec "normal oExit: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . "|"
			exec "normal oSpace: " . b:_l_delimitMate_left_delims[i] . " |"
			exec "normal oDelete space: " . b:_l_delimitMate_left_delims[i] . " \<BS>|"
			exec "normal GGoVisual-L: v\<Esc>v" . b:_l_delimitMate_visual_leader . b:_l_delimitMate_left_delims[i]
			exec "normal oVisual-R: v\<Esc>v" . b:_l_delimitMate_visual_leader . b:_l_delimitMate_right_delims[i]
			exec "normal oCar return: " . b:_l_delimitMate_left_delims[i] . "\<CR>|"
			exec "normal GGoDelete car return: " . b:_l_delimitMate_left_delims[i] . "\<CR>\<BS>|\<Esc>GG\<Esc>o"
		endfor
		for i in range(len(b:_l_delimitMate_quotes_list))
			exec "normal GGAOpen: " . b:_l_delimitMate_quotes_list[i]	. "|"
			exec "normal oDelete: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . "\<BS>|"
			exec "normal oExit: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "|"
			exec "normal oSpace: " . b:_l_delimitMate_quotes_list[i] . " |"
			exec "normal oDelete space: " . b:_l_delimitMate_quotes_list[i] . " \<BS>|"
			exec "normal GGoVisual: v\<Esc>v" . b:_l_delimitMate_visual_leader . b:_l_delimitMate_quotes_list[i]
			exec "normal oCar return: " . b:_l_delimitMate_quotes_list[i] . "\<CR>|"
			exec "normal GGoDelete car return: " . b:_l_delimitMate_quotes_list[i] . "\<CR>\<BS>|\<Esc>GG\<Esc>o"
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
			exec "normal GGoDelete car return: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . "\<CR>\<BS>|\<Esc>GG\<Esc>o"
		endfor
		for i in range(len(b:_l_delimitMate_quotes_list))
			exec "normal GGoOpen & close: " . b:_l_delimitMate_quotes_list[i]	. b:_l_delimitMate_quotes_list[i] . "|"
			exec "normal oDelete: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "\<BS>|"
			exec "normal oExit: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "|"
			exec "normal oSpace: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . " |"
			exec "normal oDelete space: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . " \<BS>|"
			exec "normal GGoVisual: v\<Esc>v" . b:_l_delimitMate_visual_leader . b:_l_delimitMate_quotes_list[i]
			exec "normal oCar return: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "\<CR>|"
			exec "normal GGoDelete car return: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "\<CR>\<BS>|\<Esc>GG\<Esc>o"
		endfor
	endif "}}}
	"exec "normal \<Esc>i"

	let imaps =
				\ b:_l_delimitMate_right_delims +
				\ b:_l_delimitMate_left_delims +
				\ b:_l_delimitMate_quotes_list +
				\ b:_l_delimitMate_apostrophes_list +
				\ ['<BS>', '<S-BS>', '<Del>', '<CR>', '<Space>', '<S-Tab>', '<Esc>'] +
				\ ['<Up>', '<Down>', '<Left>', '<Right>', '<LeftMouse>', '<RightMouse>'] +
				\ ['<Home>', '<End>', '<PageUp>', '<PageDown>', '<S-Down>', '<S-Up>']

	let vmaps =
				\ b:_l_delimitMate_right_delims +
				\ b:_l_delimitMate_left_delims +
				\ b:_l_delimitMate_quotes_list

	let ibroken = []
	for map in imaps
		if maparg(map, "i") !~? 'delimitMate'
			let output = ''
			redir => output | execute "verbose imap ".map | redir END
			let ibroken = ibroken + [map.": is not set:"] + split(output, '\n')
		endif
	endfor
	let ibroken = len(ibroken) > 0 ? ['IMAP'] + ibroken : []

	let vbroken = []
	if !exists("b:_l_delimitMate_visual_leader")
		let vleader = ""
	else
		let vleader = b:_l_delimitMate_visual_leader
	endif
	for map in vmaps
		if maparg(vleader . map, "v") !~? "delimitMate"
			let output = ''
			redir => output | execute "verbose imap ".map | redir END
			let vbroken = vbroken + [vleader.map.": is not set:"] + split(output,'\n')
		endif
	endfor
	let vbroken = len(vbroken) > 0 ? ['VMAP'] + vbroken : []

	call append('$', ibroken + vbroken + ['--------------------', '', ''])
endfunction "}}}

"}}}

" vim:foldmethod=marker:foldcolumn=4
