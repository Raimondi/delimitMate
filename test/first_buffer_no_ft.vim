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
call vimtap#Plan(1)

let g:delimitMate_expand_cr = 1
let g:delimitMate_eol_marker = ';'
DelimitMateReload
call vimtap#Like(maparg('(', 'i'), '<Plug>delimitMate(', 'Mappings defined for the first buffer without filetype set.')
call vimtest#Quit()


