#!/bin/sh

# Determine if file(s) will fit on the screen.
#
# Returns 0 for yes and 1 for no.
#
# Number of lines for separator between files, and before the first file if
# there are multiple files, is configurable at the bottom.

[ $# -eq 0 ] && set -- -

# First remove overstrikes and ANSI codes with sed
sed -e 's/.//g' \
    -e 's/\[[;?]*[0-9.;]*[A-Za-z]//g' "$@" | \
awk '
{
    if (NR == 1) {
        lines = total_lines - 2 - (num_files - 1) * file_sep_lines

        if (num_files - 1)
            lines -= first_file_sep_lines

        total_cols += 0 # coerce to number
    }

    col = 0

    for (pos = 1; pos <= length($0); pos++) {
        c = substr($0, pos, 1)

        # handle tabs
        if (c == "\t")
            col += 8 - (col % 8)
        else
            col++

        if (col > total_cols) {
            if (!--lines) exit(1)
            col = 1
        }
    }

    if (!--lines) exit(1)
}
' num_files="$#" total_lines="`tput lines`" total_cols="`tput cols`" file_sep_lines=3 first_file_sep_lines=2 -
