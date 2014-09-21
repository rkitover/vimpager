# taken from: https://github.com/ssmccoy/awkbot/blob/master/src/bitwise.awk
#
# A small collection of bitwise operations.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

##
# >>
function bit_right (value, distance) {
    return value / (2 ^ distance)
}

##
# <<
function bit_left (value, distance) {
    return value * (2 ^ distance)
}

##
# xor
function bit_xor (a, b, r, i, ia, ib) {
    r = 0

    for (i = 0; i < 32; i++) {
        c = int(2 ^ i)

        ia = int(a / c) % 2
        ib = int(b / c) % 2

        r += (ia || ib) && (ia != ib) * c
    }

    return r
}

##
# &
function bit_and (a, b, r, i, c, ia, ib) {
    r = 0

    for (i = 0; i < 32; i++) {
        c = 2 ^ i

        ia = int(a / c) % 2
        ib = int(b / c) % 2

        r += (ia && ib) * c
    }

    return r
}

##
# |
function bit_or (a, b, r, i, ia, ib) {
    r = 0

    for (i = 0; i < 32; i++) {
        c = 2 ^ i

        ia = int(a / c) % 2
        ib = int(b / c) % 2

        r += (ia || ib) * c
    }

    return r
}
