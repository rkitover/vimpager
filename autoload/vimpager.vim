scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! vimpager#Init(opts)
    let g:vimpager = { 'enabled': 1 }

    call s:DisableConflictingPlugins()

    " can't pass a:opts in autocmd
    let s:opts = a:opts

    augroup vimpager
    autocmd!

    " some plugin managers like dein overwrite the runtimepath, so we have to
    " make sure all of our versions of our plugins are loaded explicitly
    call s:LoadOurPlugins()

    " restore default runtimepath for the duration of .vimrc loading, because a
    " non-default one conflicts with some plugin managers
    call s:RestoreDefaultRTP()

    " but make sure our runtime is in runtimepath when a file is read, so that
    " things like AnsiEsc work
    autocmd BufReadPre,StdinReadPre * call s:SetRTP()

    augroup END

    augroup vimpager_process
    autocmd!

    " make buffers modifiable and not complain on quit
    autocmd BufReadPre,StdinReadPre * call s:SetBufType()

    " the post-processing .vim files are written from 1..N.vim,
    " since the arglist is modified on q we have to save the indices
    let s:file_indices = {}

    for i in range(1, argc())
        let s:file_indices[argv(i - 1)] = i
    endfor

    " any pre-processing necessary is written to .vim files, single shot
    autocmd BufWinEnter * call s:PostProcess()

    augroup END

    augroup vimpager

    " can't use VimEnter because that fires after first file is read
    autocmd BufReadPre,StdinReadPre * call s:SetHighlightOpts()
    autocmd BufReadPre,StdinReadPre * call s:SetOptions()
    autocmd BufReadPre,StdinReadPre * runtime macros/less.vim

    if has('gui')
        autocmd VimEnter * call s:GUIInit()
    endif

    " hide error messages from invalid modelines, or post processing errors
    autocmd VimEnter * if !exists('$VIMPAGER_DEBUG') || !$VIMPAGER_DEBUG | silent! redraw! | endif

    " remove autocmds when done initializing
    autocmd VimEnter * autocmd! vimpager

    augroup END

    " allow user's .vimrc or -c commands to override this
    set mouse=a

    if !has('nvim')
        set ttymouse=xterm2
    else
        set laststatus=1 " neovim defaults to 2
    endif
endfunction

function! s:SetHighlightOpts()
    " set sensible default highlight options for people without an rc
    if (s:opts.rc =~? '^ *$' || s:opts.rc =~? '^ *NO\(NE\|RC\) *$') && $MYVIMRC =~? '^ *$'
        set bg=dark
        syntax enable
    endif
endfunction

let s:post_processed = {}

function! s:PostProcess()
    let bufname = bufname('%')

    " only run this for args, if we are not on an arg or file return
    if bufname ==# '' || bufname !=# argv(argidx())
        return
    endif

    let fname = bufname

    " if we can't find the file bail out
    if !has_key(s:file_indices, fname)
        return
    endif

    let idx = s:file_indices[fname]

    " we only run this once if hidden is set, otherwise every time
    if !has_key(s:post_processed, fname) || !&hidden
        let silent=(!exists('$VIMPAGER_DEBUG') || !$VIMPAGER_DEBUG) ? 'silent! ' : ''

        " these are written by vimpager shell code
        execute silent . 'source ' . s:opts.tmp_dir . '/' . idx . '.vim'

        " in case the post-processing does something we don't want
        call s:FixBufOpts()

        " hide post-processing errors
        if !exists('$VIMPAGER_DEBUG') || !$VIMPAGER_DEBUG
            silent! redraw!
        endif

        let s:post_processed[fname] = 1
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

function! s:SetRTP()
    execute 'set runtimepath^=' . s:opts.runtime
endfunction

function! s:RestoreDefaultRTP()
    let &rtp = substitute(&rtp, '^[^,]\+,', '', '')
endfunction

function! s:LoadOurPlugins()
    call s:SetRTP()

    for plugin in split(glob(s:opts.runtime . '/plugin/**/*.vim', 1), '\n')
        execute 'source ' . fnameescape(plugin)
    endfor
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

    if exists('s:opts.tail')
        let g:less.tail = s:opts.tail
    endif

    " turn off man.vim mappings
    if !exists('g:no_man_maps')
        let g:no_man_maps = 1
    endif
endfunction

function! s:SetBufType()
    if bufname('%') =~# '^\V' . s:opts.tmp_dir
        setlocal buftype=nowrite modifiable noreadonly viminfo=
    endif
endfunction

function! s:FixBufOpts()
    call s:SetBufType() " reset these again in case the ftplugin or whatever changed them
    setlocal buflisted " neovim ftplugin/man.vim sets nobuflisted
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

" vim: ft=vim sw=4 et:
