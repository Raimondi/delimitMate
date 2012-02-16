let g:delimitMate_quotes = '" '' ` ” « |'
let lines = readfile(expand('<sfile>:t:r').'.txt')
call vimtest#StartTap()
let testsnumber = len(filter(copy(lines), 'v:val =~ ''^"'''))
let itemsnumber = len(split(g:delimitMate_quotes, ' '))
call vimtap#Plan(testsnumber * itemsnumber)
let reload = 1
let tcount = 1
for item in lines
  if item =~ '^#\|^\s*$'
    " A comment or empty line.
    continue
  endif
  if item !~ '^"'
    " A command.
    exec item
    call vimtap#Diag(item)
    let reload = 1
    continue
  endif
  if reload
    DelimitMateReload
    call vimtap#Diag('DelimitMateReload')
    let reload = 0
  endif
  let [input, output] = split(item, '"\%(\\.\|[^\\"]\)*"\zs\s*\ze"\%(\\.\|[^\\"]\)*"')
  let quotes = split(g:delimitMate_quotes, '\s')
  for quote in quotes
    let input_q = substitute(input,"'" , escape(escape(quote, '"'), '\'), 'g')
    let output_q = substitute(output,"'" , escape(escape(quote, '"'), '\'), 'g')
    %d
    exec 'normal i'.eval(input_q)."\<Esc>"
    let line = getline('.')
    let passed = line == eval(output_q)
    if quote == '”' || tcount == 31
      call vimtap#Todo(1)
    endif
    if 1 "!vimtap#Skip(1, tcount != 21, 'Test 21')
      call vimtap#Ok(passed, eval(substitute(input_q, '\\<', '<','g')) . ' => ' . line .
            \ (passed ? ' =' : ' !') . '= ' . eval(output_q))
    endif
    let tcount += 1
  endfor
endfor
call vimtest#Quit()
