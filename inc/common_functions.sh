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

# vim: sw=4 et tw=0:
