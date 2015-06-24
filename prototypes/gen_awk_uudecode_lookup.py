#!/usr/bin/env python

# Generate lookup tables code to be placed in BEGIN for an awk lookup table
# based uudecode utility.
#
# Copyright (c) 2015, Rafael Kitover <rkitover@gmail.com>
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

from sys         import stdout, stderr
from collections import defaultdict

def escape(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace("'", "'\\''")

uu_chars = []

for i in range(0, 64):
    uu_chars += chr(i + 32)

left   = {}
middle = {}
right  = {}

for c1 in uu_chars:
    for c2 in uu_chars:
        left[  c1 + c2] = chr((( ord(c1) - 32) << 2)         + ((ord(c2) - 32) >> 4))
        middle[c1 + c2] = chr((((ord(c1) - 32) << 4) & 0xFF) + ((ord(c2) - 32) >> 2))
        right[ c1 + c2] = chr((((ord(c1) - 32) << 6) & 0xFF) + (ord(c2) - 32))

lookup = defaultdict(list)

for n, s, v in [("l", k, v) for k, v in left.iteritems()] + [("m", k, v) for k, v in middle.iteritems()] + [("r", k, v) for k, v in right.iteritems()]:
    lookup[v].append('%s["%s"]' % (n, escape(s)))

pieces = []

for c, slots in lookup.iteritems():
    pieces.append("=".join(slots + [str(ord(c)) + ";"]))

# /bin/awk on Solaris has a max record length of 2559, so we write out the
# table in pieces no greater than that.
str = ''

for p in pieces:
    if len(str + p) > 2559:
        print str
        str = p
    else:
        str += p

print str
