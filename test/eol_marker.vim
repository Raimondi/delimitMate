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
call vimtap#Plan(10)

let g:delimitMate_expand_cr = 1
let g:delimitMate_eol_marker = ';'
" NOTE: Do not forget to update the plan ^
let g:delimitMate_insert_eol_marker = 0

call DMTest_single('', 'i(', '()')

call DMTest_single('', "i(\<CR>x", ['(', 'x', ')'])

let g:delimitMate_insert_eol_marker = 1
call DMTest_single('', 'i(', '();')

call DMTest_single(' a', 'i(', '() a')

call DMTest_single('', "i(\<CR>x", ['(', 'x', ');'])

let g:delimitMate_insert_eol_marker = 2
call DMTest_single('', 'i(', '()')

call DMTest_single('', "i(\<CR>x", ['(', 'x', ');'])

" Issue #195
call DMTest_single('', "i{(\<CR>x", ['{(', 'x', ')}'])

" Issue #195
call DMTest_single('', "i;\<Left>{(\<CR>x", ['{(', 'x', ')};'])

" Issue #195
call DMTest_single('', "i\<Left>{(\<CR>x", ['{(', 'x', ')};'], 0, 1)

" End: quit vim.
call vimtest#Quit()
" vim: sw=2 et
