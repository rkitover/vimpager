function! vimpager#Init(opts)
    let g:vimpager = { 'enabled': 1 }

    call s:DisableConflictingPlugins()

    augroup vimpager

    autocmd!

    " can't pass a:opts in autocmd
    let s:opts = a:opts

    " can't use VimEnter because that fires after first file is read
    autocmd BufReadPre,StdinReadPre * call s:SetOptions(s:opts)

    autocmd BufReadPre,StdinReadPre * runtime macros/less.vim

    " any pre and post processing necessary is written to .vim files
    autocmd BufWinEnter * silent! source %.vim

    let g:__save_hidden = &hidden
    set nohidden
    autocmd VimEnter * let &hidden = __save_hidden | unlet! __save_hidden

    augroup end

    " allow user's .vimrc or -c commands to override this
    set bg=dark
    syntax enable
endfunction

function! s:LessStatusLine()
  redir => pos
    silent! file
  redir END
  " remove trailing newline
  let pos = substitute(pos, '[\r\n]\+', '', 'g')
  " remove tmp dir path
  let pos = substitute(pos, '^.*/', '', '')
  " remove closing quote
  let pos = substitute(pos, '"\(\s\+\d\+\s\+line\)', '\1', 'g')
  " urldecode
  let pos = substitute(pos, '%\(\x\x\)', '\=nr2char("0x" . submatch(1))', 'g')
  echohl WarningMsg
  redraw
  unsilent echo pos . "  [ Press ',h' for HELP ]"
  echohl None
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

    if !exists('g:less.statusfunc')
        let g:less.statusfunc = function('s:LessStatusLine')
    endif

    if !exists('g:mapleader')
        let g:mapleader = ','
    endif

    " process options
    if exists('a:opts.line_numbers')
        let g:less.number = a:opts.line_numbers
    endif
endfunction

function! s:DisableConflictingPlugins()
    " disable surround plugin
    let g:loaded_surround = 1
endfunction

function! vimpager#DoAnsiEsc()
    AnsiEsc
    call s:ConcealRetab()
    call s:CheckModelineFiletypeForAnsiEsc()

    " this is necessary so that AnsiEsc is in the right state when returning to the file with :N
    exe 'autocmd! vimpager BufWinLeave ' . expand('%') . ' AnsiEsc'
endfunction

function! s:ConcealRetab()
    let current_modifiable = &l:modifiable
    setlocal modifiable

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

    let &l:modifiable = current_modifiable
endfunction

function! s:CheckModelineFiletypeForAnsiEsc()
	redir => ft_set_from
	    silent! verb set ft
	    silent! verb set syntax
	redir END

	if ft_set_from =~# 'Last set from modeline\>'
	    execute 'setlocal ft=' . &ft
	    execute 'setlocal syntax=' . &syntax
        else
            noautocmd setlocal ft=ignore
	endif
endfunction

" vim: set ft=vim sw=4 et:
