<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
### Vimpager User Manual

- [NAME](#name)
- [SYNOPSIS](#synopsis)
- [DESCRIPTION](#description)
- [COMMAND LINE OPTIONS](#command-line-options)
  - [-h | --help | --usage](#-h----help----usage)
  - [-n](#-n)
  - [-c cmd](#-c-cmd)
  - [--cmd cmd](#--cmd-cmd)
  - [-u vimrc](#-u-vimrc)
  - [-o output_file](#-o-output_file)
  - [-s](#-s)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# NAME

vimcat - vim based syntax highlighter

# SYNOPSIS

vimcat [options] file1 [file2 ...]

# DESCRIPTION

Prints a file to stdout, syntax-highlighting it using vim as a backend.

On GitHub: <http://github.com/rkitover/vimpager>

To use a different vimrc with vimcat, put your settings into a ~/.vimcatrc.

To disable loading plugins, put "set noloadplugins" into a ~/.vimcatrc file.

If output is not a terminal, it will simply run cat, so using vimcat in
pipe commands is safe. If you actually need the ANSI codes, use -o .

vimcat defaults to syntax on and set bg=dark. If you need bg=light do
something like this:

```bash
alias vimcat="vimcat -c 'set bg=light'"
```

# COMMAND LINE OPTIONS

## -h | --help | --usage

Print summary of options.

## -n

Display line numbers.

## -c cmd

Run a vim command after opening the file. Multiple -c arguments are
supported.

## --cmd cmd

Run a vim command when entering vim before anything else. Multiple --cmd
arguments are supported.

## -u vimrc

Use an alternate .vimrc or .vimcatrc.

## -o output_file

Write output to output_file instead of the terminal. This works when
vimcat is not run on a terminal as well.

If output_file is "-" then output is written to STDOUT. An extra newline
will not be output if there isn't one at the end of the file with this
option, but will be in normal operation with a terminal.

## -s

Squeeze multiple blank lines into one.
