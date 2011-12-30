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

To use a different vimrc with vimpager, put your settings into a ~/.vimpagerrc
or a file pointed to by the VIMPAGER_RC environment variable.

To disable loading plugins, put "set noloadplugins" into a ~/.vimpagerrc
file.

You can also switch on the "vimpager" variable in your vimrc to set alternate
settings for vimpager.

Put the following into your .vimrc/.vimpagerrc if you want to use gvim/MacVim
for your pager window:

    let vimpager_use_gvim = 1

To start vim with -X (no x11 connection, a bit faster startup) put the following
into your .vimrc/.vimpagerrc:

    let vimpager_disable_x11 = 1

The scroll offset (:help scrolloff), may be specified by placing the 
following into your .vimrc/.vimpagerrc (default = 5, disable = 0):

	let vimpager_scrolloff = 5

# CYGWIN NOTES
The Cygwin gvim is very buggy, vimpager works correctly with the native
Windows gvim, just put it in your PATH.
