# Function definitions common for vimpager and vimcat.

squeeze_blank_lines() {
    sed '/^[ 	]*$/{
        N
        /^[ 	]*\n[ 	]*$/D
    }'
}

create_tmp_directory() {
    if ! mkdir $mkdir_options "$tmp"; then
        echo "ERROR: Could not create temporary directory $tmp" >&2
        rm -rf "$tmp" 2>/dev/null # rm -rf "" shows error on OpenBSD
        exit 1
    fi
}

set_system_vars() {
    case "$(uname -s)" in
        Linux) linux=1;;
        SunOS) solaris=1;;
        Darwin) osx=1 bsd=1;;
        CYGWIN*) cygwin=1 win32=1;;
        MINGW*) msys=1 win32=1;;
        MSYS*) msys=1 win32=1;;
        OpenBSD) openbsd=1 bsd=1;;
        FreeBSD) freebsd=1 bsd=1;;
        NetBSD) netbsd=1 bsd=1;;
        *) bsd=1;;
    esac
}

install_trap() {
    trap 'quit 1' PIPE HUP INT QUIT ILL TRAP KILL BUS TERM
}

check_for_cygpath() {
    # special handling to rewrite cygwin/msys paths to windows POSIX paths
    if [ -n "$win32" ] && command -v cygpath >/dev/null; then
        _have_cygpath=1
    fi
}

resolve_path() {
    if [ -n "$_have_cygpath" ]; then
        cygpath --unix "$1"
    else
        echo "$1"
    fi
}

find_tmp_directory() {
    # Find and create the temporary directory used by vimpager.  Set the $tmp and $mkdir_options variable.
    mkdir_options='-m 700'
    # Default to /tmp
    tmp=/tmp

    if [ -n "$win32" ]; then
        # Use the real TEMP directory on windows in case we are
        # using a native vim/gvim
        # TEMP can be /tmp sometimes too
        tmp=$(resolve_path "$TEMP")
        if [ -n "$msys" -a -n "$temp" ]; then
            # MSYS2 is a little tricky, we're gonna stick to the user's private temp
            tmp=$(resolve_path "$temp")
        fi
        # chmod doesn't work here, even in /tmp sometimes
        mkdir_options=
    fi

    # Add a final component to the path, all other temp files should be placed in this directory.
    tmp=$tmp/${prog}_$$
}

# vim: sw=4 et tw=0:
