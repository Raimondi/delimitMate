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

call vimtap#Plan(189)


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

let g:delimitMate_autoclose = 1
" Handle backspace gracefully.
set backspace=
call DMTest_pairs('', "i(\<Esc>a\<BS>x", "(x)")

set backspace=2
" closing parens removes characters. #133
call DMTest_pairs('(a)', "a)", "()a)")

" Expand iabbreviations
iabb def ghi
call DMTest_pairs('', "idef(", "ghi()")
iunabb def

call DMTest_pairs("abc а", "$i(", "abc (а")

call DMTest_pairs("abc ñ", "$i(", "abc (ñ")

call DMTest_pairs("abc $", "$i(", "abc ($")

call DMTest_pairs("abc £", "$i(", "abc (£")

call DMTest_pairs("abc d", "$i(", "abc (d")

call DMTest_pairs("abc .", "$i(", "abc ().")

call DMTest_pairs("abc  ", "$i(", "abc () ")

call DMTest_pairs("abc (", "$i(", "abc ((")

" Play nice with undo.
call DMTest_pairs('', "ia\<C-G>u(c)b\<Esc>u", "a")

let g:delimitMate_autoclose = 1
let g:delimitMate_balance_pairs = 1
call DMTest_pairs('ab cd)', "la(x", 'ab(x cd)')


call vimtest#Quit()
" vim: sw=2 et
