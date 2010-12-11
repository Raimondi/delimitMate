function! delimitMateTests#Main()
	if !exists("g:delimitMate_testing")
		echoerr "delimitMateTests#Main(): If you really want to use me, you must set delimitMate_testing to any value."
		return
	elseif g:delimitMate_testing == "fork"
		!gvim -N -u NONE -U NONE -c "set runtimepath+=~/.vim/bundle/pathogen" -c "call pathogen\#runtime_append_all_bundles('bundle','symlinks')" -c "set backspace=eol,start" -c "set background=light" -c "syntax on" -c "let delimitMate_testing = 1" -c "ru autoload/delimitMate.vim" -c "ru autoload/delimitMateTests.vim" -c "ru plugin/delimitMate.vim" -c "call delimitMateTests\#Main()"
		return ""
	endif
	nmap <F1> :qall!<CR>
	let nomore = &more
	set nomore
	let b:test_results = {}
	let b:errors = 0
	let b:corrects = 0
	let b:ignores = 0

	function! SetOptions(list) " {{{
		let b:delimitMate_autoclose = 1
		let b:delimitMate_matchpairs = &matchpairs
		let b:delimitMate_quotes = "\" ' `"
		let b:delimitMate_excluded_regions = "Comment"
		let b:delimitMate_expand_space = 0
		let b:delimitMate_expand_cr = 0
		let b:delimitMate_smart_quotes = 1
		let b:delimitMate_apostrophes = ""
		let b:delimitMate_tab2exit = 1
		" Set current test options:
		for str in a:list
			"echom '1:'.str
			let op = strpart(str, 0, stridx(str,':'))
			"echom op
			let val = strpart(str, stridx(str, ':' ) + 1)
			"echom val
			exec "let b:delimitMate_" . op . " = " . val
		endfor
		DelimitMateReload
	endfunction " }}}

	function! Type(name, input, output, options, ...) " {{{
		if a:0 > 0
			let ignore = a:1
		else
			let ignore = 0
		endif
		if a:input != "\<Esc>."
			" Set default options:
			call SetOptions(a:options)
			let CapR = ""
			normal ggVG"_d
			exec "normal i" . a:input . "|\<Esc>"
		else
			let CapR = "_R"
			normal gg.
		endif

		exec "normal \<Esc>"
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
		if ignore == 1
			let label = "Ignored"
			let result = "?="
			let b:ignores += 1
		elseif result == 0
			let label = "Passed"
			let result = "=="
			let b:corrects += 1
		else
			let label = "Failed"
			let result = "!="
			let b:errors += 1
		endif
		exec "let b:test_results['" .
					\ substitute(a:name, "[^a-zA-Z0-9_]", "_", "g") . CapR . "'] = '" .
					\ label . ": ' . a:input . ' => ' . text . ' " .
					\ result . " ' . join(a:output, '<cr>')"
	endfunction " }}}

	function! RepeatLast(name, output, ...) " {{{
		if a:0 > 0
			let arg1 = a:1
		else
			let arg1 = ''
		endif
		call Type(a:name, "\<Esc>.", a:output, [], arg1)
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
	call Type("Space expansion", "(\<Space>\<BS>", ['(|)'], ['expand_space:1'])
	call RepeatLast("BS with space expansion", ['(|)(|)'])

	" BS with space expansion
	call Type("BS with space expansion", "(\<Space>", ['( | )'], ['expand_space:1'])
	call RepeatLast("Space expansion", ['( | )( | )'])

	" Car return expansion
	call Type("CR expansion", "(\<CR>", ['(', '|', ')'], ['expand_cr:1'])
	call RepeatLast("CR expansion", ['(', '|', ')(', '|', ')'], 1)

	" BS with car return expansion
	call Type("BS with CR expansion", "(\<CR>\<BS>", ['(|)'], ['expand_cr:1'])
	call RepeatLast("BS with CR expansion", ['(|)(|)'], 1)

	" Smart quotes
	call Type("Smart quote alphanumeric", "a\"4", ['a"4|'], [])
	call RepeatLast("Smart quote alphanumeric", ['a"4|a"4|'])

	" Smart quotes
	call Type("Smart quote escaped", "esc\\\"", ['esc\"|'], [])
	call RepeatLast("Smart quote escaped", ['esc\"|esc\"|'])

	" Smart quotes
	call Type("Smart quote apostrophe", "I'm", ["I'm|"], ['smart_quotes:0'])
	call RepeatLast("Smart quote escaped", ["I'm|I'm|"])

	" Backspace inside space expansion
	call Type("Backspace inside space expansion", "(\<Space>\<BS>", ['(|)'], ['expand_space:1'])
	call RepeatLast("Backspace inside space expansion", ['(|)(|)'])

	" <Right-arrow> inserts text
	call Type("<Right-arrow> inserts text", "(he\<Right>\<Space>th\<Right>\<Right>", ['(he) th|'], [])

	" Backspace inside CR expansion
	call Type("Backspace inside CR expansion", "(\<CR>\<BS>", ['(|)'], ['expand_cr:1'])
	call RepeatLast("Backspace inside CR expansion", ['(|)(|)'], 1)

	" FileType event
	let g:delimitMate_excluded_ft = "vim"
	set ft=vim
	call Type("FileType Autoclose parens", "(", ["(|"], [])
	unlet g:delimitMate_excluded_ft
	set ft=

	" Duplicated delimiter after CR
	call Type("Duplicated delimiter after CR", "(\<CR>", ['(', '|)'], [])

	" Deactivate on comments: The first call to a closing delimiter
	" will not work here as expected, but it does in real life tests.
	set ft=vim
	call Type("Deactivate on comments", "\"()``[]''\"\"", ["\"()``[]''\"\"|"], ["autoclose:0"], 1)
	set ft=

	" Deactivate parens on comments: The first call to a closing delimiter
	" will not work here as expected, but it does in real life tests.
	set ft=vim
	call Type("Deactivate parens on comments", "\"()[]", ["\"()[]|"], ["autoclose:0"], 1)
	set ft=

	" Deactivate quotes on comments: See previous note.
	set ft=vim
	call Type("Deactivate parens on comments", "\"(`", ["\"(``|"], [], 1)
	set ft=

	" Manual close at start of line
	call Type("Manual close at start of line", "m)\<Left>\<Left>)", [')|m)'], ["autoclose:0"])

	" Use | in quotes
	call Type("Use <Bar> in quotes", "\<Bar>bars", ['|bars|'], ["quotes:'|'"])

	" Use | in matchpairs
	call Type("Use <Bar> in matchpairs", "\<Bar>bars", ['|bars|$$'], ["matchpairs:'|:$'"])

	"}}}

	" Show results: {{{
	normal ggVG"_d
	call append(0, split(string(b:test_results)[1:-2], ', '))
	call append(0, "*TESTS REPORT: " . b:errors . " failed, " . b:corrects . " passed and " . b:ignores . " ignored.")
	normal "_ddgg
	let @/ = ".\\+Failed:.*!="
	2,$sort /^.\+':/
	normal gg
	exec search('Ignored:','nW').",$sort! /^.\\+':/"
	set nohlsearch
	syn match lineIgnored ".*Ignored.*"
	syn match labelPassed "'\@<=.\+\(': 'Passed\)\@="
	syn match labelFailed "'\@<=.\+\(': 'Failed\)\@="
	syn match resultPassed "\('Passed: \)\@<=.\+\('$\)\@="
	syn match resultFailed "\('Failed: \)\@<=.\+\('$\)\@=" contains=resultInequal
	syn match resultIgnored "\('Ignored: \)\@<=.\+\('$\)\@="
	syn match resultInequal "!="
	syn match resultSummary "^\*.\+" contains=resultSummaryNumber
	syn match resultSummaryNumber "[1-9][0-9]* failed*" contained

	hi def link lineIgnored Ignore
	hi def link labelPassed Comment
	hi def link labelFailed Special
	hi def link resultPassed Ignore
	hi def link resultFailed Boolean
	hi def link resultInequal Error
	hi def link resultSummary SpecialComment
	hi def link resultSummaryNumber Error
	" }}}

	let &more = nomore
endfunction
" vim:foldmethod=marker:foldcolumn=4

