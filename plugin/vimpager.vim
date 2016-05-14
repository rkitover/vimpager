scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if exists('g:vimpager_plugin_loaded') && g:vimpager_plugin_loaded ==# 1
    let &cpo = s:save_cpo
    finish
endif

let g:vimpager_plugin_loaded = 1

command! -nargs=* -complete=customlist,s:PageCmdComplete -bang Page call s:PageCmd('<args>', '<bang>')

function! s:PageCmdComplete(arg_lead, cmd_line, cur_pos)
    " if the user hasn't typed a space, return a space
    if a:cmd_line !~# '\s'
        return [' ']
    endif

    " complete option, -b, -t or -w
    if a:arg_lead ==# '-'
        return ['-t', '-v', '-w', '-b']
    endif

    " check for absolute path
    if a:arg_lead =~# '^/'
        return glob(a:arg_lead . '*', 0, 1)
    endif

    " check if command (first word after :Less!)
    if a:cmd_line =~# '^Page!\s\+\S\+$'
        return map(globpath(substitute($PATH, '[:;]', ',', 'g'), a:arg_lead . '*', 1, 1),
                    \ 'substitute(v:val, ''^.*/\(.*\)'', ''\1'', '''')')
    endif

    " otherwise complete files in current dir
    return glob(a:arg_lead . '*', 0, 1)
endfunction

function! s:PageCmd(args, bang)
    " initialize vimpager if unset
    if !exists('g:vimpager')
        let g:vimpager = {}
    endif

    if !exists('g:vimpager.enabled')
        let g:vimpager.enabled = 0
    endif

    " load less.vim if not loaded
    if !((exists('g:less.loaded') && g:less.loaded ==# 1) || (exists('g:loaded_less') && g:loaded_less ==# 1))
        if !exists('g:less')
            let g:less = {}
        elseif exists('g:less.enabled')
            let save_less_enabled = g:less.enabled
        endif

        runtime macros/less.vim

        if exists('l:save_less_enabled')
            let g:less.enabled = save_less_enabled
            unlet save_less_enabled
        endif
    endif

    let args = split(a:args, '\%(\\\)\@<!\s')

    if !len(args)
        if a:bang ==# '!'
            Less!
        else
            Less
        endif
        return
    endif

    if args[0] =~# '^-[tvwb]$'
        let opt  = args[0]
        let args = args[1:-1]

        if !len(args)
            let missing = a:bang ==# '!' ? 'command' : 'file'
            echohl Error
            unsilent echomsg missing . ' is required!'
            echohl None
            return
        endif

        if opt ==# '-t'
            tabnew
        elseif opt ==# '-w'
            new
        elseif opt ==# '-v'
            vnew
        else
            enew
        endif
    else
        enew
    endif

    if a:bang ==# '!'
        silent execute '0read! ' . join(args, ' ')

        " check if it's a man or perldoc command
        if args[0] =~? '^\%(man\|perldoc\|pydoc\|ri\)$'
            " remove leading blank lines
            while getline(1) =~# '^\s*$'
                1d
            endwhile

            " remove overstrikes
            %s/.\b//eg

            " remove ANSI codes
            %s/\e\[[;?]*[0-9.;]*[A-Za-z]//eg

            let &l:filetype = tolower(args[0]) ==# 'perldoc' ? 'perldoc' : 'man'
        endif
    else
        execute 'edit ' . join(args, ' ')
    endif

    " move to top
    normal gg0

    " check for ansi Codes
    if search('\e\[[;?]*[0-9.;]*[A-Za-z]', 'c') !=# 0
        " use AnsiEsc if available
        if (!exists('g:vimpager.ansiesc') || g:vimpager.ansiesc) && !vimpager_utils#FtSetFromModeline() && exists(':AnsiEsc') ==# 2
            noautocmd setlocal filetype=ignored
            AnsiEsc
            call vimpager_utils#ConcealRetab()
        else
            " otherwise remove ANSI codes
            %s/\e\[[;?]*[0-9.;]*[A-Za-z]//eg
        endif
    endif

    " move to top again, because search() moves the cursor
    normal gg0

    filetype detect

    Less!
endfunction

let &cpo = s:save_cpo

" vim: set ft=vim sw=4 et:
