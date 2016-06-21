# Function definitions for vimcat.

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

        cd "${tmp_dir%/*}" 2>/dev/null # some systems cannot remove CWD

        rm -rf "$tmp_dir" 2>/dev/null # rm -rf "" shows error on OpenBSD
    ) &
    exit "$@"
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
    cat -- "$pipeline_start" | (eval "$pipeline" <&3 & echo $! > "$tmp_dir/pipeline_pid") 3<&0
    pipeline_pid=$(cat "$tmp_dir/pipeline_pid")
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
        ("$vim" "$@" </dev/tty >/dev/null 2>&1; touch "$tmp_dir/vim_done") &
        vim_pid=$!
    else
        "$vim" "$@" </dev/tty
        touch "$tmp_dir/vim_done"
    fi
}

squeeze_blank_lines() {
    sed '/^[ 	]*$/{
        N
        /^[ 	]*\n[ 	]*$/D
    }'
}

# vim: sw=4 et tw=0:
