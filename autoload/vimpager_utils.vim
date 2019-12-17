scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! vimpager_utils#StatusLine(opts)
    redir => pos
    silent! file
    redir END
    " remove trailing newline
    let pos = substitute(pos, '[\r\n]\+', '', 'g')
    " remove any beginning quotes
    let pos = substitute(pos, '^"*', '', '')
    " remove tmp dir path
    if exists('a:opts.tmp_dir')
        let pos = substitute(pos, '^/*\V' . a:opts.tmp_dir . '\m/*', '', '')
        let pos = substitute(pos, '^/*\V' . resolve(a:opts.tmp_dir) . '\m/*', '', '')
    else
        let pos = substitute(pos, '^.*/', '', '')
    endif
    " remove possible [readonly] or [Modified] tag
    let pos = substitute(pos, '\[\%(readonly\|Modified\)\]\s\+', '', '')
    " remove closing quote (must match localized text)
    let pos = substitute(pos, '"\(\s\+\d*\s*\D\+\s\d\+\s\D\+\s\d\+\)', '\1', '')
    " urldecode
    let pos = substitute(pos, '%\(\x\x\)', '\=nr2char("0x" . submatch(1))', 'g')
    " add help message
    let leader = exists('g:mapleader') ? g:mapleader : '\'
    let pos .= "  [ Press '".leader."h' for HELP ]"
    " Trim the status line to fit the window width.
    let width = &columns - 12
    let pos = len(pos) >= width ? '<' . pos[-width+1:-1] : pos
    highlight VimpagerStatusLine ctermbg=NONE ctermfg=DarkMagenta guibg=NONE guifg=DarkMagenta
    echohl VimpagerStatusLine
    redraw
    unsilent echo pos
    echohl None
endfunction

function! vimpager_utils#DoAnsiEsc()
    if exists(':AnsiEsc') !=# 2
        return
    endif

    if vimpager_utils#FtSetFromModeline() && !vimpager_utils#IsDiff()
        return
    endif

    AnsiEsc
    call vimpager_utils#ConcealRetab()

    " if hidden is not set, we have to toggle AnsiEsc when entering/leaving buffer
    if !&hidden
        execute 'autocmd! vimpager_process BufWinLeave ' . expand('%') . ' AnsiEsc'
    endif
endfunction

function! vimpager_utils#IsDiff()
    let lnum = 1
    while getline(lnum) =~ '^\s*$'
        lnum += 1
    endwhile

    return getline(lnum) =~? '^\%(\e\[[;?]*[0-9.;]*[A-Za-z]\)*\%(diff\|---\)\s'
endfunction

function! vimpager_utils#ConcealRetab()
    let current_modifiable = &l:modifiable
    setlocal modifiable

    let modified = 0

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

        if newline !=# line
            call setline(lnum, newline)
            let modified = 1
        endif

        let lnum = search('\t')
    endwhile

    call setpos('.', current_cursor)

    let &l:modifiable = current_modifiable

    if modified
        setlocal buftype=nowrite " prevent writing out these changes to disk
    endif
endfunction

function! vimpager_utils#FtSetFromModeline()
    redir => ft_set_from
        silent! verb setlocal ft
        silent! verb setlocal syntax
    redir END

    if ft_set_from =~# '\<Last set from modeline\>'
        return 1
    endif

    return 0
endfunction

let &cpo = s:save_cpo

" vim: ft=vim sw=4 et:
