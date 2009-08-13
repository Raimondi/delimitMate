" delimitMate
" Introduction:{{{1
"
" Main novelty here (if it is one): this does NOT try to be helpful by
" inserting the closing delimiter for you when you type an opening one.
" Instead it only tries to be smart about what to do when you type a closing
" delimiter yourself.
"
" If you just typed an empty delimiter pair, it'll move the cursor back
" inside. If you type a closing delimiter the cursor is already on (or to
" the left of, if the cursor is on a space), it'll skip the cursor past that
" delimiter without inserting it.
"
" That way you never end with superfluous delimiters to delete, which deletion
" itself can be tricky to perform, since the editor might be trying to be
" helpful about deletions as well. Instead, you only ever get delimiters you
" explicitly typed yourself.
"
" I had trained myself into the good habit of typing pairs together anyway.
" The only annoying part of that habit is the manual cursor placement work;
" but that work is quite predictable almost all of the time. That's exactly
" the sort of work that computers are for.

" Init:{{{1
if exists("loaded_delimitMate")
	"finish
endif
if v:version < 700
	echoerr "delimitMate: this plugin requires vim >= 7!"
	finish
endif
let loaded_delimitMate = 1

" Set user preferences:{{{2

" Should auto-complete delimiters?
if !exists("g:delimitMate_autocomplete")
	let s:autocomplete = 1
else
	let s:autocomplete = g:delimitMate_autocomplete
endif

" Override matchpairs?
if !exists("g:delimitMate_paired_delims")
	let s:paired_delims_temp = &matchpairs
else
	if g:delimitMate_paired_delims =~ '^\(.:\)\+\(,.:.\)*$'
		finish
	endif
	let s:paired_delims_temp = g:delimitMate_paired_delims
endif

" Define your own quoting delimiters?
if !exists("g:delimitMate_quote_delims")
	let s:quote_delims = split("\" ' `")
else
	let s:quote_delims = g:delimitMate_quote_delims
endif

" Leader for visual mode:
if !exists("g:delimitMate_leader")
	let s:leader = "q"
else
	let s:leader = g:delimitMate_leader
endif

" Should space be expanded?
if exists("g:delimitMate_expand_all")
	let s:expand_space = g:delimitMate_expand_all
elseif exists("g:delimitMate_expand_space")
	let s:expand_space = g:delimitMate_expand_space
else
	let s:expand_space = 1
endif

" Should return be expanded?
if exists("g:delimitMate_expand_all")
	let s:expand_return = g:delimitMate_expand_all
elseif exists("g:delimitMate_expand_return")
	let s:expand_return = g:delimitMate_expand_return
else
	let s:expand_return = 1
endif

let s:paired_delims = split(s:paired_delims_temp, ',')
let s:left_delims = split(s:paired_delims_temp, ':.,\=')
let s:right_delims = split(s:paired_delims_temp, ',\=.:')

" Functions:{{{1

function! s:IsEmptyPair(str)
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

function! s:WithinEmptyPair()
	let cur = strpart( getline('.'), col('.')-2, 2 )
	return IsEmptyPair( cur )
endfunc

function! s:SkipDelim(char)
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

function! s:QuoteDelim(char)
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

function! s:ClosePair(char)
	if getline('.')[col('.') - 1] == a:char
		return "\<Right>"
	else
		return a:char
	endif
endf

function! s:ResetMappings()
	for delim in s:right_delims + s:left_delims + s:quote_delims
		silent! exec 'iunmap ' . delim
		silent! exec 'vunmap ' . s:leader . delim
	endfor
endfunction

" Mappings:{{{1

