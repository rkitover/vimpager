#!/usr/bin/perl

# uudecode for perl 4 and 5, decodes stdin to stdout
#
# This version uses unpack, and is much simpler.

<>;

while (<>) {
    last if /^end$/;

    print unpack('u', $_);
}
