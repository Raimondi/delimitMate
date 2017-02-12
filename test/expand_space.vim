" call DMTest_single(setup, typed, expected[, skip_expr[, todo_expr]])
" - Runs a single test.
" - Add 1 to vimtap#Plan().
"
" call DMTest_pairs(setup, typed, expected, [skip_expr[, todo_expr]])
" - Runs one test for every pair.
" - Add 7 to vimtap#Plan().
"
" call DMTest_quotes(setup, typed, expected, [skip_expr[, todo_expr]])
" - Runs one test for every quote.
" - Add 5 to vimtap#Plan().

call vimtest#StartTap()

call vimtap#Plan(60)


let g:delimitMate_expand_space = 1

let g:delimitMate_autoclose = 1
call DMTest_pairs('', "i(\<Space>x", "( x )")

call DMTest_pairs('(  )', "la\<BS>x", "(x)")

call DMTest_pairs('', "iabc x", "abc x")

call DMTest_quotes('', "i' x", "' x'")

let g:delimitMate_expand_inside_quotes = 1
call DMTest_quotes('', "i' x", "' x '")

call DMTest_quotes('', "i' \<BS>x", "'x'")

call DMTest_quotes('abc\', "A'' x", "abc\\'' x '")

" Issue #95
let b:delimitMate_jump_expansion = 1
call DMTest_pairs('', "i( test)x", '( test )x')

let g:delimitMate_autoclose = 0
call DMTest_pairs('', "i()\<Space>\<BS>x", "(x)")

call DMTest_quotes('', "i'' \<BS>x", "'x'")

call vimtest#Quit()
" vim: sw=2 et
