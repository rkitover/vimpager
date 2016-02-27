#!/usr/bin/env python

from sys import stdout, stderr

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

for s in left.keys():
    stdout.write('l["%s"]=%s;' % (escape(s), ord(left[s])))

for s in middle.keys():
    stdout.write('m["%s"]=%s;' % (escape(s), ord(middle[s])))

for s in right.keys():
    stdout.write('r["%s"]=%s;' % (escape(s), ord(right[s])))

print ""
