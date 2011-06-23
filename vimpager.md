% VIMPAGER(1) vimpager user manual
% Rafael Kitover <rkitover@cpan.org>
% June 22, 2011

# NAME

vimpager - less.sh replacement

# SYNOPSIS

cat *some_file* | vimpager

# DESCRIPTION
A slightly more sophisticated replacement for less.sh that also supports being
set as the PAGER environment variable. Displays man pages, perldocs and python
documentation properly. Works on Linux, Solaris, FreeBSD, OSX,
Cygwin and msys. Should work on most other systems as well.

On GitHub: <http://github.com/rkitover/vimpager>

To use it as as your PAGER:
put these in your ~/.bashrc or ~/.zshrc

    export PAGER=~/bin/vimpager
    alias less=$PAGER
    alias zless=$PAGER

Put the following into your ~/.vimrc if you want to use gvim/MacVim for your pager window:

    let vimpager_use_gvim = 1

# CYGWIN NOTES
The Cygwin gvim is very buggy, vimpager works correctly with the native
Windows gvim, just put it in your PATH.
