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
call vimtap#Plan(210)

let g:delimitMate_matchpairs = '(:),{:},[:],<:>,¿:?,¡:!,,::'
let g:delimitMate_autoclose = 1
call DMTest_pairs('', ["i("], "()")
call DMTest_pairs('()', ["a\<BS>"], "")
call DMTest_pairs('()', ["a)", 'ax'], "()x")
"call DMTest_pairs('', "((\<C-G>gx", "(())x")
call DMTest_pairs('', ["i(x\<Esc>u"], "")
call DMTest_pairs('', ["i@", "a(","ax"], "@(x)")
call DMTest_pairs('@#', ["a(","ax"], "@(x)#")
call DMTest_pairs('\', ["a(","ax"], '\(x')
call DMTest_pairs('', ["a(",'a\', 'a)', "ax"], '(\)x)')
"call DMTest_pairs('', "(\<S-Tab>x", "()x")
let g:delimitMate_autoclose = 0
call DMTest_pairs('', ["i(", "ax"], "(x")
call DMTest_pairs('', ["i(", "a)", "ax"], "(x)")
call DMTest_pairs('', ["i(", "a)", "a)", "ax"], "()x")
call DMTest_pairs('', ["i(", "a)", "a\<BS>", "ax"], "x")
call DMTest_pairs('', ["i@(", "a)", "ax"], "@(x)")
call DMTest_pairs('@#', ["a(", "a)", "ax"], "@(x)#")
let g:delimitMate_expand_space = 1
let g:delimitMate_autoclose = 1
call DMTest_pairs('', ['i(', "a\<Space>", 'ax'], "( x )")
" <Right> needs to be after <BS> so the cursor stays in the expected place for when
" the :doau commands fire.
call DMTest_pairs('(  )', ["2|a\<BS>\<Right>", 'ix'], "(x)")
call DMTest_pairs('', ["iabc ", 'ax'], "abc x")
let g:delimitMate_autoclose = 0
call DMTest_pairs('', ["i(", "a)", "a\<Space>", "a\<BS>\<Right>", "ix"], "(x)")
let g:delimitMate_autoclose = 1
" Handle backspace gracefully.
set backspace=
call DMTest_pairs('', ["i(", "a\<BS>\<Right>", "ix"], "(x)")
set backspace=2
" closing parens removes characters. #133
call DMTest_pairs('', ["i(", "aa", "i)"], "()a)")

" Add semicolon next to the closing paren. Issue #77.
"new
"let b:delimitMate_eol_marker = ';'
"call DMTest_pairs('', "abc(x", "abc(x);")
"" BS should behave accordingly.
"call DMTest_pairs('', "abc(\<BS>", "abc;")
"unlet b:delimitMate_eol_marker
" Expand iabbreviations
iabb def ghi
" TODO not sure how to make this test actually test if the feature works.
call DMTest_pairs('', ["idef("], "ghi()", '', 1)
iunabb def

call DMTest_pairs("abc а", ["A\<Left>", "a("], "abc (а")
call DMTest_pairs("abc ñ", ["A\<Left>", "a("], "abc (ñ")
call DMTest_pairs("abc $", ["A\<Left>", "a("], "abc ($")
call DMTest_pairs("abc £", ["A\<Left>", "a("], "abc (£")
call DMTest_pairs("abc d", ["A\<Left>", "a("], "abc (d")
call DMTest_pairs("abc .", ["A\<Left>", "a("], "abc ().")
call DMTest_pairs("abc  ", ["A\<Left>", "a("], "abc () ")
call DMTest_pairs("abc (", ["A\<Left>", "a("], "abc ((")

"" Play nice with undo.
"call DMTest_pairs('', "a\<C-G>u(c)b\<C-O>u", "a")
"
let g:delimitMate_autoclose = 1
let g:delimitMate_balance_pairs = 1
call DMTest_pairs('ab cd)', ["2|a(", "ax"], 'ab(x cd)')

call vimtest#Quit()
