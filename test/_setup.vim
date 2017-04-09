set bs=2
set hidden
set noshowmode
set whichwrap=[]
set noswapfile
let &hl = join(map(split(&hl, ','), 'substitute(v:val, '':.\+'', ''n'', ''g'')'), ',')
let &rtp = expand('<sfile>:p:h:h') . ',' . &rtp . ',' . expand('<sfile>:p:h:h') . '/after'
let g:delimitMate_pairs = ['()','{}','[]','<>','¿?','¡!',',:']
let g:delimitMate_quotes = ['"', "'", '`', '«', '|']
ru plugin/delimitMate.vim
au VimEnter * echom 'Start test'
