scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! vimpager#Init(opts)
    let g:vimpager = { 'enabled': 1 }

    call s:DisableConflictingPlugins()

    " can't pass a:opts in autocmd
    let s:opts = a:opts

    augroup vimpager_process
    autocmd!

    " make buffers modifiable and not complain on quit
    autocmd BufReadPre,StdinReadPre * call s:SetBufType()

    " any pre-processing necessary is written to .vim files
    autocmd BufReadPost,StdinReadPost * silent! source %.vim

    " hide error messages from invalide modelines
    autocmd BufWinEnter * if !exists('$VIMPAGER_DEBUG') || !$VIMPAGER_DEBUG
                \ | silent! redraw! | endif

    augroup END

    augroup vimpager
    autocmd!

    " can't use VimEnter because that fires after first file is read
    autocmd BufReadPre,StdinReadPre * call s:SetOptions()
    autocmd BufReadPre,StdinReadPre * runtime macros/less.vim

    if has('gui')
        autocmd VimEnter * call s:GUIInit()
    endif

    " remove autocmds when done initializing
    autocmd VimEnter * autocmd! vimpager

    augroup END

    " allow user's .vimrc or -c commands to override this
    set bg=dark
    syntax enable
    set mouse=a

    if !has('nvim') " neovim has its own clipboard support
        set ttymouse=xterm2
        set clipboard=autoselect
    endif
endfunction

function! s:GUIInit()
    if exists('s:opts.columns') && exists('s:opts.is_doc') && s:opts.is_doc && &columns < s:opts.columns
        let &columns = s:opts.columns
    endif

    augroup vimpager_finish
        autocmd VimLeave * call writefile([], s:opts.tmp_dir . '/gvim_done')
    augroup END
endfunction

function! s:SetOptions()
    if !exists('g:less')
        let g:less = {}
    endif

    if !exists('g:less.enabled')
        if exists('g:vimpager_less_mode')
            let g:less.enabled = g:vimpager_less_mode
        else
            let g:less.enabled = 1
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
        let g:less.statusfunc = function('vimpager#CallStatusLineFunc')
    endif

    if !exists('g:mapleader')
        let g:mapleader = ','
    endif

    " process options
    if exists('s:opts.line_numbers')
        let g:less.number = s:opts.line_numbers
    endif
endfunction

function! s:SetBufType()
    if bufname('%') =~# '^\V' . s:opts.tmp_dir
        setlocal buftype=nowrite modifiable noreadonly viminfo=
    endif
endfunction

" 7.3 has no partial funcrefs, and does not allow funcrefs to s:Func()
function! vimpager#CallStatusLineFunc()
    call vimpager_utils#StatusLine(s:opts)
endfunction

function! s:DisableConflictingPlugins()
    " we can't use <nowait> on 7.3 in mappings in less.vim, so surround must be disabled in that case
    if v:version < 704
        let g:loaded_surround = 1
    endif
endfunction

let &cpo = s:save_cpo

" vim: set ft=vim sw=4 et:
