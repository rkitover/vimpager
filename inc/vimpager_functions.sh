# Function definitions for vimpager.

# the name of this program
prog=vimpager

# this is compatible with osed
ANSI_RE='\[[;?]*[0-9.;]*[A-Za-z]'

main() {
    # if no args and no stdin, display usage
    if [ $# -eq 0 -a -t 0 ]; then
        usage
        quit 0
    fi

    # Parse the command line options as early as possible.  These variables might be set because of command line options and are thus initialized.
    vim_options=
    vimrc=
    extra_c=
    extra_cmd=
    line_numbers=0

    # Check for certain parameters to pass on to vim (or conceivably do something else)
    # Couldn't use getopt or getopts as neither supports options prepended with +
    while [ $# -gt 0 ] ; do
        case "$1" in
            -h|--help|-help|--usage|-usage)
                usage
                quit 0
                ;;
            -v|--version|-version)
                echo "vimpager $version"
                quit 0
                ;;
            +G|+)
                vim_options="$vim_options +";
                shift
                ;;
            -N|--LINE-NUMBERS)
                line_numbers=1
                shift
                ;;
            -c)
                shift
                extra_c="${extra_c:+$extra_c | }$1"
                shift
                ;;
            --cmd)
                shift
                extra_cmd="${extra_cmd:+$extra_cmd | }$1"
                shift
                ;;
            -u)
                shift
                vimrc=$1
                shift
                ;;
            -s) # Ubuntu man passes this option to /usr/bin/pager
                shift
                squeeze_blank_lines=1
                ;;
            --)
                shift
                break
                ;;
            -x)
                trace=1
                shift
                set -x
                ;;
            -)
                break
                ;;
            -*)
                echo "$0: bad option '$1', see --help for usage." >&2
                quit 1
                ;;
            *)
                break
                ;;
         esac
    done

    find_tmp_directory

    create_tmp_directory

    install_trap

    detect_term_size

    expand_config_vars

    find_vim_executable

    find_vimpagerrc_files

    read_vim_settings

    parse_pstree

    # if no args, assume stdin
    if [ $# -eq 0 ]; then
        set -- -
    # turn off man/perldoc support for > 1 arg
    elif [ $# -gt 1 ]; then
        is_man=
        is_perldoc=
        is_doc=
        force_strip_ansi=
    fi

    file_idx=1

    for file in "$@"; do
        if [ "$file" = - ]; then
            filename=stdin
        else
            if [ ! -r "$file" ]; then
                echo "$0: cannot read file '$file'" >&2
                quit 1
            fi

            filename=$(resolve_path "$file")
        fi

        set_key orig_file_names $file_idx "$filename"

        # $file still holds the orginal file name.  $filename will be
        # the encoded version of $file.  $tempfile is the path under
        # $tmp if the file is to be opend from there instead of the
        # original location.  If $tempfile is empty the file is to be
        # opened as $file.
        filename=$(encode_filename "$filename")
        tempfile=

        case "$(echo "$file" | tr 'A-Z' 'a-z')" in
            *.gz)
                filename=${filename%.??}
                tempfile=$tmp/$filename
                gunzip -c -- "$file" > "$tempfile"

                ;;
            *.bz2)
                filename=${filename%.??2}
                tempfile=$tmp/$filename
                bunzip2 -c -- "$file" > "$tempfile"
                ;;
            *.xz)
                filename=${filename%.??}
                tempfile=$tmp/$filename
                xzcat -c -- "$file" > "$tempfile"
                ;;
            *.z)
                filename=${filename%.?}
                tempfile=$tmp/$filename
                uncompress -c -- "$file" > "$tempfile"
                ;;
            *)
                if [ "$file" = - ]; then
                    tempfile=$tmp/$filename
                    cat -- "$file" > "$tempfile"
                fi
                ;;
        esac

        # check for ANSI codes and strip if not using ansiesc
        if head -100 "${tempfile:-$file}" | grep -Eq "$ANSI_RE"; then
            if [ -z "$ansiesc_available" -o -n "$force_strip_ansi" ]; then
                ansi_filter "${tempfile:-$file}" > "$tmp/$filename.work"
                tempfile=$tmp/$filename
                mv -f -- "$tempfile.work" "$tempfile"
            else
                echo 'call vimpager_utils#DoAnsiEsc()' >> "$tmp/$file_idx.vim"
                set_key ansi_files "$file_idx" yes
            fi
        fi

        # squeeze blank lines if option was specified, Ubuntu man with /usr/bin/pager does this
        if [ "${squeeze_blank_lines:-0}" -eq 1 ]; then
                squeeze_blank_lines < "${tempfile:-$file}" > "$tmp/$filename.work"
                tempfile=$tmp/$filename
                mv -f -- "$tempfile.work" "$tempfile"
        fi

        # dumb man detection when the pstree heuristic fails
        if [ -z "$is_doc" ] && head -12 "${tempfile:-$file}" | grep -Eq '^N(.)?A(.)?M(.)?E(.)?[ \t]*$'; then
            is_man=1
            is_doc=1
        fi

        # if it's a man page, remove starting blank lines, or the C syntax highlighting fails
        # and write out ft command for vim
        if [ -n "$is_doc" ]; then
            ansi_filter "${tempfile:-$file}" | overstrike_filter | awk '
                BEGIN { skipblank=1 }
                /^[ 	]*$/ { if (!skipblank) print }
                /[^ 	]/ { skipblank=0; print }
            ' > "$tmp/$filename.work"
            tempfile=$tmp/$filename
            mv -f -- "$tempfile.work" "$tempfile"

            if [ -n "$is_man" ]; then
                echo 'set ft=man' >> "$tmp/$file_idx.vim"
            elif [ -n "$is_perldoc" ]; then
                echo 'set ft=perldoc' >> "$tmp/$file_idx.vim"
            fi
        fi

        # if file is zero length, or one blank line (cygwin), and is only arg, exit
        if [ ! -s "${tempfile:-$file}" \
            -a $# -eq 1 \
            -o "$(cat "${tempfile:-$file}")" = "" \
            -a "$(wc -l < "${tempfile:-$file}")" -eq 1 ]; then

            quit 0
        fi

        set_key files $file_idx "$(resolve_path "${tempfile:-$file}")"

        file_idx=$((file_idx + 1))
    done

    file_count=$#

    set --
    i=1
    while [ $i -le $file_count ]; do
        set -- "$@" "$(get_key files $i)"
        i=$((i + 1))
    done

    if [ "${no_pass_thru:-0}" -ne 1 ] && fits_on_screen "$@"; then
        cat_files=1
    fi

    page_files "$@"

    quit $?
}

detect_term_size() {
    # Detect the terminal size and set the variables $cols and $lines.  If necessary $no_pass_thru is set.
    if command -v tput >/dev/null; then
        # this is the only way it works on some versions of Cygwin

        # 2>/dev/null makes tput not work, so don't do that
        # we are just going to hope that tput errors don't happen
        tput cols  > "$tmp/cols"
        tput lines > "$tmp/lines"

        cols=$(cat "$tmp/cols")
        lines=$(cat "$tmp/lines")

        rm -f -- "$tmp/cols" "$tmp/lines"
    fi

    # msys has no tput, this doesn't work on Cygwin by the way
    if [ -z "$cols" ] && command -v bash >/dev/null; then
        cols=$(bash -i -c 'echo $COLUMNS')
        lines=$(bash -i -c 'echo $LINES')
    fi

    # If we are unable to detect lines/columns, maximize
    # the window.
    if [ -z "$cols" ]; then
        cols=999
        lines=999
        no_pass_thru=1 # force loading vimpager
    fi
}

find_vimpagerrc_files() {
    # This function will find the system and the user vimpagerrc file and set the variables $system_vimrc and $vimrc.

    # determine location of rc file
    i=1
    OLDIFS=$IFS
    IFS='
'
    for var in $(IFS=$OLDIFS; "$tvim" -NEnR -i NONE ${vimrc:+-u "$vimrc"} +'call writefile(["", "VAL:" . $VIM, "VAL:" . $MYVIMRC], "/dev/stderr")' +q </dev/tty 2>&1 >/dev/null); do
        case "$var" in
            VAL:*)
                case $i in
                    1)
                        vim_dir=${var#VAL:}
                        ;;
                    2)
                        user_vimrc=${var#VAL:}
                        user_vimrc_dir=${user_vimrc%/*}
                        break
                        ;;
                esac
                i=$((i + 1))
                ;;
        esac
    done
    IFS=$OLDIFS

    # find system vimrc
    system_vimrc=$("$tvim" --version | sed -n '/system vimrc file: "/{
        s|\$VIM|'"$vim_dir"'|
        s/.*: "\([^"]*\).*/\1/p
        q
    }')

    # find the users vimpagerrc
    if [ -n "$vimrc" ]; then
        # The vimrc file was given on the command line.
        :
    elif [ -n "$VIMPAGER_RC" ]; then
        vimrc=$VIMPAGER_RC
    # check for vimpagerrc in same dir as vimrc in case it is set in VIMINIT
    elif [ -n "$user_vimrc_dir" -a -r "$user_vimrc_dir/.vimpagerrc" ]; then
        vimrc=$user_vimrc_dir/.vimpagerrc
    elif [ -n "$user_vimrc_dir" -a -r "$user_vimrc_dir/_vimpagerrc" ]; then
        vimrc=$user_vimrc_dir/_vimpagerrc
    elif [ -n "$user_vimrc_dir" -a -r "$user_vimrc_dir/vimpagerrc" ]; then
        vimrc=$user_vimrc_dir/vimpagerrc
    # check standard paths, according to :h initialization
    elif [ -r ~/.vimpagerrc ]; then
        vimrc=~/.vimpagerrc
    elif [ -r ~/.vim/vimpagerrc ]; then
        vimrc=~/.vim/vimpagerrc
    elif [ -r ~/_vimpagerrc ]; then
        vimrc=~/_vimpagerrc
    elif [ -r ~/vimfiles/vimpagerrc ]; then
        vimrc=~/vimfiles/vimpagerrc
    elif [ -r "$vim_dir/_vimpagerrc" ]; then
        vimrc=$vim_dir/_vimpagerrc
    # try the user's ~/.vimrc
    elif [ -n "$user_vimrc" ]; then
        :
    # if no user vimrc, then check for a global /etc/vimpagerrc
    elif [ -n "$system_vimpagerrc" -a -f "$system_vimpagerrc" ]; then
        :
    # check a couple of common places for the standalone version
    elif [ -f /usr/local/etc/vimpagerrc ]; then
        vimrc=/usr/local/etc/vimpagerrc
    elif [ -f /etc/vimpagerrc ]; then
        vimrc=/etc/vimpagerrc
    fi
}

