" File:        autoload/delimitMate.vim
" Version:     2.6
" Modified:    2011-01-14
" Description: This plugin provides auto-completion for quotes, parens, etc.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
" Manual:      Read ":help delimitMate".
" ============================================================================

" Utilities {{{

"let delimitMate_loaded = 1

function! delimitMate#ShouldJump(...) "{{{
	" Returns 1 if the next character is a closing delimiter.
	let char = delimitMate#GetCharFromCursor(0)
	let list = b:_l_delimitMate_right_delims + b:_l_delimitMate_quotes_list

	" Closing delimiter on the right.
	if (!a:0 && index(list, char) > -1)
				\ || (a:0 && char == a:1)
		return 1
	endif

	" Closing delimiter with space expansion.
	let nchar = delimitMate#GetCharFromCursor(1)
	if !a:0 && b:_l_delimitMate_expand_space && char == " "
		if index(list, nchar) > -1
			return 2
		endif
	elseif a:0 && b:_l_delimitMate_expand_space && nchar == a:1
		return 3
	endif

	" Closing delimiter with CR expansion.
	let uchar = matchstr(getline(line('.') + 1), '^\s*\zs\S')
	if !a:0 && b:_l_delimitMate_expand_cr && char == ""
		if index(list, uchar) > -1
			return 4
		endif
	elseif a:0 && b:_l_delimitMate_expand_cr && uchar == a:1
		return 5
	endif

	return 0
endfunction "}}}

function! delimitMate#IsEmptyPair(str) "{{{
	if strlen(substitute(a:str, ".", "x", "g")) != 2
		return 0
	endif
	let idx = index(b:_l_delimitMate_left_delims, matchstr(a:str, '^.'))
	if idx > -1 &&
				\ b:_l_delimitMate_right_delims[idx] == matchstr(a:str, '.$')
		return 1
	endif
	let idx = index(b:_l_delimitMate_quotes_list, matchstr(a:str, '^.'))
	if idx > -1 &&
				\ b:_l_delimitMate_quotes_list[idx] == matchstr(a:str, '.$')
		return 1
	endif
	return 0
endfunction "}}}

function! delimitMate#GetCharFromCursor(...) "{{{
	let idx = col('.') - 1
	if !a:0 || (a:0 && a:1 >= 0)
		" Get char from cursor.
		let line = getline('.')[idx :]
		let pos = a:0 ? a:1 : 0
		return matchstr(line, '^'.repeat('.', pos).'\zs.')
	endif
	" Get char behind cursor.
	let line = getline('.')[: idx - 1]
	let pos = 0 - (1 + a:1)
	return matchstr(line, '.\ze'.repeat('.', pos).'$')
endfunction "delimitMate#GetCharFromCursor }}}

function! delimitMate#IsCRExpansion(...) " {{{
	let nchar = getline(line('.')-1)[-1:]
	let schar = matchstr(getline(line('.')+1), '^\s*\zs\S')
	let isEmpty = a:0 ? getline('.') =~ '^\s*$' : empty(getline('.'))
	if index(b:_l_delimitMate_left_delims, nchar) > -1
				\ && index(b:_l_delimitMate_left_delims, nchar) == index(b:_l_delimitMate_right_delims, schar)
				\ && isEmpty
		return 1
	elseif index(b:_l_delimitMate_quotes_list, nchar) > -1
				\ && index(b:_l_delimitMate_quotes_list, nchar) == index(b:_l_delimitMate_quotes_list, schar)
				\ && isEmpty
		return 1
	else
		return 0
	endif
endfunction " }}} delimitMate#IsCRExpansion()

function! delimitMate#IsSpaceExpansion() " {{{
	if col('.') > 2
		let pchar = delimitMate#GetCharFromCursor(-2)
		let nchar = delimitMate#GetCharFromCursor(1)
		let isSpaces = (delimitMate#GetCharFromCursor(-1) == delimitMate#GetCharFromCursor(0) && delimitMate#GetCharFromCursor(-1) == " ")

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
	" get char before the cursor.
	let char1 = delimitMate#GetCharFromCursor(-1)
	" get char under the cursor.
	let char2 = delimitMate#GetCharFromCursor(0)
	return delimitMate#IsEmptyPair( char1.char2 )
endfunction "}}}

function! delimitMate#CursorIdx() "{{{
	let idx = len(split(getline('.')[: col('.') - 1], '\zs')) - 1
	return idx
endfunction "delimitMate#CursorCol }}}

function! delimitMate#WriteBefore(str) "{{{
	let len = len(a:str)
	let line = getline('.')
	let col = delimitMate#CursorIdx() - 1
	if col < 0
		call setline('.',line[(col+len+1):])
	else
		call setline('.',line[:(col)].line[(col+len+1):])
	endif
	return a:str
endfunction " }}}

function! delimitMate#WriteAfter(str) "{{{
	let len = 1 "len(a:str)
	let line = split(getline('.'), '\zs')
	let col = delimitMate#CursorIdx() - 1
	if (col + 1) < 0
		let line = insert(line, a:str)
	elseif col('.') == col('$')
		let line = add(line, a:str)
	else
		let line1 = line[:(col)]
		let line2 = line[(col+len):]
		let line = line1 + [a:str] + line2
	endif
	call setline('.', join(line, ''))
	return ''
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
	let region = delimitMate#GetCurrentSyntaxRegion()
	if index(b:_l_delimitMate_excluded_regions_list, region) >= 0
		"echom "Forbidden 1!"
		return 1
	endif
	let region = delimitMate#GetCurrentSyntaxRegionIf(a:char)
	"echom "Forbidden 2!"
	return index(b:_l_delimitMate_excluded_regions_list, region) >= 0
endfunction "}}}

function! delimitMate#FlushBuffer() " {{{
	let b:_l_delimitMate_buffer = []
	return ''
endfunction " }}}

function! delimitMate#AddToBuffer(str) "{{{
	call insert(b:_l_delimitMate_buffer, a:str)
endfunction "delimitMate#AddToBuffer }}}

function! delimitMate#BalancedParens(char) "{{{
	" Returns:
	" = 0 => Parens balanced.
	" > 0 => More opening parens.
	" < 0 => More closing parens.

	let line = getline('.')
	let col = delimitMate#CursorIdx() - 1
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

	" Return the found balance:
	return opening - closing
endfunction "}}}

function! delimitMate#RmBuffer(num) " {{{
	if len(b:_l_delimitMate_buffer) > 0
	   call remove(b:_l_delimitMate_buffer, 0, (a:num-1))
	endif
	return ""
endfunction " }}}

function! delimitMate#IsSmartQuote(char) "{{{
	if !b:_l_delimitMate_smart_quotes
		return 0
	endif
	let char_at = delimitMate#GetCharFromCursor(0)
	let char_before = delimitMate#GetCharFromCursor(-1)
	let valid_char_re = '\w\|[^[:punct:][:space:]]'
	let word_before = char_before =~ valid_char_re
	let word_at = char_at  =~ valid_char_re
	let escaped = delimitMate#CursorIdx() >= 1 && delimitMate#GetCharFromCursor(-1) == '\'
	let result = word_before || escaped || word_at
	return result
endfunction "delimitMate#SmartQuote }}}

" }}}

" Doers {{{
function! delimitMate#SkipDelim(char) "{{{
	if delimitMate#IsForbidden(a:char)
		return a:char
	endif
	let col = col('.') - 1
	let line = getline('.')
	if col > 0
		let cur = delimitMate#GetCharFromCursor(0)
		let pre = delimitMate#GetCharFromCursor(-1)
	else
		let cur = delimitMate#GetCharFromCursor(0)
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
		call delimitMate#AddToBuffer(a:char)
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
	" Try to balance matchpairs
	if b:_l_delimitMate_balance_matchpairs &&
				\ delimitMate#BalancedParens(a:char) <= 0
		return ''
	endif
	let line = getline('.')
	let col = col('.')-2
	let tail = len(line) == (col + 1) ? b:_l_delimitMate_eol_marker : ''
	let left = b:_l_delimitMate_left_delims[index(b:_l_delimitMate_right_delims,a:char)]
	let smart_matchpairs = substitute(b:_l_delimitMate_smart_matchpairs, '\\!', left, 'g')
	let smart_matchpairs = substitute(smart_matchpairs, '\\#', a:char, 'g')
	"echom left.':'.smart_matchpairs . ':' . matchstr(line[col+1], smart_matchpairs)
	if b:_l_delimitMate_smart_matchpairs != '' &&
				\ line[col+1:] =~ smart_matchpairs
		return ''
	elseif (col) < 0
		call setline('.',a:char.line)
		call delimitMate#AddToBuffer(a:char)
	else
		"echom string(col).':'.line[:(col)].'|'.line[(col+1):]
		call setline('.',line[:(col)].a:char.tail.line[(col+1):])
		call delimitMate#AddToBuffer(a:char . tail)
	endif
	return ''
endfunction " }}}

function! delimitMate#QuoteDelim(char) "{{{
	if delimitMate#IsForbidden(a:char)
		return a:char
	endif
	let char_at = delimitMate#GetCharFromCursor(0)
	let char_before = delimitMate#GetCharFromCursor(-1)
	if char_at == a:char &&
				\ index(b:_l_delimitMate_nesting_quotes, a:char) < 0
		" Get out of the string.
		return a:char . delimitMate#Del()
	elseif delimitMate#IsSmartQuote(a:char)
		" Seems like a smart quote, insert a single char.
		return a:char
	elseif (char_before == a:char && char_at != a:char) && b:_l_delimitMate_smart_quotes
		" Seems like we have an unbalanced quote, insert one quotation mark and jump to the middle.
		call delimitMate#AddToBuffer(a:char)
		return delimitMate#WriteAfter(a:char)
	else
		" Insert a pair and jump to the middle.
		call delimitMate#AddToBuffer(a:char)
		call delimitMate#WriteAfter(a:char)
		return a:char
	endif
endfunction "}}}

function! delimitMate#JumpOut(char) "{{{
	if delimitMate#IsForbidden(a:char)
		return a:char
	endif
	let jump = delimitMate#ShouldJump(a:char)
	if jump == 1
		return a:char . delimitMate#Del()
	elseif jump == 3
		return ' '.a:char.delimitMate#Del().delimitMate#Del()
	elseif jump == 5
		call delimitMate#FlushBuffer()
		return "\<C-O>:exec \"normal! \\<CR>a\"\<CR>"
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
	let char = delimitMate#GetCharFromCursor(0)
	if char == " "
		" Space expansion.
		"let char = char . getline('.')[col('.')] . delimitMate#Del()
		return char . getline('.')[col('.')] . delimitMate#Del() . delimitMate#Del()
		"call delimitMate#RmBuffer(1)
	elseif char == ""
		" CR expansion.
		"let char = "\<CR>" . getline(line('.') + 1)[0] . "\<Del>"
		call delimitMate#FlushBuffer()
		return "\<CR>" . getline(line('.') + 1)[0] . delimitMate#Del() . "\<Del>"
	else
		"call delimitMate#RmBuffer(1)
		return char . delimitMate#Del()
	endif
endfunction " delimitMate#JumpAny() }}}

function! delimitMate#JumpMany() " {{{
	let line = split(getline('.')[col('.') - 1 : ], '\zs')
	let rights = ""
	let found = 0
	for char in line
		if index(b:_l_delimitMate_quotes_list, char) >= 0 ||
					\ index(b:_l_delimitMate_right_delims, char) >= 0
			let rights .= "\<Right>"
			let found = 1
		elseif found == 0
			let rights .= "\<Right>"
		else
			break
		endif
	endfor
	if found == 1
		return rights
	else
		return ''
	endif
endfunction " delimitMate#JumpMany() }}}

function! delimitMate#ExpandReturn() "{{{
	if delimitMate#IsForbidden("")
		return "\<CR>"
	endif
	if delimitMate#WithinEmptyPair()
		" Expand:
		call delimitMate#FlushBuffer()

		" Not sure why I used the previous combos, but I'm sure somebody will tell
		" me about it.
		" XXX zv prevents breaking expansion with syntax folding enabled by
		" InsertLeave.
		return "\<Esc>a\<CR>\<Esc>zvO"
	else
		return "\<CR>"
	endif
endfunction "}}}

function! delimitMate#ExpandSpace() "{{{
	if delimitMate#IsForbidden("\<Space>")
		return "\<Space>"
	endif
	let escaped = delimitMate#CursorIdx() >= 2 && delimitMate#GetCharFromCursor(-2) == '\'
	if delimitMate#WithinEmptyPair() && !escaped
		" Expand:
		call delimitMate#AddToBuffer('s')
		return delimitMate#WriteAfter(' ') . "\<Space>"
	else
		return "\<Space>"
	endif
endfunction "}}}

function! delimitMate#BS() " {{{
	let buffer_tail = get(b:_l_delimitMate_buffer, '-1', '')
	if delimitMate#IsForbidden("")
		let extra = ''
	elseif &backspace !~ 'start\|2' && empty(b:_l_delimitMate_buffer)
		let extra = ''
	elseif delimitMate#WithinEmptyPair()
		let extra = delimitMate#Del()
	elseif delimitMate#IsSpaceExpansion()
		let extra = delimitMate#Del()
	elseif delimitMate#IsCRExpansion()
		let extra = repeat("\<Del>", len(matchstr(getline(line('.') + 1), '^\s*\S')))
	else
		let extra = ''
	endif
	let tail_re = '\m\C\%('
				\ . join(b:_l_delimitMate_right_delims, '\|')
				\ . '\)'
				\ . escape(b:_l_delimitMate_eol_marker, '\*.^$')
				\ . '$'
	if buffer_tail =~ tail_re && search('\%#'.tail_re, 'cWn')
		let extra .= join(map(split(b:_l_delimitMate_eol_marker, '\zs'),
					\ 'delimitMate#Del()'), '')
	endif
	return "\<BS>" . extra
endfunction " }}} delimitMate#BS()

function! delimitMate#Del() " {{{
	if len(b:_l_delimitMate_buffer) > 0
		call delimitMate#RmBuffer(1)
		return "\<Del>"
	else
		return "\<Del>"
	endif
endfunction " }}}

function! delimitMate#Finish(move_back) " {{{
	let len = len(b:_l_delimitMate_buffer)
	if len > 0
		let buffer = join(b:_l_delimitMate_buffer, '')
		let len2 = len(buffer)
		" Reset buffer:
		let b:_l_delimitMate_buffer = []
		let line = getline('.')
		let col = col('.') -2
		"echom 'col: ' . col . '-' . line[:col] . "|" . line[col+len+1:] . '%' . buffer
		if col < 0
			call setline('.', line[col+len2+1:])
		else
			call setline('.', line[:col] . line[col+len2+1:])
		endif
		let i = 1
		let lefts = ""
		while i <= len && a:move_back
			let lefts = lefts . "\<Left>"
			let i += 1
		endwhile
		let result = substitute(buffer, "s", "\<Space>", 'g') . lefts
		return result
	endif
	return ''
endfunction " }}}

" }}}

" Tools: {{{
function! delimitMate#TestMappings() "{{{
	if &modified
		echohl WarningMsg
		let answer = input("Modified buffer, type \"yes\" to write and proceed with test: ") !~ '\c^yes$'
		echohl NONE
		if answer != '\c^yes$'
			return
		endif
		write
	endif
	let options = sort(keys(delimitMate#OptionsList()))
	let optoutput = ['delimitMate Report', '==================', '', '* Options: ( ) default, (g) global, (b) buffer','']
	for option in options
		exec 'call add(optoutput, ''('.(exists('b:delimitMate_'.option) ? 'b' : exists('g:delimitMate_'.option) ? 'g' : ' ').') delimitMate_''.option.'' = ''.string(b:_l_delimitMate_'.option.'))'
	endfor
	call append(line('$'), optoutput + ['--------------------',''])

	" Check if mappings were set. {{{
	let imaps = b:_l_delimitMate_right_delims
	let imaps = imaps + ( b:_l_delimitMate_autoclose ? b:_l_delimitMate_left_delims : [] )
	let imaps = imaps +
				\ b:_l_delimitMate_quotes_list +
				\ b:_l_delimitMate_apostrophes_list +
				\ ['<BS>', '<S-BS>', '<Del>', '<S-Tab>', '<Esc>'] +
				\ ['<Up>', '<Down>', '<Left>', '<Right>', '<LeftMouse>', '<RightMouse>'] +
				\ ['<Home>', '<End>', '<PageUp>', '<PageDown>', '<S-Down>', '<S-Up>', '<C-G>g'] +
				\ ['<ScrollWheelUp>', '<S-ScrollWheelUp>', '<C-ScrollWheelUp>'] +
				\ ['<ScrollWheelDown>', '<S-ScrollWheelDown>', '<C-ScrollWheelDown>'] +
				\ ['<ScrollWheelLeft>', '<S-ScrollWheelLeft>', '<C-ScrollWheelLeft>'] +
				\ ['<ScrollWheelRight>', '<S-ScrollWheelRight>', '<C-ScrollWheelRight>']
	let imaps = imaps + ( b:_l_delimitMate_expand_cr ?  ['<CR>'] : [] )
	let imaps = imaps + ( b:_l_delimitMate_expand_space ?  ['<Space>'] : [] )

	let vmaps =
				\ b:_l_delimitMate_right_delims +
				\ b:_l_delimitMate_left_delims +
				\ b:_l_delimitMate_quotes_list

	let imappings = []
	for map in imaps
		let output = ''
		if map == '|'
			let map = '<Bar>'
		endif
		redir => output | execute "verbose imap ".map | redir END
		let imappings = imappings + split(output, '\n')
	endfor

	unlet! output
	let output = ['* Mappings:', ''] + imappings + ['--------------------', '']
	call append('$', output+['* Showcase:', ''])
	" }}}
	if b:_l_delimitMate_autoclose
		" {{{
		for i in range(len(b:_l_delimitMate_left_delims))
			exec "normal Go0\<C-D>Open: " . b:_l_delimitMate_left_delims[i]. "|"
			exec "normal o0\<C-D>Delete: " . b:_l_delimitMate_left_delims[i] . "\<BS>|"
			exec "normal o0\<C-D>Exit: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . "|"
			if b:_l_delimitMate_expand_space == 1
				exec "normal o0\<C-D>Space: " . b:_l_delimitMate_left_delims[i] . " |"
				exec "normal o0\<C-D>Delete space: " . b:_l_delimitMate_left_delims[i] . " \<BS>|"
			endif
			if b:_l_delimitMate_expand_cr == 1
				exec "normal o0\<C-D>Car return: " . b:_l_delimitMate_left_delims[i] . "\<CR>|"
				exec "normal Go0\<C-D>Delete car return: " . b:_l_delimitMate_left_delims[i] . "\<CR>0\<C-D>\<BS>|"
			endif
			call append(line('$'), '')
		endfor
		for i in range(len(b:_l_delimitMate_quotes_list))
			exec "normal Go0\<C-D>Open: " . b:_l_delimitMate_quotes_list[i]	. "|"
			exec "normal o0\<C-D>Delete: " . b:_l_delimitMate_quotes_list[i] . "\<BS>|"
			exec "normal o0\<C-D>Exit: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "|"
			if b:_l_delimitMate_expand_space == 1
				exec "normal o0\<C-D>Space: " . b:_l_delimitMate_quotes_list[i] . " |"
				exec "normal o0\<C-D>Delete space: " . b:_l_delimitMate_quotes_list[i] . " \<BS>|"
			endif
			if b:_l_delimitMate_expand_cr == 1
				exec "normal o0\<C-D>Car return: " . b:_l_delimitMate_quotes_list[i] . "\<CR>|"
				exec "normal Go0\<C-D>Delete car return: " . b:_l_delimitMate_quotes_list[i] . "\<CR>\<BS>|"
			endif
			call append(line('$'), '')
		endfor
		"}}}
	else
		"{{{
		for i in range(len(b:_l_delimitMate_left_delims))
			exec "normal GoOpen & close: " . b:_l_delimitMate_left_delims[i]	. b:_l_delimitMate_right_delims[i] . "|"
			exec "normal oDelete: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . "\<BS>|"
			exec "normal oExit: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . b:_l_delimitMate_right_delims[i] . "|"
			if b:_l_delimitMate_expand_space == 1
				exec "normal oSpace: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . " |"
				exec "normal oDelete space: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . " \<BS>|"
			endif
			if b:_l_delimitMate_expand_cr == 1
				exec "normal oCar return: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . "\<CR>|"
				exec "normal GoDelete car return: " . b:_l_delimitMate_left_delims[i] . b:_l_delimitMate_right_delims[i] . "\<CR>\<BS>|"
			endif
			call append(line('$'), '')
		endfor
		for i in range(len(b:_l_delimitMate_quotes_list))
			exec "normal GoOpen & close: " . b:_l_delimitMate_quotes_list[i]	. b:_l_delimitMate_quotes_list[i] . "|"
			exec "normal oDelete: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "\<BS>|"
			exec "normal oExit: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "|"
			if b:_l_delimitMate_expand_space == 1
				exec "normal oSpace: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . " |"
				exec "normal oDelete space: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . " \<BS>|"
			endif
			if b:_l_delimitMate_expand_cr == 1
				exec "normal oCar return: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "\<CR>|"
				exec "normal GoDelete car return: " . b:_l_delimitMate_quotes_list[i] . b:_l_delimitMate_quotes_list[i] . "\<CR>\<BS>|"
			endif
			call append(line('$'), '')
		endfor
	endif "}}}
	redir => setoptions | set | filetype | version | redir END
	call append(line('$'), split(setoptions,"\n")
				\ + ['--------------------'])
	setlocal nowrap
endfunction "}}}

function! delimitMate#OptionsList() "{{{
	return {'autoclose' : 1,'matchpairs': &matchpairs, 'quotes' : '" '' `', 'nesting_quotes' : [], 'expand_cr' : 0, 'expand_space' : 0, 'smart_quotes' : 1, 'smart_matchpairs' : '\w', 'balance_matchpairs' : 0, 'excluded_regions' : 'Comment', 'excluded_ft' : '', 'eol_marker': '', 'apostrophes' : ''}
endfunction " delimitMate#OptionsList }}}
"}}}

" vim:foldmethod=marker:foldcolumn=4
