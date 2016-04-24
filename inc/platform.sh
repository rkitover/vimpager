#!/bin/sh

# This file is used to set some variables acording to the system we are
# running on.  It assumes a POSIX compatible shell.

# Detect the operating system.
case $(uname -s) in
    Linux) linux=1 ;;
    SunOS) solaris=1 ;;
    Darwin) osx=1; bsd=1 ;;
    CYGWIN*) cygwin=1; win32=1 ;;
    MINGW*) msys=1; win32=1 ;;
    MSYS*) msys=1; win32=1 ;;
    OpenBSD) openbsd=1; bsd=1 ;;
    FreeBSD) freebsd=1; bsd=1 ;;
    NetBSD) netbsd=1; bsd=1 ;;
    *) bsd=1 ;;
esac

# Find a suitble awk executable.
if [ -n "$AWK" ] && command -v "$AWK" >/dev/null; then
    :
elif command -v gawk >/dev/null; then
    AWK=gawk
elif command -v nawk >/dev/null; then
    AWK=nawk
elif command -v mawk >/dev/null; then
    AWK=mawk
elif [ -x /usr/xpg4/bin/awk ]; then
    AWK=/usr/xpg4/bin/awk
elif command -v awk >/dev/null; then
    AWK=awk
else
    echo "ERROR: No awk found!" >&2
    exit 1
fi

# Find a suitable sed executable.
if [ -n "$SED" ] && command -v "$SED" >/dev/null; then
    :
elif command -v gsed >/dev/null; then
    SED=gsed
elif [ -x /usr/xpg4/bin/sed ]; then
    SED=/usr/xpg4/bin/sed
elif command -v sed >/dev/null; then
    SED=sed
else
    echo "ERROR: No sed found!" >&2
    exit 1
fi

# Find a suitable head executable.
if command -v ghead >/dev/null; then
    HEAD=ghead
else
    HEAD=head
fi

# Check the syntax for head.
if [ "$HEAD_SYNTAX" = new -o "$HEAD_SYNTAX" = old ]; then
    :
else
    if [ "$(echo xx | "$HEAD" -n 1 2>/dev/null)" = xx ]; then
        HEAD_SYNTAX=new
    else
        if ! "$HEAD" -1 -- "$0" >/dev/null 2>&1; then
            HEAD_NO_DOUBLE_DASH=1
        fi
        HEAD_SYNTAX=old
    fi
fi

# vim: sw=4 et tw=0:
