#!/bin/sh

# uudecode in GNU awk (and some others, like OpenBSD) decodes stdin to stdout
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

gawk '
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

        char_val = or(c4, or(or(lshift(c3, 6), lshift(c2, 12)), lshift(c1, 18)));

        char[1] = sprintf("%c", rshift(and(char_val, 16711680), 16));
        char[2] = sprintf("%c", rshift(and(char_val, 65280),     8));
        char[3] = sprintf("%c", and(char_val, 255));

        for (i = 1; i <= 3 && chars < cnt; i++) {
            printf("%s", char[i]);

            chars++;
        }

        pos += 4;
    }
}
'
