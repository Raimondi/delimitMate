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
		if s:ValidMatchpairs(&matchpairs) == 1
			let s:matchpairs_temp = &matchpairs
		else
			echoerr "delimitMate: There seems to be a problem with 'matchpairs', read ':help matchpairs' and fix it or notify the maintainer of this script if this is a bug."
			finish
		endif
	elseif exists("b:delimitMate_matchpairs")
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
	else
		if s:ValidMatchpairs(g:delimitMate_matchpairs) || g:delimitMate_matchpairs == ""
			let s:matchpairs_temp = g:delimitMate_matchpairs
		else
			echoerr "delimitMate: Invalid format in 'g:delimitMate_matchpairs', falling back to matchpairs. Fix the error and use the command :DelimitMateReload to try again."
			if s:ValidMatchpairs(&matchpairs) == 1
				let s:matchpairs_temp = &matchpairs
			else
				echoerr "delimitMate: There seems to be a problem with 'matchpairs', read ':help matchpairs' and fix it or notify the maintainer of this script if this is a bug."
				let s:matchpairs_temp = ""
			endif
		endif

	endif " }}}

	" delimitMate_quotes {{{
	if exists("b:delimitMate_quotes")
		if b:delimitMate_quotes =~ '^\(\S\)\(\s\S\)*$' || b:delimitMate_quotes == ""
			let s:quotes = split(b:delimitMate_quotes)
		else
			let s:quotes = split("\" ' `")
			echoerr "delimitMate: There is a problem with the format of 'b:delimitMate_quotes', it should be a string of single characters separated by spaces. Falling back to default values."
		endif
	elseif exists("g:delimitMate_quotes")
		if g:delimitMate_quotes =~ '^\(\S\)\(\s\S\)*$' || g:delimitMate_quotes == ""
			let s:quotes = split(g:delimitMate_quotes)
		else
			let s:quotes = split("\" ' `")
			echoerr "delimitMate: There is a problem with the format of 'g:delimitMate_quotes', it should be a string of single characters separated by spaces. Falling back to default values."
		endif
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
	let s:VMapMsg = "delimitMate: delimitMate is disabled on blockwise visual mode."

	call s:UnMap()
	if b:delimitMate_autoclose
		call s:AutoClose()
	else
		call s:NoAutoClose()
	endif
	call s:VisualMaps()
	call s:ExtraMappings()

endfunction "}}} Init()
"}}}

" Utilities: {{{
function! s:ValidMatchpairs(str) "{{{
	if a:str !~ '^.:.\(,.:.\)*$'
		return 0
	endif
	for pair in split(a:str,',')
		if strpart(pair, 0, 1) == strpart(pair, 2, 1) || strlen(pair) != 3
			return 0
		endif
	endfor
	return 1
endfunction "}}}

function! DelimitMate_ShouldJump() "{{{
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

function! s:IsBlockVisual() " {{{
	if visualmode() == "<C-V>"
		return 1
	endif
	" Store unnamed register values for later use in s:RestoreRegister().
	let s:save_reg = getreg('"')
	let s:save_reg_mode = getregtype('"')

	if len(getline('.')) == 0
		" This for proper wrap of empty lines.
		let @" = "\n"
	endif
	return 0
endfunction " }}}

function! s:IsEmptyPair(str) "{{{
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

function! s:IsCRExpansion() " {{{
	let nchar = getline(line('.')-1)[-1:]
	let schar = getline(line('.')+1)[-1:]
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
endfunction " }}} s:IsCRExpansion()

function! s:IsSpaceExpansion() " {{{
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

function! DelimitMate_WithinEmptyPair() "{{{
	let cur = strpart( getline('.'), col('.')-2, 2 )
	return s:IsEmptyPair( cur )
endfunction "}}}

function! s:WriteBefore(str) "{{{
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

function! s:WriteAfter(str) "{{{
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

function! s:RestoreRegister() " {{{
	" Restore unnamed register values store in s:IsBlockVisual().
	call setreg('"', s:save_reg, s:save_reg_mode)
	echo ""
endfunction " }}}

function! s:GetCurrentSyntaxRegion() "{{{
    return synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
endfunction " }}}

function! s:GetCurrentSyntaxRegionIf(char) "{{{
	let col = col('.')
    let origin_line = getline('.')
    let changed_line = strpart(origin_line, 0, col - 1) . a:char . strpart(origin_line, col - 1)
    call setline('.', changed_line)
    let region = synIDattr(synIDtrans(synID(line('.'), col, 1)), 'name')
    call setline('.', origin_line)
    return region
endfunction "}}}

