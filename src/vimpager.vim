function! vimpager#Init(opts)
    let g:vimpager = { 'enabled': 1 }

    augroup vimpager

    autocmd!

    " can't pass a:opts in autocmd
    let s:opts = a:opts

    " can't use VimEnter because that fires after first file is read
    autocmd BufReadPre,StdinReadPre * call s:SetOptions(s:opts)

    autocmd BufReadPre,StdinReadPre * runtime macros/less.vim

    let g:__save_hidden = &hidden
    set nohidden
    autocmd VimEnter * let &hidden = __save_hidden | unlet! __save_hidden

    augroup end

    set bg=dark
    syntax enable
endfunction

function! s:SetOptions(opts)
    if exists('s:options_set') && s:options_set ==# 1
        return
    endif

    let s:options_set = 1

    if !exists('g:less')
        let g:less = {}
    endif

    if !exists('g:less.enabled')
        if exists('g:vimpager_less_mode')
            let g:less.enabled = g:vimpager_less_mode
        endif
    endif

    if !exists('g:less.scrolloff')
        if exists('g:vimpager.scrolloff')
            g:less.scrolloff = g:vimpager.scrolloff
        elseif exists('g:vimpager_scrolloff')
            g:less.scrolloff = g:vimpager_scrolloff
        endif
    endif

    " process options
    if exists('a:opts.line_numbers')
        let g:less.number = a:opts.line_numbers
    endif

    " disable surround plugin
    let g:loaded_surround = 1
endfunction

function! vimpager#SetupAnsiEsc()
    autocmd vimpager BufReadPost,StdinReadPost * call s:DoAnsiEsc()
endfunction

function! s:DoAnsiEsc()
    AnsiEsc
    call s:ConcealRetab()
    call s:CheckModelineFiletype()
endfunction

function! s:ConcealRetab()
    let current_cursor = getpos('.')

    call cursor(1,1)

    let lnum = search('\t')

    while lnum !=# 0
        let newline = ''
        let column  = 0
        let linepos = 1
	let line    = getline('.')

        while linepos <=# len(line)
            if line[linepos-1] ==# "\t"
                let spaces   = 8 - (column % 8)
                let column  += spaces

                let newline .= repeat(' ', spaces)
            else
                let concealed = synconcealed(lnum, linepos)

                if concealed[0] ==# 0 || (concealed[1] !=# '' && (&conceallevel ==# 1 || &conceallevel ==# 2))
                    let column += 1
                endif

                let newline .= line[linepos-1]
            endif

            let linepos += 1
        endwhile

        call setline(lnum, newline)

        let lnum = search('\t')
    endwhile

    call setpos('.', current_cursor)
endfunction

function! s:CheckModelineFiletype()
	redir => ft_set_from
	    silent! verb set ft
	    silent! verb set syntax
	redir END

	if ft_set_from =~# 'Last set from modeline\>'
	    execute 'setlocal ft=' . &ft
	    execute 'setlocal syntax=' . &syntax
	endif
endfunction
