#!/usr/bin/env python

# Generate lookup tables code to be placed in BEGIN for an awk lookup table
# based uuencode utility.
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
import string

def escape(s):
    s = s.replace('\\', '\\\\').replace('"', '\\"')
    for c in s:
        if c not in string.printable or c.isspace():
            s = s.replace(c, '\\%03d' % (int(oct(ord(c)))))
    return s

left   = {}
right  = {}

for c1 in range(0, 256):
    for c2 in range(0, 256):
        left[ chr(c1) + chr(c2)] = chr((c1 >> 2) + 32) + chr(((((c1 & 0b11) << 6) | (c2 >> 2)) >> 2) + 32)
        right[chr(c1) + chr(c2)] = chr(((((c1 & 0xF) << 2) & 0b111111) | ((c2 >> 6))) + 32) + chr((c2 & 0b111111) + 32)

lookup = defaultdict(list)

for lr, s, v in [("l", k, v) for k, v in left.items()] + [("r", k, v) for k, v in right.items()]:
    lookup[v].append('%s["%s"]' % (lr, escape(s)))

print """\
#!/bin/sh

if command -v gawk >/dev/null; then
    awk=gawk
elif command -v nawk >/dev/null; then
    awk=nawk
elif command -v mawk >/dev/null; then
    awk=mawk
elif [ -x /usr/xpg4/bin/awk ]; then
    awk=/usr/xpg4/bin/awk
elif command -v awk >/dev/null; then
    awk=awk
else
    echo "No awk found!" >&2
    exit 1
fi

mkdir /tmp/awk_uuencode_$$
chmod 0700 /tmp/awk_uuencode_$$

trap 'rm -rf /tmp/awk_uuencode_'$$ HUP INT QUIT ILL TRAP KILL BUS TERM

cat <<'EOF' > /tmp/awk_uuencode_$$/uuencode.awk
BEGIN {\
"""

for v, slots in lookup.iteritems():
    stdout.write("=".join(slots + ['"%s";\n' % (escape(v))]))

print """\

exit
}
EOF

$awk -f /tmp/awk_uuencode_$$/uuencode.awk

rm -rf /tmp/awk_uuencode_$$
"""
