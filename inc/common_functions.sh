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

# vim: sw=4 et tw=0:
