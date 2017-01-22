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
call vimtap#Plan(217)

let g:delimitMate_matchpairs = '(:),{:},[:],<:>,¿:?,¡:!,,::'
let g:delimitMate_autoclose = 1
DelimitMateReload
call DMTest_pairs('', "(x", "(x)")
call DMTest_pairs('', "(\<BS>x", "x")
call DMTest_pairs('', "()x", "()x")
call DMTest_pairs('', "((\<C-G>gx", "(())x")
call DMTest_pairs('', "(x\<Esc>u", "")
call DMTest_pairs('', "@(x", "@(x)")
call DMTest_pairs('', "@#\<Left>(x", "@(x)#")
call DMTest_pairs('', "(\<S-Tab>x", "()x")
let g:delimitMate_autoclose = 0
DelimitMateReload
call DMTest_pairs('', "(x", "(x")
call DMTest_pairs('', "()x", "(x)")
call DMTest_pairs('', "())x", "()x")
call DMTest_pairs('', "()\<BS>x", "x")
call DMTest_pairs('', "@()x", "@(x)")
call DMTest_pairs('', "@#\<Left>()x", "@(x)#")
let g:delimitMate_expand_space = 1
let g:delimitMate_autoclose = 1
DelimitMateReload
call DMTest_pairs('', "(\<Space>x", "( x )")
call DMTest_pairs('', "(\<Space>\<BS>x", "(x)")
let g:delimitMate_autoclose = 0
DelimitMateReload
call DMTest_pairs('', "()\<Space>\<BS>x", "(x)")
let g:delimitMate_autoclose = 1
DelimitMateReload
" Handle backspace gracefully.
set backspace=
call DMTest_pairs('', "(\<Esc>a\<BS>x", "(x)")
set bs=2
" closing parens removes characters. #133
call DMTest_pairs('', "(a\<Esc>i)", "()a)")

" Add semicolon next to the closing paren. Issue #77.
new
let b:delimitMate_eol_marker = ';'
DelimitMateReload
call DMTest_pairs('', "abc(x", "abc(x);")
" BS should behave accordingly.
call DMTest_pairs('', "abc(\<BS>", "abc;")
" Expand iabbreviations
unlet b:delimitMate_eol_marker
DelimitMateReload
iabb def ghi
call DMTest_pairs('', "def(", "ghi()")
iunabb def

call DMTest_pairs('', "abc а\<Left>(", "abc (а")
call DMTest_pairs('', "abc ñ\<Left>(", "abc (ñ")
call DMTest_pairs('', "abc $\<Left>(", "abc ($")
call DMTest_pairs('', "abc £\<Left>(", "abc (£")
call DMTest_pairs('', "abc d\<Left>(", "abc (d")
call DMTest_pairs('', "abc \<C-V>(\<Left>(", "abc ((")
call DMTest_pairs('', "abc .\<Left>(", "abc ().")
call DMTest_pairs('', "abc  \<Left>(", "abc () ")

" Play nice with undo.
call DMTest_pairs('', "a\<C-G>u(c)b\<C-O>u", "a")

call vimtest#Quit()
