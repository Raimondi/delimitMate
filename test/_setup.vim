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

let &rtp = expand('<sfile>:p:h:h') . ',' . &rtp . ',' . expand('<sfile>:p:h:h') . '/after'
set bs=2
set hidden
let g:delimitMate_pairs = ['()','{}','[]','<>','¿?','¡!',',:']
let g:delimitMate_quotes = ['"', "'", '`', '«', '|']
ru plugin/delimitMate.vim
let runVimTests = expand('<sfile>:p:h').'/build/runVimTests'
if isdirectory(runVimTests)
  let &rtp = runVimTests . ',' . &rtp
endif
let vimTAP = expand('<sfile>:p:h').'/build/VimTAP'
if isdirectory(vimTAP)
  let &rtp = vimTAP . ',' . &rtp
endif

function! s:setup_buffer(buf_content)
  "silent DelimitMateReload "call delimitMate#setup()
  silent %d_
  if !empty(a:buf_content)
    call setline(1, a:buf_content)
    call feedkeys("gg0", 'ntx')
  endif
endfunction

"function! DMTest_single(setup, typed, expected[, skip_expr[, todo_expr]])
" Runs a single test (add 1 to vimtap#Plan())
function! DMTest_single(setup, typed, expected, ...)
  if type(a:typed) != v:t_list
    return vimtap#Fail('Second argument should be a list: ' . a:typed)
  end
  if type(a:setup) == v:t_list
    let setup = copy(a:setup)
  else
    let setup = [a:setup]
  endif
  if type(a:expected) == v:t_list
    let expected = copy(a:expected)
  else
    let expected = [a:expected]
  endif
  let skip_expr = a:0 && !empty(a:1) ? a:1 : 0
  let todo_expr = a:0 > 1 && !empty(a:2) ? a:2 : 0
  if vimtap#Skip(1, !eval(skip_expr), skip_expr)
    return
  elseif eval(todo_expr)
    call vimtap#Todo(1)
  endif
  call s:setup_buffer(setup)
  for cmd in a:typed
    echom strtrans(cmd)
    call feedkeys(cmd, 'mt')
    call feedkeys('', 'x')
    doau delimitMate CursorMovedI
    doau delimitMate TextChangedI
    call feedkeys('', 'x')
  endfor
  call vimtap#Is(getline(1,'$'), expected, string(map(copy(a:typed), 'strtrans(v:val)')))
endfunction

function! s:do_set(pat, sub, set, setup, typed, expected, ...)
  if type(a:typed) != v:t_list
    return vimtap#Fail('Second argument should be a list: ' . string(a:typed))
  end
  let skip_expr = get(a:, '1', '')
  let todo_expr = get(a:, '2', '')
  let escaped = '\.*^$'
  for elem in a:set
    if type(a:setup) == v:t_list
      let setup = copy(a:setup)
    else
      let setup = [a:setup]
    endif
    if type(a:expected) == v:t_list
      let expected = copy(a:expected)
    else
      let expected = [a:expected]
    endif
    if strchars(elem) > 1
      "let [left, right] = map(split(elem, '\zs'), 'escape(v:val, escaped)')
      let left  = escape(strcharpart(elem, 0, 1), escaped)
      let right = escape(strcharpart(elem, 1, 1), escaped)
      let sub = a:sub
    else
      let quote = escape(elem, escaped)
      let sub = eval(a:sub)
    endif
    call map(setup, "substitute(v:val, a:pat, sub, 'g')")
    let typed = map(copy(a:typed), "substitute(v:val, a:pat, sub, 'g')")
    call map(expected, "substitute(v:val, a:pat, sub, 'g')")
    call DMTest_single(setup, typed, expected, skip_expr, todo_expr)
  endfor
endfunction

"function! DMTest_pairs(setup, typed, expected, [skip_expr[, todo_expr]])
" Runs one test for every pair (add 7 to vimtap#Plan())
function! DMTest_pairs(setup, typed, expected, ...)
  let skip_expr = get(a:, '1', '')
  let todo_expr = get(a:, '2', '')
  let pairs = delimitMate#option('pairs')
  let pat = '[()]'
  let sub = '\=submatch(0) == "(" ? left : right'
  return s:do_set(pat, sub, pairs, a:setup, a:typed, a:expected, skip_expr, todo_expr)
endfunction

"function! DMTest_quotes(setup, typed, expected, [skip_expr[, todo_expr]])
" Runs one test for every quote (add 5 to vimtap#Plan())
function! DMTest_quotes(setup, typed, expected, ...)
  let skip_expr = get(a:, '1', '')
  let todo_expr = get(a:, '2', '')
  let quotes = delimitMate#option('quotes')
  let pat = "'"
  let sub = 'quote'
  return s:do_set(pat, sub, quotes, a:setup, a:typed, a:expected, skip_expr, todo_expr)
endfunction
