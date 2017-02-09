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
call vimtap#Plan(140)

let g:delimitMate_autoclose = 1
call DMTest_quotes('', ["i'", "ax"], "'x'")
call DMTest_quotes('', ["i'x", "u"], "")
call DMTest_quotes('', ["i'", "a'", "ax"], "''x", 'a:typed[0] == "i«"')
call DMTest_quotes('', ["a'", "a\<BS>", "ax"], "x")
"call DMTest_quotes('', "'\<C-G>gx", "''x")
" This will fail for double quote.
call DMTest_quotes('', ["i'", "a\"", "ax"], "'\"x\"'", 'a:typed[0] =~ "i[\"«]"')
call DMTest_quotes('', ["i@", "a'", "ax"], "@'x'")
call DMTest_quotes('', ["i@#", "i'", "ax"], "@'x'#")
"call DMTest_quotes('', "'\<S-Tab>x", "''x")
call DMTest_quotes('', ["iabc", "a'"], "abc'")
call DMTest_quotes('abc\', ["A'", "ax"], "abc\\'x")
" TODO find out why this test doesn't work when it does interactively.
call DMTest_quotes('', ["au", "a'", "aПривет", "a'"], "u'Привет'", '', 1)
call DMTest_quotes('', ["au", "a'", "astring", "a'"], "u'string'")
let g:delimitMate_autoclose = 0
call DMTest_quotes('', ["a'", "ax"], "'x")
call DMTest_quotes('', ["a'", "a'", "ax"], "'x'")
call DMTest_quotes('', ["a'", "a'", "a'", "ax"], "''x")
call DMTest_quotes('', ["a'", "a'", "a\<BS>", "ax"], "x")
call DMTest_quotes('', ["a@", "a'", "a'", "ax"], "@'x'")
call DMTest_quotes('', ["a@#", "i'", "a'", "ax"], "@'x'#")
let g:delimitMate_autoclose = 1
"let g:delimitMate_expand_space = 1
"call DMTest_quotes('', "'\<Space>x", "' x'")
"let g:delimitMate_expand_inside_quotes = 1
"call DMTest_quotes('', "'\<Space>x", "' x '")
"call DMTest_quotes('', "'\<Space>\<BS>x", "'x'")
"call DMTest_quotes('', "abc\\''\<Space>x", "abc\\' x'")
"let g:delimitMate_autoclose = 0
"call DMTest_quotes('', "''\<Space>\<BS>x", "'x'")
"let g:delimitMate_autoclose = 1
" Handle backspace gracefully.
set backspace=
call DMTest_quotes('', ["a'", "a\<BS>", "ax"], "'x'")
set backspace=2
"set cpo=ces$
"call DMTest_quotes('', "'x", "'x'")
" Make sure smart quote works beyond first column.
call DMTest_quotes(' ', ["a'", "ax"], " 'x'")
" smart quote, check fo char on the right.
call DMTest_quotes('a b', ["la'"], "a 'b")
" Make sure we jump over a quote on the right. #89.
call DMTest_quotes('', ["a(", "a'", "atest", "a'", "ax"], "('test'x)")
" Duplicate whole line when inserting quote at bol #105
call DMTest_quotes('}', ["i'"], "''}")
call DMTest_quotes("'abc  ", ["A'"], "'abc  '")
call DMTest_quotes("''abc ", ["A'"], "''abc ''")
"" Nesting quotes:
let g:delimitMate_nesting_quotes = delimitMate#option('quotes')
call DMTest_quotes("'' ", ["la'\<Right>", "ix"], "'''x''' ")
call DMTest_quotes("''' ", ["lla'\<Right>", "ix"], "''''x'''' ")
call DMTest_quotes(' ', ["i'", "a'\<Right>", "ix"], "''x ")
call DMTest_quotes('', ["i'", "ax"], "'x'")
unlet g:delimitMate_nesting_quotes
"" expand iabbreviations
"iabb def ghi
"call DMTest_quotes('', "def'", "ghi'")
"call DMTest_quotes('', "'\<CR>\<BS>", "''")

call vimtest#Quit()
