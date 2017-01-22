" function! DMTest_single(setup, typed, expected[, skip_expr[, todo_expr]])
" - Runs a single test.
" - Add 1 to vimtap#Plan().
"
" function! DMTest_pairs(setup, typed, expected, [skip_expr[, todo_expr]])
" - Runs one test for every pair.
" - Add 7 to vimtap#Plan().
"
" function! DMTest_quotes(setup, typed, expected, [skip_expr[, todo_expr]])
" - Runs one test for every quote.
" - Add 5 to vimtap#Plan().

call vimtest#StartTap()
call vimtap#Plan(230)

let g:delimitMate_quotes = '" '' ` « |'
let g:delimitMate_autoclose = 1
DelimitMateReload
call DMTest_quotes('', "'x", "'x'")
call DMTest_quotes('', "'x\<Esc>u", "")
call DMTest_quotes('', "''x", "''x")
call DMTest_quotes('', "'\<BS>x", "x")
call DMTest_quotes('', "'\<C-G>gx", "''x")
" This will fail for double quote.
call DMTest_quotes('', "'\"x", "'\"x\"'", "a:typed == '\"\"x'")
call DMTest_quotes('', "@'x", "@'x'")
call DMTest_quotes('', "@#\<Left>'x", "@'x'#")
call DMTest_quotes('', "'\<S-Tab>x", "''x")
call DMTest_quotes('', "abc'", "abc'")
call DMTest_quotes('', "abc\\'x", "abc\\'x")
call DMTest_quotes('', "u'Привет'", "u'Привет'")
call DMTest_quotes('', "u'string'", "u'string'")
let g:delimitMate_autoclose = 0
DelimitMateReload
call DMTest_quotes('', "'x", "'x")
call DMTest_quotes('', "''x", "'x'")
call DMTest_quotes('', "'''x", "''x")
call DMTest_quotes('', "''\<BS>x", "x")
call DMTest_quotes('', "@''x", "@'x'")
call DMTest_quotes('', "@#\<Left>''x", "@'x'#")
let g:delimitMate_expand_space = 1
let g:delimitMate_autoclose = 1
DelimitMateReload
call DMTest_quotes('', "'\<Space>x", "' x'")
let g:delimitMate_expand_inside_quotes = 1
DelimitMateReload
call DMTest_quotes('', "'\<Space>x", "' x '")
call DMTest_quotes('', "'\<Space>\<BS>x", "'x'")
call DMTest_quotes('', "abc\\''\<Space>x", "abc\\' x'")
let g:delimitMate_autoclose = 0
DelimitMateReload
call DMTest_quotes('', "''\<Space>\<BS>x", "'x'")
let g:delimitMate_autoclose = 1
DelimitMateReload
" Handle backspace gracefully.
set backspace=
call DMTest_quotes('', "'\<Esc>a\<BS>x", "'x'")
set backspace=2
set cpo=ces$
call DMTest_quotes('', "'x", "'x'")
" Make sure smart quote works beyond first column.
call DMTest_quotes('', " 'x", " 'x'")
" smart quote, check fo char on the right.
call DMTest_quotes('', "a\<space>b\<left>'", "a 'b")
" Make sure we jump over a quote on the right. #89.
call DMTest_quotes('', "('test'x", "('test'x)")
" Duplicate whole line when inserting quote at bol #105
call DMTest_quotes('', "}\<Home>'", "''}")
call DMTest_quotes('', "'\<Del>abc  '", "'abc  '")
call DMTest_quotes('', "''abc '", "''abc ''")
" Nesting quotes:
let g:delimitMate_nesting_quotes = split(g:delimitMate_quotes, '\s\+')
DelimitMateReload
call DMTest_quotes('', "'''x", "'''x'''")
call DMTest_quotes('', "''''x", "''''x''''")
call DMTest_quotes('', "''x", "''x")
call DMTest_quotes('', "'x", "'x'")
unlet g:delimitMate_nesting_quotes
DelimitMateReload
" expand iabbreviations
iabb def ghi
call DMTest_quotes('', "def'", "ghi'")
let g:delimitMate_smart_quotes = '\w\%#\_.'
DelimitMateReload
call DMTest_quotes('', "xyz'x", "xyz'x")
call DMTest_quotes('', "xyz 'x", "xyz 'x'")
let g:delimitMate_smart_quotes = '\s\%#\_.'
DelimitMateReload
call DMTest_quotes('', "abc'x", "abc'x'")
call DMTest_quotes('', "abc 'x", "abc 'x")
" let's try the negated form
let g:delimitMate_smart_quotes = '!\w\%#\_.'
DelimitMateReload
call DMTest_quotes('', "cba'x", "cba'x'")
call DMTest_quotes('', "cba 'x", "cba 'x")
let g:delimitMate_smart_quotes = '!\s\%#\_.'
DelimitMateReload
call DMTest_quotes('', "zyx'x", "zyx'x")
call DMTest_quotes('', "zyx 'x", "zyx 'x'")
unlet g:delimitMate_smart_quotes
DelimitMateReload
call DMTest_quotes('', "'\<CR>\<BS>", "''")

call vimtest#Quit()
