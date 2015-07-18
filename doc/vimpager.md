% VIMPAGER(1) vimpager user manual
% Rafael Kitover <rkitover@gmail.com>
% April 29, 2015

# NAME

vimpager - less.sh replacement

# SYNOPSIS

vimpager 'some file'

&#35; or (this won't always syntax highlight as well)

cat 'some file' | vimpager

# RUN-TIME DEPENDENCIES

* vim

# BUILD DEPENDENCIES

* sharutils or some uuencode (only if you change the .vim sources)
* pandoc (for man pages)

# INSTALL

```bash
git clone git://github.com/rkitover/vimpager
cd vimpager
sudo make install
```

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

# DESCRIPTION
A PAGER using less.vim with support for highlighting of man pages and
many other features. Works on most UNIX-like systems as well as Cygwin
and MSYS.

On GitHub: <http://github.com/rkitover/vimpager>

To use a different vimrc with vimpager, put your settings into a ~/.vimpagerrc
or ~/.vim/vimpagerrc or a file pointed to by the VIMPAGER_RC environment
variable.

You can also have a global config file for all users in /etc/vimpagerrc, users
can override it by creating a ~/.vimpagerrc or a ~/.vim/vimpagerrc.

These are the keys for paging while in vimpager, they are the same as in
less for the most part:

| _Key_   | _Action_                | _Key_   | _Action_                  |  
|---------|-------------------------|---------|---------------------------|  
|Space    |One page forward         |b        |One page backward          |  
|d        |Half a page forward      |u        |Half a page backward       |  
|Enter    |One line forward         |k        |One line backward          |  
|G        |End of file              |g        |Start of file              |  
|N%       |percentage in file       |,h       |Display this help          |  
|/pattern |Search for pattern       |?pattern |Search backward for pattern|  
|n        |next pattern match       |N        |Previous pattern match     |  
|ESC-u    |toggle search highlight  |         |                           |  
|:n-Enter |Next file                |:p-Enter |Previous file              |  
|q        |Quit                     |,v       |Toggle Less Mode           |  

To disable loading plugins, put "set noloadplugins" into a vimpagerrc
file.

You can also switch on the "vimpager" variable in your vimrc to set alternate
settings for vimpager.

If you want to disable less compatibility mode, and use regular vim
motion commands, put this into your .vimrc/vimpagerrc:

```vim
let vimpager_less_mode = 0
```

You can still enable less mode with this setting by pressing ",v".

At runtime whenever less mode is toggled with ,v , this variable will
reflect the current state, regardless of the initial value.

Put the following into your .vimrc/vimpagerrc if you want to use gvim/MacVim
for your pager window:

```vim
let vimpager_use_gvim = 1
```

To turn off the feature of passing through text that is smaller than the
terminal height use this:

```vim
let vimpager_passthrough = 0
```

See "PASSTHROUGH MODE" further down.

To start vim with -X (no x11 connection, a bit faster startup) put the following
into your .vimrc/vimpagerrc:

```vim
let vimpager_disable_x11 = 1
```

The scroll offset (:help scrolloff), may be specified by placing the 
following into your .vimrc/vimpagerrc (default = 5, disable = 0):

```vim
let vimpager_scrolloff = 5
```

The default is 5 only in less mode, with less mode disabled the default
is the user's scrolloff setting.

The process tree of vimpager is available in the "vimpager_ptree" variable, an
example usage is as follows:

```vim
if exists("vimpager")
  if exists("vimpager_ptree") && vimpager_ptree[-2] == 'wman'
    set ft=man
  endif
endif
```

To disable the use of AnsiEsc.vim to display ANSI colors in the source,
set:

```vim
let vimpager_disable_ansiesc = 1
```

see the section "ANSI ESCAPE SEQUENCES AND OVERSTRIKES" for more
details.

# COMMAND LINE OPTIONS

## + | +G

Start at the end of the file, just like less.

## -c cmd

Run a vim command after opening the file. Multiple -c arguments are
supported.

## --cmd cmd

Run a vim command when entering vim before anything else. Multiple --cmd
arguments are supported.

## -u vimrc

Use alternate .vimrc or .vimpagerrc.

# ANSI ESCAPE SEQUENCES AND OVERSTRIKES

If your source is using ANSI escape codes, the AnsiEsc plugin will be
used to show them, rather than the normal vim highlighting, however read
the caveats below. If this is not possible, they will be stripped out
and normal vim highlighting will be used instead.

Overstrikes such as in man pages will always be removed.

vimpager bundles the
[AnsiEsc](http://www.vim.org/scripts/script.php?script_id=4979)
plugin (it is expanded at runtime,
there is nothing you have to do to enable it.)

However, your vim must have been compiled with the 'conceal' feature
enabled. To check, try

```vim
:echo has("conceal")
```

if the result is '1' you have conceal, if it's '0' you do not, and the
AnsiEsc plugin will not be enabled.

If you're on a Mac, the system vim does not enable this feature, install
vim from Homebrew.

To disable the use of AnsiEsc.vim, set:

```vim
let vimpager_disable_ansiesc = 1
```

in your .vimrc.

# PASSTHROUGH MODE

If the text sent to the pager is smaller than the terminal window, then
it will be displayed without vim as text. If it has ansi codes, they
will be preserved, otherwise the text will be highlighted with vimcat.

You can turn this off by putting

```vim
let vimpager_passthrough = 0
```

Passthrough mode requires a POSIX shell with arithmetic expansion, if
there is one on your system and it is not detected please submit an
issue with the path and your OS version.

# CYGWIN/MSYS/MSYS2 NOTES

vimpager works correctly with the native Windows gvim, just put it in
your PATH and set the vimpager_use_gvim option as described above.
