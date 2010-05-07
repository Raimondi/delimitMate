function! delimitMateTests#Main() " {{{
	if !exists("g:delimitMate_testing")
		echoerr "delimitMateTests#Main(): You shouldn't use this function!"
		return
	endif
	nmap <F1> :qall!<CR>
	let b:test_results = {}

	function! SetOptions(list) " {{{
		let b:delimitMate_autoclose = 1
		let b:delimitMate_matchpairs = &matchpairs
		let b:delimitMate_quotes = "\" ' `"
		let b:delimitMate_excluded_regions = ["Comment"]
		silent! unlet b:delimitMate_visual_leader
		let b:delimitMate_expand_space = 0
		let b:delimitMate_expand_cr = 0
		let b:delimitMate_smart_quotes = 1
		let b:delimitMate_apostrophes = ""
		let b:delimitMate_tab2exit = 1
		" Set current test options:
		for str in a:list
			let pair = split(str, ':')
			exec "let b:delimitMate_" . pair[0] . " = " . pair[1]
		endfor
		DelimitMateReload
	endfunction " }}}

	function! Type(name, input, output, options) " {{{
		" Set default options:
		call SetOptions(a:options)
		normal ggVG"_d
		exec "normal i" . a:input . "|\<Esc>"
		call setpos('.', [0, 1, 1, 0])
		let result = len(a:output) != line('$')
		for line in a:output
			if getline('.') != line || result == 1
				let result = 1
				break
			endif
			call setpos('.', [0, line('.') + 1, 1, 0])
		endfor
		let text = getline('.')
		let i = 2
		while i <= line('$')
			let text = text . "<cr>" . getline(i)
			let i += 1
		endwhile
		echom "text: " . text
		if result == 0
			exec "let b:test_results['" . substitute(a:name, "[^a-zA-Z0-9_]", "_", "g") . "'] = 'Passed: ' . text . ' == ' . join(a:output, '<cr>')"
		else
			exec "let b:test_results['" . substitute(a:name, "[^a-zA-Z0-9_]", "_", "g") . "'] = 'Failed: ' . text . ' != ' . join(a:output, '<cr>')"
		endif
	endfunction " }}}

	function! RepeatLast(name, output) " {{{
		normal gg.
		call setpos('.', [0, 1, 1, 0])
		let result = len(a:output) != line('$')
		for line in a:output
			echom line . " vs " . getline('.')
			if getline('.') != line || result == 1
				let result = 1
				break
			endif
			call setpos('.', [0, line('.') + 1, 1, 0])
		endfor
		let text = getline('1')
		let i = 2
		while i <= line('$')
			let text = text . "<cr>" . getline(i)
			let i += 1
		endwhile
		if result == 0
			exec "let b:test_results['" . substitute(a:name, "[^a-zA-Z0-9_]", "_", "g") . "_R'] = 'Passed: ' . text . ' == ' . join(a:output, '<cr>')"
		else
			exec "let b:test_results['" . substitute(a:name, "[^a-zA-Z0-9_]", "_", "g") . "_R'] = 'Failed: ' . text . ' != ' . join(a:output, '<cr>')"
		endif
	endfunction " }}}

	" Test's test {{{
	call Type("Test 1", "123", ["123|"], [])
	call RepeatLast("Test 1", ["123|123|"])

	" Auto-closing parens
	call Type("Autoclose parens", "(", ["(|)"], [])
	call RepeatLast("Autoclose_parens", ["(|)(|)"])

	" Auto-closing quotes
	call Type("Autoclose quotes", '"', ['"|"'], [])
	call RepeatLast("Autoclose_quotes", ['"|""|"'])

	" Deleting parens
	call Type("Delete empty parens", "(\<BS>", ["|"], [])
	call RepeatLast("Delete empty parens", ["||"])

	" Deleting quotes
	call Type("Delete emtpy quotes", "\"\<BS>", ['|'], [])
	call RepeatLast("Delete empty quotes", ["||"])

	" Manual closing parens
	call Type("Manual closing parens", "()", ["(|)"], ["autoclose:0"])
	call RepeatLast("Manual closing parens", ["(|)(|)"])

	" Manual closing quotes
	call Type("Manual closing quotes", "\"\"", ['"|"'], ["autoclose:0"])
	call RepeatLast("Manual closing quotes", ['"|""|"'])

	" Jump over paren
	call Type("Jump over paren", "()", ['()|'], [])
	call RepeatLast("Jump over paren", ['()|()|'])

	" Jump over quote
	call Type("Jump over quote", "\"\"", ['""|'], [])
	call RepeatLast("Jump over quote", ['""|""|'])

	" Apostrophe
	call Type("Apostrophe", "test'", ["test'|"], [])
	call RepeatLast("Apostrophe", ["test'|test'|"])

	" Close quote
	call Type("Close quote", "'\<Del>\<Esc>a'", ["'|'"], [])

	" Closing paren
	call Type("Closing paren", "abcd)", ["abcd)|"], [])

	" <S-Tab>
	call Type("S Tab", "(\<S-Tab>", ["()|"], [])
	call RepeatLast("S Tab", ["()|()|"])

	" Space expansion
	call Type("Space expansion", "(\<Space>", ['( | )'], ['expand_space:1'])
	call RepeatLast("Space expansion", ['( | )( | )'])

	" Car return expansion
	call Type("CR expansion", "(\<CR>", ['(', '|', ')'], ['expand_cr:1'])
	call RepeatLast("CR expansion", ['(', '|', ')(', '|', ')'])

	" Visual wrapping
	call Type("Visual wrapping left paren", "1234\<Esc>v,(", ['123(4)'], ['visual_leader:","'])
	cal RepeatLast("Visual wrapping left paren", ['(1)23(4)'])

	" Visual line wrapping
	call Type("Visual line wrapping left paren", "1234\<Esc>V,(", ['(1234)'], ['visual_leader:","'])
	cal RepeatLast("Visual line wrapping left paren", ['((1234))'])

	" Visual wrapping
	call Type("Visual wrapping right paren", "1234\<Esc>v,)", ['123(4)'], ['visual_leader:","'])
	cal RepeatLast("Visual wrapping right paren", ['(1)23(4)'])

	" Visual line wrapping
	call Type("Visual line wrapping right paren", "1234\<Esc>V,)", ['(1234)'], ['visual_leader:","'])
	cal RepeatLast("Visual line wrapping right paren", ['((1234))'])

	" Visual wrapping
	call Type("Visual wrapping quote", "1234\<Esc>v,\"", ['123"4"'], ['visual_leader:","'])
	cal RepeatLast("Visual wrapping quote", ['"1"23"4"'])

	" Visual line wrapping
	call Type("Visual line wrapping quote", "1234\<Esc>V,\"", ['"1234"'], ['visual_leader:","'])
	cal RepeatLast("Visual line wrapping quote", ['""1234""'])

	" Visual line wrapping empty line
	call Type("Visual line wrapping paren empty line", "\<Esc>V,(", ['()'], ['visual_leader:","'])

	" Visual line wrapping empty line
	call Type("Visual line wrapping quote empty line", "\<Esc>V,\"", ['""'], ['visual_leader:","'])

	" Smart quotes
	call Type("Smart quote alphanumeric", "alpha\"numeric", ['alpha"numeric|'], [])
	call RepeatLast("Smart quote alphanumeric", ['alpha"numeric|alpha"numeric|'])

	" Smart quotes
	call Type("Smart quote escaped", "esc\\\"", ['esc\"|'], [])
	call RepeatLast("Smart quote escaped", ['esc\"|esc\"|'])

	" Smart quotes
	call Type("Smart quote apostrophe", "I'm", ["I'm|"], ['smart_quotes:0'])
	call RepeatLast("Smart quote escaped", ["I'm|I'm|"])

	" Backspace inside space expansion
	call Type("Backspace inside space expansion", "(\<Space>\<BS>", ['(|)'], ['expand_space:1'])
	call RepeatLast("Backspace inside space expansion", ['(|)(|)'])

	" Backspace inside CR expansion
	call Type("Backspace inside CR expansion", "(\<CR>\<BS>", ['(|)'], ['expand_cr:1'])
	call RepeatLast("Backspace inside CR expansion", ['(|)(|)'])

	" FileType event
	let g:delimitMate_excluded_ft = "vim"
	set ft=vim
	call Type("FileType Autoclose parens", "(", ["(|"], [])
	unlet g:delimitMate_excluded_ft
	set ft=

	"}}}

	" Show results: {{{
	normal ggVG"_d
	call append(0, split(string(b:test_results)[1:-2], ', '))
	normal "_ddgg
	let @/ = ".\\+Failed:.*!="
	set nohlsearch
	"syntax match failedLine "^.*Failed.*$" contains=ALL
	"syn match passedLine ".*Passed.*"
	syn match labelPassed "'\@<=.\+\(': 'Passed\)\@="
	syn match labelFailed "'\@<=.\+\(': 'Failed\)\@="
	syn match resultPassed "\('Passed: \)\@<=.\+\('$\)\@="
	syn match resultFailed "\('Failed: \)\@<=.\+\('$\)\@=" contains=resultInequal
	syn match resultInequal "!="

	hi def link labelPassed Comment
	hi def link labelFailed Special
	hi def link resultPassed Ignore
	hi def link resultFailed Boolean
	hi def link resultInequal Error
	" }}}
endfunction " }}}

function! delimitMateTests#Go()
	call system("gvim -c 'call delimitMateTests\#Main()'")
endfunction
" vim:foldmethod=marker:foldcolumn=4
