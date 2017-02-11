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
call vimtap#Plan(26)


let g:delimitMate_expand_cr = 1
"let g:delimitMate_eol_marker = ';'
filetype indent on
set bs=2 et sts=4 sw=4 ft=javascript
call DMTest_single('$(document).ready(function() {})',
      \ "31|i\<CR>x",
      \ ["$(document).ready(function() {", "    x", "})"])

" Issue #95
new
let b:delimitMate_jump_expansion = 1
call DMTest_single('', "i(\<CR>test)x",
      \ ['(', 'test', ')x'])

" Remove CR expansion on BS
call DMTest_single('', "i(\<CR>\<BS>x",
      \ ['(x)'])

" Consider indentation with BS inside an empty CR expansion.
call DMTest_single('', "i(  \<CR>\<BS>\<BS>x",  '(x)')

" Conflict with indentation settings (cindent). Issue #95
se cindent

call DMTest_single(
      \ ['sub foo {',
      \  '    while (1) {',
      \  '',
      \  '    }',
      \  '}'],
      \ "3Gi\<BS>x",
      \ ['sub foo {',
      \  '    while (1) {x}',
      \  '}'])

call DMTest_single(
      \ ['sub foo {',
      \  '    while (1) {',
      \  '        bar',
      \  '    }',
      \  '}'],
      \ "3GA}x",
      \ ['sub foo {',
      \  '    while (1) {',
      \  '        bar',
      \  '    }x',
      \  '}'])

call DMTest_single('"{bracketed}', "\<Esc>A\"x", '"{bracketed}"x')

" Syntax folding enabled by autocmd breaks expansion.
new
autocmd InsertEnter <buffer> let w:fdm=&foldmethod | setl foldmethod=manual
autocmd InsertLeave <buffer> let &foldmethod = w:fdm
set foldmethod=marker
set foldmarker={,}
set foldlevel=0
set backspace=2
call DMTest_single('', "iabc {\<CR>x",
      \['abc {',
      \ '    x',
      \ '}'])
:bp
" expand_cr != 2
call DMTest_single('abc(def)', "i\<Esc>$i\<CR>x",
      \ ['abc(def',
      \  '        x)'])

" expand_cr == 2
let delimitMate_expand_cr = 2
call DMTest_single('abc(def)', "$i\<CR>x", ['abc(def', '        x', '   )'])

" Play nice with smartindent
set all&
set whichwrap=[]
set bs=2
set smartindent
call DMTest_single('', "i{\<CR>x", ['{', '	x', '}'])

call DMTest_quotes('', "i' x", "' x'")

call DMTest_quotes('', "i'\<CR>x", ["'", "x'"])

let delimitMate_expand_inside_quotes = 1

call DMTest_quotes('', "i'\<CR>x", ["'", "x", "'"])

call vimtest#Quit()
