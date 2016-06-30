<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
### Vimpager User Manual

- [NAME](#name)
- [SYNOPSIS](#synopsis)
- [RUN-TIME DEPENDENCIES](#run-time-dependencies)
- [BUILD DEPENDENCIES](#build-dependencies)
- [INSTALL](#install)
- [PATHOGEN INSTALLATION](#pathogen-installation)
- [DESCRIPTION](#description)
- [USING FROM VIM](#using-from-vim)
- [COMMAND LINE OPTIONS](#command-line-options)
  - [-h | --help | --usage](#-h----help----usage)
  - [-v | --version](#-v----version)
  - [+ | +G](#--g)
  - [-N | --LINE-NUMBERS](#-n----line-numbers)
  - [-c cmd](#-c-cmd)
  - [--cmd cmd](#--cmd-cmd)
  - [-u vimrc](#-u-vimrc)
  - [-s](#-s)
  - [-x](#-x)
- [ANSI ESCAPE SEQUENCES AND OVERSTRIKES](#ansi-escape-sequences-and-overstrikes)
- [PASSTHROUGH MODE](#passthrough-mode)
- [CYGWIN/MSYS/MSYS2 NOTES](#cygwinmsysmsys2-notes)
- [ENVIRONMENT](#environment)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# NAME

vimpager - pager using vim and less.vim

# SYNOPSIS

vimpager [options] 'some file'

&#35; or (this won't always syntax highlight as well)

cat 'some file' | vimpager [options]

For vimcat see [here](markdown/vimcat.md) or 'man vimcat'.

# RUN-TIME DEPENDENCIES

* vim, version >= 7.3
* a POSIX conformant shell, see [the
  standard](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
  common variants are searched for, bash is fine

# BUILD DEPENDENCIES

* sharutils or some uuencode (only if you change the */*.vim sources)
* pandoc (for man pages and html, optional)
* doctoc (for markdown TOCs, optional)
* bats (for tests, optional, get it from:
  https://github.com/sstephenson/bats.git)

# INSTALL

On Ubuntu or Debian, use the following to install a package:

```bash
git clone git://github.com/rkitover/vimpager
cd vimpager
sudo make install-deb
```

Otherwise use 'make install' instead:

```bash
git clone git://github.com/rkitover/vimpager
cd vimpager
sudo make install
```

The following make settings are supported at `make install` time:

| **Variable** | **Purpose**                                         |
|--------------|-----------------------------------------------------|
| DESTDIR      | base dir where files will be written, for packaging |
| PREFIX       | install prefix to configure for, e.g. /usr/local    |
| prefix       | prefix for writing files, e.g. for GNU stow         |
| POSIX_SHELL  | POSIX shell to use to run the scripts               |

If you got vimpager from the vim.org scripts section, just put it
somewhere in your PATH, e.g.:

```bash
cp vimpager ~/bin
chmod +x ~/bin/vimpager
```

In your ~/.bashrc add the following:

```bash
export PAGER=/usr/local/bin/vimpager
alias less=$PAGER
alias zless=$PAGER
```

# PATHOGEN INSTALLATION

```bash
cd ~/.vim/bundle
git clone https://github.com/rkitover/vimpager.git
```

If you installed using one of the above methods, you can add the runtime to your
`runtimepath` by putting the following in your `.vimrc`:

```vim
set rtp^=/usr/share/vimpager
```

Set `PAGER` and aliases as above with the path into `~/.vim/bundle/vimpager`.

See [Using From Vim](#using-from-vim).

# DESCRIPTION

A PAGER using less.vim with support for highlighting of man pages and
many other features. Works on most UNIX-like systems as well as Cygwin
and MSYS.

On GitHub: <http://github.com/rkitover/vimpager>

To use a different vimrc with vimpager, put your settings into a ~/.vimpagerrc
or ~/.vim/vimpagerrc or a file pointed to by the VIMPAGER_RC environment
variable.

You can also have a global config file for all users in /etc/vimpagerrc, it will
be used if the user does not have a `.vimrc` or `.vimpagerrc`.

These are the keys for paging while in vimpager, they are the same as in
less for the most part:

| **Key** | **Action**              | **Key** | **Action**                |
|---------|-------------------------|---------|---------------------------|
|Space    |One page forward         |b        |One page backward          |
|d        |Half a page forward      |u        |Half a page backward       |
|Enter    |One line forward         |k        |One line backward          |
|G        |End of file              |g        |Start of file              |
|N%       |percentage in file       |,h       |Display this help          |
|/pattern |Search forward           |?pattern |Search backward            |
|n        |next match               |N        |Previous match             |
|`:n`     |next file                |`:N`     |Previous file              |
|ESC-u    |toggle search highlight  |         |                           |
|q        |Quit                     |,v       |Toggle Less Mode           |

The commands that start with `,` will use your value of `g:mapleader` if you set
one instead.

To disable loading plugins, put "set noloadplugins" into a vimpagerrc
file.

You can also switch on `exists('g:vimpager.enabled')` in your vimrc to set
alternate settings for vimpager.

**WARNING:** Option names have changed from the previous releases to use a
dict, if you use the old option names and check on `exists('g:vimpager')`
everything will work the same way, if you use the new option names you must
check `exists('g:vimpager.enabled')` instead.

**NOTE:** Before setting the vimpager and less.vim related options described
below, make sure the `g:vimpager` and `g:less` dicts exist like so:

```vim
let g:vimpager = {}
let g:less     = {}
```

If you want to disable less compatibility mode, and use regular vim
motion commands, put this into your .vimrc/vimpagerrc:

```vim
let g:less.enabled = 0
```

You can still enable less mode with this setting by pressing ",v". If you
define `g:mapleader` then it will be the value of `g:mapleader` plus `v`
instead of `,v`.

Put the following into your .vimrc/vimpagerrc if you want to use gvim/MacVim
for your pager window:

```vim
let g:vimpager.gvim = 1
```

To turn off the feature of passing through text that is smaller than the
terminal height use this:

```vim
let g:vimpager.passthrough = 0
```

See "PASSTHROUGH MODE" further down.

To turn on line numbers set:

```vim
let g:less.number = 1
```

they are turned off by default. You can also invoke vimpager with the `-N`
option to turn on line numbers.

To turn off search highlighting set:

```vim
let g:less.hlsearch = 0
```

this can always be toggled with `ESC-u`.

To start vim with -X (no x11 connection, a bit faster startup) put the following
into your .vimrc/vimpagerrc:

```vim
let g:vimpager.X11 = 0
```

**NOTE:** this may disable clipboard integration in X terminals.

The scroll offset (:help scrolloff), may be specified by placing the
following into your .vimrc/vimpagerrc (default = 5, disable = 0):

```vim
let g:less.scrolloff = 5
```

The default is 5 only in less mode, with less mode disabled the default
is the user's scrolloff setting.

The process tree of vimpager is available in `vimpager.ptree`, an example usage
is as follows:

```vim
if exists('g:vimpager.enabled')
  if exists('g:vimpager.ptree') && g:vimpager.ptree[-2] == 'wman'
    set ft=man
  endif
endif
```

To disable the use of AnsiEsc.vim to display ANSI colors in the source,
set:

```vim
let g:vimpager.ansiesc = 0
```

see the section [ANSI ESCAPE SEQUENCES AND
OVERSTRIKES](#ansi-escape-sequences-and-overstrikes) for more details.

You can also set your own function for the message on the statusline via
`g:less.statusfunc`, see `autoload/vimpager_utils.vim` for the default one as an
example.

# USING FROM VIM

If you installed vimpager via [Pathogen](#pathogen-installation) or added it to
your `runtimepath`, then the `Page` command is available from normal vim
sessions, and it is also available when invoking the vimpager script.

If your global `keywordprg` is set to `man` or `:Man`, which is the default, the
plugin will reset it to `:Page!\ -t\ man` to page man pages in a new tab. See
the example below for how to set this for other file types.

You may want to add something like the following to your `.vimrc` to enable the
mapping to turn on less mode:

```vim
let g:mapleader = ','
runtime macros/less.vim
```

Then `,v` will toggle less mode in any buffer. The default `mapleader` is `\`.

**NOTE:** If you are using Vim 7.3 or earlier, the Surround plugin will conflict
with less.vim mappings such as Ctrl-D, on 7.4+ this is not an issue as the
`<nowait>` tag is used for mappings.

The syntax of the `Page` command is:

| **Command** | **Option**       | **Arg**        | **Action**                          |
|-------------|------------------|----------------|-------------------------------------|
| Page        | -t, -v, -w or -b | file_path      | open file in less mode              |
| Page!       | -t, -v, -w or -b | shell_command  | open output of command in less mode |
| Page        |                  |                | toggle less mode for current file   |
| Page!       |                  |                | turn on less mode for current file  |

The option switch is optional and determines where the file or command is
opened:

| **Option** | **Target**           |
|------------|----------------------|
| -t         | new tab              |
| -v         | vertical split       |
| -w         | new window           |
| -b         | new buffer (default) |

The default is to open a new buffer.

For `Page!` commands, STDERR is suppressed.

I recommend adding `set hidden` to your `.vimrc`.

If the command is one of `man`, `perldoc`, `pydoc` or `ri` it will be handled
specially, overstrikes will be removed and `filetype` will be set to `man` or
`perldoc`.

Ansi escapes will be handled with `AnsiEsc` if available, or removed otherwise.
See [here](#ansi-escape-sequences-and-overstrikes) for details. The
`g:vimpager.ansiesc` setting applies to the `Page` command if set.

Here is an example (that is already enabled in the plugin) of how you can use
this command to look up the python documentation for the module under the cursor
in a new tab:

```vim
autocmd FileType python setlocal keywordprg=:Page!\ -t\ pydoc
```

Then pressing `K` on a module name under the cursor will open the pydoc for it
in a new tab.

This is done by default in the plugin now for python, ruby, perl and sh (bash
help.) The global default is man.

# COMMAND LINE OPTIONS

## -h | --help | --usage

Print summary of options.

## -v | --version

Print the version information.

## + | +G

Start at the end of the file, just like less.

## -N | --LINE-NUMBERS

Turn on line numbers, this can also be set with `let g:less.number = 1` .

## -c cmd

Run a vim command after opening the file. Multiple -c arguments are
supported.

## --cmd cmd

Run a vim command when entering vim before anything else. Multiple --cmd
arguments are supported.

## -u vimrc

Use alternate .vimrc or .vimpagerrc.

## -s

Squeeze blank lines into a single blank line. GNU man passes this option to
/usr/bin/pager.

## -x

Enable debugging output for the shell script part of vimpager.

# ANSI ESCAPE SEQUENCES AND OVERSTRIKES

If your source is using ANSI escape codes, the AnsiEsc plugin will be
used to show them, rather than the normal vim highlighting, however read
the caveats below. If this is not possible, they will be stripped out
and normal vim highlighting will be used instead.

Overstrikes in man pages, perl, python or ruby docs will always be removed.

vimpager bundles the
[AnsiEsc](http://www.vim.org/scripts/script.php?script_id=4979)
plugin (it is expanded at runtime,
there is nothing you have to do to enable it.)

However, your vim must have been compiled with the 'conceal' feature
enabled. To check, try

```vim
:echo has('conceal')
```

if the result is '1' you have conceal, if it's '0' you do not, and the
AnsiEsc plugin will not be enabled.

If you're on a Mac, the system vim does not enable this feature, install
vim from Homebrew.

To disable the use of AnsiEsc.vim, set:

```vim
let g:vimpager.ansiesc = 0
```

If the file has a modeline that sets ft or syntax, the setting will override
the use of AnsiEsc.

To turn off AnsiEsc while viewing a file, simply run

```vim
:AnsiEsc
```

To turn off AnsiEsc on the commandline, use an invocation such as the following:

```sh
vimpager -c 'set ft=&ft' somefile
```

**NOTE:** The `conceal` feature of vim is still very buggy, especially as
concerns spacing, and the line wrapping in files highlighted with `AnsiEsc`
will not be correct (they are wrapped too soon.) The tab stops will be correct
however, this is fixed up with a vim script.

**NOTE:** `AnsiEsc` is a work in progress, and will only display files with
simple ANSI codes correctly, such as that output by git tools. More complex
highlighting is likely not going to work right now. We are working on this.

# PASSTHROUGH MODE

If the text sent to the pager is smaller than the terminal window, then
it will be displayed without vim as text. If it has ansi codes, they
will be preserved, otherwise the text will be highlighted with vimcat.

You can turn this off by using:

```vim
let g:vimpager.passthrough = 0
```

# CYGWIN/MSYS/MSYS2 NOTES

vimpager works correctly with the native Windows gvim, just put it in
your PATH and set the vimpager_use_gvim option as described above.

# ENVIRONMENT

`VIMPAGER_VIM` can be set to the vim binary you want to use, if it starts with
gvim or mvim then gui mode will be used. Will fall back to `EDITOR` if it
contains vim.

You can specify the vimrc to use with the `VIMPAGER_RC` environment variable.

Setting `VIMPAGER_DEBUG` to a non-zero value will disable suppressing vim
errors on startup and when switching to the next file.
