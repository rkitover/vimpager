"" Vim script to work like "less"
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last Change:	2014 May 13

" This file is derived from the Vim project and is licensed under the
" same terms as Vim. See uganda.txt.

" Avoid loading this file twice, allow the user to define his own script.
if (exists('g:less.loaded') && g:less.loaded ==# 1) || (exists('g:loaded_less') && g:loaded_less ==# 1)
  " if the user re-read the file, he probably intends to turn on less mode
  if exists('*s:LessMode')
    call s:LessMode()
  endif

  " no need to redefine anything
  finish
endif

if !exists('g:less')
  let g:less = {}
endif

let g:less.loaded = 1

if !exists('g:less.enabled')
  let g:less.enabled = 1
endif

" If not reading from stdin, skip files that can't be read.
" Exit if there is no file at all.
if g:less.enabled && argc() > 0
  let s:i = 0
  while 1
    if filereadable(argv(s:i))
      if s:i != 0
	sleep 3
      endif
      break
    endif
    if isdirectory(argv(s:i))
      echomsg "Skipping directory " . argv(s:i)
    elseif getftime(argv(s:i)) < 0
      echomsg "Skipping non-existing file " . argv(s:i)
    else
      echomsg "Skipping unreadable file " . argv(s:i)
    endif
    echo "\n"
    let s:i = s:i + 1
    if s:i == argc()
      quit
    endif
    next
  endwhile
endif

" called on OptionSet for options we track
function! s:UpdateOption()
  let opt = expand('<amatch>')
  let val = v:option_new

  let less_buffer = has_key(g:less.buffers, bufnr('%'))
  let in_less     = less_buffer && g:less.buffers[bufnr('%')].enabled

  if v:option_type ==? 'global'
    execute 'let g:less.current_'.opt.' = val'

    " if setting outside of less, assume the original is meant to be changed
    if !in_less
      execute 'let g:less.original_'.opt.' = val'
    endif
  endif

  " if the option is global, assume the user used :set and wants to set both local and global
  if in_less
    execute 'let g:less.buffers[bufnr(''%'')].current_'.opt.' = val'
  elseif less_buffer
    execute 'let g:less.buffers[bufnr(''%'')].original_'.opt.' = val'
  endif
endfunction

function! s:SaveSetOpt(opt, val)
  if !exists('g:less.buffers.'.bufnr('%').'.original_'.a:opt)
    execute 'let g:less.buffers[bufnr(''%'')].original_'.a:opt.' = &l:'.a:opt
  endif
  if !exists('g:less.original_'.a:opt)
    execute 'let g:less.original_'.a:opt.' = &g:'.a:opt
  endif
  noautocmd execute 'let &l:'.a:opt.' = a:val'
  execute 'let g:less.buffers[bufnr(''%'')].current_'.a:opt.' = &l:'.a:opt
  execute 'let g:less.current_'.a:opt.' = &g:'.a:opt

  augroup less
    execute 'autocmd! OptionSet '.a:opt.' call s:UpdateOption()'
  augroup END
endfunction

function! s:RestoreLocalOpts()
  for k in keys(g:less.buffers[bufnr('%')])
    if match(k, '^original_') !=# -1
      let opt = k[9:-1]
      execute 'let &l:'.opt.' = g:less.buffers[bufnr(''%'')].original_'.opt
    endif
  endfor
endfunction

function! s:RestoreGlobalOpts()
  for k in keys(g:less)
    if match(k, '^original_') !=# -1
      let opt = k[9:-1]
      execute 'let &g:'.opt.' = g:less.original_'.opt
    endif
  endfor
endfunction

function! s:RestoreOpts()
  call s:RestoreGlobalOpts()
  call s:RestoreLocalOpts()
endfunction

function! s:ReenableLocalOpts()
  for k in keys(g:less.buffers[bufnr('%')])
    if match(k, '^current_') !=# -1
      let opt = k[8:-1]
      execute 'let &l:'.opt.' = g:less.buffers[bufnr(''%'')].current_'.opt
    endif
  endfor
endfunction

function! s:ReenableGlobalOpts()
  for k in keys(g:less)
    if match(k, '^current_') !=# -1
      let opt = k[8:-1]
      execute 'let &g:'.opt.' = g:less.current_'.opt
    endif
  endfor
endfunction

function! s:ReenableOpts()
  call s:ReenableGlobalOpts()
  call s:ReenableLocalOpts()
endfunction

function! s:InLessBuffer()
  return exists('g:less.buffers.'.bufnr('%'))
endfunction

function! s:InEnabledLessBuffer()
  return s:InLessBuffer() && g:less.buffers[bufnr('%')].enabled
endfunction

function! s:EnterWindow()
  if s:InEnabledLessBuffer()
    call s:ReenableOpts()
    call g:less.statusfunc()
  else
    call s:RestoreGlobalOpts()
  endif
endfunction

" set up less mode before reading each file
augroup less
  autocmd!
  autocmd BufReadPost,StdinReadPost * if exists('g:less.enabled') && g:less.enabled | call s:LessMode() | endif

  " display file on start
  autocmd BufWinEnter * call s:EnterWindow()
augroup end

" the toggle mapping we want globally and regardless of enabled setting
nnoremap <Leader>v :call <SID>ToggleLess()<CR>

function! s:Forward()
  " Searching forward
  noremap <buffer> <script> n H$nzt<SID>L
  if &wrap
    noremap <buffer> <script> N H0Nzt<SID>L
  else
    noremap <buffer> <script> N Hg0Nzt<SID>L
  endif
  cnoremap <buffer> <silent> <script> <CR> <CR>:cunmap <lt>buffer> <lt>CR><CR>zt<SID>L
endfunction

function! s:Backward()
  " Searching backward
  if &wrap
    noremap <buffer> <script> n H0nzt<SID>L
  else
    noremap <buffer> <script> n Hg0nzt<SID>L
  endif
  noremap <buffer> <script> N H$Nzt<SID>L
  cnoremap <buffer> <silent> <script> <CR> <CR>:cunmap <lt>buffer> <lt>CR><CR>zt<SID>L
endfunction

function! s:DisplayPosition()
  redir => pos
    silent! file
  redir END
  " remove trailing newline
  let pos = substitute(pos, '[\r\n]\+', '', 'g')
  let pos .= "  [ Press ',h' for help ]"
  " Trim the status line to fit the window width.
  let pos = len(pos) >= &columns ? '<' . pos[-&columns+2:-1] : pos
  highlight LessStatusLine ctermbg=NONE ctermfg=DarkMagenta guibg=NONE guifg=DarkMagenta
  echohl LessStatusLine
  redraw
  unsilent echo pos
  echohl None
endfunction

function! s:LessMode()
  if !exists('g:less')
    let g:less = {}
  endif

  if !exists('g:less.buffers')
    let g:less.buffers = {}
  endif

  if !s:InLessBuffer()
    let g:less.buffers[bufnr('%')] = {}
  endif

  let g:less.buffers[bufnr('%')].enabled = 1

  if !exists('g:less.statusfunc')
    let g:less.statusfunc = function('s:DisplayPosition')
  endif

  call s:SaveSetOpt('buftype', 'nowrite')
  call s:SaveSetOpt('modifiable', 1)
  call s:SaveSetOpt('readonly', 0)

  " Don't remember file names and positions
  call s:SaveSetOpt('viminfo', '')

  " Inhibit screen updates while searching
  call s:SaveSetOpt('lazyredraw', 1)

  " disable folds
  call s:SaveSetOpt('foldlevel', 9999)

  if exists('g:less.number')
    call s:SaveSetOpt('number', 1)
  else
    call s:SaveSetOpt('number', 0)
  endif

  silent! call s:SaveSetOpt('relativenumber', 0)

  if !exists('g:less.scrolloff')
    let g:less.scrolloff = 5
  endif
  call s:SaveSetOpt('scrolloff', g:less.scrolloff)

  if !exists('g:less.hlsearch')
    let g:less.hlsearch = 1
  endif

  if g:less.hlsearch
    call s:SaveSetOpt('hlsearch', 1)
    let g:less.buffers[bufnr('%')].hlsearch = 1
  else
    call s:SaveSetOpt('hlsearch', 0)
    nohlsearch
    let g:less.buffers[bufnr('%')].hlsearch = 0
  endif

  call s:SaveSetOpt('incsearch', 1)
  call s:SaveSetOpt('wrapscan', 0)

  " Used after each command: put cursor at end and display position
  if &wrap
    noremap <buffer> <SID>L L0:call g:less.statusfunc()<CR>
  else
    noremap <buffer> <SID>L Lg0:call g:less.statusfunc())<CR>
  endif

  " Give help
  noremap <buffer> ,h :call <SID>Help()<CR>
  map <buffer> ,H ,h

  " Scroll one page forward
  noremap <buffer> <script> <Space> :call <SID>NextPage()<CR><SID>L
  map <buffer> <C-V> <Space>
  map <buffer> f <Space>
  map <buffer> <C-F> <Space>
  map <buffer> <PageDown> <Space>
  map <buffer> <kPageDown> <Space>
  map <buffer> <S-Down> <Space>
  map <buffer> z <Space>
  map <buffer> <Esc><Space> <Space>

  " Re-read file and page forward "tail -f"
  map <buffer> F :e<CR>G<SID>L:sleep 1<CR>F

  " Scroll half a page forward
  noremap <buffer> <script> d <C-D><SID>L
  map <buffer> <C-D> d

  " Scroll one line forward
  noremap <buffer> <script> <CR> <C-E><SID>L
  map <buffer> <C-N> <CR>
  map <buffer> e <CR>
  map <buffer> <C-E> <CR>
  map <buffer> j <CR>
  map <buffer> <C-J> <CR>
  map <buffer> <Down> 1<C-d>

  " Scroll one page backward
  noremap <buffer> <script> b <C-B><SID>L
  map <buffer> <C-B> b
  map <buffer> <PageUp> b
  map <buffer> <kPageUp> b
  map <buffer> <S-Up> b
  map <buffer> w b
  map <buffer> <Esc>v b

  " Scroll half a page backward
  noremap <buffer> <script> u <C-U><SID>L
  noremap <buffer> <script> <C-U> <C-U><SID>L

  " Scroll one line backward
  noremap <buffer> <script> k <C-Y><SID>L
  map <buffer> y k
  map <buffer> <C-Y> k
  map <buffer> <C-P> k
  map <buffer> <C-K> k
  map <buffer> <Up> 1<C-u>

  " Redraw
  noremap <buffer> <script> r <C-L><SID>L
  noremap <buffer> <script> <C-R> <C-L><SID>L
  noremap <buffer> <script> R <C-L><SID>L

  " Start of file
  noremap <buffer> <script> g gg<SID>L
  map <buffer> < g
  map <buffer> <Esc>< g
  map <buffer> <Home> g
  map <buffer> <kHome> g

  " End of file
  noremap <buffer> <script> G G<SID>L
  map <buffer> > G
  map <buffer> <Esc>> G
  map <buffer> <End> G
  map <buffer> <kEnd> G

  " Go to percentage
  noremap <buffer> <script> % %<SID>L
  map <buffer> p %

  " Search
  noremap <buffer> <script> / H$:call <SID>Forward()<CR>/
  if &wrap
    noremap <buffer> <script> ? H0:call <SID>Backward()<CR>?
  else
    noremap <buffer> <script> ? Hg0:call <SID>Backward()<CR>?
  endif

  " esc-u to toggle search highlighting like in less
  nnoremap <buffer> <ESC>u :if g:less.buffers[bufnr('%')].hlsearch ==# 1 \| set nohlsearch \| nohlsearch \| let g:less.buffers[bufnr('%')].hlsearch = 0 \| else \| set hlsearch \| let g:less.buffers[bufnr('%')].hlsearch = 1 \| endif<CR><CR>

  call s:Forward()
  cunmap <buffer> <CR>

  " Quitting
  noremap <buffer> q :<C-u>qa!<CR>

  " Switch to editing (switch off less mode) with v (,v is global)
  map <buffer> v :call <SID>End()<CR>
