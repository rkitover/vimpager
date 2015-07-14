command! -nargs=0 -bang -bar ConcealRetab :call ConcealRetab#ConcealRetab()

function! ConcealRetab#ConcealRetab()
    let l:current_cursor = getpos('.')

    call cursor(1,1)

    let l:lnum = search('\t')

    while l:lnum !=# 0
        let l:newline = ''
        let l:column  = 0
        let l:linepos = 1

        for l:c in split(getline('.'), '\zs')
            if l:c ==# "\t"
                let l:spaces   = 8 - (l:column % 8)
                let l:column  += l:spaces

                let l:newline .= repeat(' ', l:spaces)
            else
                let l:concealed = synconcealed(l:lnum, l:linepos)

                if l:concealed[0] ==# 0 || l:concealed[1] !=# ''
                    let l:column += 1
                endif

                let l:newline .= c
            endif

            let l:linepos += 1
        endfor

        call setline(l:lnum, l:newline)

        let l:lnum = search('\t')
    endwhile

    call setpos('.', l:current_cursor)
endfun
