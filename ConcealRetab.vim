command! -nargs=0 -bang -bar ConcealRetab :call ConcealRetab()

function! ConcealRetab()
    let current_cursor = getcurpos()

    call cursor(1,1)

    let lnum = search('\t')

    while lnum !=# 0
        let newline = ''
        let column  = 0
        let linepos = 1

        for c in split(getline('.'), '\zs')
            if c ==# "\t"
                let spaces   = 8 - (column % 8)
                let column  += spaces

                let newline .= repeat(' ', spaces)
            else
                let concealed = synconcealed(lnum, linepos)

                if concealed[0] ==# 0 || concealed[1] !=# ''
                    let column += 1
                endif

                let newline .= c
            endif

            let linepos += 1
        endfor

        call setline(lnum, newline)

        let lnum = search('\t')
    endwhile

    call setpos('.', current_cursor)
endfun