function! s:IsForbidden(char) "{{{
    let result = index(b:delimitMate_excluded_regions_list, s:GetCurrentSyntaxRegion()) >= 0
	if result
		return result
	endif
	let region = s:GetCurrentSyntaxRegionIf(a:char)
	let result = index(b:delimitMate_excluded_regions_list, region) >= 0
	"return result || region == 'Comment'
	return result
endfunction "}}}

" }}}

" Doers: {{{
function! s:JumpIn(char) " {{{
	if s:IsForbidden(b:delimitMate_left_delims[index(b:delimitMate_right_delims, a:char)])
		echom 1
		return a:char
	endif
	call s:WriteAfter(b:delimitMate_right_delims[index(b:delimitMate_left_delims, a:char)])
	return a:char
endfunction " }}}

function! s:JumpOut(char) "{{{
	if s:IsForbidden(a:char)
		return a:char
	endif
	let line = getline('.')
	let col = col('.') - 2
	if line[col + 1] == a:char
		return a:char . "\<Del>"
	endif
	return a:char
endfunction " }}}

function! DelimitMate_JumpAny() " {{{
	" Let's get the character on the right.
	let char = getline('.')[col('.')-1]
	if char == " "
		" Space expansion.
		let char = char . getline('.')[col('.')] . "\<Del>"
	elseif char == ""
		" CR expansion.
		let char = "\<CR>" . getline(line('.') + 1)[0] . "\<Del>"
	endif
	return char . "\<Del>"
endfunction " DelimitMate_JumpAny() }}}

function! s:SkipDelim(char) "{{{
	if s:IsForbidden(a:char)
		return a:char
	endif
	let cur = strpart( getline('.'), col('.')-2, 3 )
	if cur[0] == "\\"
		" Escaped character
		return a:char
	elseif cur[1] == a:char
		" Exit pair
		return s:WriteBefore(a:char)
	"elseif cur[1] == ' ' && cur[2] == a:char
		"" I'm leaving this in case someone likes it. Jump an space and delimiter.
		"return "\<Right>\<Right>"
	elseif s:IsEmptyPair( cur[0] . a:char )
		" Add closing delimiter and jump back to the middle.
		return s:WriteAfter(a:char)
	else
		" Nothing special here, return the same character.
		return a:char
	endif
endfunction "}}}

function! s:QuoteDelim(char) "{{{
	if s:IsForbidden(a:char)
		return a:char
	endif
	let line = getline('.')
	let col = col('.') - 2
	if line[col] == "\\"
		" Seems like a escaped character, insert one quotation mark.
		return a:char
	elseif line[col + 1] == a:char
		" Get out of the string.
		return s:WriteBefore(a:char)
	elseif (line[col] =~ '[a-zA-Z0-9]' && a:char == "'") ||
				\(line[col] =~ '[a-zA-Z0-9]' && b:delimitMate_smart_quotes)
		" Seems like an apostrophe or a closing, insert a single quote.
		return a:char
	elseif (line[col] == a:char && line[col + 1 ] != a:char) && b:delimitMate_smart_quotes
		" Seems like we have an unbalanced quote, insert one quotation mark and jump to the middle.
		return s:WriteAfter(a:char)
	else
		" Insert a pair and jump to the middle.
		call s:WriteAfter(a:char)
		return a:char
	endif
endfunction "}}}

function! s:MapMsg(msg) "{{{
	redraw
	echomsg a:msg
	return ""
endfunction "}}}

function! DelimitMate_ExpandReturn() "{{{
	if DelimitMate_WithinEmptyPair() &&
				\ b:delimitMate_expand_cr &&
				\ s:IsForbidden('') == 0
		" Expand:
		return "\<Esc>a\<CR>x\<CR>\<Esc>k$\"_xa"
	else
		return "\<CR>"
	endif
endfunction "}}}

function! DelimitMate_ExpandSpace() "{{{
	if DelimitMate_WithinEmptyPair() &&
				\ b:delimitMate_expand_space &&
				\ s:IsForbidden('') == 0
		" Expand:
		return s:WriteAfter(' ') . "\<Space>"
	else
		return "\<Space>"
	endif
endfunction "}}}

function! DelimitMate_BS() " {{{
	let IsF = s:IsForbidden('')
	if DelimitMate_WithinEmptyPair() && IsF == 0
		return "\<Right>\<BS>\<BS>" 
	elseif b:delimitMate_expand_cr &&
				\ IsF == 0 &&
				\ (<SID>IsCRExpansion() != 0 || <SID>IsSpaceExpansion())
	   return "\<BS>\<Del>"
   else
	   return "\<BS>"
   endif
endfunction " }}} DelimitMate_BS()

"}}}

" Mappings: {{{
function! s:NoAutoClose() "{{{
	" inoremap <buffer> ) <C-R>=<SID>SkipDelim('\)')<CR>
	for delim in b:delimitMate_right_delims + b:delimitMate_quotes_list
		exec 'inoremap <buffer> ' . delim . ' <C-R>=<SID>SkipDelim("' . escape(delim,'"') . '")<CR>'
	endfor
endfunction "}}}

function! s:AutoClose() "{{{
	" Add matching pair and jump to the midle:
	" inoremap <buffer> ( ()<Left>
	let i = 0
	while i < len(b:delimitMate_matchpairs_list)
		let ld = b:delimitMate_left_delims[i]
		let rd = b:delimitMate_right_delims[i]
		"exec 'inoremap <buffer> ' . ld . ' ' . ld . '<C-R>=<SID>JumpIn("' . rd . '")<CR>'
		exec 'inoremap <buffer> ' . ld . ' ' '<C-R>=<SID>JumpIn("' . ld . '")<CR>'
		let i += 1
	endwhile

	" Exit from inside the matching pair:
	for delim in b:delimitMate_right_delims
		exec 'inoremap <buffer> ' . delim . ' <C-R>=<SID>JumpOut("\' . delim . '")<CR>'
	endfor

	" Add matching quote and jump to the midle, or exit if inside a pair of matching quotes:
	" inoremap <buffer> " <C-R>=<SID>QuoteDelim("\"")<CR>
	for delim in b:delimitMate_quotes_list
		exec 'inoremap <buffer> ' . delim . ' <C-R>=<SID>QuoteDelim("\' . delim . '")<CR>'
	endfor

	" Try to fix the use of apostrophes (de-activated by default):
	" inoremap <buffer> n't n't
	for map in b:delimitMate_apostrophes_list
		exec "inoremap <buffer> " . map . " " . map
	endfor

endfunction "}}}

function! s:VisualMaps() " {{{
	let vleader = b:delimitMate_visual_leader
	" Wrap the selection with matching pairs, but do nothing if blockwise visual mode is active:
	let i = 0
	while i < len(b:delimitMate_matchpairs_list)
		" Map left delimiter:
		let ld = b:delimitMate_left_delims[i]
		let rd = b:delimitMate_right_delims[i]
		exec 'vnoremap <buffer> <expr> ' . vleader . ld . ' <SID>IsBlockVisual() ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . ld . '\<C-R>\"' . rd . '\<Esc>:call <SID>RestoreRegister()<CR>"'

		" Map right delimiter:
		exec 'vnoremap <buffer> <expr> ' . vleader . rd . ' <SID>IsBlockVisual() ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . ld . '\<C-R>\"' . rd . '\<Esc>:call <SID>RestoreRegister()<CR>"'
		let i += 1
	endwhile

	" Wrap the selection with matching quotes, but do nothing if blockwise visual mode is active:
	for quote in b:delimitMate_quotes_list
		" vnoremap <buffer> <expr> \' <SID>IsBlockVisual() ? <SID>MapMsg("Message") : "s'\<C-R>\"'\<Esc>:call <SID>RestoreRegister()<CR>"
		exec 'vnoremap <buffer> <expr> ' . vleader . quote . ' <SID>IsBlockVisual() ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . escape(quote,'"') .'\<C-R>\"' . escape(quote,'"') . '\<Esc>:call <SID>RestoreRegister()<CR>"'
	endfor
endfunction "}}}

function! s:ExtraMappings() "{{{
	" If pair is empty, delete both delimiters:
	inoremap <buffer> <BS> <C-R>=DelimitMate_BS()<CR>

	" If pair is empty, delete closing delimiter:
	inoremap <buffer> <expr> <S-BS> DelimitMate_WithinEmptyPair() ? "\<Del>" : "\<S-BS>"

	" Expand return if inside an empty pair:
	if b:delimitMate_expand_cr != 0
		inoremap <buffer> <CR> <C-R>=DelimitMate_ExpandReturn()<CR>
	endif

	" Expand space if inside an empty pair:
	if b:delimitMate_expand_space != 0
		inoremap <buffer> <Space> <C-R>=DelimitMate_ExpandSpace()<CR>
	endif

	" Jump out ot any empty pair:
	if b:delimitMate_tab2exit
		inoremap <buffer> <expr> <S-Tab> DelimitMate_ShouldJump() ? DelimitMate_JumpAny() : "\<S-Tab>"
	endif
endfunction "}}}
"}}}

" Tools: {{{
function! s:TestMappings() "{{{
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
	"DelimitMateReload
	if !exists("g:delimitMate_testing")
		"call s:DelimitMateDo()
		call s:TestMappings()
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
				call s:TestMappings()
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