read_vim_settings() {
    # Read settings from the vimpagerrc file and possibly set $use_gvim, $ansiesc_available, $disable_x11 and $no_pass_thru.
    i=1
    OLDIFS=$IFS
    IFS='
'
    for var in $(IFS=$OLDIFS; "$tvim" -NEnR ${vimrc:+-u "$vimrc"} -i NONE --cmd 'let g:vimpager = { "enabled": 1 }' +'
        if !exists("g:vimpager.gvim")
            if !exists("g:vimpager_use_gvim")
                let g:vimpager.gvim = 0
            else
                let g:vimpager.gvim = g:vimpager_use_gvim
            endif
        endif

        if !exists("g:vimpager.X11")
            if !exists("g:vimpager_disable_x11")
                let g:vimpager.X11 = 1
            else
                let g:vimpager.X11 = !g:vimpager_disable_x11
            endif
        endif

        if !exists("g:vimpager.passthrough")
            if !exists("g:vimpager_passthrough")
                let g:vimpager.passthrough = 1
            else
                let g:vimpager.passthrough = g:vimpager_passthrough
            endif
        endif

        let g:use_ansiesc = 0

        if has("conceal") && (!exists("g:vimpager.ansiesc") || g:vimpager.ansiesc == 1) && (!exists("g:vimpager_disable_ansiesc") || g:vimpager_disable_ansiesc == 0)
            let g:use_ansiesc = 1
        endif

        call writefile([""] + map([g:vimpager.gvim, g:vimpager.X11, g:vimpager.passthrough, g:use_ansiesc], "\"VAL:\".v:val"), "/dev/stderr")
        quit
    ' </dev/tty 2>&1 >/dev/null); do
        case "$var" in
            VAL:*)
                case $i in
                    1)
                        [ "${var#VAL:}" -eq 1 ] && use_gvim=1
                        ;;
                    2)
                        [ "${var#VAL:}" -eq 0 ] && disable_x11=1
                        ;;
                    3)
                        [ "${var#VAL:}" -eq 0 ] && no_pass_thru=1
                        ;;
                    4)
                        [ "${var#VAL:}" -ne 0 ] && ansiesc_available=1
                        break
                        ;;
                esac
                i=$((i + 1))
                ;;
        esac
    done
    IFS=$OLDIFS
}

