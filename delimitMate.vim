" DELIMITERS MADE LESS ANNOYING
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
if exists("loaded_annoying_delimiters")
	"	finish
endif
if v:version < 700
	echoerr "AnnoyingDelimiters: this plugin requires vim >= 7!"
	finish
endif
let loaded_annoying_delimiters = 1

if !exists("g:annoyDelims_delims_list")
	let s:delims = split (") } ] ' \" `")
else
	let s:delims = g:annoyDelims_delims_list
endif

if !exists("g:annoyDelims_autocomplete")
	let s:autocomplete = 1
else
	let s:autocomplete = g:annoyDelims_autocomplete
endif

let s:paired_delims = split( &matchpairs, ',' )
let s:quote_delims = split("\" ' ` ´")
"let s:left_delims = []
"let s:right_delims = []

"for pair in s:paired_delims
"let pairl = split(pair,":")
"let s:left_delims = s:left_delims + pairl[0]
"let s:right_delims = s:right_delims + pairl[1]
"endfor

let s:left_delims = split(&matchpairs, ':.,\=')
let s:right_delims = split(&matchpairs, ',\=.:')

let s:leader = "q"

" Functions:{{{1
function! IsEmptyPair(str)
	for pair in split( &matchpairs, ',' ) + [ "''", '""', '``' ]
		if a:str == join( split( pair, ':' ),'' )
			return 1
		endif
	endfor
	return 0
endfunc

function! WithinEmptyPair()
	let cur = strpart( getline('.'), col('.')-2, 2 )
	return IsEmptyPair( cur )
endfunc

function! SkipDelim(char)
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

function! QuoteDelim(char)
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

function! ClosePair(char)
	if getline('.')[col('.') - 1] == a:char
		return "\<Right>"
	else
		return a:char
	endif
endf

function! ResetMappings()
	for delim in s:right_delims + s:left_delims + s:quote_delims
		silent! exec 'iunmap ' . delim
		silent! exec 'vunmap ' . s:leader . delim
	endfor
endfunction

" Mappings:{{{1

call ResetMappings()
if s:autocomplete == 0
	" Don't auto-complete:{{{2
	let test_string = "Don't"
	"inoremap <expr> ) SkipDelim(')')
	for delim in s:right_delims + s:quote_delims
		exec 'imap <expr> ' . delim . ' SkipDelim("\' . delim . '")'
	endfor

	" Wrap the selection with delimiters:
	"vmap <expr> q( visualmode() == "<C-V>" ? "I(\<Esc>" : "s(\<C-R>\")\<Esc>"
	let s:i = 0
	while s:i < len(s:paired_delims)
		exec 'vmap <expr> ' . s:leader . s:left_delims[s:i] . 
					\' visualmode() == "<C-V>" ? "I' . s:left_delims[s:i] . 
					\'\<Esc>" : "s' . s:left_delims[s:i] . '\<C-R>\"' . 
					\s:right_delims[s:i] . '\<Esc>"'
		exec 'vmap <expr> ' . s:leader . s:right_delims[s:i] . 
					\' visualmode() == "<C-V>" ? "I' . s:left_delims[s:i] . 
					\'\<Esc>" : "s' . s:left_delims[s:i] . '\<C-R>\"' . 
					\s:right_delims[s:i] . '\<Esc>"'
		let s:i = s:i + 1
	endwhile

	for quote in s:quote_delims
		exec 'vmap <expr> ' . s:leader . quote . 
					\' visualmode() == "<C-V>" ? "I' . quote . 
					\'\<Esc>" : "s' . quote . '\<C-R>\"' . quote . '\<Esc>"'
	endfor

else
	" Do auto-complete:{{{2
	let test_string = "Do"
	let s:i = 0
	while s:i < len(s:paired_delims)
		exec 'imap ' . s:left_delims[s:i] . ' ' . s:left_delims[s:i] . s:right_delims[s:i] . '<Left>'
		let s:i = s:i + 1
	endwhile
	"imap ( ()<Left>
	"imap [ []<Left>
	"imap { {}<Left>
	"autocmd Syntax html,vim imap < <lt>><Left>
	"let test_list = []
	let s:i = 0
	for delim in s:quote_delims
		exec 'imap ' . delim . ' <c-r>=QuoteDelim("\' . delim . '")<CR>'
	endfor
	for delim in s:right_delims
		exec 'imap ' . delim . ' <c-r>=ClosePair("\' . delim . '")<CR>'
	endfor
	"imap " <c-r>=QuoteDelim('"')<CR>
	"imap ' <c-r>=QuoteDelim("'")<CR>
	"imap ) <c-r>=ClosePair(')')<CR>
	"imap ] <c-r>=ClosePair(']')<CR>
	"imap } <c-r>=ClosePair('}')<CR>

	" Wrap the selection with delimiters:
	"vmap <expr> q( visualmode() == "<C-V>" ? "I(\<Esc>" : "s()\<C-R>\"\<Esc>"
	let s:i = 0
	while s:i < len(s:paired_delims)
		exec 'vmap <expr> ' . s:leader . s:left_delims[s:i] . ' visualmode() == "<C-V>" ? "I' . s:left_delims[s:i] . '\<Esc>" : "s' . s:left_delims[s:i] . s:right_delims[s:i] . '\<C-R>\"\<Esc>"'
		exec 'vmap <expr> ' . s:leader . s:right_delims[s:i] . ' visualmode() == "<C-V>" ? "I' . s:left_delims[s:i] . '\<Esc>" : "s' . s:left_delims[s:i] . s:right_delims[s:i] . '\<C-R>\"\<Esc>"'
		let s:i = s:i + 1
	endwhile

	for quote in s:quote_delims
		exec 'vmap <expr> ' . s:leader . quote . 
					\' visualmode() == "<C-V>" ? "I' . quote . 
					\'\<Esc>" : "s' . quote . '\<C-R>\"' . quote . '\<Esc>"'
	endfor
	"vmap (  <ESC>`>a)<ESC>`<i(<ESC>
	"vmap )  <ESC>`>a)<ESC>`<i(<ESC>
	"vmap {  <ESC>`>a}<ESC>`<i{<ESC>
	"vmap }  <ESC>`>a}<ESC>`<i{<ESC>
	"vmap "  <ESC>`>a"<ESC>`<i"<ESC>
	"vmap '  <ESC>`>a'<ESC>`<i'<ESC>
	"vmap `  <ESC>`>a`<ESC>`<i`<ESC>
	"vmap [  <ESC>`>a]<ESC>`<i[<ESC>
	"vmap ]  <ESC>`>a]<ESC>`<i[<ESC>


endif
" Expansions:{{{2
imap <expr> <BS> WithinEmptyPair() ? "\<Right>\<BS>\<BS>" : "\<BS>"
imap <expr> <CR> WithinEmptyPair() ? "\<CR>\<CR>\<Up>" : "\<CR>"
imap <expr> <Space> WithinEmptyPair() ? "\<Space>\<Space>\<Left>" : "\<Space>"

" vim:foldmethod=marker:foldcolumn=2
