let s:defaults = {}
let s:defaults.delimitMate_pairs = ['()', '[]', '{}']
let s:defaults.delimitMate_quotes = ['"', "'", '`']
let s:defaults.delimitMate_enabled = 1
let s:defaults.delimitMate_autoclose = 1
let s:defaults.delimitMate_expand_space = 0
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
call add(s:exprs, 'next_char =~# "[^[:space:][:punct]".escape(join(options.quotes, ""), "\\^[]")."]"')
" Balance quotes
call add(s:exprs, 'strchars(substitute(substitute(a:info.cur.text, "\\\\.", "", "g"), "[^".escape(char, "\\^[]")."]", "", "g")) % 2')

let s:defaults.delimitMate_smart_quotes_base = s:exprs

unlet s:exprs

function! s:defaults.consolidate()
  let g = filter(copy(g:), 'v:key =~# "^delimitMate_"')
  let b = filter(copy(b:), 'v:key =~# "^delimitMate_"')
  call extend(g, b, 'force')
  call extend(g, self, 'keep')
  let short_options = {}
  call map(g, 'extend(short_options, {substitute(v:key, "^delimitMate_", "", ""): v:val}, "force")')
  return short_options
endfunction

function! s:balance_pairs(pair, info, opts)
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

let s:info = {}
let s:info.char = ''
let s:info.template = {}

function! s:info.template.is_escaped(...)
  let str = a:0 ? a1 : self.behind
  return len(matchstr(str, '\\*$')) % 2
endfunction

function! s:option(name, ...)
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

function! delimitMate#option(name)
  return s:option(a:name)
endfunction

function! s:synstack(lnum, col)
  return map(synstack(a:lnum, a:col), 'synIDattr(v:val, "name")') + [synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')]
endfunction

function! delimitMate#ex_cmd(global, action)
  let scope = a:global ? g: : b:
  if a:action ==# 'enable'
    let scope.delimitMate_enabled = 1
  elseif a:action ==# 'disable'
    let scope.delimitMate_enabled = 0
  elseif a:action ==# 'switch'
    let scope.delimitMate_enabled = !s:option('enabled')
  endif
endfunction

function! delimitMate#InsertCharPre(str)
  if s:info.skip_icp
    " iabbrev fires this event for every char and the trigger
    echom 11
    return 0
  endif
  let s:info.skip_icp = 1
  if !s:option('enabled')
    echom 12
    return 0
  endif
  if !empty(filter(s:option('excluded_regions'), 'index(s:synstack(line("."), col(".")), v:val) >= 0'))
    echom 13
    return 0
  endif
  return map(split(a:str, '\zs'), 's:handle_vchar(v:val)')
endfunction

function! s:handle_vchar(str)
  echom 'ICP ' . string(a:str) . ': ' . get(s:info, 'cur', {'text': ''}).text
  let s:info.char = a:str
  let opts = s:defaults.consolidate()
  if s:info.cur.is_escaped()
    echom 12
    return
  elseif a:str == ' '
    echom 13
    let keys = s:keys4space(s:info, opts)
  elseif a:str == "\<C-]>"
    echom 14
    return 0
  elseif !empty(filter(copy(opts.quotes), 'v:val ==# a:str'))
    echom 15
    let keys = s:keys4quote(a:str, s:info, opts)
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

function! s:keys4space(info, opts)
  if !a:opts.expand_space || empty(filter(copy(a:opts.pairs), 'v:val ==# a:info.cur.around'))
    return ''
  endif
  return " \<C-G>U\<Left>"
endfunction

function! s:keys4left(char, pair, info, opts)
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
  echom 34
  return strcharpart(a:pair, 1, 1) . "\<C-G>U\<Left>"
endfunction

function! s:keys4right(char, pair, info, opts)
  if !a:opts.autoclose
    if s:info.cur.around == a:pair
      return "\<Del>"
    elseif s:info.cur.p_char == strcharpart(a:pair, 0, 1)
      return "\<C-G>U\<Left>"
    endif
    return ""
  endif
  if strcharpart(a:info.cur.text[a:info.cur.col - 1 :], 0, 1) ==# a:char
    echom 41
    return "\<Del>"
  endif
  return ''
endfunction

function! s:keys4quote(char, info, opts)
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

function! s:get_info(...)
  if a:0
    let d = a:1
  else
    let d = {}
    let d.text = getline('.')
    let d.col = col('.')
    let d.line = line('.')
  endif
  let d.ahead = len(d.text) >= d.col ? d.text[d.col - 1 : ] : ''
  let d.behind = d.col >= 2 ? d.text[: d.col - 2] : ''
  let d.p_char = strcharpart(d.behind, strchars(d.behind) - 1, 1)
  let d.n_char = strcharpart(d.ahead, 0, 1)
  let d.around = d.p_char . d.n_char
  call extend(d, s:info.template, 'keep')
  echom string(d)
  return d
endfunction

function! s:any_is_true(expressions, info, options)
  let char = a:info.char
  let info = deepcopy(a:info)
  let options = deepcopy(a:options)
  let line = info.cur.text
  let linenr = info.cur.line
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

function! delimitMate#CursorMovedI(...)
  let s:info.prev = s:info.cur
  let s:info.cur = call('s:get_info', a:000)
  let s:info.skip_icp = 0
  echom 'INFO: ' . string(s:info)
  echom 'CMI: ' . s:info.prev.text
endfunction

function! delimitMate#InsertEnter(...)
  let s:info.cur = call('s:get_info', a:000)
  let s:info.prev = {}
  let s:info.skip_icp = 0
  echom 'IE: ' . s:info.cur.text
endfunction

function! delimitMate#TextChangedI(...)
  echom 'TCI: ' . s:info.cur.text
  call s:is_bs()
endfunction

function! s:is_bs()
  if !s:option('enabled')
    echom 21
    return
  endif
  if s:info.cur.line != s:info.prev.line
    echom 22
    return
  endif
  if s:info.prev.col - s:info.cur.col != len(s:info.prev.p_char)
    echom 23
    return
  endif
  if len(s:info.prev.text) == len(s:info.cur.text)
    echom 24
    return
  endif
  echom s:info.prev.around
  let pair = filter(s:option('pairs'), 'v:val ==# (s:info.cur.p_char . matchstr(s:info.cur.ahead, "^\\s\\zs\\S"))')
  if s:option('expand_space') && !empty(pair)
    echom 25
    return feedkeys("\<Del>", 'tni')
  endif
  let pair = filter(s:option('pairs'), 'v:val ==# s:info.prev.around')
  let quote = filter(s:option('quotes'), 'v:val . v:val ==# s:info.prev.around')
  if empty(pair) && empty(quote)
    echom 26
    return
  endif
  let keys = "\<Del>"
  call feedkeys(keys, 'tni')
endfunction

" vim: sw=2 et
