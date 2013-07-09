" File:        autoload/delimitMate.vim
" Version:     2.6
" Modified:    2011-01-14
" Description: This plugin provides auto-completion for quotes, parens, etc.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
" Manual:      Read ":help delimitMate".
" ============================================================================

" Utilities {{{

"let delimitMate_loaded = 1

if !exists('s:options')
	let s:options = {}
endif
function! s:s(name, value, ...) "{{{
	let scope = a:0 ? a:1 : 's'
	let bufnr = bufnr('%')
	if !exists('s:options[bufnr]')
		let s:options[bufnr] = {}
	endif
	if scope == 's'
		let name = 'options.' . bufnr . '.' . a:name
	else
		let name = 'delimitMate_' . a:name
	endif
	exec 'let ' . scope . ':' . name . ' = a:value'
endfunction "}}}

function! s:g(name, ...) "{{{
	let scope = a:0 ? a:1 : 's'
	if scope == 's'
		let bufnr = bufnr('%')
		let name = 'options.' . bufnr . '.' . a:name
	else
		let name = 'delimitMate_' . a:name
	endif
	return eval(scope . ':' . name)
endfunction "}}}

function! s:exists(name, ...) "{{{
	let scope = a:0 ? a:1 : 's'
	if scope == 's'
		let bufnr = bufnr('%')
		let name = 'options.' . bufnr . '.' . a:name
	else
		let name = 'delimitMate_' . a:name
	endif
	return exists(scope . ':' . name)
endfunction "}}}

function! delimitMate#Set(...) "{{{
	return call('s:s', a:000)
endfunction "}}}

function! delimitMate#Get(...) "{{{
	return call('s:g', a:000)
endfunction "}}}

function! delimitMate#ShouldJump(...) "{{{
	" Returns 1 if the next character is a closing delimiter.
	let char = delimitMate#GetCharFromCursor(0)
	let list = s:g('right_delims') + s:g('quotes_list')

	" Closing delimiter on the right.
	if (!a:0 && index(list, char) > -1)
				\ || (a:0 && char == a:1)
		return 1
	endif

	" Closing delimiter with space expansion.
	let nchar = delimitMate#GetCharFromCursor(1)
	if !a:0 && s:g('expand_space') && char == " "
		if index(list, nchar) > -1
			return 2
		endif
	elseif a:0 && s:g('expand_space') && nchar == a:1 && char == ' '
		return 3
	endif

	if !s:g('jump_expansion')
		return 0
	endif

	" Closing delimiter with CR expansion.
	let uchar = matchstr(getline(line('.') + 1), '^\s*\zs\S')
	if !a:0 && s:g('expand_cr') && char == ""
		if index(list, uchar) > -1
			return 4
		endif
	elseif a:0 && s:g('expand_cr') && uchar == a:1
		return 5
	endif
	return 0
endfunction "}}}

function! delimitMate#IsEmptyPair(str) "{{{
	if strlen(substitute(a:str, ".", "x", "g")) != 2
		return 0
	endif
	let idx = index(s:g('left_delims'), matchstr(a:str, '^.'))
	if idx > -1 &&
				\ s:g('right_delims')[idx] == matchstr(a:str, '.$')
		return 1
	endif
	let idx = index(s:g('quotes_list'), matchstr(a:str, '^.'))
	if idx > -1 &&
				\ s:g('quotes_list')[idx] == matchstr(a:str, '.$')
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
	if index(s:g('left_delims'), nchar) > -1
				\ && index(s:g('left_delims'), nchar)
				\    == index(s:g('right_delims'), schar)
				\ && isEmpty
		return 1
	elseif index(s:g('quotes_list'), nchar) > -1
				\ && index(s:g('quotes_list'), nchar)
				\    == index(s:g('quotes_list'), schar)
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
		let isSpaces =
					\ (delimitMate#GetCharFromCursor(-1)
					\   == delimitMate#GetCharFromCursor(0)
					\ && delimitMate#GetCharFromCursor(-1) == " ")

		if index(s:g('left_delims'), pchar) > -1 &&
				\ index(s:g('left_delims'), pchar)
				\   == index(s:g('right_delims'), nchar) &&
				\ isSpaces
			return 1
		elseif index(s:g('quotes_list'), pchar) > -1 &&
				\ index(s:g('quotes_list'), pchar)
				\   == index(s:g('quotes_list'), nchar) &&
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
	if (col + 1) < 0 || col('.') == 1
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
	let changed_line = strpart(origin_line, 0, col - 1) . a:char
				\ . strpart(origin_line, col - 1)
	call setline('.', changed_line)
	let region = delimitMate#GetSyntaxRegion(line('.'), col)
	call setline('.', origin_line)
	return region
endfunction "}}}

function! delimitMate#IsForbidden(char) "{{{
	if s:g('excluded_regions_enabled') == 0
		return 0
	endif
	let region = delimitMate#GetCurrentSyntaxRegion()
	if index(s:g('excluded_regions_list'), region) >= 0
		"echom "Forbidden 1!"
		return 1
	endif
	let region = delimitMate#GetCurrentSyntaxRegionIf(a:char)
	"echom "Forbidden 2!"
	return index(s:g('excluded_regions_list'), region) >= 0
endfunction "}}}

function! delimitMate#FlushBuffer() " {{{
	call s:s('buffer', [])
	return ''
endfunction " }}}

function! delimitMate#AddToBuffer(str, ...) "{{{
	if a:0 && a:1 == 1
		return add(s:g('buffer'), a:str)
	endif
	return insert(s:g('buffer'), a:str)
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
	let left = s:g('left_delims')[index(s:g('right_delims'), a:char)]
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
	if len(s:g('buffer')) > 0
	   call remove(s:g('buffer'), 0, (a:num-1))
	endif
	return ""
endfunction " }}}

function! delimitMate#IsSmartQuote(char) "{{{
	if !s:g('smart_quotes')
		return 0
	endif
	let char_at = delimitMate#GetCharFromCursor(0)
	let char_before = delimitMate#GetCharFromCursor(-1)
	let valid_char_re = '\w\|[^[:punct:][:space:]]'
	let word_before = char_before =~ valid_char_re
	let word_at = char_at  =~ valid_char_re
	let escaped = delimitMate#CursorIdx() >= 1
				\ && delimitMate#GetCharFromCursor(-1) == '\'
	let noescaped = substitute(getline('.'), '\\.', '', 'g')
	let even = !(count(split(noescaped, '\zs'), a:char) % 2)
	let result = word_before || escaped || word_at || !even
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
	if s:g('balance_matchpairs') &&
				\ delimitMate#BalancedParens(a:char) <= 0
		return ''
	endif
	let line = getline('.')
	let col = col('.')-2
	let tail = len(line) == (col + 1) ? s:g('eol_marker') : ''
	let left = s:g('left_delims')[index(s:g('right_delims'),a:char)]
	let smart_matchpairs = substitute(s:g('smart_matchpairs'), '\\!', left, 'g')
	let smart_matchpairs = substitute(smart_matchpairs, '\\#', a:char, 'g')

	if s:g('smart_matchpairs') != '' &&
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
				\ index(s:g('nesting_quotes'), a:char) < 0
		" Get out of the string.
		return a:char . delimitMate#Del()
	elseif delimitMate#IsSmartQuote(a:char)
		" Seems like a smart quote, insert a single char.
		return a:char
	elseif (char_before == a:char && char_at != a:char)
				\ && s:g('smart_quotes')
		" Seems like we have an unbalanced quote, insert one quotation
		" mark and jump to the middle.
		call delimitMate#AddToBuffer(a:char)
		return delimitMate#WriteAfter(a:char)
	else
		" Insert a pair and jump to the middle.
		let sufix = ''
		if !empty(s:g('eol_marker')) && col('.') - 1 == len(getline('.'))
			let idx = len(s:g('eol_marker')) * -1
			let marker = getline('.')[idx : ]
			let has_marker = marker == s:g('eol_marker')
			let sufix = !has_marker ? s:g('eol_marker') : ''
		endif
		call delimitMate#AddToBuffer(a:char . sufix)
		call delimitMate#WriteAfter(a:char . sufix)
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

function! delimitMate#JumpAny(...) " {{{
	if delimitMate#IsForbidden('')
		return ''
	endif
	if !delimitMate#ShouldJump()
		return ''
	endif
	" Let's get the character on the right.
	let char = delimitMate#GetCharFromCursor(0)
	if char == " "
		" Space expansion.
		return char . getline('.')[col('.')] . delimitMate#Del() .
					\ delimitMate#Del()
		"call delimitMate#RmBuffer(1)
	elseif char == ""
		" CR expansion.
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
		if index(s:g('quotes_list'), char) >= 0 ||
					\ index(s:g('right_delims'), char) >= 0
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

		" Not sure why I used the previous combos, but I'm sure somebody will
		" tell me about it.
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
	let escaped = delimitMate#CursorIdx() >= 2
				\ && delimitMate#GetCharFromCursor(-2) == '\'
	if delimitMate#WithinEmptyPair() && !escaped
		" Expand:
		call delimitMate#AddToBuffer('s')
		return delimitMate#WriteAfter(' ') . "\<Space>"
	else
		return "\<Space>"
	endif
endfunction "}}}

function! delimitMate#BS() " {{{
	let buffer_tail = get(s:g('buffer'), '-1', '')
	if delimitMate#IsForbidden("")
		let extra = ''
	elseif &backspace !~ 'start\|2' && empty(s:g('buffer'))
		let extra = ''
	elseif delimitMate#WithinEmptyPair()
		let extra = delimitMate#Del()
	elseif delimitMate#IsSpaceExpansion()
		let extra = delimitMate#Del()
	elseif delimitMate#IsCRExpansion()
		let extra = repeat("\<Del>",
					\ len(matchstr(getline(line('.') + 1), '^\s*\S')))
	else
		let extra = ''
	endif
	let tail_re = '\m\C\%('
				\ . join(s:g('right_delims')+s:g('quotes_list'), '\|')
				\ . '\)'
				\ . escape(s:g('eol_marker'), '\*.^$')
				\ . '$'
	if buffer_tail =~ tail_re && search('\%#'.tail_re, 'cWn')
		let extra .= join(map(split(s:g('eol_marker'), '\zs'),
					\ 'delimitMate#Del()'), '')
	endif
	return "\<BS>" . extra
endfunction " }}} delimitMate#BS()

function! delimitMate#Del() " {{{
	if len(s:g('buffer')) > 0
		call delimitMate#RmBuffer(1)
		return "\<Del>"
	else
		return "\<Del>"
	endif
endfunction " }}}

function! delimitMate#Finish(move_back) " {{{
	let len = len(s:g('buffer'))
	if len > 0
		let buffer = join(s:g('buffer'), '')
		let len2 = len(buffer)
		" Reset buffer:
		call s:s('buffer', [])
		let line = getline('.')
		let col = col('.') -2
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
	echom 1
	%d
	let options = sort(keys(delimitMate#OptionsList()))
	let optoutput = ['delimitMate Report', '==================', '',
				\ '* Options: ( ) default, (g) global, (b) buffer','']
	for option in options
		let scope = s:exists(option, 'b') ? 'b'
					\ : s:exists(option, 'g') ? 'g' : ' '
		call add(optoutput, '(' . scope . ')' . ' delimitMate_' . option . ' = ' . string(s:g(option)))
	endfor
	call append(line('$'), optoutput + ['--------------------',''])

	" Check if mappings were set. {{{
	let imaps = s:g('right_delims')
	let imaps += ( s:g('autoclose') ? s:g('left_delims') : [] )
	let imaps +=
				\ s:g('quotes_list') +
				\ s:g('apostrophes_list') +
				\ ['<BS>', '<S-BS>', '<Del>', '<S-Tab>', '<Esc>'] +
				\ ['<Up>', '<Down>', '<Left>', '<Right>', '<LeftMouse>',
				\ '<RightMouse>'] +
				\ ['<Home>', '<End>', '<PageUp>', '<PageDown>', '<S-Down>',
				\ '<S-Up>', '<C-G>g'] +
				\ ['<ScrollWheelUp>', '<S-ScrollWheelUp>', '<C-ScrollWheelUp>'] +
				\ ['<ScrollWheelDown>', '<S-ScrollWheelDown>',
				\ '<C-ScrollWheelDown>'] +
				\ ['<ScrollWheelLeft>', '<S-ScrollWheelLeft>',
				\ '<C-ScrollWheelLeft>'] +
				\ ['<ScrollWheelRight>', '<S-ScrollWheelRight>',
				\ '<C-ScrollWheelRight>']
	let imaps += ( s:g('expand_cr') ?  ['<CR>'] : [] )
	let imaps += ( s:g('expand_space') ?  ['<Space>'] : [] )

	let imappings = []
	for map in imaps
		let output = ''
		if map == '|'
			let map = '<Bar>'
		endif
		redir => output | execute "verbose imap ".map | redir END
		let imappings += split(output, '\n')
	endfor

	unlet! output
	let output = ['* Mappings:', ''] + imappings + ['--------------------', '']
	call append('$', output+['* Showcase:', ''])
	" }}}
	if s:g('autoclose')
		" {{{
		for i in range(len(s:g('left_delims')))
			exec "normal Go0\<C-D>Open: " . s:g('left_delims')[i]. "|"
			exec "normal o0\<C-D>Delete: " . s:g('left_delims')[i] . "\<BS>|"
			exec "normal o0\<C-D>Exit: " . s:g('left_delims')[i] . s:g('right_delims')[i] . "|"
			if s:g('expand_space') == 1
				exec "normal o0\<C-D>Space: " . s:g('left_delims')[i] . " |"
				exec "normal o0\<C-D>Delete space: " . s:g('left_delims')[i]
							\ . " \<BS>|"
			endif
			if s:g('expand_cr') == 1
				exec "normal o0\<C-D>Car return: " . s:g('left_delims')[i] .
							\ "\<CR>|"
				exec "normal Go0\<C-D>Delete car return: " . s:g('left_delims')[i]
							\ . "\<CR>0\<C-D>\<BS>|"
			endif
			call append(line('$'), '')
		endfor
		for i in range(len(s:g('quotes_list')))
			exec "normal Go0\<C-D>Open: " . s:g('quotes_list')[i]	. "|"
			exec "normal o0\<C-D>Delete: " . s:g('quotes_list')[i] . "\<BS>|"
			exec "normal o0\<C-D>Exit: " . s:g('quotes_list')[i] . s:g('quotes_list')[i] . "|"
			if s:g('expand_space') == 1
				exec "normal o0\<C-D>Space: " . s:g('quotes_list')[i] . " |"
				exec "normal o0\<C-D>Delete space: " . s:g('quotes_list')[i]
							\ . " \<BS>|"
			endif
			if s:g('expand_cr') == 1
				exec "normal o0\<C-D>Car return: " . s:g('quotes_list')[i]
							\ . "\<CR>|"
				exec "normal Go0\<C-D>Delete car return: " . s:g('quotes_list')[i]
							\ . "\<CR>\<BS>|"
			endif
			call append(line('$'), '')
		endfor
		"}}}
	else
		"{{{
		for i in range(len(s:g('left_delims')))
			exec "normal GoOpen & close: " . s:g('left_delims')[i]
						\ . s:g('right_delims')[i] . "|"
			exec "normal oDelete: " . s:g('left_delims')[i]
						\ . s:g('right_delims')[i] . "\<BS>|"
			exec "normal oExit: " . s:g('left_delims')[i] . s:g('right_delims')[i]
						\ . s:g('right_delims')[i] . "|"
			if s:g('expand_space') == 1
				exec "normal oSpace: " . s:g('left_delims')[i]
							\ . s:g('right_delims')[i] . " |"
				exec "normal oDelete space: " . s:g('left_delims')[i]
							\ . s:g('right_delims')[i] . " \<BS>|"
			endif
			if s:g('expand_cr') == 1
				exec "normal oCar return: " . s:g('left_delims')[i]
							\ . s:g('right_delims')[i] . "\<CR>|"
				exec "normal GoDelete car return: " . s:g('left_delims')[i]
							\ . s:g('right_delims')[i] . "\<CR>\<BS>|"
			endif
			call append(line('$'), '')
		endfor
		for i in range(len(s:g('quotes_list')))
			exec "normal GoOpen & close: " . s:g('quotes_list')[i]
						\ . s:g('quotes_list')[i] . "|"
			exec "normal oDelete: " . s:g('quotes_list')[i]
						\ . s:g('quotes_list')[i] . "\<BS>|"
			exec "normal oExit: " . s:g('quotes_list')[i] . s:g('quotes_list')[i]
						\ . s:g('quotes_list')[i] . "|"
			if s:g('expand_space') == 1
				exec "normal oSpace: " . s:g('quotes_list')[i]
							\ . s:g('quotes_list')[i] . " |"
				exec "normal oDelete space: " . s:g('quotes_list')[i]
							\ . s:g('quotes_list')[i] . " \<BS>|"
			endif
			if s:g('expand_cr') == 1
				exec "normal oCar return: " . s:g('quotes_list')[i]
							\ . s:g('quotes_list')[i] . "\<CR>|"
				exec "normal GoDelete car return: " . s:g('quotes_list')[i]
							\ . s:g('quotes_list')[i] . "\<CR>\<BS>|"
			endif
			call append(line('$'), '')
		endfor
	endif "}}}
	redir => setoptions | set | filetype | version | redir END
	call append(line('$'), split(setoptions,"\n")
				\ + ['--------------------'])
	setlocal nowrap
	call feedkeys("\<Esc>\<Esc>", 'n')
endfunction "}}}

function! delimitMate#OptionsList() "{{{
	return {
				\ 'apostrophes'        : '',
				\ 'autoclose'          : 1,
				\ 'balance_matchpairs' : 0,
				\ 'jump_expansion'     : 0,
				\ 'eol_marker'         : '',
				\ 'excluded_ft'        : '',
				\ 'excluded_regions'   : 'Comment',
				\ 'expand_cr'          : 0,
				\ 'expand_space'       : 0,
				\ 'matchpairs'         : &matchpairs,
				\ 'nesting_quotes'     : [],
				\ 'quotes'             : '" '' `',
				\ 'smart_matchpairs'   : '\w',
				\ 'smart_quotes'       : 1,
				\}
endfunction " delimitMate#OptionsList }}}
"}}}

" vim:foldmethod=marker:foldcolumn=4:ts=2:sw=2
