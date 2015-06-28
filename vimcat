#!/bin/sh
#!/usr/bin/env vim
#! This is a bash script that executes itself as a vimscript to do its work
#! Based on _v by Magnus Woldrich: https://github.com/trapd00r/utils/blob/master/_v

: if 0
  # Just pass through if not on a tty
  if [ ! -t 1 ]; then
    exec cat "${@}"
  fi
  # try to find a better shell, especially on Solaris

  PATH=$PATH:/usr/local/bin:/opt/csw/bin:/opt/local/bin:/usr/dt/bin:/usr/xpg4/bin:/usr/bin:/bin

  _MY_SHELL=/bin/sh
  export _MY_SHELL

  if [ -z "$IN_BASH" ] && command -v bash >/dev/null; then
    IN_BASH=1
    export IN_BASH
    _MY_SHELL=`command -v bash`
    export _MY_SHELL
    exec bash "$0" "$@"
  elif [ -z "$IN_BASH" ] && [ -z "$IN_KSH" ]; then
    if command -v dtksh >/dev/null; then
      IN_KSH=1
      export IN_KSH
      _MY_SHELL=`command -v dtksh`
      export _MY_SHELL
      exec dtksh "$0" "$@"
    elif [ -x /usr/xpg4/bin/sh ]; then
      IN_KSH=1
      export IN_KSH
      _MY_SHELL=/usr/xpg4/bin/sh
      export _MY_SHELL
      exec /usr/xpg4/bin/sh "$0" "$@"
    elif command -v ksh93 >/dev/null; then
      IN_KSH=1
      export IN_KSH
      _MY_SHELL=`command -v ksh93`
      export _MY_SHELL
      exec ksh93 "$0" "$@"
    elif command -v ksh >/dev/null; then
      IN_KSH=1
      export IN_KSH
      _MY_SHELL=`command -v ksh`
      export _MY_SHELL
      exec ksh "$0" "$@"
    else
      _MY_SHELL="${SHELL:-/bin/sh}"
    fi
  fi

  # hopefully we're now POSIX, and shell is saved in ${_MY_SHELL}

  tmp_dir=/tmp
  mkdir_options="-m 700"

  case $(uname -s) in
    MINGW*|MSYS*)
      if [ -n "${temp}" ]; then
        # MSYS2 is a little tricky, we're gonna stick to the user's private temp
        # the -m mode switch to mkdir doesn't work
        tmp_dir=$(cygpath --unix "${temp}")
        mkdir_options=""
      fi
    ;;
  esac

  tmp_dir="${tmp_dir}/vimcat_${$}"

  if ! mkdir ${mkdir_options} ${tmp_dir}; then
    echo Could not create temporary directory ${tmp_dir} >&2
    exit 1
  fi 

  trap "rm -rf ${tmp_dir}" HUP INT QUIT ILL TRAP KILL BUS TERM
  tmp_file=${tmp_dir}/vimcat

  script=$(command -v ${0})

  # check for arguments to pass to vim
  while [ $# -gt 0 ] ; do
    case "${1}" in
      "-c")
        shift
        if [ -z "${extra_c}" ]; then
          extra_c="${1}"
        else
          extra_c="${extra_c} | ${1}"
        fi
        shift
        ;;
      "--cmd")
        shift
        if [ -z "${extra_cmd}" ]; then
          extra_cmd="${1}"
        else
          extra_cmd="${extra_cmd} | ${1}"
        fi
        shift
        ;;
      "-u")
        shift
        vimcatrc="${1}"
        shift
        ;;
      "--")
        shift
        break
        ;;
      -*)
        echo "${0}: bad option '${1}'"
        exit 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [ -z "${vimcatrc}" ]; then
    if [ -f ~/.vimcatrc ]; then
        vimcatrc="~/.vimcatrc"
    else
        vimcatrc=""
    fi
  fi

  if [ -z "${extra_cmd}" ]; then
    extra_cmd='silent! echo'
  fi

  if [ -z "${extra_c}" ]; then
    extra_c='silent! echo'
  fi

  if [ "${#}" -eq 0 ]; then
    set -- -
  fi

  for file in "$@"
  do
    if [ "${#}" -ge 2 ]; then
      echo "==> ${file} <=="
    fi

    if [ "${file}" = "-" ]; then
      cat - >${tmp_file}
      file=${tmp_file}
    fi

    # Check that the file exists
    if test -r "${file}" -a -f "${file}"; then
      if test -s "${file}"; then
        if [ -n "${vimcatrc}" ]; then
          vim -E -X -R -i NONE -u "${vimcatrc}" --cmd "${extra_cmd}" -c "source ${script} | ${extra_c} | visual | call AnsiHighlight(\"${tmp_file}\") | q" -- "${file}" </dev/tty >/dev/null 2>&1
        else
          vim -E -X -R -i NONE                  --cmd "${extra_cmd}" -c "source ${script} | ${extra_c} | visual | call AnsiHighlight(\"${tmp_file}\") | q" -- "${file}" </dev/tty >/dev/null 2>&1
        fi
        cat "${tmp_file}"
        # if file doesn't end in a newline, output a newline
        # regular Solaris tail does not work for this
        tail_cmd=tail
        if [ -x /usr/xpg4/bin/tail ]; then
          tail_cmd=/usr/xpg4/bin/tail
        fi
        if command -v gtail >/dev/null; then
          tail_cmd=gtail
        fi
        last_char=$($tail_cmd -c 1 "${tmp_file}")
        if [ "${last_char}" != "" ]; then
          echo
        fi
      fi
    else
      echo "${0}: Cannot read file: ${file}" >&2
    fi
  done

  rm -rf "${tmp_dir}"

  exit

: endif
: endif
: endif
: endif
: endif
: endwhile
: endif
: endfor
: endif
: endif
: endif
: endif
: endif
: endif
: endif
: endif
: endif
: endif
: endif
: endif
: endif
: endif

" AnsiHighlight: Allows for marking up a file, using ANSI color escapes when
" the syntax changes colors, for easy, faithful reproduction.
" Author: Matthew Wozniski (mjw@drexel.edu)
" Date: Fri, 01 Aug 2008 05:22:55 -0400
" Version: 1.0 FIXME
" History: FIXME see :help marklines-history
" License: BSD. Completely open source, but I would like to be
" credited if you use some of this code elsewhere.

" Copyright (c) 2015, Matthew J. Wozniski {{{1
" All rights reserved.
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

" Turn off vi-compatible mode, unless it's already off {{{1
if &cp
  set nocp
endif

let s:type = 'cterm'
if &t_Co == 0
  let s:type = 'term'
endif

" Converts info for a highlight group to a string of ANSI color escapes {{{1
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

  if !exists('fg') && !groupnum == hlID('Normal')
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

function! AnsiHighlight(output_file)
  let retv = []

  for lnum in range(1, line('$'))
    let last = hlID('Normal')
    let output = s:GroupToAnsi(last) . "\<Esc>[K" " Clear to right

        " Hopefully fix highlighting sync issues
    exe "norm! " . lnum . "G$"

    let line = getline(lnum)

    for cnum in range(1, col('.'))
      if synIDtrans(synID(lnum, cnum, 1)) != last
        let last = synIDtrans(synID(lnum, cnum, 1))
        let output .= s:GroupToAnsi(last)
      endif

      let output .= matchstr(line, '\%(\zs.\)\{'.cnum.'}')
      "let line = substitute(line, '.', '', '')
            "let line = matchstr(line, '^\@<!.*')
    endfor
    let retv += [output]
  endfor
  " Reset the colors to default after displaying the file
  let retv[-1] .= "\<Esc>[0m"

  return writefile(retv, a:output_file)
endfunction

" See copyright in the vim script above (for the vim script) and in
" vimcat.md for the whole script.
"
" The list of contributors is at the bottom of the vimpager script in this
" project.
"
" vim: sw=2 sts=2 et ft=vim
