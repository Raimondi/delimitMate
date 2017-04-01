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

call vimtap#Plan(239)


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

call DMTest_pairs('"abc"', "ifoo(", 'foo("abc"')

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
" Not sure how to make it work on the test
call DMTest_single('', "idef(", "ghi()", 0, 1)
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

" TODO: way to jump over one or several closing chars
call DMTest_single('()', 'a\<magic>x', '()x', 0, 1)

call DMTest_single('{()}', 'la\<magic>x', '{()}x', 0, 1)

let g:delimitMate_balance_pairs = 0
call DMTest_pairs('ab cd)', "la(x", 'ab(x) cd)')
" Issue #229
call DMTest_pairs('((ab cd)', "$i)x", '((ab cd)x')

let g:delimitMate_balance_pairs = 1
call DMTest_pairs('ab cd)', "la(x", 'ab(x cd)')
" Issue #229
call DMTest_pairs('((ab cd)', "$i)x", '((ab cd)x)')
unlet g:delimitMate_balance_pairs

" Issue #220
let g:delimitMate_jump_next = 0
call DMTest_pairs('()', 'a)', '())')
unlet g:delimitMate_jump_next

" Issues #207 and #223
let g:delimitMate_jump_long = 1
call DMTest_single('{[(foobar)]}', 'fbi)x', '{[(foobar)x]}')

" Issues #207 and #223
call DMTest_single('{[(foobar)]}', 'fbi]x', '{[(foobar)]x}')
unlet g:delimitMate_jump_long

" Issues #207 and #223
let g:delimitMate_jump_all = 1
call DMTest_single('{[(foobar)]}', 'fbi<magic>x', '{[(foobar)]}x', 0, 1)
unlet g:delimitMate_jump_all

let g:delimitMate_jump_back = 1
call DMTest_pairs('', 'i()x', '()x')
unlet g:delimitMate_jump_back

" Disable on syntax groups
new
syntax on
set ft=vim
let g:delimitMate_excluded_regions = ['String']
call DMTest_pairs('echo "  "', "f\"la(", 'echo " ( "')
unlet g:delimitMate_excluded_regions

filetype indent plugin on
set ft=php
" Issue #160
call DMTest_single('<?php incl', "A\<C-X>\<C-O>\<C-Y>", '<?php include()', 0, 1)
syntax off
bp

" This breaks Vim for now, so let's put it at the end
" Play nice with redo
call DMTest_single('abc ', "Afoo(x\<Esc>.", 'abc foo(x)foo(x)', 0, 1)

call vimtest#Quit()
" vim: sw=2 et
