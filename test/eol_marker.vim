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
call vimtap#Plan(8)

let g:delimitMate_expand_cr = 1
let g:delimitMate_eol_marker = ';'
" NOTE: Do not forget to update the plan ^
let g:delimitMate_insert_eol_marker = 0
DelimitMateReload

call DMTest_single('', '(', '()')

call DMTest_single('', "(\<CR>x", ['(', 'x', ')'])

let g:delimitMate_insert_eol_marker = 1
DelimitMateReload
call DMTest_single('', '(', '();')

call DMTest_single('', "(\<CR>x", ['(', 'x', ');'])

let g:delimitMate_insert_eol_marker = 2
DelimitMateReload
call DMTest_single('', '(', '()')

call DMTest_single('', "(\<CR>x", ['(', 'x', ');'])

call DMTest_single('', "{(\<CR>x", ['{(', 'x', ')};'])

call DMTest_single('', ";\<Esc>I{(\<CR>x", ['{(', 'x', ')};'])

" End: quit vim.
call vimtest#Quit()