find_vim_executable() {
    # Find the vim executable to use.  Set $vim_cmd and $gui.
    if [ -n "$win32" ]; then
        # msys/cygwin may be using a native vim, and if we're not in a real
        # console the native vim will not work, so we have to use gvim.

        if [ "x$TERM" != "xdumb" -a "x$TERM" != "xcygwin" -a "x$TERM" != "x" ]; then
            if command -v vim >/dev/null | grep -Eq '^/(cygdrive/)?[a-z]/'; then
                use_gvim=1
            fi
        fi
    fi

    tvim=vim

    if [ -n "$EDITOR" -a -z "$VIMPAGER_VIM" ]; then
        case "${EDITOR##*/}" in
            *vim*)
                export VIMPAGER_VIM=$EDITOR
                ;;
        esac
    fi

    if [ -n "$VIMPAGER_VIM" ]; then
        case "${VIMPAGER_VIM##*/}" in
            vim*)
                tvim=$VIMPAGER_VIM
                ;;
            nvim*)
                tvim=$VIMPAGER_VIM
                ;;
            gvim*|mvim*)
                use_gvim=1
                gvim=$VIMPAGER_VIM
                ;;
        esac
    fi

    if [ -n "$use_gvim" ]; then
        # determine if this is an ssh session and/or $DISPLAY is set
        if [ -n "$osx" ]; then
            if [ -z "$SSH_CONNECTION" ] && command -v mvim >/dev/null; then
                vim_cmd=${gvim:-mvim}
                gui=1
            else
                vim_cmd=$tvim
            fi
        elif [ -n "$cygwin" ]; then
            if command -v gvim >/dev/null; then
                if [ -n "$SSH_CONNECTION" ]; then
                    vim_cmd=$tvim
                # The Cygwin gvim uses X
                elif win32_native gvim; then
                    if [ -z "$DISPLAY" ]; then
                        vim_cmd=$tvim
                    else
                        vim_cmd=${gvim:-gvim}
                        gui=1
                    fi
                else
                    vim_cmd=${gvim:-gvim}
                    gui=1
                fi
            else
                vim_cmd=$tvim
            fi
        elif [ -n "$msys" ]; then
            if [ -z "$SSH_CONNECTION" ] && command -v gvim >/dev/null; then
                vim_cmd=${gvim:-gvim}
                gui=1
            else
                vim_cmd=$tvim
            fi
        elif [ -z "$DISPLAY" ]; then
            vim_cmd=$tvim
        else
            if command -v gvim >/dev/null; then
                vim_cmd=${gvim:-gvim}
                gui=1
            else
                vim_cmd=$tvim
            fi
        fi
    else
        vim_cmd=${vim_cmd:-${tvim:-vim}}
    fi

    if [ ! -n "$gui" -a -n "$disable_x11" ]; then
        vim_cmd="$vim_cmd -X"
    fi
}

parse_pstree() {
    # Parse the process tree and set $is_man, $is_doc, $is_perldoc, $force_strip_ansi and $extra_cmd.
    ptree=$(do_ptree)

    # Check if called from man, perldoc or pydoc
    if echo "$ptree" | grep -Eq '([ \t]+|/)(man|[Pp]y(thon|doc)[0-9.]*|[Rr](uby|i)[0-9.]*)([ \t]|$)'; then
        is_man=1
        is_doc=1
        force_strip_ansi=1
    elif echo "$ptree" | grep -Eq '([ \t]+|/)perl(doc)?([0-9.]*)?([ \t]|$)'; then
        is_perldoc=1
        is_doc=1
        force_strip_ansi=1
    fi

    extra_cmd="${extra_cmd:+$extra_cmd | }let g:vimpager.ptree=[$(echo "$ptree" | awk '{ print "\"" $2 "\"" }' | tr '\n' ',')] | call remove(g:vimpager.ptree, -1) | let g:vimpager_ptree = g:vimpager.ptree"
}

expand_config_vars() {
    eval runtime=\"$runtime\"
    eval vimcat=\"$vimcat\"
    eval system_vimpagerrc=\"$system_vimpagerrc\"
}

quit() {
    rm -f gvim.exe.stackdump # for a cygwin bug
    cd "${tmp%/*}" 2>/dev/null # some systems cannot remove CWD
    rm -rf "$tmp" 2>/dev/null # rm -rf "" shows error on OpenBSD
    exit "${1:-0}"
}

usage() {
    cat <<'EOF'
Usage: [32mvimpager [1;34m[[1;35mOPTION[1;34m][0m... [1;34m[[1;35mFILE [1m| [1;35m-[1;34m][0m...
Display [1;35mFILE[0m(s) in (n)vim with a pager emulating less.

With no [1;35mFILE[0m, or when [1;35mFILE[0m is [1;35m-[0m, read standard input.

  [1m-h, --help, --usage[0m                Show this help screen and exit.
  [1m-v, --version[0m                      Show version information and exit.
  [1m+G, +[0m                              Go to the end of the file.
  [1m-N, --LINE-NUMBERS[0m                 Show line numbers.
  [1m-s[0m                                 Squeeze multiple blank lines into one.
  [1m--cmd [1;35mCOMMAND[0m                      Run (n)vim [1;35mCOMMAND[0m before initialization.
  [1m-c [1;35mCOMMAND[0m                         Run (n)vim [1;35mCOMMAND[0m after initialization.
  [1m-u [1;35mFILE[0m                            Use [1;35mFILE[0m as the vimrc.
  [1m-x [0m                                Give debugging output on stderr.

Examples:
  [32mvimpager [1;35mprogram.py[0m                # view [1;35mprogram.py[0m in the pager
  PAGER=vimpager [32mman[0m 3 [1;35msprintf[0m       # view man page for [1;35msprintf[0m(3)

Project homepage and documentation: <[1;34mhttp://github.com/rkitover/vimpager[0m>
or available locally via: [32mman [1;35mvimpager[0m
Press '[1;35m,h[0m' for a summary of keystrokes in the program.
EOF
}

awk() {
    command "$_awk" "$@"
}

sed() {
    command "$_sed" "$@"
}

grep() {
    case "$1" in
        -Eq)
            # we only check for -Eq when it's the only option
            case "$2" in
                -*)
                    command "$_grep" "$@"
                    ;;
                *)
                    if [ "${_have_grep_E_q:-0}" -eq 1 ]; then
                        command "$_grep" "$@"
                    else
                        shift
                        awk_grep_E_q "$@"
                    fi
                    ;;
            esac
            ;;
        *)
            command "$_grep" "$@"
            ;;
    esac
}

awk_grep_E_q() {
    _pat=$(printf '%s' "$1" | sed -e 's!/!\\/!g')
    shift
    awk '
        BEGIN { exit_val = 1 }
        /'"$_pat"'/ { exit_val = 0; exit(exit_val) }
        END { exit(exit_val) }
    ' "$@"
}

head() {
    _lines=
    case "$1" in
        -[0-9]*)
            _lines=${1#-}
            shift
    esac

    if [ -z "$_lines" ]; then
        command "$_head" "$@"
    elif [ "$_head_syntax" = "new" ]; then
        command "$_head" -n $_lines -- "$@"
    elif [ -z "$_head_no_double_dash" ]; then
        command "$_head" -$_lines -- "$@"
    else
        command "$_head" -$_lines "$@"
    fi
}

# We are escaping only slashes (because they are special in file paths) and
# percent (because it is our escape char).  This makes it possible to encode
# the path to the original file in the basename of the temporary file.
encode_filename() {
    echo "$@" | sed -e 's|%|%25|g' -e 's|/|%2F|g'
}

# emulate arrays
set_key() {
    eval "$1_$2=\"$3\""
}

get_key() {
    eval "echo \"\${$1_$2}\""
}

# this actually runs vim or gvim, or vimcat, or just cats the file
page_files() {
    # EXTRACT BUNDLED SCRIPTS HERE

    if [ -n "$cat_files" ]; then
        i=1
        for cur_file in "$@"; do
            orig_file=$(get_key orig_file_names $i)

            if [ $# -gt 1 ]; then
                if [ $i -gt 1 ]; then
                    printf '\n'
                fi
                printf '==> %s <==\n\n' "$orig_file"
            fi

            if [ -n "$(get_key ansi_files $i)" ]; then
                cat "$cur_file"
                _exit_status=$?
            else
                "$POSIX_SHELL" ${trace:+-x} "$vimcat" ${vimrc:+-u "$vimrc"} \
                    --cmd "set rtp^=$runtime | let vimpager={ 'enabled': 1 }" \
                    ${extra_cmd:+--cmd "$extra_cmd"} \
                    -c 'silent! source '"$tmp/$i"'.vim' \
                    ${extra_c:+-c "$extra_c"} \
                    "$cur_file" </dev/tty
                _exit_status=$?
            fi
            i=$((i + 1))
        done
        return "${_exit_status:-0}"
    fi

    init_opts="'columns': $cols, 'tmp_dir': '$tmp', 'line_numbers': ${line_numbers:-0}, 'is_doc': ${is_doc:-0}, 'runtime': '$runtime', 'rc': '$vimrc'"

    "$vim_cmd" -N -i NONE \
        $vim_options \
        --cmd "set rtp^=$runtime" \
        --cmd "call vimpager#Init({ $init_opts })" \
        --cmd "silent! exe 'source ' . fnameescape('$system_vimrc')" \
        ${extra_cmd:+--cmd "$extra_cmd"} \
        ${vimrc:+-u "$vimrc"} \
        ${extra_c:+-c "$extra_c"} \
        "$@" </dev/tty

    _vim_exit_status=$?

    if [ -n "$gui" ]; then
        ( (
            while [ ! -e "$tmp/gvim_done" ]; do
                sleep 1
            done
            quit 0
        ) & ) # double fork to ignore HUP etc.

        exit $_vim_exit_status # must NOT delete "$tmp"
    fi

    return $_vim_exit_status
}

awk_pstree() {
    awk -v mypid=$1 '{
        cmd[$1]=substr($0, index($0, $3))
        ppid[$1]=$2
    }
    END {
        while (mypid != 1 && cmd[mypid]) {
            ptree=mypid " " cmd[mypid] "\n" ptree
            mypid=ppid[mypid]
        }
        print ptree
    }'
}

cygwin_ps() {
    ps | sed 's/^[^0-9]*//; /^$/d' | awk '{ print $1 " " $2 " " substr($0, index($0, $8)) }'
}

do_ptree() {
    if [ -n "$solaris" ]; then
        # Tested on Solaris 8 and 10
        ptree $$
    elif [ -n "$win32" ]; then
        cygwin_ps | awk_pstree $$
    else
        ps aw -o pid= -o ppid= -o command= | awk_pstree $$
    fi 2>/dev/null
}

win32_native() {
    if [ "x$(get_key _win32_native "$1")" = x1 ]; then
        return 0
    else
        if [ -n "$msys" -o -n "$cygwin" ]; then
            if command -v "$1" > /dev/null | grep -Eq '^/(cygdrive/)?[a-z]/'; then
                set_key _win32_native "$1" 1
                return 0
            else
                set_key _win32_native "$1" 0
                return 1
            fi
        else
            set_key _win32_native "$1" 0
            return 1
        fi
    fi
    return 1
}

ansi_filter() {
    sed -e 's/'"$ANSI_RE"'//g' "$@"
}

# Even /bin/sed on Solaris handles UTF-8 characters correctly, so we can safely
# use sed for this.
overstrike_filter() {
    sed 's/.//g' "$@"
}

fits_on_screen() {
    [ $# -eq 0 ] && set -- -

    # First remove overstrikes and ANSI codes with sed
    ansi_filter "$@" | overstrike_filter | \
    awk '
    {
        if (NR == 1) {
        lines = total_lines - 2 - (num_files - 1) * file_sep_lines

        if (num_files - 1)
            lines -= first_file_sep_lines

        total_cols += 0 # coerce to number
        }

        col = 0

        for (pos = 1; pos <= length($0); pos++) {
        c = substr($0, pos, 1)

        # handle tabs
        if (c == "\t")
            col += 8 - (col % 8)
        else
            col++

        if (col > total_cols) {
            if (!--lines) exit(1)
            col = 1
        }
        }

        if (!--lines) exit(1)
    }
    ' num_files=$# total_lines=$lines total_cols=$cols file_sep_lines=3 first_file_sep_lines=2 -
}

select_awk_executable() {
    if command -v gawk >/dev/null; then
        _awk=gawk
    elif command -v nawk >/dev/null; then
        _awk=nawk
    elif command -v mawk >/dev/null; then
        _awk=mawk
    elif [ -x /usr/xpg4/bin/awk ]; then
        _awk=/usr/xpg4/bin/awk
    elif command -v awk >/dev/null; then
        _awk=awk
    else
        echo "ERROR: No awk found!" >&2
        quit 1
    fi
}

select_sed_executable() {
    if command -v gsed >/dev/null; then
        _sed=gsed
    elif [ -x /usr/xpg4/bin/sed ]; then
        _sed=/usr/xpg4/bin/sed
    elif command -v sed >/dev/null; then
        _sed=sed
    else
        echo "ERROR: No sed found!" >&2
        quit 1
    fi
}

select_grep_executable() {
    if command -v ggrep >/dev/null; then
        _grep=ggrep
    elif [ -x /usr/xpg4/bin/grep ]; then
        _grep=/usr/xpg4/bin/grep
    elif command -v grep >/dev/null; then
        _grep=grep
    else
        echo "ERROR: No grep found!" >&2
        quit 1
    fi
}

check_for_grep_q() {
    # check that grep -Eq works
    if [ -z "$(echo foo | "$_grep" -Eq foo >/dev/null 2>&1)" -a $? -eq 0 ]; then
        _have_grep_E_q=1
    fi
}

select_head_executable() {
    if command -v ghead >/dev/null; then
        _head=ghead
    else
        _head=head
    fi
}

select_head_syntax() {
    if [ "$(echo xx | head -n 1 2>/dev/null)" = "xx" ]; then
        _head_syntax=new
    else
        if ! head -1 -- "$0" >/dev/null 2>&1; then
            _head_no_double_dash=1
        fi
    fi
}

# vim: sw=4 et tw=0:
