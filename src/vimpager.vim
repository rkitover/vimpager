function! vimpager#init()
    nnoremap ,v :call <SID>LoadLess()<CR>
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
