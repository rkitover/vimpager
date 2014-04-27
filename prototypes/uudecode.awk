#!/bin/sh

# uudecode in standard awk, decodes stdin to stdout
#
# It's not exactly lightning fast, but passable for reasonable sizes.
#
# Copyright (c) 2014, Rafael Kitover <rkitover@gmail.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if command -v gawk >/dev/null; then
    awk=gawk
elif command -v nawk >/dev/null; then
    awk=nawk
elif command -v mawk >/dev/null; then
    awk=mawk
elif [ -x /usr/xpg4/bin/awk ]; then
    awk=/usr/xpg4/bin/awk
elif command -v awk >/dev/null; then
    # plain solaris 10 awk won't work, no functions
    awk=awk
else
    echo "No awk found!" >&2
    exit 1
fi

$awk '
BEGIN {
    charset=" !\"#$%&'\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_";
}

function charval(char) {
    return index(charset, char) + 32 - 1;
}

/^begin / { next }
/^end$/   { exit }

{
    cnt = substr($0, 1, 1);

    if (cnt == "`") next;

    cnt = charval(cnt) - 32;

    enc = substr($0, 2, length($0) - 1);

    chars = 0;
    pos   = 1;

    while (chars < cnt) {
        grp = substr(enc, pos, 4);
        gsub(/`/, " ", grp); # zero bytes

        c1 = charval(substr(grp, 1, 1)) - 32;
        c2 = charval(substr(grp, 2, 1)) - 32;
        c3 = charval(substr(grp, 3, 1)) - 32;
        c4 = charval(substr(grp, 4, 1)) - 32;

        char_val = bit_or(c4, bit_or(bit_or(bit_left(c3, 6), bit_left(c2, 12)), bit_left(c1, 18)));

        char[1] = sprintf("%c", bit_right(bit_and(char_val, 16711680), 16));
        char[2] = sprintf("%c", bit_right(bit_and(char_val, 65280),     8));
        char[3] = sprintf("%c", bit_and(char_val, 255));

        for (i = 1; i <= 3 && chars < cnt; i++) {
            printf("%s", char[i]);

            chars++;
        }

        pos += 4;
    }
}

# The following bitwise functions are taken from:
# https://github.com/ssmccoy/awkbot/blob/master/src/bitwise.awk
#
# A small collection of bitwise operations.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD jail.c:
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
'
