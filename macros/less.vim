"" Vim script to work like "less"
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last Change:	2014 May 13

" This file is derived from the Vim project and is licensed under the
" same terms as Vim. See uganda.txt.

" Avoid loading this file twice, allow the user to define his own script.

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if (exists('g:less.loaded') && g:less.loaded ==# 1) || (exists('g:loaded_less') && g:loaded_less ==# 1)
  " if the user re-read the file, he probably intends to turn on less mode
  if exists('*s:LessMode')
    call s:LessMode()
  endif

  " no need to redefine anything
  let &cpo = s:save_cpo
  finish
endif

if !exists('g:less')
  let g:less = {}
endif

let g:less.loaded = 1

" This must be set before the first LessMode(), so that if enabled for the
" current file at source time, there is no jump.
if !exists('g:less.scrolloff')
  let g:less.scrolloff = 5
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

  if exists('##OptionSet')
    augroup less
      execute 'autocmd! OptionSet '.a:opt.' call s:UpdateOption()'
    augroup END
  endif
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
    if exists('g:less.enabled') && g:less.enabled
      call s:LessMode()
      call g:less.statusfunc()
    else
      call s:RestoreGlobalOpts()
    endif
  endif
endfunction

augroup less
  autocmd!
  autocmd BufWinEnter * call s:EnterWindow()
augroup end

" 7.3 does not support <nowait> in maps, so we only add it for 7.4+
function! s:Map(cmd)
  let cmd = a:cmd

  if v:version >= 704
    let cmd = substitute(cmd, '^\(\s*\S*map\s\+\)', '\1<nowait> ', '')
  endif

  execute cmd
endfunction

" the toggle mapping we want globally and regardless of enabled setting
call s:Map('nnoremap <silent> <Leader>v :call <SID>ToggleLess()<CR>')

function! s:Forward()
  " Searching forward
  call s:Map('noremap <buffer> <script> n H$nzt<SID>L')
  if &wrap
    call s:Map('noremap <buffer> <script> N H0Nzt<SID>L')
  else
    call s:Map('noremap <buffer> <script> N Hg0Nzt<SID>L')
  endif
  call s:Map('cnoremap <silent> <buffer> <script> <CR> <CR>:silent! cunmap <lt>buffer> <lt>CR><CR>zt<SID>L')
endfunction

function! s:Backward()
  " Searching backward
  if &wrap
    call s:Map('noremap <buffer> <script> n H0nzt<SID>L')
  else
    call s:Map('noremap <buffer> <script> n Hg0nzt<SID>L')
  endif
  call s:Map('noremap <buffer> <script> N H$Nzt<SID>L')
  call s:Map('cnoremap <silent> <buffer> <silent> <script> <CR> <CR>:silent! cunmap <lt>buffer> <lt>CR><CR>zt<SID>L')
endfunction

function! s:StatusLine()
  redir => pos
    silent! file
  redir END
  " remove trailing newline
  let pos = substitute(pos, '[\r\n]\+', '', 'g')
  " remove any beginning quotes
  let pos = substitute(pos, '^"*', '', '')
  " remove possible [readonly] or [Modified] tag
  let pos = substitute(pos, '\[\%(readonly\|Modified\)\]\s\+', '', '')
  " remove closing quote
  let pos = substitute(pos, '"\(\s\+\d*\s*line\)', '\1', '')
  " add help message
  let leader = exists('g:mapleader') ? g:mapleader : '\'
  let pos .= "  [ Press '".leader."h' for HELP ]"
  " Trim the status line to fit the window width.
  let width = &columns - 12
  let pos = len(pos) >= width ? '<' . pos[-width+1:-1] : pos
  highlight LessStatusLine ctermbg=NONE ctermfg=DarkMagenta guibg=NONE guifg=DarkMagenta
  echohl LessStatusLine
  redraw
  unsilent echo pos
  echohl None
endfunction

" In 7.3 calling a funcref to an s:Func() from a mapping is not allowed, so we call it indirectly
function! s:CallStatusFunc()
  call g:less.statusfunc()
endfunction

" define Less command

command! -nargs=* -complete=customlist,s:LessCmdComplete -bang Less call s:LessCmd('<args>', '<bang>')

function! s:LessCmdComplete(arg_lead, cmd_line, cur_pos)
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
    return split(glob(a:arg_lead . '*', 0), '\n')
  endif

  " check if command (first word after :Less!)
  if a:cmd_line =~# '^Less!\s\+\S\+$'
    return map(split(globpath(substitute($PATH, '[:;]', ',', 'g'), a:arg_lead . '*', 1), '\n'),
      \ 'substitute(v:val, ''^.*/\(.*\)'', ''\1'', '''')')
  endif

  " otherwise complete files in current dir
  return split(glob(a:arg_lead . '*', 0), '\n')
endfunction

function! s:LessCmd(args, bang)
  let args = split(a:args, '\%(\\\)\@<!\s')

  if !len(args)
    if a:bang ==# '!'
      call s:LessMode()
    else
      call s:ToggleLess()
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

    " check if it's a man command
    if args[0] =~? '^\%(man\|perldoc\|pydoc\|ri\)$'
      " remove leading blank lines
      while getline(1) =~# '^\s*$'
        1d
      endwhile

      " remove overstrikes
      %s/.\b//eg

      " remove ANSI codes
      %s/\e\[[;?]*[0-9.;]*[A-Za-z]//eg

      setlocal filetype=man
    endif

    call s:LessMode()
  else
    let save_less_mode = g:less.enabled
    let g:less.enabled = 1

    execute 'edit ' . join(args, ' ')

    let g:less.enabled = save_less_mode
  endif

  " move to top
  normal gg0

  " check for ansi Codes
  if search('\e\[[;?]*[0-9.;]*[A-Za-z]', 'c') !=# 0
    " if ft or syntax is set from modeline, do nothing
    redir => ft_set_from
        silent! verb setlocal ft
        silent! verb setlocal syntax
    redir END

    if ft_set_from !~# '\<Last set from modeline\>'
      " use AnsiEsc if available
      if exists(':AnsiEsc') ==# 2
        noautocmd setlocal filetype=ignored
        AnsiEsc
      else
        " otherwise remove ANSI codes
        %s/\e\[[;?]*[0-9.;]*[A-Za-z]//eg
      endif
    endif
  endif

  filetype detect

  " move to top again, because search() moves the cursor
  normal gg0
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
    let g:less.statusfunc = function('s:StatusLine')
  endif

  " turn off extra status lines (especially in neovim)
  call s:SaveSetOpt('laststatus', 1)

  " turn off cursor line highlighting
  call s:SaveSetOpt('cursorline', 0)

  " turn off ruler, it interferes with the status line, and we have our own
  call s:SaveSetOpt('ruler', 0)

  " Inhibit screen updates while searching
  call s:SaveSetOpt('lazyredraw', 1)

  " disable folds
  call s:SaveSetOpt('foldlevel', 9999)

  if exists('g:less.number')
    call s:SaveSetOpt('number', g:less.number)
  else
    call s:SaveSetOpt('number', 0)
  endif

  silent! call s:SaveSetOpt('relativenumber', 0)

  " adjust cursor position for scrolloff setting
  if !exists('g:less.scrolloff')
    let g:less.scrolloff = 5
  endif
  let jump = g:less.scrolloff

  let curpos = getpos('.')

  if winline() <= jump
      call setpos('.', [curpos[0], curpos[1] + (jump - winline()) + 1, curpos[2], curpos[3]])
  elseif (winheight(0) - winline()) <= jump
      call setpos('.', [curpos[0], curpos[1] - (jump - (winheight(0) - winline())) - 1 , curpos[2], curpos[3]])
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
    call s:Map('noremap <silent> <buffer> <SID>L L0:call <SID>CallStatusFunc()<CR>')
  else
    call s:Map('noremap <silent> <buffer> <SID>L Lg0:silent! call <SID>CallStatusFunc())<CR>')
  endif

  " Give help
  call s:Map('nnoremap <silent> <buffer> <Leader>h :unsilent call <SID>Help()<CR>')
  call s:Map('nnoremap <silent> <buffer> <Leader>H :unsilent call <SID>Help()<CR>')

  " Scroll one page forward
  call s:Map('noremap <silent> <buffer> <script> <Space> :call <SID>NextPage()<CR><SID>L')
  call s:Map('map <buffer> <C-V> <Space>')
  call s:Map('map <buffer> f <Space>')
  call s:Map('map <buffer> <C-F> <Space>')
  call s:Map('map <buffer> <PageDown> <Space>')
  call s:Map('map <buffer> <kPageDown> <Space>')
  call s:Map('map <buffer> <S-Down> <Space>')
  call s:Map('map <buffer> z <Space>')
  call s:Map('map <buffer> <Esc><Space> <Space>')

  " Re-read file and page forward "tail -f"
  call s:Map('map <silent> <buffer> F :e<CR>G<SID>L:sleep 1<CR>F')

  " Scroll half a page forward
  call s:Map('noremap <buffer> <script> d <C-D><SID>L')
  call s:Map('map <buffer> <C-D> d')

  " Scroll one line forward
  call s:Map('noremap <buffer> <script> <CR> <C-E><SID>L')
  call s:Map('map <buffer> <C-N> <CR>')
  call s:Map('map <buffer> e <CR>')
  call s:Map('map <buffer> <C-E> <CR>')
  call s:Map('map <buffer> j <CR>')
  call s:Map('map <buffer> <C-J> <CR>')
  call s:Map('map <buffer> <Down> 1<C-d>')

  " Scroll one page backward
  call s:Map('noremap <buffer> <script> b <C-B><SID>L')
  call s:Map('map <buffer> <C-B> b')
  call s:Map('map <buffer> <PageUp> b')
  call s:Map('map <buffer> <kPageUp> b')
  call s:Map('map <buffer> <S-Up> b')
  call s:Map('map <buffer> w b')
  call s:Map('map <buffer> <Esc>v b')

  " Scroll half a page backward
  call s:Map('noremap <buffer> <script> u <C-U><SID>L')
  call s:Map('noremap <buffer> <script> <C-U> <C-U><SID>L')

  " Scroll one line backward
  call s:Map('noremap <buffer> <script> k <C-Y><SID>L')
  call s:Map('map <buffer> y k')
  call s:Map('map <buffer> <C-Y> k')
  call s:Map('map <buffer> <C-P> k')
  call s:Map('map <buffer> <C-K> k')
  call s:Map('map <buffer> <Up> 1<C-u>')

  " Redraw
  call s:Map('noremap <buffer> <script> r <C-L><SID>L')
  call s:Map('noremap <buffer> <script> <C-R> <C-L><SID>L')
  call s:Map('noremap <buffer> <script> R <C-L><SID>L')

  " Start of file
  call s:Map('noremap <buffer> <script> g gg<SID>L')
  call s:Map('map <buffer> < g')
  call s:Map('map <buffer> <Esc>< g')
  call s:Map('map <buffer> <Home> g')
  call s:Map('map <buffer> <kHome> g')

  " End of file
  call s:Map('noremap <buffer> <script> G G<SID>L')
  call s:Map('map <buffer> > G')
  call s:Map('map <buffer> <Esc>> G')
  call s:Map('map <buffer> <End> G')
  call s:Map('map <buffer> <kEnd> G')

  " Go to percentage
  call s:Map('noremap <buffer> <script> % %<SID>L')
  call s:Map('map <buffer> p %')

  " Search
  call s:Map('noremap <buffer> <script> / H$:call <SID>Forward()<CR>/')
  if &wrap
    call s:Map('noremap <silent> <buffer> <script> ? H0:call <SID>Backward()<CR>?')
  else
    call s:Map('noremap <silent> <buffer> <script> ? Hg0:call <SID>Backward()<CR>?')
  endif

  " esc-u to toggle search highlighting like in less
  call s:Map('nnoremap <silent> <buffer> <ESC>u :if g:less.buffers[bufnr(''%'')].hlsearch ==# 1 \| set nohlsearch \| nohlsearch \| let g:less.buffers[bufnr(''%'')].hlsearch = 0 \| else \| set hlsearch \| let g:less.buffers[bufnr(''%'')].hlsearch = 1 \| endif<CR><CR>')

  call s:Forward()
  silent! cunmap <buffer> <CR>

  " Quitting
  call s:Map('nnoremap <silent> <buffer> q :<C-u>silent call <SID>CloseBuffer()<CR>')

  " Switch to editing (switch off less mode) with v (,v is global)
  call s:Map('map <silent> <buffer> v :call <SID>ToggleLess()<CR>')
endfunction

function! s:CloseBuffer()
  try
    redir => ls_out
      silent! ls
    redir END

    " check if this is the last buffer, if so quit
    if count(split(ls_out, '\zs'), "\n") == 1
      quit
      return
    endif

    " if modifiable buffer was modified, force error message
    if &l:buftype !~? '^no\%(write\|file\)$' && &l:modified
      bwipeout " this will error out
      return
    endif

    " check if there are unopened args and we are on an arg
    if argc() > 1 && argv(argidx()) ==# bufname('%') && ls_out =~# '\n\s\+\d\+\s\+".*"\s\+line 0\>'
      let cur_buf = bufnr('%')

      execute (argidx() + 1) . 'argdelete'

      execute 'argument ' . (argidx() + 1)

      execute 'bwipeout ' . cur_buf
    else
      " otherwise try to delete the buffer

      " if current buffer is the current arg, delete from arg list
      if argv(argidx()) ==# bufname('%')
        execute (argidx() + 1) . 'argdelete'
      endif

      bwipeout
    endif
  catch
    echohl Error
    unsilent echo v:exception[stridx(v:exception, ':')+1 : -1]
    echohl None
  endtry
endfunction

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
  let leader = exists('g:mapleader') ? g:mapleader : '\'
  echo "<Space>   One page forward          b         One page backward"
  echo "d         Half a page forward       u         Half a page backward"
  echo "<Enter>   One line forward          k         One line backward"
  echo "G         End of file               g         Start of file"
  echo "N%        percentage in file        ".leader."h        Display this help"
  echo "\n"
  echo "/pattern  Search for pattern        ?pattern  Search backward for pattern"
  echo "n         next pattern match        N         Previous pattern match"
  echo "<ESC>u    toggle search highlight"
  echo "\n"
  echo ":n<Enter> Next file                 :N<Enter> Previous file"
  echo "\n"
  echo "q         Quit                      ".leader."v        Toggle Less Mode"
  let i = input("Hit Enter to continue")
endfunction

function! s:ToggleLess()
  if !exists('g:less.buffers.'.bufnr('%').'.enabled') || g:less.buffers[bufnr('%')].enabled ==# 0
    call s:LessMode()
    redraw
    echomsg 'Less Mode Enabled'
  else
    call s:End()
    redraw
    echomsg 'Less Mode Disabled'
  endif
endfunction

" enable for current file at source time, but disable for other files and from .vimrc
if !has('vim_starting') && (!exists('g:less.enabled') || g:less.enabled)
  Less
endif

function! s:End()
  call s:RestoreOpts()
  let g:less.buffers[bufnr('%')].enabled = 0
  silent! unmap <buffer> <Leader>h
  silent! unmap <buffer> <Leader>H
  silent! unmap <buffer> <Space>
  silent! unmap <buffer> <C-V>
  silent! unmap <buffer> f
  silent! unmap <buffer> <C-F>
  silent! unmap <buffer> z
  silent! unmap <buffer> <Esc><Space>
  silent! unmap <buffer> F
  silent! unmap <buffer> d
  silent! unmap <buffer> <C-D>
  silent! unmap <buffer> <CR>
  silent! unmap <buffer> <C-N>
  silent! unmap <buffer> e
  silent! unmap <buffer> <C-E>
  silent! unmap <buffer> j
  silent! unmap <buffer> <C-J>
  silent! unmap <buffer> b
  silent! unmap <buffer> <C-B>
  silent! unmap <buffer> w
  silent! unmap <buffer> <Esc>v
  silent! unmap <buffer> u
  silent! unmap <buffer> <C-U>
  silent! unmap <buffer> k
  silent! unmap <buffer> y
  silent! unmap <buffer> <C-Y>
  silent! unmap <buffer> <C-P>
  silent! unmap <buffer> <C-K>
  silent! unmap <buffer> r
  silent! unmap <buffer> <C-R>
  silent! unmap <buffer> R
  silent! unmap <buffer> g
  silent! unmap <buffer> <
  silent! unmap <buffer> <Esc><
  silent! unmap <buffer> G
  silent! unmap <buffer> >
  silent! unmap <buffer> <Esc>>
  silent! unmap <buffer> %
  silent! unmap <buffer> p
  silent! unmap <buffer> n
  silent! unmap <buffer> N
  silent! unmap <buffer> q
  silent! unmap <buffer> v
  silent! unmap <buffer> /
  silent! unmap <buffer> ?
  silent! unmap <buffer> <Up>
  silent! unmap <buffer> <Down>
  silent! unmap <buffer> <PageDown>
  silent! unmap <buffer> <kPageDown>
  silent! unmap <buffer> <PageUp>
  silent! unmap <buffer> <kPageUp>
  silent! unmap <buffer> <S-Down>
  silent! unmap <buffer> <S-Up>
  silent! unmap <buffer> <Home>
  silent! unmap <buffer> <kHome>
  silent! unmap <buffer> <End>
  silent! unmap <buffer> <kEnd>
endfunction

let &cpo = s:save_cpo

" vim: sw=2
