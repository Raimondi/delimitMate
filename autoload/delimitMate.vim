" ============================================================================
" File:        autoload/delimitMate.vim
" Version:     2.1
" Description: This plugin provides auto-completion for quotes, parens, etc.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
" Manual:      Read ":help delimitMate".

" Utilities {{{
function! delimitMate#ShouldJump() "{{{
	let col = col('.')
	let lcol = col('$')
	let char = getline('.')[col - 1]
	let nchar = getline('.')[col]
	let uchar = getline(line('.') + 1)[0]

	for cdel in b:delimitMate_right_delims + b:delimitMate_quotes_list
		if char == cdel
			" Closing delimiter on the right.
			return 1
		endif
	endfor

	if b:delimitMate_expand_space && char == " "
		for cdel in b:delimitMate_right_delims + b:delimitMate_quotes_list
			if nchar == cdel
				" Closing delimiter with space expansion.
				return 1
			endif
		endfor
	endif

	if b:delimitMate_expand_cr && char == ""
		for cdel in b:delimitMate_right_delims + b:delimitMate_quotes_list
			if uchar == cdel
				" Closing delimiter with CR expansion.
				return 1
			endif
		endfor
	endif

	return 0
endfunction "}}}

function! delimitMate#IsBlockVisual() " {{{
	if mode() == "\<C-V>"
		return 1
	endif
	" Store unnamed register values for later use in delimitMate#RestoreRegister().
	let b:save_reg = getreg('"')
	let b:save_reg_mode = getregtype('"')

	if len(getline('.')) == 0
		" This for proper wrap of empty lines.
		let @" = "\n"
	endif
	return 0
endfunction " }}}

function! delimitMate#Visual(del) " {{{
	let mode = mode()
	if mode == "\<C-V>"
		redraw
		echom "delimitMate: delimitMate is disabled on blockwise visual mode."
		return ""
	endif
	" Store unnamed register values for later use in delimitMate#RestoreRegister().
	let b:save_reg = getreg('"')
	let b:save_reg_mode = getregtype('"')

	if len(getline('.')) == 0
		" This for proper wrap of empty lines.
		let @" = "\n"
	endif

	if mode ==# "V"
		let dchar = "\<BS>"
	else
		let dchar = ""
	endif

	let index = index(b:delimitMate_left_delims, a:del)
	if index >= 0
		let ld = a:del
		let rd = b:delimitMate_right_delims[index]
	endif

	let index = index(b:delimitMate_right_delims, a:del)
	if index >= 0
		let ld = b:delimitMate_left_delims[index]
		let rd = a:del
	endif

	let index = index(b:delimitMate_quotes_list, a:del)
	if index >= 0
		let ld = a:del
		let rd = ld
	endif

	return "s" . ld . "\<C-R>\"" . dchar . rd . "\<Esc>:call delimitMate#RestoreRegister()\<CR>"
endfunction " }}}

function! delimitMate#IsEmptyPair(str) "{{{
	for pair in b:delimitMate_matchpairs_list
		if a:str == join( split( pair, ':' ),'' )
			return 1
		endif
	endfor
	for quote in b:delimitMate_quotes_list
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
	if index(b:delimitMate_left_delims, nchar) > -1 &&
				\ index(b:delimitMate_left_delims, nchar) == index(b:delimitMate_right_delims, schar) &&
				\ isEmpty
		return 1
	elseif index(b:delimitMate_quotes_list, nchar) > -1 &&
				\ index(b:delimitMate_quotes_list, nchar) == index(b:delimitMate_quotes_list, schar) &&
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

		if index(b:delimitMate_left_delims, pchar) > -1 &&
				\ index(b:delimitMate_left_delims, pchar) == index(b:delimitMate_right_delims, nchar) &&
				\ isSpaces
			return 1
		elseif index(b:delimitMate_quotes_list, pchar) > -1 &&
				\ index(b:delimitMate_quotes_list, pchar) == index(b:delimitMate_quotes_list, nchar) &&
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
	" Restore unnamed register values store in delimitMate#IsBlockVisual().
	call setreg('"', b:save_reg, b:save_reg_mode)
	echo ""
endfunction " }}}

function! delimitMate#GetCurrentSyntaxRegion() "{{{
	return synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
endfunction " }}}

function! delimitMate#GetCurrentSyntaxRegionIf(char) "{{{
	let col = col('.')
	let origin_line = getline('.')
	let changed_line = strpart(origin_line, 0, col - 1) . a:char . strpart(origin_line, col - 1)
	call setline('.', changed_line)
	let region = synIDattr(synIDtrans(synID(line('.'), col, 1)), 'name')
	call setline('.', origin_line)
	return region
endfunction "}}}

function! delimitMate#IsForbidden(char) "{{{
	if b:delimitMate_excluded_regions_enabled = 0
		return 0
	endif
	let result = index(b:delimitMate_excluded_regions_list, delimitMate#GetCurrentSyntaxRegion()) >= 0
	if result >= 0
		return result + 1
	endif
	let region = delimitMate#GetCurrentSyntaxRegionIf(a:char)
	let result = index(b:delimitMate_excluded_regions_list, region) >= 0
	"return result || region == 'Comment'
	return result + 1
endfunction "}}}

function! delimitMate#FlushBuffer() " {{{
	let b:delimitMate_buffer = []
	return ''
endfunction " }}}
" }}}

" Doers {{{
function! delimitMate#JumpIn(char) " {{{
	let line = getline('.')
	let col = col('.')-2
	if (col) < 0
		call setline('.',a:char.line)
		call insert(b:delimitMate_buffer, a:char)
	else
		"echom string(col).':'.line[:(col)].'|'.line[(col+1):]
		call setline('.',line[:(col)].a:char.line[(col+1):])
		call insert(b:delimitMate_buffer, a:char)
	endif
	return ''
endfunction " }}}

function! delimitMate#JumpOut(char) "{{{
	let line = getline('.')
	let col = col('.')-2
	if line[col+1] == a:char
		return a:char . delimitMate#Del()
	else
		return a:char
	endif
endfunction " }}}

function! delimitMate#JumpAny() " {{{
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
		let b:delimitMate_buffer = []
		return "\<CR>" . getline(line('.') + 1)[0] . "\<Del>"
	else
		"call delimitMate#RmBuffer(1)
		return char . delimitMate#Del()
	endif
endfunction " delimitMate#JumpAny() }}}

function! delimitMate#SkipDelim(char) "{{{
	let cur = strpart( getline('.'), col('.')-2, 3 )
	if cur[0] == "\\"
		" Escaped character
		return a:char
	elseif cur[1] == a:char
		" Exit pair
		"return delimitMate#WriteBefore(a:char)
		return a:char . delimitMate#Del()
	"elseif cur[1] == ' ' && cur[2] == a:char
		"" I'm leaving this in case someone likes it. Jump an space and delimiter.
		"return "\<Right>\<Right>"
	elseif delimitMate#IsEmptyPair( cur[0] . a:char )
		" Add closing delimiter and jump back to the middle.
		call insert(b:delimitMate_buffer, a:char)
		return delimitMate#WriteAfter(a:char)
	else
		" Nothing special here, return the same character.
		return a:char
	endif
endfunction "}}}

function! delimitMate#QuoteDelim(char) "{{{
	let line = getline('.')
	let col = col('.') - 2
	if line[col] == "\\"
		" Seems like a escaped character, insert one quotation mark.
		return a:char
	elseif line[col + 1] == a:char
		" Get out of the string.
		"return delimitMate#WriteBefore(a:char)
		return a:char . delimitMate#Del()
	elseif (line[col] =~ '[a-zA-Z0-9]' && a:char == "'") ||
				\(line[col] =~ '[a-zA-Z0-9]' && b:delimitMate_smart_quotes)
		" Seems like an apostrophe or a closing, insert a single quote.
		return a:char
	elseif (line[col] == a:char && line[col + 1 ] != a:char) && b:delimitMate_smart_quotes
		" Seems like we have an unbalanced quote, insert one quotation mark and jump to the middle.
		call insert(b:delimitMate_buffer, a:char)
		return delimitMate#WriteAfter(a:char)
	else
		" Insert a pair and jump to the middle.
		call insert(b:delimitMate_buffer, a:char)
		call delimitMate#WriteAfter(a:char)
		return a:char
	endif
endfunction "}}}

function! delimitMate#MapMsg(msg) "{{{
	redraw
	echomsg a:msg
	return ""
endfunction "}}}

function! delimitMate#ExpandReturn() "{{{
	if delimitMate#WithinEmptyPair() &&
				\ b:delimitMate_expand_cr
		" Expand:
		call delimitMate#FlushBuffer()
		return "\<Esc>a\<CR>x\<CR>\<Esc>k$\"_xa"
	else
		return "\<CR>"
	endif
endfunction "}}}

function! delimitMate#ExpandSpace() "{{{
	if delimitMate#WithinEmptyPair() &&
				\ b:delimitMate_expand_space
		" Expand:
		call insert(b:delimitMate_buffer, 's')
		return delimitMate#WriteAfter(' ') . "\<Space>"
	else
		return "\<Space>"
	endif
endfunction "}}}

function! delimitMate#BS() " {{{
	if delimitMate#WithinEmptyPair()
		"call delimitMate#RmBuffer(1)
		return "\<BS>" . delimitMate#Del()
"        return "\<Right>\<BS>\<BS>"
	elseif b:delimitMate_expand_space &&
				\ delimitMate#IsSpaceExpansion()
		"call delimitMate#RmBuffer(1)
		return "\<BS>" . delimitMate#Del()
	elseif b:delimitMate_expand_cr &&
				\ delimitMate#IsCRExpansion()
		return "\<BS>\<Del>"
	else
		return "\<BS>"
	endif
endfunction " }}} delimitMate#BS()

function! delimitMate#Del() " {{{
	if len(b:delimitMate_buffer) > 0
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
	let len = len(b:delimitMate_buffer)
	if len > 0
		let buffer = join(b:delimitMate_buffer, '')
		let line = getline('.')
		let col = col('.') -2
		"echom 'col: ' . col . '-' . line[:col] . "|" . line[col+len+1:] . '%' . buffer
		call setline('.', line[:col] . line[col+len+1:])
		let i = 1
		let lefts = ''
		while i < len
			let lefts = lefts . "\<Left>"
			let i += 1
		endwhile
		return substitute(buffer, "s", "\<Space>", 'g') . lefts
	endif
	return ''
endfunction " }}}

function! delimitMate#RmBuffer(num) " {{{
	if len(b:delimitMate_buffer) > 0
	   call remove(b:delimitMate_buffer, 0, (a:num-1))
	endif
	return ""
endfunction " }}}

" }}}

" Mappers: {{{
function! delimitMate#NoAutoClose() "{{{
	" inoremap <buffer> ) <C-R>=delimitMate#SkipDelim('\)')<CR>
	for delim in b:delimitMate_right_delims + b:delimitMate_quotes_list
		exec 'inoremap <buffer> ' . delim . ' <C-R>=delimitMate#SkipDelim("' . escape(delim,'"') . '")<CR>'
	endfor
endfunction "}}}

function! delimitMate#AutoClose() "{{{
	" Add matching pair and jump to the midle:
	" inoremap <buffer> ( ()<Left>
	let i = 0
	while i < len(b:delimitMate_matchpairs_list)
		let ld = b:delimitMate_left_delims[i]
		let rd = b:delimitMate_right_delims[i]
		exec 'inoremap <buffer> ' . ld . ' ' . ld . '<C-R>=delimitMate#JumpIn("' . rd . '")<CR>'
		let i += 1
	endwhile

	" Exit from inside the matching pair:
	for delim in b:delimitMate_right_delims
		exec 'inoremap <buffer> ' . delim . ' <C-R>=delimitMate#JumpOut("\' . delim . '")<CR>'
	endfor

	" Add matching quote and jump to the midle, or exit if inside a pair of matching quotes:
	" inoremap <buffer> " <C-R>=delimitMate#QuoteDelim("\"")<CR>
	for delim in b:delimitMate_quotes_list
		exec 'inoremap <buffer> ' . delim . ' <C-R>=delimitMate#QuoteDelim("\' . delim . '")<CR>'
	endfor

	" Try to fix the use of apostrophes (de-activated by default):
	" inoremap <buffer> n't n't
	for map in b:delimitMate_apostrophes_list
		exec "inoremap <buffer> " . map . " " . map
	endfor
endfunction "}}}

function! delimitMate#VisualMaps() " {{{
	let VMapMsg = "delimitMate: delimitMate is disabled on blockwise visual mode."
	let vleader = b:delimitMate_visual_leader
	" Wrap the selection with matching pairs, but do nothing if blockwise visual mode is active:
	for del in b:delimitMate_right_delims + b:delimitMate_left_delims + b:delimitMate_quotes_list
		exec "vnoremap <buffer> <expr> " . vleader . del . ' delimitMate#Visual("' . escape(del, '")') . '")'
	endfor
endfunction "}}}

function! delimitMate#ExtraMappings() "{{{
	" If pair is empty, delete both delimiters:
	inoremap <buffer> <BS> <C-R>=delimitMate#BS()<CR>

	" If pair is empty, delete closing delimiter:
	inoremap <buffer> <expr> <S-BS> delimitMate#WithinEmptyPair() ? "\<Del>" : "\<S-BS>"

	" Expand return if inside an empty pair:
	if b:delimitMate_expand_cr != 0
		inoremap <buffer> <expr> <CR> delimitMate#WithinEmptyPair() ? "\<C-R>=delimitMate#ExpandReturn()\<CR>" : "\<CR>"
	endif

	" Expand space if inside an empty pair:
	if b:delimitMate_expand_space != 0
		inoremap <buffer> <expr> <Space> delimitMate#WithinEmptyPair() ? "\<C-R>=delimitMate#ExpandSpace()\<CR>" : "\<Space>"
	endif

	" Jump out ot any empty pair:
	if b:delimitMate_tab2exit
		inoremap <buffer> <expr> <S-Tab> delimitMate#ShouldJump() ? "\<C-R>=delimitMate#JumpAny()\<CR>" : "\<S-Tab>"
	endif

	" Fix the re-do feature:
	inoremap <buffer> <Esc> <C-R>=delimitMate#Finish()<CR><Esc>

	" Flush the char buffer on mouse click:
	inoremap <buffer> <LeftMouse> <C-R>=delimitMate#Finish()<CR><LeftMouse>
	inoremap <buffer> <RightMouse> <C-R>=delimitMate#Finish()<CR><RightMouse>

	" Flush the char buffer on key movements:
	inoremap <buffer> <Left> <C-R>=delimitMate#Finish()<CR><Left>
	inoremap <buffer> <Right> <C-R>=delimitMate#Finish()<CR><Right>
	inoremap <buffer> <Up> <C-R>=delimitMate#Finish()<CR><Up>
	inoremap <buffer> <Down> <C-R>=delimitMate#Finish()<CR><Down>

	inoremap <buffer> <Del> <C-R>=delimitMate#Del()<CR>

endfunction "}}}

function! delimitMate#UnMap() " {{{
	let imaps =
				\ b:delimitMate_right_delims +
				\ b:delimitMate_left_delims +
				\ b:delimitMate_quotes_list +
				\ b:delimitMate_apostrophes_list +
				\ ['<BS>', '<S-BS>', '<Del>', '<CR>', '<Space>', '<S-Tab>', '<Esc>'] +
				\ ['<Up>', '<Down>', '<Left>', '<Right>', '<LeftMouse>', '<RightMouse>']

	let vmaps =
				\ b:delimitMate_right_delims +
				\ b:delimitMate_left_delims +
				\ b:delimitMate_quotes_list

	for map in imaps
		if maparg(map, "i") =~? 'delimitMate'
			exec 'silent! iunmap <buffer> ' . map
		endif
	endfor

	if !exists("b:delimitMate_visual_leader")
		let vleader = ""
	else
		let vleader = b:delimitMate_visual_leader
	endif
	for map in vmaps
		if maparg(vleader . map, "v") =~? "delimitMate"
			exec 'silent! vunmap <buffer> ' . vleader . map
		endif
	endfor
endfunction " }}} delimitMate#UnMap()

"}}}

" Tools: {{{
function! delimitMate#TestMappings() "{{{
	exec "normal i*b:delimitMate_autoclose = " . b:delimitMate_autoclose . "\<CR>"
	exec "normal i*b:delimitMate_expand_space = " . b:delimitMate_expand_space . "\<CR>"
	exec "normal i*b:delimitMate_expand_cr = " . b:delimitMate_expand_cr . "\<CR>\<CR>"

	if b:delimitMate_autoclose
		for i in range(len(b:delimitMate_left_delims))
			exec "normal GGAOpen & close: " . b:delimitMate_left_delims[i]. "|"
			exec "normal A\<CR>Delete: " . b:delimitMate_left_delims[i] . "\<BS>|"
			exec "normal A\<CR>Exit: " . b:delimitMate_left_delims[i] . b:delimitMate_right_delims[i] . "|"
			exec "normal A\<CR>Space: " . b:delimitMate_left_delims[i] . " |"
			exec "normal A\<CR>Delete space: " . b:delimitMate_left_delims[i] . " \<BS>|"
			exec "normal GGA\<CR>Visual-L: v\<Esc>v" . b:delimitMate_visual_leader . b:delimitMate_left_delims[i]
			exec "normal A\<CR>Visual-R: v\<Esc>v" . b:delimitMate_visual_leader . b:delimitMate_right_delims[i]
			exec "normal A\<CR>Car return: " . b:delimitMate_left_delims[i] . "\<CR>|"
			exec "normal GGA\<CR>Delete car return: " . b:delimitMate_left_delims[i] . "\<CR>\<BS>|\<Esc>GGA\<CR>\<CR>"
		endfor
		for i in range(len(b:delimitMate_quotes_list))
			exec "normal GGAOpen & close: " . b:delimitMate_quotes_list[i]	. "|"
			exec "normal A\<CR>Delete: "
			exec "normal A". b:delimitMate_quotes_list[i]
			exec "normal a\<BS>|"
			exec "normal A\<CR>Exit: " . b:delimitMate_quotes_list[i] . b:delimitMate_quotes_list[i] . "|"
			exec "normal A\<CR>Space: " . b:delimitMate_quotes_list[i] . " |"
			exec "normal A\<CR>Delete space: " . b:delimitMate_quotes_list[i] . " \<BS>|"
			exec "normal GGA\<CR>Visual: v\<Esc>v" . b:delimitMate_visual_leader . b:delimitMate_quotes_list[i]
			exec "normal A\<CR>Car return: " . b:delimitMate_quotes_list[i] . "\<CR>|"
			exec "normal GGA\<CR>Delete car return: " . b:delimitMate_quotes_list[i] . "\<CR>\<BS>|\<Esc>GGA\<CR>\<CR>"
		endfor
	else
		for i in range(len(b:delimitMate_left_delims))
			exec "normal GGAOpen & close: " . b:delimitMate_left_delims[i]	. b:delimitMate_right_delims[i] . "|"
			exec "normal A\<CR>Delete: " . b:delimitMate_left_delims[i] . b:delimitMate_right_delims[i] . "\<BS>|"
			exec "normal A\<CR>Exit: " . b:delimitMate_left_delims[i] . b:delimitMate_right_delims[i] . b:delimitMate_right_delims[i] . "|"
			exec "normal A\<CR>Space: " . b:delimitMate_left_delims[i] . b:delimitMate_right_delims[i] . " |"
			exec "normal A\<CR>Delete space: " . b:delimitMate_left_delims[i] . b:delimitMate_right_delims[i] . " \<BS>|"
			exec "normal GGA\<CR>Visual-L: v\<Esc>v" . b:delimitMate_visual_leader . b:delimitMate_left_delims[i]
			exec "normal A\<CR>Visual-R: v\<Esc>v" . b:delimitMate_visual_leader . b:delimitMate_right_delims[i]
			exec "normal A\<CR>Car return: " . b:delimitMate_left_delims[i] . b:delimitMate_right_delims[i] . "\<CR>|"
			exec "normal GGA\<CR>Delete car return: " . b:delimitMate_left_delims[i] . b:delimitMate_right_delims[i] . "\<CR>\<BS>|\<Esc>GGA\<CR>\<CR>"
		endfor
		for i in range(len(b:delimitMate_quotes_list))
			exec "normal GGAOpen & close: " . b:delimitMate_quotes_list[i]	. b:delimitMate_quotes_list[i] . "|"
			exec "normal A\<CR>Delete: " . b:delimitMate_quotes_list[i] . b:delimitMate_quotes_list[i] . "\<BS>|"
			exec "normal A\<CR>Exit: " . b:delimitMate_quotes_list[i] . b:delimitMate_quotes_list[i] . b:delimitMate_quotes_list[i] . "|"
			exec "normal A\<CR>Space: " . b:delimitMate_quotes_list[i] . b:delimitMate_quotes_list[i] . " |"
			exec "normal A\<CR>Delete space: " . b:delimitMate_quotes_list[i] . b:delimitMate_quotes_list[i] . " \<BS>|"
			exec "normal GGA\<CR>Visual: v\<Esc>v" . b:delimitMate_visual_leader . b:delimitMate_quotes_list[i]
			exec "normal A\<CR>Car return: " . b:delimitMate_quotes_list[i] . b:delimitMate_quotes_list[i] . "\<CR>|"
			exec "normal GGA\<CR>Delete car return: " . b:delimitMate_quotes_list[i] . b:delimitMate_quotes_list[i] . "\<CR>\<BS>|\<Esc>GGA\<CR>\<CR>"
		endfor
	endif
	exec "normal \<Esc>i"
endfunction "}}}

"}}}

" vim:foldmethod=marker:foldcolumn=4
