let g:delimitMate_expand_cr = 1
let g:delimitMate_eol_marker = ';'
call vimtest#StartTap()
call vimtap#Plan(6)
" NOTE: Do not forget to update the plan ^
let g:delimitMate_insert_eol_marker = 0
DelimitMateReload
normal i(
call vimtap#Is(getline(1), '()', 'value = 1, case 1')
%d _
exec "normal i(\<CR>x"
call vimtap#Like(join(getline(1,line('$')), "\<NL>"), '^(\n\s*x\n)$', 'Value = 2, case 2')
let g:delimitMate_insert_eol_marker = 1
DelimitMateReload
%d _
normal i(
call vimtap#Is(getline(1), '();', 'value = 1, case 1')
%d _
exec "normal i(\<CR>x"
call vimtap#Like(join(getline(1,line('$')), "\<NL>"), '^(\n\s*x\n);$', 'Value = 2, case 2')
%d _
let g:delimitMate_insert_eol_marker = 2
DelimitMateReload
normal i(
call vimtap#Is(getline(1), '()', 'Value = 2, case 1')
%d _
exec "normal i(\<CR>x"
call vimtap#Like(join(getline(1,line('$')), "\<NL>"), '^(\n\s*x\n);$', 'Value = 2, case 2')
call vimtest#Quit()

