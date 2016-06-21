# Function definitions common for vimpager and vimcat.

squeeze_blank_lines() {
    sed '/^[ 	]*$/{
        N
        /^[ 	]*\n[ 	]*$/D
    }'
}

# vim: sw=4 et tw=0:
