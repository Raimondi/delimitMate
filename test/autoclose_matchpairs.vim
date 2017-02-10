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
call DMTest_pairs('', "i(", "()")
call DMTest_pairs('()', "a\<BS>", "")
call DMTest_pairs('()', "a)x", "()x")
"call DMTest_pairs('', "((\<C-G>gx", "(())x")
call DMTest_pairs('', "i(x\<Esc>u", "")
call DMTest_pairs('', "i@(x", "@(x)")
call DMTest_pairs('@#', "a(x", "@(x)#")
call DMTest_pairs('\', "a(x", '\(x')
call DMTest_pairs('(\)', "la)x", '(\)x)')
"call DMTest_pairs('', "(\<S-Tab>x", "()x")
let g:delimitMate_autoclose = 0
call DMTest_pairs('', "i(x", "(x")
call DMTest_pairs('', "i()x", "(x)")
call DMTest_pairs('', "i())x", "()x")
call DMTest_pairs('', "i()\<BS>x", "x")
call DMTest_pairs('', "i@()x", "@(x)")
call DMTest_pairs('@#', "a()x", "@(x)#")
let g:delimitMate_expand_space = 1
let g:delimitMate_autoclose = 1
call DMTest_pairs('', "i(\<Space>x", "( x )")
call DMTest_pairs('(  )', "2|a\<BS>x", "(x)")
call DMTest_pairs('', "iabc x", "abc x")
let g:delimitMate_autoclose = 0
call DMTest_pairs('', "i()\<Space>\<BS>x", "(x)")
let g:delimitMate_autoclose = 1
" Handle backspace gracefully.
set backspace=
call DMTest_pairs('', "i(\<Esc>a\<BS>x", "(x)")
set backspace=2
" closing parens removes characters. #133
call DMTest_pairs('(a)', "a)", "()a)")

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
call DMTest_pairs('', "idef(", "ghi()") ", '', 1)
iunabb def

call DMTest_pairs("abc а", "$i(", "abc (а")
call DMTest_pairs("abc ñ", "$i(", "abc (ñ")
call DMTest_pairs("abc $", "$i(", "abc ($")
call DMTest_pairs("abc £", "$i(", "abc (£")
call DMTest_pairs("abc d", "$i(", "abc (d")
call DMTest_pairs("abc .", "$i(", "abc ().")
call DMTest_pairs("abc  ", "$i(", "abc () ")
call DMTest_pairs("abc (", "$i(", "abc ((")

"" Play nice with undo.
"call DMTest_pairs('', "a\<C-G>u(c)b\<C-O>u", "a")
"
let g:delimitMate_autoclose = 1
let g:delimitMate_balance_pairs = 1
call DMTest_pairs('ab cd)', "2|a(x", 'ab(x cd)')

call vimtest#Quit()
