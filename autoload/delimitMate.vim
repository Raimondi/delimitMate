" Script variables {{{1
let s:defaults = {}
let s:defaults.delimitMate_pairs = ['()', '[]', '{}']
let s:defaults.delimitMate_quotes = ['"', "'", '`']
let s:defaults.delimitMate_enabled = 1
let s:defaults.delimitMate_autoclose = 1
let s:defaults.delimitMate_expand_space = 0
let s:defaults.delimitMate_expand_cr = 0
let s:defaults.delimitMate_jump_expansion = 0
let s:defaults.delimitMate_insert_eol_marker = 0
let s:defaults.delimitMate_eol_marker = ';'
let s:defaults.delimitMate_expand_inside_quotes = 0
let s:defaults.delimitMate_smart_pairs = 1
let s:defaults.delimitMate_smart_pairs_extra = []
let s:defaults.delimitMate_balance_pairs = 0
let s:defaults.delimitMate_nesting_quotes = []
let s:defaults.delimitMate_smart_quotes = 1
let s:defaults.delimitMate_smart_quotes_extra = []
let s:defaults.delimitMate_excluded_regions = ['String', 'Comment']

" Set smart_pairs expressions:
let s:exprs = []
call add(s:exprs, 'next_char =~# "\\w"')
call add(s:exprs, 'next_char =~# "[".escape(v:char,"\\^]")."€£$]"')
call add(s:exprs, 'ahead =~# "^[^[:space:][:punct:]]"')
let s:defaults.delimitMate_smart_pairs_base = s:exprs

" Set smart_quotes expressions:
let s:exprs = []
call add(s:exprs, 'prev_char =~# "\\w"')
call add(s:exprs, 'prev_char =~# "[^[:space:][:punct]".escape(join(options.quotes, ""), "\\^[]")."]"')
call add(s:exprs, 'next_char =~# "\\w"')
call add(s:exprs, 'char == "\"" && &filetype =~? "\\<vim\\>" && line =~ "^\\s*$"')
call add(s:exprs, 'next_char =~# "[^[:space:][:punct]".escape(join(options.quotes, ""), "\\^[]")."]"')
" Balance quotes
call add(s:exprs, 'strchars(substitute(substitute(a:info.cur.line, "\\\\.", "", "g"), "[^".escape(char, "\\^[]")."]", "", "g")) % 2')

let s:defaults.delimitMate_smart_quotes_base = s:exprs

unlet s:exprs

let s:info = {}
let s:info.char = ''
let s:info.nesting = 0
let s:info.template = {}

function! s:defaults.consolidate() "{{{1
  let g = filter(copy(g:), 'v:key =~# "^delimitMate_"')
  let b = filter(copy(b:), 'v:key =~# "^delimitMate_"')
  call extend(g, b, 'force')
  call extend(g, self, 'keep')
  let short_options = {}
  call map(g, 'extend(short_options, {substitute(v:key, "^delimitMate_", "", ""): v:val}, "force")')
  return short_options
endfunction

function! s:balance_pairs(pair, info, opts) "{{{1
  let left = strcharpart(a:pair, 0, 1)
  let right = strcharpart(a:pair, 1, 1)
  let behind = matchstr(a:info.cur.behind, '['.escape(left, '\^[]').'].*')
  let ahead = matchstr(a:info.cur.ahead, '^.*['.escape(right, '\^[]').']')
  let pat = '[^' . escape(a:pair, '\^[]') . ']'
  let behind = substitute(behind, pat, '', 'g')
  let ahead = substitute(ahead, pat, '', 'g')
  let lefts = 0
  let rights = 0
  for c in split(behind, '\zs')
    if c ==# left
      let lefts += 1
    elseif c ==# right
      let rights += rights < lefts
    endif
  endfor
  let lefts += count(split(ahead, '\zs'), left)
  let rights += count(split(ahead, '\zs'), right)
  return lefts - rights
endfunction

function! s:info.template.is_escaped(...) "{{{1
  let str = a:0 ? a1 : self.behind
  return len(matchstr(str, '\\*$')) % 2
endfunction

function! s:option(name, ...) "{{{1
  if a:0
    let opt = get(a:1, 'delimitMate_' . a:name, '')
  else
    let opt = get(b:, 'delimitMate_' . a:name,
          \     get(g:, 'delimitMate_' . a:name,
          \       get(s:defaults, 'delimitMate_' . a:name, '')))
  endif
  if type(opt) == v:t_list
    return copy(opt)
  endif
  return opt
endfunction

function! s:synstack(lnum, col) "{{{1
  return map(synstack(a:lnum, a:col), 'synIDattr(v:val, "name")') + [synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')]
endfunction

function! s:get_info(...) "{{{1
  if a:0
    let d = a:1
  else
    let d = {}
    let d.line = getline('.')
    let d.col = col('.')
    let d.lnum = line('.')
    let d.prev_line = line('.') == 1 ? '' : getline(line('.') - 1)
    let d.next_line = line('.') == line('$') ? '' : getline(line('.') + 1)
  endif
  let d.ahead = len(d.line) >= d.col ? d.line[d.col - 1 : ] : ''
  let d.behind = d.col >= 2 ? d.line[: d.col - 2] : ''
  let d.p_char = strcharpart(d.behind, strchars(d.behind) - 1, 1)
  let d.n_char = strcharpart(d.ahead, 0, 1)
  let d.around = d.p_char . d.n_char
  call extend(d, s:info.template, 'keep')
  echom string(d)
  return d
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
  let prev_char = info.cur.p_char
  let next_char = info.cur.n_char
  let exprs = copy(a:expressions)
  call filter(exprs, 'eval(v:val)')
  echom 'any_is_true: ' . string(exprs)
  return !empty(exprs)
endfunction

function! delimitMate#option(name) "{{{1
  return s:option(a:name)
endfunction

function! delimitMate#ex_cmd(global, action) "{{{1
  let scope = a:global ? g: : b:
  if a:action ==# 'enable'
    let scope.delimitMate_enabled = 1
  elseif a:action ==# 'disable'
    let scope.delimitMate_enabled = 0
  elseif a:action ==# 'switch'
    let scope.delimitMate_enabled = !s:option('enabled')
  endif
endfunction

function! delimitMate#CursorMovedI(...) "{{{1
  let s:info.prev = s:info.cur
  let s:info.cur = call('s:get_info', a:000)
  let s:info.skip_icp = 0
  echom 'INFO: ' . string(s:info)
  echom 'CMI: ' . s:info.prev.line
endfunction

function! delimitMate#InsertEnter(...) "{{{1
  let s:info.cur = call('s:get_info', a:000)
  let s:info.prev = {}
  let s:info.skip_icp = 0
  echom 'IE: ' . s:info.cur.line
endfunction

function! delimitMate#TextChangedI(...) "{{{1
  echom 'TCI: ' . s:info.cur.line
  if !s:option('enabled')
    echom 21
    return
  endif
  if s:info.cur.lnum == s:info.prev.lnum + 1
        \&& s:info.prev.behind ==# s:info.cur.prev_line
        \&& s:info.prev.ahead ==# s:info.cur.ahead
        \&& s:info.cur.behind =~ '^\s*$'
    " CR
    echom 22
    return feedkeys(s:keys4cr(s:info, s:defaults.consolidate()), 'tni')
  endif
  if s:info.cur.lnum == s:info.prev.lnum - 1
        \&& s:info.prev.prev_line ==# s:info.cur.line
        \&& s:info.prev.next_line ==# s:info.cur.next_line
    let pair = filter(s:option('pairs'), 's:info.cur.p_char . matchstr(s:info.cur.next_line, "^\\s*\\zs\\S") ==# v:val')
    echom 23
    if s:option('expand_cr') && !empty(pair)
      echom "23.1"
      let spaces = strchars(s:info.cur.next_line, '^\s*')
      return feedkeys(repeat("\<Del>", spaces), 'nti')
    endif
    let quote = filter(s:option('quotes'), 's:info.cur.p_char . matchstr(s:info.cur.next_line, "^\\s*\\zs\\S") ==# v:val.v:val')
    if s:option('expand_cr') && s:option('expand_inside_quotes') && !empty(quote)
      echom "23.2"
      return feedkeys("\<Del>")
    endif
    return
  endif
  if s:info.cur.lnum != s:info.prev.lnum
    echom 24
    return
  endif
  if s:info.prev.col - s:info.cur.col != len(s:info.prev.p_char)
    echom 25
    return
  endif
  if len(s:info.prev.line) == len(s:info.cur.line)
    echom 26
    return
  endif
  echom s:info.prev.around
  let pair = filter(s:option('pairs'), 'v:val ==# (s:info.cur.p_char . matchstr(s:info.cur.ahead, "^\\s\\zs\\S"))')
  let quotes = filter(s:option('quotes'), 'v:val . v:val ==# (s:info.cur.p_char . matchstr(s:info.cur.ahead, "^\\s\\zs\\S"))')
  if s:option('expand_space') && (!empty(pair) || (s:option('expand_inside_quotes') && !empty(quotes)))
    echom 27
    return feedkeys("\<Del>", 'tni')
  endif
  let pair = filter(s:option('pairs'), 'v:val ==# s:info.prev.around')
  let quote = filter(s:option('quotes'), 'v:val . v:val ==# s:info.prev.around')
  if empty(pair) && empty(quote)
    echom 28
    return
  endif
  echom 29
  let keys = "\<Del>"
  call feedkeys(keys, 'tni')
endfunction

" vim: sw=2 et
function! delimitMate#InsertCharPre(str) "{{{1
  if s:info.skip_icp
    " iabbrev fires this event for every char and the trigger
    echom 01
    return 0
  endif
  if s:info.nesting
    echom 02
    let s:info.nesting -= 1
    return 0
  endif
  let s:info.skip_icp = 1
  if !s:option('enabled')
    echom 03
    return 0
  endif
  let synstack = join(map(synstack(line('.'), col('.')), 'tolower(synIDattr(v:val, "name"))'), ',')
  if !empty(filter(s:option('excluded_regions'), 'stridx(synstack, tolower(v:val)) >= 0'))
    echom 04
    return 0
  endif
  return map(split(a:str, '\zs'), 's:handle_vchar(v:val)')
endfunction

function! s:handle_vchar(str) "{{{1
  echom 'ICP ' . string(a:str) . ': ' . get(s:info, 'cur', {'line': ''}).line
  let s:info.char = a:str
  let opts = s:defaults.consolidate()
  if s:info.cur.is_escaped()
    echom 12
    return
  elseif a:str == ' '
    echom 13
    let keys = s:keys4space(s:info, opts)
  elseif a:str == "\<C-]>"
    let prev_line = line('.') == 1 ? '' : getline(line('.') - 1)
    let next_line = line('.') == line('$') ? '' : getline(line('.') + 1)
    echom 14
    let keys = s:keys4cr(prev_line, next_line, s:info, opts)
  elseif !empty(filter(copy(opts.quotes), 'v:val ==# a:str'))
    echom 15
    let keys = s:keys4quote(a:str, s:info, opts)
    let s:info.nesting = strchars(matchstr(keys, '^[^[:cntrl:]]*'))
    let s:info.nesting = s:info.nesting < 3 ? 0 : s:info.nesting
  elseif !empty(filter(copy(opts.pairs), 'strcharpart(v:val, 0, 1) ==# a:str'))
    echom 16
    let pair = get(filter(copy(opts.pairs), 'strcharpart(v:val, 0, 1) ==# a:str'), 0, '')
    let keys = s:keys4left(a:str, pair, s:info, opts)
    "echom strtrans(keys)
    "echom string(pair)
  elseif !empty(filter(copy(opts.pairs), 'strcharpart(v:val, 1, 1) ==# a:str'))
    let pair = get(filter(copy(opts.pairs), 'strcharpart(v:val, 1, 1) ==# a:str'), 0, '')
    let keys = s:keys4right(a:str, pair, s:info, opts)
    echom 17
    echom keys
  else
    echom 18
    return 0
  endif
  return feedkeys(keys, 'mti')
endfunction

function! s:keys4space(info, opts) "{{{1
  echom string(a:opts)
  let empty_pair = !empty(filter(copy(a:opts.pairs), 'v:val ==# a:info.cur.around'))
  if a:opts.expand_space && empty_pair
    echom 61
    return " \<C-G>U\<Left>"
  endif
  let empty_quotes = !empty(filter(copy(a:opts.quotes), 'v:val.v:val ==# a:info.cur.around'))
  if a:opts.expand_space && a:opts.expand_inside_quotes && empty_quotes
    echom 62
    return " \<C-G>U\<Left>"
  endif
  echom 69
  return ''
endfunction

function! s:keys4left(char, pair, info, opts) "{{{1
  if !a:opts.autoclose
    echom 31
    return ''
  endif
  let exprs = a:opts.smart_pairs_base + a:opts.smart_pairs_extra
  if a:opts.smart_pairs && s:any_is_true(exprs, a:info, a:opts)
    echom 32
    return ''
  endif
  if a:opts.balance_pairs && s:balance_pairs(a:pair, a:info, a:opts) < 0
    echom 33
    return ''
  endif
  let eol_marker = a:opts.insert_eol_marker == 1 && empty(a:info.cur.ahead) ? a:opts.eol_marker . "\<C-G>U\<Left>" : ''
  echom 34
  return strcharpart(a:pair, 1, 1) . eol_marker . "\<C-G>U\<Left>"
endfunction

function! s:keys4right(char, pair, info, opts) "{{{1
  if a:opts.jump_expansion
    echom 40
    let around = matchstr(a:info.cur.prev_line, "\\S$") . matchstr(a:info.cur.next_line, "^\\s*\zs\\S")
    if  empty(a:info.cur.ahead) && a:char ==# matchstr(a:info.cur.next_line, "^\\s*\\zs\\S")
      let rights = strchars(matchstr(a:info.cur.next_line, '^\s*')) + 2
      echom "40.1"
      return "\<Esc>s" . repeat("\<Right>", rights)
    endif
  endif
  if !a:opts.autoclose
    if s:info.cur.around == a:pair
      echom 41
      return "\<Del>"
    elseif s:info.cur.p_char == strcharpart(a:pair, 0, 1)
      echom 42
      return "\<C-G>U\<Left>"
    endif
    echom 43
    return ""
  endif
  if strcharpart(a:info.cur.line[a:info.cur.col - 1 :], 0, 1) ==# a:char
    echom 44
    return "\<Del>"
  endif
  if a:opts.expand_space && a:opts.jump_expansion
        \ && matchstr(a:info.cur.ahead, '^ ['.escape(a:char, '\^[]').']') ==# ' ' . a:char
    echom 45
    return "\<Del>\<Del>\<C-G>U\<Left> \<C-G>U\<Right>"
  endif
  echom 49
  return ''
endfunction

function! s:keys4quote(char, info, opts) "{{{1
  let quotes_behind = strchars(matchstr(a:info.cur.behind, '['.escape(a:char,  '\^[]').']*$'))
  let quotes_ahead = strchars(matchstr(a:info.cur.ahead, '^['.escape(a:char,  '\^[]').']*'))
  echom 'k4q: ' quotes_behind . ' - ' . quotes_ahead
  echom string(a:opts.nesting_quotes)
  if a:opts.autoclose && index(a:opts.nesting_quotes, a:char) >= 0
        \&& quotes_behind > 1
    let add2right = quotes_ahead > quotes_behind + 1 ? 0 : quotes_behind - quotes_ahead + 1
    echom 51
    echom add2right
    return repeat(a:char, add2right) . repeat("\<C-G>U\<Left>", add2right)
  endif
  if a:info.cur.n_char ==# a:char
    echom 53
    return "\<Del>"
  endif
  let exprs = a:opts.smart_quotes_base + a:opts.smart_quotes_extra
  if a:opts.autoclose && a:opts.smart_quotes
        \&& s:any_is_true(exprs, a:info, a:opts)
    echom 52
    return ''
  endif
  if !a:opts.autoclose && quotes_behind
    echom 54
    return "\<Left>"
  endif
  if !a:opts.autoclose
    echom 55
    return ''
  endif
  echom 59
  return a:char . "\<C-G>U\<Left>"
endfunction

function! s:keys4cr(info, opts) "{{{1
  if a:opts.expand_cr
        \&& !empty(filter(copy(a:opts.pairs), 'v:val ==# a:info.prev.around'))
        \|| (a:opts.expand_cr == 2 && !empty(filter(copy(a:opts.pairs), 'strcharpart(v:val, 1, 1) == a:info.cur.n_char')))
    " Empty pair
    echom 71
    let right = a:info.cur.line
    let rm_spaces = empty(a:info.cur.behind) ? '' : "\<C-U>"
    let eol_marker = a:opts.insert_eol_marker == 2 && strchars(a:info.cur.ahead) == 1 ? a:opts.eol_marker : ''
    return rm_spaces . "\<Del>x\<C-G>U\<Left>\<BS>\<CR>" . a:info.cur.n_char . "\<Del>" . eol_marker . "\<Up>\<End>\<CR>"
  endif
  if a:opts.expand_cr && a:opts.expand_inside_quotes
        \&& !empty(filter(copy(a:opts.quotes), 'v:val.v:val ==# a:info.prev.around'))
    " Empty pair
    echom 72
    return "\<Up>\<End>\<CR>"
  endif
  echom 79
  return ''
endfunction
" vim: sw=2 et
