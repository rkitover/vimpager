% VIMCAT(1) vimcat user manual
% Abdó Roig-Maranges <abdo.roig@gmail.com>
% December 21, 2013

# NAME

vimcat - vim based syntax highlighter

# SYNOPSIS

vimcat *some_file*

# DESCRIPTION
cat's a file to stdout, syntax-highlighting it using vim as a backend.

On GitHub: <http://github.com/rkitover/vimpager>

To use a different vimrc with vimcat, put your settings into a ~/.vimcatrc.

To disable loading plugins, put "set noloadplugins" into a ~/.vimcatrc file.

# COMMAND LINE OPTIONS

## -c cmd

Run a vim command after opening the file. Multiple -c arguments are
supported.

## --cmd cmd

Run a vim command when entering vim before anything else. Multiple --cmd
arguments are supported.

## -u vimrc

Use an alternate .vimrc or .vimcatrc.
