" AnsiHighlight: Allows for marking up a file, using ANSI color escapes when
" the syntax changes colors, for easy, faithful reproduction.
" Author: Matthew Wozniski (mjw@drexel.edu)
" Date: Fri, 01 Aug 2008 05:22:55 -0400
" Version: 1.0 FIXME
" History: FIXME see :help marklines-history
" License: BSD. Completely open source, but I would like to be
" credited if you use some of this code elsewhere.

" Copyright (c) 2015, Matthew J. Wozniski {{{1
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
" * Redistributions of source code must retain the above copyright
" notice, this list of conditions and the following disclaimer.
" * Redistributions in binary form must reproduce the above copyright
" notice, this list of conditions and the following disclaimer in the
" documentation and/or other materials provided with the distribution.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY
" EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
" WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
" DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
" DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
" (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
" LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
" ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
" (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
" SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

" Converts info for a highlight group to a string of ANSI color escapes {{{1

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! s:GroupToAnsi(groupnum)
    if ! exists("s:ansicache")
        let s:ansicache = {}
    endif

    let groupnum = a:groupnum

    if groupnum == 0
        let groupnum = hlID('Normal')
    endif

    if has_key(s:ansicache, groupnum)
        return s:ansicache[groupnum]
    endif

    let fg = synIDattr(groupnum, 'fg', s:type)
    let bg = synIDattr(groupnum, 'bg', s:type)
    let rv = synIDattr(groupnum, 'reverse', s:type)
    let bd = synIDattr(groupnum, 'bold', s:type)

    " FIXME other attributes?

    if rv == "" || rv == -1
        let rv = 0
    endif

    if bd == "" || bd == -1
        let bd = 0
    endif

    if rv
        let temp = bg
        let bg = fg
        let fg = temp
    endif

    if fg == "" || fg == -1
        unlet fg
    endif

    if !exists('fg') && groupnum != hlID('Normal')
        let fg = synIDattr(hlID('Normal'), 'fg', s:type)
        if fg == "" || fg == -1
            unlet fg
        endif
    endif

    if bg == "" || bg == -1
        unlet bg
    endif

    if !exists('bg')
        let bg = synIDattr(hlID('Normal'), 'bg', s:type)
        if bg == "" || bg == -1
            unlet bg
        endif
    endif

    let retv = "\<Esc>[22;24;25;27;28"

    if bd
        let retv .= ";1"
    endif

    if exists('fg') && fg < 8
        let retv .= ";3" . fg
    elseif exists('fg')  && fg < 16    "use aixterm codes
        let retv .= ";9" . (fg - 8)
    elseif exists('fg')                "use xterm256 codes
        let retv .= ";38;5;" . fg
    else
        let retv .= ";39"
    endif

    if exists('bg') && bg < 8
        let retv .= ";4" . bg
    elseif exists('bg') && bg < 16     "use aixterm codes
        let retv .= ";10" . (bg - 8)
    elseif exists('bg')                "use xterm256 codes
        let retv .= ";48;5;" . bg
    else
        let retv .= ";49"
    endif

    let retv .= "m"

    let s:ansicache[groupnum] = retv

    return retv
endfunction

function! s:ReadChunks()
    let chunk_files = filter(split(glob(s:pipeline_dir . '/*', 1), '\n'), 'getfsize(v:val) > 0')

    if !len(chunk_files)
        return 0
    endif

    call sort(chunk_files)

    for chunk_file in chunk_files
        let block = readfile(chunk_file, 'b')

        let chunk_newline = 0

        if block[-1] == ''
            let chunk_newline = 1
            call remove(block, -1)
        endif

        let lines = []

        if line('$') == 1 && getline(1) == ''
            let append_to = 0
        else
            if !s:chunk_newline
                let lines = [ getline(line('$')) . remove(block, 0) ]
                $d
            endif

            let append_to = line('$')
        endif

        let lines += block

        call append(append_to, lines)

        if append_to == 0
            $d
        endif

        if s:chunk_num > 20
            normal '0ggd/\_.\{4096}/e'
        endif

        let s:chunk_newline = chunk_newline

        let s:chunk_num += 1
    endfor

    call map(chunk_files, 'delete(v:val)')

    return 1
endfunction

