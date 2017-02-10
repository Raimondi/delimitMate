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
call vimtap#Plan(170)

let g:delimitMate_autoclose = 1
call DMTest_quotes('', "i'x", "'x'")
call DMTest_quotes('', "i'x\<Esc>u", "")
call DMTest_quotes('', "i''x", "''x")
call DMTest_quotes("''", "a\<BS>x", "x")
"call DMTest_quotes('', "'\<C-G>gx", "''x")
" This will fail for double quote.
call DMTest_quotes('', "i'\"x", "'\"x\"'", 'a:typed =~ "i\"\"x"')
call DMTest_quotes('', "i@'x", "@'x'")
call DMTest_quotes('@#', "a'x", "@'x'#")
"call DMTest_quotes('', "'\<S-Tab>x", "''x")
call DMTest_quotes('abc', "A'", "abc'")
call DMTest_quotes('abc\', "A'x", "abc\\'x")
call DMTest_quotes('', "au'Привет'", "u'Привет'")
call DMTest_quotes('', "au'string'", "u'string'")
let g:delimitMate_autoclose = 0
call DMTest_quotes('', "a'x", "'x")
call DMTest_quotes('', "a''x", "'x'")
call DMTest_quotes('', "a'''x", "''x")
call DMTest_quotes('', "a''\<BS>x", "x")
call DMTest_quotes('', "a@''x", "@'x'")
call DMTest_quotes('@#', "a''x", "@'x'#")
let g:delimitMate_autoclose = 1
let g:delimitMate_expand_space = 1
call DMTest_quotes('', "i' x", "' x'")
let g:delimitMate_expand_inside_quotes = 1
call DMTest_quotes('', "i' x", "' x '")
call DMTest_quotes('', "i' \<BS>x", "'x'")
call DMTest_quotes('abc\', "A'' x", "abc\\'' x '")
let g:delimitMate_autoclose = 0
call DMTest_quotes('', "i'' \<BS>x", "'x'")
unlet g:delimitMate_expand_space
unlet g:delimitMate_expand_inside_quotes
let g:delimitMate_autoclose = 1
" Handle backspace gracefully.
set backspace=
call DMTest_quotes('', "a'\<Esc>a\<BS>x", "'x'")
set backspace=2
"set cpo=ces$
"call DMTest_quotes('', "'x", "'x'")
" Make sure smart quote works beyond first column.
call DMTest_quotes(' ', "a'x", " 'x'")
" smart quote, check fo char on the right.
call DMTest_quotes('a b', "la'", "a 'b")
" Make sure we jump over a quote on the right. #89.
call DMTest_quotes('', "a('test'x", "('test'x)")
" Duplicate whole line when inserting quote at bol #105
call DMTest_quotes('}', "i'", "''}")
call DMTest_quotes("'abc  ", "A'", "'abc  '")
call DMTest_quotes("''abc ", "A'", "''abc ''")
" Nesting quotes:
let g:delimitMate_nesting_quotes = delimitMate#option('quotes')
call DMTest_quotes("''", "A'x", "'''x'''")
call DMTest_quotes("'''", "A'x", "''''x''''")
call DMTest_quotes('', "i''x", "''x")
call DMTest_quotes('', "i'x", "'x'")
unlet g:delimitMate_nesting_quotes
" expand iabbreviations
iabb def ghi
call DMTest_quotes('', "idef'", "ghi'", 'a:typed =~ "^idef[''`«|]"')
iunabb def
""call DMTest_quotes('', "'\<CR>\<BS>", "''")

call vimtest#Quit()