endfunction

" enable for current file
if exists('g:less.enabled') && g:less.enabled
  call s:LessMode()
endif

function! s:NextPage()
  if line(".") == line("$")
    if argidx() + 1 >= argc()
      " Don't quit at the end of the last file
      return
    endif
    next
    1
  else
    execute "normal! \<C-F>"
  endif
endfunction

function! s:Help()
  echo "<Space>   One page forward          b         One page backward"
  echo "d         Half a page forward       u         Half a page backward"
  echo "<Enter>   One line forward          k         One line backward"
  echo "G         End of file               g         Start of file"
  echo "N%        percentage in file        ,h        Display this help"
  echo "\n"
  echo "/pattern  Search for pattern        ?pattern  Search backward for pattern"
  echo "n         next pattern match        N         Previous pattern match"
  echo "<ESC>u    toggle search highlight"
  echo "\n"
  echo ":n<Enter> Next file                 :N<Enter> Previous file"
  echo "\n"
  echo "q         Quit                      ,v        Toggle Less Mode"
  let i = input("Hit Enter to continue")
endfunction

function! s:ToggleLess()
  if !exists('g:less.buffers.'.bufnr('%').'.enabled') || g:less.buffers[bufnr('%')].enabled ==# 0
    let jump = 5
    if exists('g:less.scrolloff')
      let jump = g:less.scrolloff
    endif

    let curpos = getpos('.')

    if winline() <= jump
        call setpos('.', [curpos[0], curpos[1] + (jump - winline()) + 1, curpos[2], curpos[3]])
    elseif (winheight(0) - winline()) <= jump
        call setpos('.', [curpos[0], curpos[1] - (jump - (winheight(0) - winline())) - 1 , curpos[2], curpos[3]])
    endif

    call s:LessMode()
    redraw
    echomsg 'Less Mode Enabled'
  else
    call s:End()
    redraw
    echomsg 'Less Mode Disabled'
  endif
endfunction

function! s:End()
  call s:RestoreOpts()
  let g:less.buffers[bufnr('%')].enabled = 0
  unmap <buffer> ,h
  unmap <buffer> ,H
  unmap <buffer> <Space>
  unmap <buffer> <C-V>
  unmap <buffer> f
  unmap <buffer> <C-F>
  unmap <buffer> z
  unmap <buffer> <Esc><Space>
  unmap <buffer> F
  unmap <buffer> d
  unmap <buffer> <C-D>
  unmap <buffer> <CR>
  unmap <buffer> <C-N>
  unmap <buffer> e
  unmap <buffer> <C-E>
  unmap <buffer> j
  unmap <buffer> <C-J>
  unmap <buffer> b
  unmap <buffer> <C-B>
  unmap <buffer> w
  unmap <buffer> <Esc>v
  unmap <buffer> u
  unmap <buffer> <C-U>
  unmap <buffer> k
  unmap <buffer> y
  unmap <buffer> <C-Y>
  unmap <buffer> <C-P>
  unmap <buffer> <C-K>
  unmap <buffer> r
  unmap <buffer> <C-R>
  unmap <buffer> R
  unmap <buffer> g
  unmap <buffer> <
  unmap <buffer> <Esc><
  unmap <buffer> G
  unmap <buffer> >
  unmap <buffer> <Esc>>
  unmap <buffer> %
  unmap <buffer> p
  unmap <buffer> n
  unmap <buffer> N
  unmap <buffer> q
  unmap <buffer> v
  unmap <buffer> /
  unmap <buffer> ?
  unmap <buffer> <Up>
  unmap <buffer> <Down>
  unmap <buffer> <PageDown>
  unmap <buffer> <kPageDown>
  unmap <buffer> <PageUp>
  unmap <buffer> <kPageUp>
  unmap <buffer> <S-Down>
  unmap <buffer> <S-Up>
  unmap <buffer> <Home>
  unmap <buffer> <kHome>
  unmap <buffer> <End>
  unmap <buffer> <kEnd>
endfunction

" vim: sw=2
