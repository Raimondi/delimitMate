" ============================================================================
" File:        autoload/delimitMate.vim
" Version:     2.3.1
" Modified:    2010-06-06
" Description: This plugin provides auto-completion for quotes, parens, etc.
" Maintainer:  Israel Chauca F. <israelchauca@gmail.com>
" Manual:      Read ":help delimitMate".

" Utilities {{{
function! delimitMate#Init() "{{{
" Initialize variables:

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

	let b:loaded_delimitMate = 1
	let b:delimitMate_enabled = 1
endfunction "}}} Init()

function! delimitMate#ShouldJump() "{{{
	" Returns 1 if the next character is a closing delimiter.
	let col = col('.')
	let lcol = col('$')
	let char = getline('.')[col - 1]

	for cdel in b:delimitMate_right_delims + b:delimitMate_quotes_list
		if char == cdel
			" Closing delimiter on the right.
			return 1
		endif
	endfor

	let nchar = getline('.')[col]
	if b:delimitMate_expand_space && char == " "
		for cdel in b:delimitMate_right_delims + b:delimitMate_quotes_list
			if nchar == cdel
				" Closing delimiter with space expansion.
				return 1
			endif
		endfor
	endif

	let uchar = getline(line('.') + 1)[0]
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
	if b:delimitMate_excluded_regions_enabled == 0
		return 0
	endif
	"let result = index(b:delimitMate_excluded_regions_list, delimitMate#GetCurrentSyntaxRegion()) >= 0
	if index(b:delimitMate_excluded_regions_list, delimitMate#GetCurrentSyntaxRegion()) >= 0
		"echom "Forbidden 1!"
		return 1
	endif
	let region = delimitMate#GetCurrentSyntaxRegionIf(a:char)
	"let result = index(b:delimitMate_excluded_regions_list, region) >= 0
	"return result || region == 'Comment'
	"echom "Forbidden 2!"
	return index(b:delimitMate_excluded_regions_list, region) >= 0
endfunction "}}}

function! delimitMate#FlushBuffer() " {{{
	let b:delimitMate_buffer = []
	return ''
endfunction " }}}
" }}}

" Doers {{{
function! delimitMate#JumpIn(char) " {{{
	if delimitMate#IsForbidden(a:char)
		return ''
	endif
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
		let b:delimitMate_buffer = []
		return "\<CR>" . getline(line('.') + 1)[0] . "\<Del>"
	else
		"call delimitMate#RmBuffer(1)
		return char . delimitMate#Del()
	endif
endfunction " delimitMate#JumpAny() }}}

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
		call insert(b:delimitMate_buffer, a:char)
		return delimitMate#WriteAfter(a:char)
	else
		" Nothing special here, return the same character.
		return a:char
	endif
endfunction "}}}

function! delimitMate#QuoteDelim(char) "{{{
	if delimitMate#IsForbidden(a:char)
		return a:char
	endif
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
		call insert(b:delimitMate_buffer, 's')
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
		" Reset buffer:
		let b:delimitMate_buffer = []
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
		exec 'inoremap <buffer> ' . delim . ' <C-R>=delimitMate#SkipDelim("' . escape(delim,'"\|') . '")<CR>'
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
	inoremap <buffer> <expr> <S-BS> delimitMate#WithinEmptyPair() && !delimitMate#IsForbidden("") ? "\<Del>" : "\<S-BS>"

	" Expand return if inside an empty pair:
	if b:delimitMate_expand_cr != 0
		inoremap <buffer> <CR> <C-R>=delimitMate#ExpandReturn()<CR>
	endif

	" Expand space if inside an empty pair:
	if b:delimitMate_expand_space != 0
		inoremap <buffer> <Space> <C-R>=delimitMate#ExpandSpace()<CR>
	endif

	" Jump out ot any empty pair:
	if b:delimitMate_tab2exit
		inoremap <buffer> <S-Tab> <C-R>=delimitMate#JumpAny("\<S-Tab>")<CR>
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

	"the following simply creates an ambiguous mapping so vim fully
	"processes the escape sequence for terminal keys, see 'ttimeout' for a
	"rough explanation, this just forces it to work
	if &term[:4] == "xterm"
		inoremap <silent> <C-[>OC <RIGHT>
	endif
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

	let b:delimitMate_enabled = 0
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