function! s:AnsiHighlight(output_file, line_numbers, pipeline_dir)
    let s:pipeline_dir = a:pipeline_dir

    setlocal modifiable noreadonly buflisted buftype=nowrite

    if a:pipeline_dir != ''
        let s:chunk_num     = 1
        let s:chunk_newline = 0

        while !s:ReadChunks()
            sleep 100 m
        endwhile

        let ln_field_len = 7
    else
        let ln_field_len = len(line('$'))
    endif

    if &l:ft == ''
        filetype detect
    endif
    syntax enable
    syntax sync minlines=500 maxlines=500

    let done = 0
    let lnum = 1

    while !done
        let last = hlID('Normal')
        let output = s:GroupToAnsi(last) . "\<Esc>[K" " Clear to right

        " Hopefully fix highlighting sync issues
        exe "norm! " . lnum . "G$"

        let line = getline(lnum)
        let cnum = 1

        while cnum <=# col('.')
            " skip ansi codes in the file
            if cnum <=# col('.') - 1 && line[cnum-1] ==# "\e" && line[cnum] ==# '['
                let cnum += 2
                while match(line[cnum-1], '[A-Za-z]') ==# -1
                    let cnum += 1
                endwhile

                let cnum += 1
                continue
            endif

            let concealed = synconcealed(lnum, cnum)

            if empty(concealed) " no conceal feature
                let concealed = [0]
            endif

            if concealed[0] !=# 1 && synIDtrans(synID(lnum, cnum, 1)) != last
                let last = synIDtrans(synID(lnum, cnum, 1))
                let output .= s:GroupToAnsi(last)
            endif

            if concealed[0] ==# 1 && &conceallevel !=# 0
                if &conceallevel ==# 1 || &conceallevel ==# 2
                    let output .= concealed[1]
                endif
            else
                let output .= line[cnum-1]
            endif
            "let line = substitute(line, '.', '', '')
                        "let line = matchstr(line, '^\@<!.*')
            let cnum += 1
        endwhile

        if a:line_numbers
            let output = printf("\<Esc>[0m\<Esc>[37;1m%" . ln_field_len . "d ", lnum) . output
        endif

        call writefile([output . "\<Esc>[0m\r"], a:output_file, 'a')

        let lnum += 1

        if a:pipeline_dir == ''
            if lnum > line('$')
                let done = 1
            endif
        else
            if lnum % 30 == 0
                call s:ReadChunks()
            endif

            if lnum > line('$')
                let stream_underrun = 1

                while stream_underrun
                    let stream_underrun = !s:ReadChunks()

                    if stream_underrun
                        if filereadable(a:pipeline_dir . '/PIPELINE_DONE')
                            let done = 1
                            break
                        endif

                        sleep 100 m
                    endif
                endwhile
            endif
        endif
    endwhile

    return 1
endfunction

function! vimcat#Init(opts)
    " save for other functions
    let s:opts = a:opts

    " Turn off vi-compatible mode, unless it's already off {{{1
    if !has('nvim') && &cp
        set nocp
    endif

    let s:type = 'cterm'
    if &t_Co == 0
        let s:type = 'term'
    endif

    set foldlevel=9999
endfunction

function! s:SetHighlightOpts()
    " set sensible default highlight options for people without an rc
    if (s:opts.rc =~? '^ *$' || s:opts.rc =~? '^ *NO\(NE\|RC\) *$') && $MYVIMRC =~? '^ *$'
        set bg=dark
        highlight Normal ctermbg=NONE
    endif

    syntax enable
endfunction

function! vimcat#Run(output_file, line_numbers, pipeline_dir, pipeline_start)
    call s:SetHighlightOpts()
    silent! execute 'file ' . fnameescape(a:pipeline_start)
    setlocal buftype=nowrite modifiable noreadonly viminfo=
    call s:AnsiHighlight(a:output_file, a:line_numbers, a:pipeline_dir)
    if !exists('$VIMCAT_DEBUG') || $VIMCAT_DEBUG == 0
        quitall!
    endif
endfunction

let &cpo = s:save_cpo

" See copyright in the vim script above (for the vim script) and in
" vimcat.md for the whole script.
"
" The list of contributors is at the bottom of the vimpager script in this
" project.
"
" vim: sw=4 et ft=vim:
