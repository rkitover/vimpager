function! vimpager#Init()
    let g:vimpager=1

    nnoremap ,v :call <SID>LoadLess()<CR>

    " disable surround plugin
    let g:loaded_surround = 1

    let g:__save_hidden = &hidden
    set nohidden
    autocmd VimEnter * let &hidden = __save_hidden

    autocmd BufNewFile,BufReadPost * set buftype=nofile modifiable noreadonly

    autocmd VimEnter * call cursor(1, 1)

    set bg=dark
    syntax on
endfunction

function! s:LoadLess()
    let jump = 5
    if exists('g:vimpager_scrolloff')
        let jump = g:vimpager_scrolloff
    endif

    let curpos = getpos('.')

    if winline() < jump
        call setpos('.', [curpos[0], curpos[1] + (jump - winline()) + 1, curpos[2], curpos[3]])
    elseif (winheight(0) - winline()) < jump
        call setpos('.', [curpos[0], curpos[1] - (jump - (winheight(0) - winline())) - 1 , curpos[2], curpos[3]])
    endif

    runtime macros/less.vim

    redraw
    echomsg 'Less Mode Enabled'
endfunction

function! vimpager#SetupAnsiEsc()
    autocmd VimEnter * call s:DoAnsiEsc()
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
