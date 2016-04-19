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

# vim: sw=4 et tw=0:
