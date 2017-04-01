" Script variables {{{1
let s:defaults = {}
let s:defaults.enabled = 1
let s:defaults.pairs = ['()', '[]', '{}']
let s:defaults.quotes = ['"', "'", '`']
let s:defaults.debug = 0
let s:defaults.autoclose = 1
let s:defaults.expand_space = 0
let s:defaults.expand_cr = 0
let s:defaults.jump_expansion = 0
let s:defaults.jump_next = 1
let s:defaults.jump_long = 0
let s:defaults.insert_eol_marker = 0
let s:defaults.eol_marker = ';'
let s:defaults.expand_inside_quotes = 0
let s:defaults.smart_pairs = 1
let s:defaults.smart_pairs_extra = []
let s:defaults.balance_pairs = 0
let s:defaults.nesting_quotes = []
let s:defaults.smart_quotes = 1
let s:defaults.smart_quotes_extra = []
let s:defaults.excluded_regions = []

" Set smart_pairs expressions:
let s:exprs = []
call add(s:exprs, 'next_char =~# "\\w"')
call add(s:exprs, 'next_char =~# "[".escape(v:char,"\\^]")."€£$]"')
call add(s:exprs,
      \'next_char =~# "[".escape(join(s:option("quotes"),""),"\\^]")."]"')
call add(s:exprs, 'ahead =~# "^[^[:space:][:punct:]]"')
let s:defaults.smart_pairs_base = s:exprs

" Set smart_quotes expressions:
let s:exprs = []
call add(s:exprs, 'prev_char =~# "\\w"')
call add(s:exprs, 'prev_char =~# "[^[:space:][:punct:]"
      \.escape(join(options.quotes, ""), "\\^[]")."]"')
call add(s:exprs, 'next_char =~# "\\w"')
call add(s:exprs, 'char == "\"" && &filetype =~? "\\<vim\\>"
      \&& line =~ "^\\s*$"')
call add(s:exprs, 'next_char =~# "[^[:space:][:punct:]"
      \. escape(join(options.quotes, ""), "\\^[]")."]"')
" Balance quotes
call add(s:exprs, 'strchars(substitute(substitute(a:info.cur.line,
      \"\\\\.", "", "g"), "[^".escape(char, "\\^[]")."]", "", "g")) % 2')

let s:defaults.smart_quotes_base = s:exprs

unlet s:exprs

let s:info = {}
let s:info.char = ''
let s:info.nesting = 0
let s:info.skip_icp = 0
let s:info.is_ignored_syn = 0
let s:info.template = {}

function! s:debug(debug_level, ...) "{{{1
  if get(b:, 'delimitMate_debug',
        \     get(g:, 'delimitMate_debug',
        \       get(s:defaults, 'debug', 0)))
    let trail = expand('<sfile>')
    let trail = substitute(trail, '\%(\.\.<SNR>\d\+_debug\)\+$', '', '')
    let trail = substitute(trail, '<SNR>\d\+_', '', 'g')
    let trail = substitute(trail, '\.\.', '.', 'g')
    let trail = substitute(trail, '^function\s\+\%(delimitMate\)\?', '', '')
    let message = get(a:, 1, '')
    echom printf('%s: %s', trail, message)
  endif
endfunction
command! -nargs=* -count=3 DMDebug call s:debug(<count>, <args>)

function! s:defaults.consolidate() "{{{1
  3DMDebug 'Consolidate options'
  let g = filter(copy(g:), 'v:key =~# "^delimitMate_"')
  let b = filter(copy(b:), 'v:key =~# "^delimitMate_"')
  call extend(g, b, 'force')
  let short_options = {}
  call map(g, 'extend(short_options,
        \{substitute(v:key, "^delimitMate_", "", ""): v:val}, "force")')
  call extend(short_options, self, 'keep')
  return short_options
endfunction

function! s:info.update() "{{{1
  let self.prev = get(self, 'cur', {})
  let d = {}
  let d.line = getline('.')
  let d.col = col('.')
  let d.lnum = line('.')
  let d.prev_line = line('.') == 1 ? '' : getline(line('.') - 1)
  let d.next_line = line('.') == line('$') ? '' : getline(line('.') + 1)
  let d.ahead = len(d.line) >= d.col ? d.line[d.col - 1 : ] : ''
  let d.behind = d.col >= 2 ? d.line[: d.col - 2] : ''
  let d.prev_char = strcharpart(d.behind, strchars(d.behind) - 1, 1)
  let d.next_char = strcharpart(d.ahead, 0, 1)
  let d.around = d.prev_char . d.next_char
  call extend(d, s:info.template, 'keep')
  1DMDebug printf('lnum: %s, col: %s, prev_char: %s, next_char: %s',
        \ d.lnum, d.col, string(d.prev_char), string(d.next_char))
  1DMDebug printf("behind: %s", d.behind)
  1DMDebug printf("ahead : %s", d.ahead )
  1DMDebug printf("prev_line: %s", d.prev_line)
  1DMDebug printf('cur_line : %s', d.line)
  1DMDebug printf('next_line: %s', d.next_line)
  let self.cur = d
  return d
endfunction

function! s:balance_pairs(pair, info, opts) "{{{1
  let left = strcharpart(a:pair, 0, 1)
  let right = strcharpart(a:pair, 1, 1)
  let pat = '[^' . escape(a:pair, '\^[]') . ']'
  let behind = substitute(a:info.cur.behind, '\\.', '', 'g')
  let behind = matchstr(behind, '['.escape(left, '\^[]').'].*')
  let behind = substitute(behind, pat, '', 'g')
  let ahead = substitute(a:info.cur.ahead, '\\.', '', 'g')
  let ahead = matchstr(ahead, '^.*['.escape(right, '\^[]').']')
  let ahead = substitute(ahead, pat, '', 'g')
  let lefts = 0
  let rights = 0
  for char in split(behind, '\zs')
    if char ==# left
      let lefts += 1
    elseif char ==# right
      let rights += rights < lefts
    endif
  endfor
  let balance1 = lefts - rights
  let lefts = 0
  let rights = 0
  let balance2 = 0
  for char in split(ahead, '\zs')
    if char ==# left
      let lefts += 1
    elseif char ==# right
      let rights += 1
    endif
    if lefts < rights
      let balance2 -= 1
      let lefts = 0
      let rights = 0
    endif
  endfor
  3DMDebug balance1 + balance2
  return balance1 + balance2
endfunction

function! s:info.template.is_escaped(...) "{{{1
  3DMDebug
  let str = a:0 ? a1 : self.behind
  return len(matchstr(str, '\\*$')) % 2
endfunction

function! s:option(name) "{{{1
  3DMDebug
  let opt = get(b:, 'delimitMate_' . a:name,
        \     get(g:, 'delimitMate_' . a:name,
        \       get(s:defaults, a:name, '')))
  3DMDebug printf('%s: %s', a:name, string(opt))
  if type(opt) == 3 || type(opt) == 4
    return copy(opt)
  endif
  return opt
endfunction

function! s:synstack(lnum, col) "{{{1
  3DMDebug
  return map(synstack(a:lnum, a:col), 'synIDattr(v:val, "name")')
        \+ [synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')]
endfunction

function! s:any_is_true(expressions, info, options) "{{{1
  let char = a:info.char
  let info = deepcopy(a:info)
  let options = deepcopy(a:options)
  let line = info.cur.line
  let lnum = info.cur.lnum
  let col = info.cur.col
  let behind = info.cur.behind
  let ahead = info.cur.ahead
  let prev_char = info.cur.prev_char
  let next_char = info.cur.next_char
  let exprs = copy(a:expressions)
  call filter(exprs, 'eval(v:val)')
  3DMDebug string(exprs)
  return !empty(exprs)
endfunction

function! s:rights2jump_pair(char, pair, info, opts, go_next) "{{{1
  " TODO consider escaped characters
  let go_next = a:go_next
        \ && empty(a:info.cur.ahead)
        \ && a:info.cur.next_line =~# '^\s*['.escape(a:char, '[]^-\').']'
  let line = a:info.cur.ahead
  3DMDebug 'ahead: ' . line
  let pair_pat = '[' . escape(a:pair, '[]^\-') . ']'
  let char_pat = '[' . escape(a:char, '[]^\-') . ']'
  let idx = match(line, pair_pat)
  let balance = 0
  while go_next || idx >= 0 && balance >= 0 && line[idx : ] !~# char_pat
    if idx == -1
      let idx = strchars(matchstr(a:info.cur.next_line, '^\s*\S'))
      break
    endif
    if line[idx : ] =~# char_pat
      let balance -= 1
    else
      let balance += 1
    endif
    let idx = match(line, pair_pat, idx + 1)
  endwhile
  3DMDebug 'idx: ' . idx
  return idx + 1
endfunction
    if line[idx : ] =~# char_pat
      let balance -= 1
    else
      let balance += 1
    endif
    let idx = match(line, pair_pat, idx + 1)
  endwhile
  3DMDebug 'idx: ' . idx
  return idx + 1
endfunction

function! s:keys4space(info, opts) "{{{1
  2DMDebug string(a:opts)
  let empty_pair = !empty(filter(copy(a:opts.pairs),
        \'v:val ==# a:info.cur.around'))
  if a:opts.expand_space && empty_pair
    2DMDebug "expand space inside a pair"
    return " \<C-G>U\<Left>"
  endif
  let empty_quotes = !empty(filter(copy(a:opts.quotes),
        \'v:val.v:val ==# a:info.cur.around'))
  if a:opts.expand_space && a:opts.expand_inside_quotes && empty_quotes
    2DMDebug "expand space inside quotes"
    return " \<C-G>U\<Left>"
  endif
  2DMDebug "do nothing"
  return ''
endfunction

function! s:keys4left(char, pair, info, opts) "{{{1
  "| cases  | criteria |  action options             |   action
  "|        | balance  | auto balance back smart     | close back
  "|--------|----------|-----------------------------|------------
  "| any    | any      | 0    0       1    1         | 0     0
  "| any    | any      | 0    0       1    0         | 0     0
  "| (|))   | -1       | 1    1       1    0         | 0     0
  "| (|)    | 0        | 1    1       1    0         | 1     1
  "| ((|)   | 1        | 1    1       1    0         | 1     0
  if !a:opts.autoclose
    2DMDebug "No autoclose"
    return ''
  endif
  let exprs = a:opts.smart_pairs_base + a:opts.smart_pairs_extra
  if a:opts.smart_pairs && s:any_is_true(exprs, a:info, a:opts)
    2DMDebug "smart pairs"
    return ''
  endif
  if a:opts.balance_pairs && s:balance_pairs(a:pair, a:info, a:opts) < 0
    2DMDebug "balance pairs"
    return ''
  endif
  let eol_marker = a:opts.insert_eol_marker == 1
        \&& empty(a:info.cur.ahead) ? a:opts.eol_marker
        \  . "\<C-G>U\<Left>" : ''
  2DMDebug "add right delimiter"
  let jump_back = a:opts.jump_back ? "\<C-G>U\<Left>" : ''
  return "\<C-V>" . strcharpart(a:pair, 1, 1) . eol_marker . jump_back
endfunction

function! s:keys4right(char, pair, info, opts) "{{{1
  "| cases  |       criteria      | action options |   action
  "|        | next prev close bal | next long bal  | jump back
  "|--------|---------------------|----------------|-----------
  "| (|))   | 1    1    1     -1  | 1    1    0    | 1    0
  "| (|)    | 1    1    1      0  | 1    1    0    | 1    0
  "| ((|)   | 1    1    1      1  | 1    1    0    | 1    0
  "| x|)    | 1    0    1     -1  | 1    1    0    | 1    0
  "| (x|)   | 1    0    1      0  | 1    1    0    | 1    0
  "| ((x|)  | 1    0    1      1  | 1    1    1    | 1    0
  "| (|     | 0    1    0      1  | 0    0    1    | 0    1
  "| |x)    | 0    0    1     -1  | 0    1    0    | 1    0
  "| (x|x)) | 0    0    1     -1  | 0    1    0    | 1    0
  "| (x|x)  | 0    0    1      0  | 0    1    0    | 1    0
  "| ((x|x) | 0    0    1      1  | 0    0    1    | 0    1
  "| x|     | 0    0    0      0  | 0    0    0    | 0    0
  "|  (x|   | 0    0    0      1  | 0    0    0    | 0    0
  let previous = strcharpart(a:pair, 0, 1) ==# a:info.cur.prev_char
  let is_cr_exp = a:opts.expand_cr
        \ && empty(a:info.cur.ahead)
        \ && matchstr(a:info.cur.next_line, '^\s*\zs\S') ==# a:char
  let is_space_exp = a:opts.expand_space
        \ && matchstr(a:info.cur.ahead, '^\s\zs\S') ==# a:char
  let next = a:char ==# a:info.cur.next_char || is_cr_exp || is_space_exp
  let balance = s:balance_pairs(a:pair, a:info, a:opts)
        \ - is_cr_exp
  let next_line = a:opts.jump_expansion && a:opts.expand_cr
  let closing = s:rights2jump_pair(a:char, a:pair, a:info, a:opts, next_line)
  let jump_opts = a:opts.jump_next + (a:opts.jump_long * 2)
  2DMDebug 'is_cr_exp: ' . is_cr_exp
  2DMDebug 'is_space_exp: ' . is_space_exp
  2DMDebug 'next: ' . next
  2DMDebug 'previous: ' . previous
  2DMDebug 'closing: ' . closing
  2DMDebug 'balance: ' . balance
  2DMDebug 'next_line: ' . next_line
  2DMDebug 'jump_opts: ' . jump_opts
  if next
    2DMDebug "next"
    if closing && jump_opts && (!a:opts.balance_pairs || balance <= 0)
      2DMDebug "cases: '(|)', '(|))' or '((|)'"
      2DMDebug "cases: 'x|)', '(x|)' or '((x|)'"
      return "\<BS>" . repeat("\<C-G>U\<Right>", closing)
    endif
    2DMDebug "Nothing to do"
    return ''
  endif
  " !next
  if previous
    2DMDebug "!next && previous"
    if (!a:opts.balance_pairs || balance > 0) && a:opts.jump_back
      2DMDebug "case: '(|'"
      return "\<C-G>U\<Left>"
    endif
    2DMDebug "Nothing to do"
    return ''
  endif
  " !next && !previous
  if closing
    2DMDebug "!next && !previous && closing"
    if (!a:opts.balance_pairs || balance <= 0) && jump_opts >= 2
      2DMDebug "case: '(x|x))' or '(x|x)'"
      return "\<BS>" . repeat("\<C-G>U\<Right>", closing)
    elseif (!a:opts.balance_pairs || balance > 0) && a:opts.jump_back
      2DMDebug "case: '((x|x)'"
      return "\<C-G>U\<Left>"
    endif
    2DMDebug "Nothing to do"
    return ''
  endif
  2DMDebug "Nothing to do"
  return ''
endfunction

function! s:keys4quote(char, info, opts) "{{{1
  let quotes_behind = strchars(matchstr(a:info.cur.behind,
        \'['.escape(a:char,  '\^[]').']*$'))
  let quotes_ahead = strchars(matchstr(a:info.cur.ahead,
        \'^['.escape(a:char,  '\^[]').']*'))
  2DMDebug quotes_behind . ' - ' . quotes_ahead
  2DMDebug string(a:opts.nesting_quotes)
  if a:opts.autoclose && index(a:opts.nesting_quotes, a:char) >= 0
        \&& quotes_behind > 1
    let add2right = quotes_ahead > quotes_behind + 1
          \? 0 : quotes_behind - quotes_ahead + 1
    2DMDebug "nesting quotes"
    2DMDebug add2right
    return repeat(a:char, add2right) . repeat("\<C-G>U\<Left>", add2right)
  endif
  if a:info.cur.next_char ==# a:char
    2DMDebug "jump over quote"
    return "\<Del>"
  endif
  if a:info.is_ignored_syn
    return ''
  endif
  let exprs = a:opts.smart_quotes_base + a:opts.smart_quotes_extra
  if a:opts.autoclose && a:opts.smart_quotes
        \&& s:any_is_true(exprs, a:info, a:opts)
    2DMDebug "smart quotes"
    return ''
  endif
  if !a:opts.autoclose && quotes_behind
    2DMDebug "don't autoclose, jump back"
    return "\<C-G>U\<Left>"
  endif
  if !a:opts.autoclose
    2DMDebug "don't autoclose"
    return ''
  endif
  2DMDebug "jump back"
  return a:char . "\<C-G>U\<Left>"
endfunction

function! s:keys4cr(info, opts) "{{{1
  if a:opts.expand_cr
        \&& !empty(filter(copy(a:opts.pairs),
        \  'v:val ==# a:info.prev.around'))
        \|| (a:opts.expand_cr == 2
        \    && !empty(filter(copy(a:opts.pairs),
        \      'strcharpart(v:val, 1, 1) == a:info.cur.next_char')))
    " Empty pair
    2DMDebug "expand CR inside pair"
    let eol_marker = a:opts.insert_eol_marker == 2
          \&& strchars(a:info.cur.ahead) == 1 ? a:opts.eol_marker : ''
    return "0\<C-D>\<Del>x\<C-G>U\<Left>\<BS>\<CR>" . a:info.cur.next_char
          \. "\<Del>" . eol_marker . "\<Up>\<End>\<CR>"
  endif
  if a:opts.expand_cr && a:opts.expand_inside_quotes
        \&& !empty(filter(copy(a:opts.quotes),
        \  'v:val.v:val ==# a:info.prev.around'))
    " Empty pair
    2DMDebug "expand CR inside quotes"
    return "\<Up>\<End>\<CR>"
  endif
  2DMDebug "do nothing"
  return ''
endfunction
" vim: sw=2 et
function! delimitMate#option(name) "{{{1
  return s:option(a:name)
endfunction

function! delimitMate#ex_cmd(global, action) "{{{1
  1DMDebug 'action: ' . a:action . ', scope: ' . (a:global ? 'g:' : 'b:')
  let scope = a:global ? g: : b:
  if a:action ==# 'enable'
    let scope.delimitMate_enabled = 1
  elseif a:action ==# 'disable'
    let scope.delimitMate_enabled = 0
  elseif a:action ==# 'switch'
    let scope.delimitMate_enabled = !s:option('enabled')
  endif
endfunction

function! delimitMate#InsertEnter(...) "{{{1
  1DMDebug
  call s:info.update()
  let s:info.skip_icp = 0
endfunction

function! delimitMate#CursorMovedI(...) "{{{1
  1DMDebug
  call s:info.update()
  let s:info.skip_icp = 0
endfunction

function! delimitMate#InsertCharPre(str) "{{{1
  1DMDebug
  1DMDebug printf('v:char: %s', string(a:str))
  if s:info.skip_icp
    " iabbrev fires this event for every char and the trigger
    1DMDebug "iabbrev expansion running"
    return 0
  endif
  if pumvisible()
    1DMDebug "pumvisible"
    return 0
  endif
  if s:info.nesting
    1DMDebug "nesting"
    let s:info.nesting -= 1
    return 0
  endif
  let s:info.skip_icp = 1
  if !s:option('enabled')
    1DMDebug "disabled"
    return 0
  endif
  let typeahead = ''
  let synstack = join(map(
        \synstack(line('.'), col('.')),
        \'tolower(synIDattr(v:val, "name"))'), ',')
  let s:info.is_ignored_syn = !empty(filter(
        \s:option('excluded_regions'),
        \'stridx(synstack, tolower(v:val)) >= 0'))
  " v:char could be more than one character
  for char in split(a:str, '\zs')
    1DMDebug 'char: ' . char
    let keys = ''
    let s:info.char = char
    let opts = s:defaults.consolidate()
    if s:info.cur.is_escaped()
      1DMDebug "escaped"
      return
    elseif !empty(filter(copy(opts.quotes), 'v:val ==# char'))
      1DMDebug "quote"
      let keys = s:keys4quote(char, s:info, opts)
      let s:info.nesting = strchars(matchstr(keys, '^[^[:cntrl:]]*'))
      let s:info.nesting = s:info.nesting < 3 ? 0 : s:info.nesting
    elseif s:info.is_ignored_syn
      1DMDebug "ignored syn group"
      return
    elseif char == ' '
      1DMDebug "space"
      let keys = s:keys4space(s:info, opts)
    elseif !empty(filter(copy(opts.pairs),
          \'strcharpart(v:val, 0, 1) ==# char'))
      1DMDebug "left delimiter"
      let pair = get(filter(copy(opts.pairs),
            \'strcharpart(v:val, 0, 1) ==# char'), 0, '')
      let keys = s:keys4left(char, pair, s:info, opts)
    elseif !empty(filter(copy(opts.pairs),
          \'strcharpart(v:val, 1, 1) ==# char'))
      let pair = get(filter(copy(opts.pairs),
            \'strcharpart(v:val, 1, 1) ==# char'), 0, '')
      let keys = s:keys4right(char, pair, s:info, opts)
      1DMDebug "right delimiter"
    else
      1DMDebug "just ignore it"
      return 0
    endif
    1DMDebug 'keys: ' . strtrans(keys)
    let typeahead .= keys
  endfor
  if !empty(typeahead)
    1DMDebug "feed typeahead: " . strtrans(typeahead)
    call feedkeys(typeahead, 'tmi')
  endif
endfunction

function! delimitMate#TextChangedI(...) "{{{1
  1DMDebug
  if pumvisible()
    1DMDebug "pumvisible"
    return 0
  endif
  if !s:option('enabled')
    1DMDebug "disabled"
    return
  endif
  if s:info.cur.lnum == s:info.prev.lnum + 1
        \&& s:info.prev.behind ==# s:info.cur.prev_line
        \&& s:info.prev.ahead ==# s:info.cur.ahead
        \&& s:info.cur.behind =~ '^\s*$'
    " CR
    1DMDebug "CR at eol"
    return feedkeys(s:keys4cr(s:info, s:defaults.consolidate()), 'tni')
  endif
  if s:info.cur.lnum == s:info.prev.lnum - 1
        \&& s:info.prev.prev_line ==# s:info.cur.line
        \&& s:info.prev.next_line ==# s:info.cur.next_line
    let pair = filter(s:option('pairs'), 's:info.cur.prev_char
          \. matchstr(s:info.cur.next_line, "^\\s*\\zs\\S") ==# v:val')
    if s:option('expand_cr') && !empty(pair)
      1DMDebug "CR expansion inside pair"
      let spaces = strchars(s:info.cur.next_line, '^\s*')
      return feedkeys(repeat("\<Del>", spaces), 'nti')
    endif
    let quote = filter(s:option('quotes'), 's:info.cur.prev_char
          \. matchstr(s:info.cur.next_line, "^\\s*\\zs\\S") ==# v:val.v:val')
    if s:option('expand_cr') && s:option('expand_inside_quotes')
          \&& !empty(quote)
      1DMDebug "CR expansion inside quotes"
      return feedkeys("\<Del>")
    endif
    1DMDebug "BS at bol"
    return
  endif
  if s:info.cur.lnum != s:info.prev.lnum
    1DMDebug "Cursor changed line"
    return
  endif
  if s:info.prev.col - s:info.cur.col != len(s:info.prev.prev_char)
    1DMDebug "zero or several characters were deleted"
    return
  endif
  if len(s:info.prev.line) == len(s:info.cur.line)
    1DMDebug "Same line length"
    return
  endif
  1DMDebug s:info.prev.around
  let pair = filter(s:option('pairs'), 'v:val ==# (s:info.cur.prev_char
        \ . matchstr(s:info.cur.ahead, "^\\s\\zs\\S"))')
  let quotes = filter(s:option('quotes'),
        \ 'v:val . v:val ==# (s:info.cur.prev_char
        \   . matchstr(s:info.cur.ahead, "^\\s\\zs\\S"))')
  if s:option('expand_space') && (!empty(pair)
        \|| (s:option('expand_inside_quotes') && !empty(quotes)))
    1DMDebug "Space expansion inside pair"
    return feedkeys("\<Del>", 'tni')
  endif
  let pair = filter(s:option('pairs'), 'v:val ==# s:info.prev.around')
  let quote = filter(s:option('quotes'),
        \'v:val . v:val ==# s:info.prev.around')
  if !empty(pair) || !empty(quote)
    1DMDebug "BS inside empty pair or quotes"
    let keys = "\<Del>"
    return feedkeys(keys, 'tni')
  endif
  1DMDebug "Everything else"
  return
endfunction

