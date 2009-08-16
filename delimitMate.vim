" delimitMate
"
" Credit:{{{1
"
" This script relies on code from the following places:
"
" - Ian McCracken
" http://concisionandconcinnity.blogspot.com/2009/07/vim-part-ii-matching-pairs.html
"
" - Aristotle Pagaltzis
" http://concisionandconcinnity.blogspot.com/2009/07/vim-part-ii-matching-pairs.html#comment-6278381178877777788
" http://gist.github.com/144619
"
" - Orestis Markou
" http://www.vim.org/scripts/script.php?script_id=2339
"
" Introduction:{{{1
"
" This script emulates the auto-complete matching pairs feature of TextMate
" and the behaviour is easily customizable through the use of variables. There
" is an option to prevent the closing delimiter from being automatically
" inserted, in this case the cursor is placed in the middle when the closing
" delimiter is typed, so you get the following behaviours (the cursor = |):
"
" With auto-complete:
"                     After typing "(|", you get "(|)"
"
" Without auto-complete:
"                     After typing "()|", you get "(|)"
"
" If visual mode is active and you type a delimiter, the selection will be
" enclosed in matching delimiters. This feature doesn't currently work on
" blockwise visual mode, any sugestion will be welcome.
"
" Options:{{{1
"
" - Auto-close
" If the variable 'b:delimitMate_autoclose' exists, a value of 1 will activate
" the auto-close feature, 0 will disable it.
"
" let b:delimitMate_autocomplete = 0
"
" - Matching pairs
" This script will use the delimiters found in the option 'matchpairs' and the
" quotes ", ' and `.
" If the variable 'b:delimitMate_paired_delims' exists, it takes precedence
" over 'matchpairs', so matchpairs values are ignored. Also, keep in mind that
" 'b:delimitMate_paired_delims' content has to follow 'matchpairs' syntax.
" 'b:delimitMate_quote_delims' is used to set the quotes.
"
" autocmd Syntax html,vim set matchpairs+=<:>
"
" let b:delimitMate_paired_delimits = "(:),[:]"
"
" let b:delimitMate_quote_delims = "\",',`,*"
"
" - Leader
" Since () and [] are used in visual mode to modify the selection, this script
" uses a leader when the mentioned mode is active. The default value for the
" leader is the letter q. You can modify this leader using the variable
" 'b:delimitMate_visual_leader'. e.g.: q( would wrap the selection between
" parenthesis.
"
" let b:delimitMate_visual_leader = "f"
"
" - Expansions
" The behaviour of <CR> and <Space> can be modified when typed inside an empty
" pair of delimiters, set the mappings you want to use in the variable
" 'b:delimitMate_car_return' and/or 'b:delimitMate_space'.
"
" let b:delimitMate_expand_return = '<CR><CR><Up>'
"
" let b:delimitMate_expand_space = '<Space><Space><Left>'

" Init:{{{1
if exists("b:loaded_delimitMate")
	"	finish
endif
if v:version < 700
	echoerr "delimitMate: this plugin requires vim >= 7!"
	finish
endif
let b:loaded_delimitMate = 1

" Functions:

" Don't define the functions if they already exist:
if !exists("*s:Init")
" Set user preferences:{{{1
	function! s:Init()
		" Should auto-complete delimiters?
		if !exists("b:delimitMate_autocomplete")
			let s:autocomplete = 1
		else
			let s:autocomplete = b:delimitMate_autocomplete
		endif

		" Override matchpairs?
		if !exists("b:delimitMate_paired_delims")
			let s:paired_delims_temp = &matchpairs
		else
			let s:i = 1
			for pair in (split(&matchpairs,','))
				if strpart(pair, 0, 1) == strpart(pair, -1, 1)
					let s:i = 0
					break
				endif
			endfor

			if (s:i && b:delimitMate_paired_delims =~ '^\(.:.\)\+\(,.:.\)*$') || b:delimitMate_paired_delims == ""
				let s:paired_delims_temp = b:delimitMate_paired_delims
			else
				let s:paired_delims_temp = &matchpairs
				echoerr "Invalid format in b:delimitMate_paired_delims, falling back to matchpairs."
				echoerr "Fix the error and use the command :DelimitMateReload to try again."
			endif
		endif

		" Define your own quoting delimiters?
		if !exists("b:delimitMate_quote_delims")
			let s:quote_delims = split("\" ' `")
		else
			let s:quote_delims = b:delimitMate_quote_delims
		endif

		" Leader for visual mode:
		if !exists("b:delimitMate_visual_leader")
			let s:visual_leader = "q"
		else
			let s:visual_leader = b:delimitMate_visual_leader
		endif

		" Should space be expanded?
		"if exists("b:delimitMate_expand_all")
			"let s:expand_space = b:delimitMate_expand_all
		"elseif exists("b:delimitMate_expand_space")
			"let s:expand_space = b:delimitMate_expand_space
		"else
			"let s:expand_space = 1
		"endif
		if !exists("b:delimitMate_expand_space")
			let s:expand_space = '<Space>'
		elseif b:delimitMate_expand_space == ""
			let s:expand_space = '<Space>'
		else
			let s:expand_space = b:delimitMate_expand_space
		endif

		" Should return be expanded?
		"if exists("b:delimitMate_expand_all")
			"let s:expand_return = b:delimitMate_expand_all
		"elseif exists("b:delimitMate_expand_return")
			"let s:expand_return = b:delimitMate_expand_return
		"else
			"let s:expand_return = 1
		"endif
		if !exists("b:delimitMate_expand_return")
			let s:expand_return = '<CR>'
		elseif b:delimitMate_expand_return == ""
			let s:expand_return = '<CR>'
		else
			let s:expand_return = b:delimitMate_expand_return
		endif


		let s:paired_delims = split(s:paired_delims_temp, ',')
		let s:left_delims = split(s:paired_delims_temp, ':.,\=')
		let s:right_delims = split(s:paired_delims_temp, ',\=.:')
		let s:VMapMsg = "delimitMate is disabled on blockwise visual mode."
	endfunction

	function! s:IsEmptyPair(str) "{{{2
		for pair in s:paired_delims
			if a:str == join( split( pair, ':' ),'' )
				return 1
			endif
		endfor
		for quote in s:quote_delims
			if a:str == quote . quote
				return 1
			endif
		endfor
		return 0
	endfunc

	function! s:WithinEmptyPair() "{{{2
		let cur = strpart( getline('.'), col('.')-2, 2 )
		return IsEmptyPair( cur )
	endfunc

	function! s:SkipDelim(char) "{{{2
		let cur = strpart( getline('.'), col('.')-2, 3 )
		if cur[0] == "\\"
			return a:char
		elseif cur[1] == a:char
			return "\<Right>"
		elseif cur[1] == ' ' && cur[2] == a:char
			return "\<Right>\<Right>"
		elseif IsEmptyPair( cur[0] . a:char )
			return a:char . "\<Left>"
		else
			return a:char
		endif
	endfunc

	function! s:QuoteDelim(char) "{{{2
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

	function! s:ClosePair(char) "{{{2
		if getline('.')[col('.') - 1] == a:char
			return "\<Right>"
		else
			return a:char
		endif
	endf

	function! s:ResetMappings() "{{{2
		for delim in s:right_delims + s:left_delims + s:quote_delims
			silent! exec 'iunmap <buffer> ' . delim
			silent! exec 'vunmap <buffer> ' . s:visual_leader . delim
		endfor
		silent! iunmap <buffer> <CR>
		silent! iunmap <buffer> <Space>
	endfunction

	function! s:MapMsg(msg) "{{{2
		redraw
		echomsg a:msg
		return ""
	endfunction


	" Don't auto-complete: {{{2
	function! s:NoAutoComplete()
		let test_string = "Don't"
		" imap <buffer> <expr> ) <SID>SkipDelim('\)')
		for delim in s:right_delims + s:quote_delims
			exec 'imap <buffer> <expr> ' . delim . ' <SID>SkipDelim("\' . delim . '")'
		endfor

		" Wrap the selection with delimiters, but do nothing if blockwise visual
		" mode is active:
		let s:i = 0
		while s:i < len(s:paired_delims)

			" vmap <buffer> <expr> q( visualmode() == "<C-V>" ? <SID>MapMsg(VMapMsg) : "s(\<C-R>\")\<Esc>"
			exec 'vmap <buffer> <expr> ' . s:visual_leader . s:left_delims[s:i] . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . s:left_delims[s:i] . '\<C-R>\"' . s:right_delims[s:i] . '\<Esc>"'

			" vmap <buffer> <expr> q) visualmode() == "<C-V>" ? <SID>MapMsg(VMapMsg) : "s(\<C-R>\")\<Esc>"
			exec 'vmap <buffer> <expr> ' . s:visual_leader . s:right_delims[s:i] . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . s:left_delims[s:i] . '\<C-R>\"' . s:right_delims[s:i] . '\<Esc>"'
			let s:i = s:i + 1
		endwhile

		for quote in s:quote_delims
			if quote == '"'
				" Ugly fix for double quotes:
				" vmap <buffer> <expr> q" visualmode() == "<C-V>" ? <SID>MapMsg(VMapMsg) : "s\"\<C-R>\"\"\<Esc>"
				exec 'vmap <buffer> <expr> ' . s:visual_leader . quote . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s\' . quote . '\<C-R>\"\' . quote . '\<Esc>"'
			else
				" vmap <buffer> <expr> q" visualmode() == "<C-V>" ? <SID>MapMsg(VMapMsg) : "s'\<C-R>\"'\<Esc>"
				exec 'vmap <buffer> <expr> ' . s:visual_leader . quote . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . quote . '\<C-R>\"' . quote . '\<Esc>"'
			endif
		endfor
	endfunction

	" Do auto-complete: {{{2
	function! s:AutoComplete()
		" Add matching pair and jump to the midle:
		" imap <buffer> ( ()<Left>
		let s:i = 0
		while s:i < len(s:paired_delims)
			exec 'imap <buffer> ' . s:left_delims[s:i] . ' ' . s:left_delims[s:i] . s:right_delims[s:i] . '<Left>'
			let s:i = s:i + 1
		endwhile

		" Add matching quote and jump to the midle, or exit if inside a pair of
		" matching quotes:
		" imap <buffer> " <c-r>=<SID>QuoteDelim("\"")<CR>
		let s:i = 0
		for delim in s:quote_delims
			exec 'imap <buffer> ' . delim . ' <c-r>=<SID>QuoteDelim("\' . delim . '")<CR>'
		endfor

		" Exit from inside the matching pair:
		" imap <buffer> ) <c-r>=<SID>ClosePair(')')<CR>
		for delim in s:right_delims
			exec 'imap <buffer> ' . delim . ' <c-r>=<SID>ClosePair("\' . delim . '")<CR>'
		endfor

		" Wrap the selection with matching pairs, but do nothing if blockwise visual
		" mode is active:
		let s:i = 0
		while s:i < len(s:paired_delims)
			" vmap <buffer> <expr> q( visualmode() == "<C-V>" ? <SID>MapMsg("Message") : "s(\<C-R>\"\<Esc>"
			exec 'vmap <buffer> <expr> ' . s:visual_leader . s:left_delims[s:i] . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . s:left_delims[s:i] . '\<C-R>\"\<Esc>"'

			" vmap <buffer> <expr> q) visualmode() == "<C-V>" ? <SID>MapMsg("Message") : "s(\<C-R>\""\<Esc>"
			exec 'vmap <buffer> <expr> ' . s:visual_leader . s:right_delims[s:i] . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . s:left_delims[s:i] . '\<C-R>\"\<Esc>"'
			let s:i = s:i + 1
		endwhile

		" Wrap the selection with matching quotes, but do nothing if blockwise visual
		" mode is active:
		for quote in s:quote_delims
			if quote == '"'
				" Ugly fix for double quotes:
				" vmap <buffer> <expr> q" visualmode() == "<C-V>" ? <SID>MapMsg("Message") : "s\"\<C-R>\"\<Esc>"
				exec 'vmap <buffer> <expr> ' . s:visual_leader . '" visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s\"\<C-R>\"\<Esc>"'
			else

				" vmap <buffer> <expr> q' visualmode() == "<C-V>" ? <SID>MapMsg("Message") : "s'\<C-R>\"'\<Esc>"
				exec 'vmap <buffer> <expr> ' . s:visual_leader . quote . ' visualmode() == "<C-V>" ? <SID>MapMsg("' . s:VMapMsg . '") : "s' . quote .'\<C-R>\"' . quote . '\<Esc>"'
			endif
		endfor
	endfunction

	" Expansions and Deletion: {{{2
	function! s:ExtraMappings()
		" If pair is empty, delete both delimiters:
		imap <buffer> <expr> <BS> <SID>WithinEmptyPair() ? "\<Right>\<BS>\<BS>" : "\<BS>"

		" Expand return if inside an empty pair:
		" imap <buffer> <expr> <CR> <SID>WithinEmptyPair() ? "\<CR>\<CR>\<Up>" : "\<CR>"
		exec 'imap <buffer> <expr> <CR> <SID>WithinEmptyPair() ? "' . escape(s:expand_return,'"<') .  '" : "<CR>"'
		echomsg s:expand_return

		" Expand space if inside an empty pair:
		" imap <buffer> <expr> <Space> <SID>WithinEmptyPair() ? "\<Space>\<Space>\<Left>" : "\<Space>"
		exec 'imap <buffer> <expr> <Space> <SID>WithinEmptyPair() ? "' . escape(s:expand_space,'"<') .  '" : "<Space>"'
		echomsg s:expand_space
	endfunction

	" Task list:
	function! s:DelimitMateDo()
		call s:Init()
		call s:ResetMappings()
		if s:autocomplete
			call s:AutoComplete()
		else
			call s:NoAutoComplete()
		endif
		call s:ExtraMappings()
	endfunction
endif "}}}1

" Do the real work:
call s:DelimitMateDo()

" Let me refresh without re-loading the buffer:
command! DelimitMateReload call s:DelimitMateDo()

" vim:foldmethod=marker:foldcolumn=4
