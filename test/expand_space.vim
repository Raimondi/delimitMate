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
call vimtap#Plan(12)

let g:delimitMate_expand_space = 1

" Issue #95
let b:delimitMate_jump_expansion = 1
call DMTest_pairs('', "i( test)x", '( test )x')

let delimitMate_expand_inside_quotes = 1

call DMTest_quotes('', "i' x", "' x '")

call vimtest#Quit()
