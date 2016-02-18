#!/bin/sh

# Adapted from: https://gist.github.com/moyashi/4063894

# We are escaping only slashes, spaces, and chars special to vim (see :h expand).

awk '
BEGIN {
    for (i = 0; i <= 255; i++) {
	ord[sprintf("%c", i)] = i
    }
}

{
    len = length($0)
    res = ""
    for (i = 1; i <= len; i++) {
	c = substr($0, i, 1);
	if (c ~ /[\/#%<> 	]/)
	    res = res "%" sprintf("%02X", ord[c])
	else
	    res = res c
    }
    print res
}
'