call s:ResetMappings()
if s:autocomplete == 0
	" Don't auto-complete:{{{2
	let test_string = "Don't"
	"inoremap <expr> ) <SID>SkipDelim('\)')
	for delim in s:right_delims + s:quote_delims
		exec 'imap <expr> ' . delim . ' <SID>SkipDelim("\' . delim . '")'
	endfor

	" Wrap the selection with delimiters:
	let s:i = 0
	while s:i < len(s:paired_delims)

	"vmap <expr> q( visualmode() == "<C-V>" ? "I(\<Esc>" : "s(\<C-R>\")\<Esc>"		
		exec 'vmap <expr> ' . s:leader . s:left_delims[s:i] . 
					\' visualmode() == "<C-V>" ? "I' . s:left_delims[s:i] . 
					\'\<Esc>" : "s' . s:left_delims[s:i] . '\<C-R>\"' . 
					\s:right_delims[s:i] . '\<Esc>"'

	"vmap <expr> q) visualmode() == "<C-V>" ? "A\<Esc>" : "s(\<C-R>\")\<Esc>"
		exec 'vmap <expr> ' . s:leader . s:right_delims[s:i] . 
					\' visualmode() == "<C-V>" ? "I' . s:left_delims[s:i] . 
					\'\<Esc>" : "s' . s:left_delims[s:i] . '\<C-R>\"' . 
					\s:right_delims[s:i] . '\<Esc>"'
		let s:i = s:i + 1
	endwhile

	"vmap <expr> q" visualmode() == "<C-V>" ? "I"\<Esc>" : "s"\<C-R>\""\<Esc>"
	for quote in s:quote_delims
		exec 'vmap <expr> ' . s:leader . quote . 
					\' visualmode() == "<C-V>" ? "I' . quote . 
					\'\<Esc>" : "s' . quote . '\<C-R>\"' . quote . '\<Esc>"'
	endfor

else
	" Do auto-complete:{{{2

	" Add matching pair and jump to the midle:
	" imap ( ()<Left>
	let s:i = 0
	while s:i < len(s:paired_delims)
		exec 'imap ' . s:left_delims[s:i] . ' ' . s:left_delims[s:i] . s:right_delims[s:i] . '<Left>'
		let s:i = s:i + 1
	endwhile
	
	" Add matching quote and jump to the midle, or exit if inside a pair of
	" matching quotes:
	" imap " <c-r>=<SID>QuoteDelim("\"")<CR>
	let s:i = 0
	for delim in s:quote_delims
		exec 'imap ' . delim . ' <c-r>=<SID>QuoteDelim("\' . delim . '")<CR>'
	endfor

	" Exit from inside the matching pair:
	" imap ) <c-r>=<SID>ClosePair(')')<CR>
	for delim in s:right_delims
		exec 'imap ' . delim . ' <c-r>=<SID>ClosePair("\' . delim . '")<CR>'
	endfor

	" Wrap the selection with matching pairs:
	let s:i = 0
	while s:i < len(s:paired_delims)
		" But only insert opening delimiter if blocking visual is active:
		" vmap <expr> q( visualmode() == "<C-V>" ? "I(\<Esc>" : "s()\<C-R>\"\<Esc>"
		exec 'vmap <expr> ' . s:leader . s:left_delims[s:i] . ' visualmode() == "<C-V>" ? "I' . s:left_delims[s:i] . '\<Esc>" : "s' . s:left_delims[s:i] . s:right_delims[s:i] . '\<C-R>\"\<Esc>"'

		" But only insert closing delimiter if blocking visual is active:
		"vmap <expr> q) visualmode() == "<C-V>" ? "A)\<Esc>" : "s"\<C-R>\""\<Esc>"
		exec 'vmap <expr> ' . s:leader . s:right_delims[s:i] . ' visualmode() == "<C-V>" ? "A' . s:left_delims[s:i] . '\<Esc>" : "s' . s:left_delims[s:i] . s:right_delims[s:i] . '\<C-R>\"\<Esc>"'
		let s:i = s:i + 1
	endwhile

	" Wrap the selection with matching quotes, but only insert the opening
	" quote if blocking visual is active:
	for quote in s:quote_delims
		if quote == '"'
			" Ugly fix for double quotes:
			" vmap <expr> q" visualmode() == "<C-V>" ? 'I\"<Left><BS><Right><Esc>' : "s\"\<C-R>\"\<Esc>"
			exec 'vmap <expr> ' . s:leader . '" visualmode() == "<C-V>" ? ' .
						\ "'I\\\"<Left><BS><Right><Esc>' : " .
						\ '"s\"\<C-R>\"\<Esc>"'
		else

			"vmap <expr> q' visualmode() == "<C-V>" ? "I\\'\<Left>\<BS>\<Right>\<Esc>" : "s'\<C-R>\"'\<Esc>"
			exec 'vmap <expr> ' . s:leader . quote .
						\ ' visualmode() == "<C-V>" ? "I\\' . quote .
						\ '\<Left>\<BS>\<Right>\<Esc>" : "s' . quote .
						\ '\<C-R>\"' . quote . '\<Esc>"'
		endif
	endfor
endif

" Expansions and Deletion:{{{2

" If pair is empty, delete both delimiters:
imap <expr> <BS> <SID>WithinEmptyPair() ? "\<Right>\<BS>\<BS>" : "\<BS>"

" If pair is empty, expand the pair to three lines and place the cursor
" in the middle:
if s:expand_return
	imap <expr> <CR> <SID>WithinEmptyPair() ? "\<CR>\<CR>\<Up>" : "\<CR>"
endif

" If pair is emtpy, add a space to each side of the cursor:
if s:expand_space
	imap <expr> <Space> <SID>WithinEmptyPair() ? "\<Space>\<Space>\<Left>" : "\<Space>"
endif

"}}}1
" vim:foldmethod=marker:foldcolumn=4
