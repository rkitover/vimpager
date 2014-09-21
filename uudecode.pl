#!/usr/bin/perl

# uudecode for perl 4 and 5, decodes stdin to stdout
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

<>;

while (<>) {
    last if /^end$/;

    $cnt = ord(substr($_, 0, 1));

    next if $cnt == 96; # ord("`") == 96, zero bytes line

    $cnt -= 32;

    $enc = substr($_, 1);

    chop $enc;

    $chars = 0;
    $pos   = 0;

    while ($chars < $cnt) {
        $grp = substr($enc, $pos, 4);

        $grp =~ s/\`/ /g; # zero bytes

        $c1 = (ord(substr($grp, 0, 1)) - 32);
        $c2 = (ord(substr($grp, 1, 1)) - 32);
        $c3 = (ord(substr($grp, 2, 1)) - 32);
        $c4 = (ord(substr($grp, 3, 1)) - 32);

        $char_val = $c4 | ($c3 << 6) | ($c2 << 12) | ($c1 << 18);

        @chars = ();

        push(@chars,
            pack('c', (($char_val & 0xff0000) >> 16)),
            pack('c', (($char_val & 0x00ff00) >>  8)),
            pack('c', (($char_val & 0x0000ff)      ))
        );

        while (@chars && $chars < $cnt) {
            print shift @chars;

            $chars++;
        }

        $pos += 4;
    }
}
