# Function definitions for vimcat.

# the name of this program
prog=vimcat

quit() {
    (
        kill "$vim_pid" >/dev/null 2>&1
        do_sleep 100
        kill -9 "$vim_pid" >/dev/null 2>&1

        kill "$pipeline_pid" >/dev/null 2>&1
        do_sleep 100
        kill -9 "$pipeline_pid" >/dev/null 2>&1

        kill "$tail_pid" >/dev/null 2>&1
        do_sleep 100
        kill -9 "$tail_pid" >/dev/null 2>&1

        cd "${tmp%/*}" 2>/dev/null # some systems cannot remove CWD

        rm -rf "$tmp" 2>/dev/null # rm -rf "" shows error on OpenBSD
    ) &
    exit "${1:-0}"
}

do_sleep() {
    _ms=${1:-100}
    "$vim" -NEsnR -i NONE -u NONE +"sleep $_ms m" +q >/dev/null 2>&1
}

usage() {
    cat <<'EOF'
Usage: [32mvimcat [1;34m[[1;35mOPTION[1;34m][0m... [1;34m[[1;35mFILE [1m| [1;35m-[1;34m][0m...
Display [1;35mFILE[0m(s) in the terminal with (n)vim syntax highlighting using ANSI escape codes.

With no [1;35mFILE[0m, or when [1;35mFILE[0m is [1;35m-[0m, read standard input.

  [1m-h, --help, --usage[0m                This help screen.
  [1m-v, --version[0m                      Show version information and exit.
  [1m-n[0m                                 Print with line numbers.
  [1m-s[0m                                 Squeeze multiple blank lines into one.
  [1m-o [1;35mFILE[0m | [1;35m-[0m                        Output ANSI highlighted text to [1;35mFILE[0m or standard output.
  [1m--cmd [1;35mCOMMAND[0m                      Run (n)vim [1;35mCOMMAND[0m before initialization.
  [1m-c [1;35mCOMMAND[0m                         Run (n)vim [1;35mCOMMAND[0m after initialization.
  [1m-u [1;35mFILE[0m                            Use [1;35mFILE[0m as the vimrc.
  [1m-x [0m                                Give debugging output on stderr.

Examples:
  [32mvimcat [1;35mprogram.py[0m                  # output [1;35mprogram.py[0m with highlighting to terminal

Project homepage: <[1;34mhttp://github.com/rkitover/vimpager[0m>
and documentation: <[1;34mhttps://github.com/rkitover/vimpager/blob/master/markdown/vimcat.md[0m>
or available locally via: [32mman [1;35mvimcat[0m
EOF
}

write_chunks() {
    cd "$chunks_dir"
    rm -f -- *
    split -b 4096 -
    touch PIPELINE_DONE
}

start_pipeline() {
    if [ -n "$pipeline" ]; then
        pipeline="$pipeline | write_chunks"
    else
        pipeline=write_chunks
    fi
    cat -- "$pipeline_start" | (eval "$pipeline" <&3 & echo $! > "$tmp/pipeline_pid") 3<&0
    pipeline_pid=$(cat "$tmp/pipeline_pid")
}

start_highlight_job() {
    # INSERT VIMCAT_DEBUG PREPARATION HERE
    set -- -NE -i NONE -n \
        --cmd "set runtimepath^=$runtime" \
        --cmd "call vimcat#Init({ 'rc': '$vimcatrc' })" \
        --cmd visual \
        ${extra_cmd:+--cmd "$extra_cmd"} \
        ${extra_c:+-c "$extra_c"} \
        -c "call vimcat#Run(\"$dest_file\", ${line_numbers:-0}, \"$chunks_dir\", \"$pipeline_start\")"

    [ -n "$vimcatrc" ] && set -- "$@" -u "$vimcatrc"

    if [ "${VIMCAT_DEBUG:-0}" -eq 0 ]; then
        ("$vim" "$@" </dev/tty >/dev/null 2>&1; touch "$tmp/vim_done") &
        vim_pid=$!
    else
        "$vim" "$@" </dev/tty
        touch "$tmp/vim_done"
    fi
}

select_vim_executable() {
    if command -v vim >/dev/null; then
        vim=vim
    elif command -v nvim >/dev/null; then
        vim=nvim
    else
        echo "$0: neither vim nor nvim found, vim or nvim is required for vimcat" >&2
        exit 1
    fi
}

parse_command_line_options_1() {
    # if no args and no stdin, display usage
    if [ $# -eq 0 -a -t 0 ]; then
        usage
        quit 0
    fi

    # check for -h before main option parsing, this is much faster
    for arg in "$@"; do
        case "$arg" in
            "-h"|"--help"|"-help"|"--usage"|"-usage")
                usage
                quit 0
                ;;
            "-v"|"--version"|"-version")
                echo "vimcat $version"
                quit 0
                ;;
            "-x")
                set -x
                ;;
        esac
    done
}

create_fifo() {
    tmp_file_in=$tmp/vimcat_in.txt
    out_fifo=$tmp/vimcat_out.fifo

    if [ -n "$solaris" -o -n "$win32" ]; then
        # the fifo streaming doesn't work on windows and solaris
        touch "$out_fifo"
    else
        mkfifo "$out_fifo"
    fi
}

main() {
    # check for arguments
    while [ $# -gt 0 ] ; do
        case "$1" in
            "-c")
                shift
                if [ -z "$extra_c" ]; then
                    extra_c=$1
                else
                    extra_c="$extra_c | $1"
                fi
                shift
                ;;
            "--cmd")
                shift
                if [ -z "$extra_cmd" ]; then
                    extra_cmd=$1
                else
                    extra_cmd="$extra_cmd | $1"
                fi
                shift
                ;;
            "-u")
                shift
                vimcatrc=$1
                shift
                ;;
            "-o")
                shift
                output_file=$1
                shift
                ;;
            "-s")
                shift
                squeeze_blank_lines=1
                ;;
            "-n")
                shift
                line_numbers=1
                ;;
            "-x")
                # xtrace should already be set by the first option parsing
                shift
                ;;
            "--")
                shift
                break
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

    # Just pass through if not on a tty, unless -o was given
    if [ -z "$output_file" ]; then
        if [ ! -t 1 ]; then
            exec cat "$@"
        fi
    fi

    if [ -z "$vimcatrc" ]; then
        if [ -f ~/.vimcatrc ]; then
            vimcatrc=~/.vimcatrc
        else
            vimcatrc=
        fi
    fi

    if [ $# -eq 0 ]; then
        set -- -
    fi

    if [ -n "$output_file" -a $# -gt 1 ]; then
        echo "$0: -o can only be used with one input file or stdin." >&2
        quit 1
    fi

    chunks_dir=$tmp/chunks
    mkdir "$chunks_dir"

    i=1
    for file in "$@"
    do
        if [ $# -ge 2 ]; then
            if [ $i -gt 1 ]; then
                printf '\n'
            fi
            printf "==> %s <==\n\n" "$file"
        fi

        pipeline=
        pipeline_start=$file

        if [ "${squeeze_blank_lines:-0}" -eq 1 ]; then
            pipeline=squeeze_blank_lines
        fi

        exit_code=0

        # Check that the file is readable
        if [ "$file" != - ]; then
            if [ ! -r "$file" ]; then
                echo "$0: Cannot read file: $file" >&2
                exit_code=1
            fi

            [ ! -s "$file" ] && continue
        fi

        if [ -z "$output_file" -o "$output_file" = "-" ]; then
            dest_file=$out_fifo

            tail -f "$out_fifo" &
            tail_pid=$!
        else
            dest_file=$output_file
            printf '' > "$dest_file"
        fi

        start_highlight_job
        start_pipeline
        while [ ! -f "$tmp/vim_done" ]; do
            do_sleep 50
        done

        if [ -n "$tail_pid" ]; then
            # if it's not a fifo where this doesn't work, tail needs some time to catch up
            [ ! -p "$out_fifo" ] && do_sleep 1100

            kill $tail_pid >/dev/null 2>&1
        fi

        i=$((i + 1))
    done

    quit $exit_code
}

# vim: sw=4 et tw=0:
