#!/usr/bin/env bats

load helpers

@test "vimpager cats files if stdout is not a terminal" {
    run ./vimpager uganda.txt
    status_ok
    [[ "${lines[0]}" = '*uganda.txt*    For Vim version 7.4.  Last change: 2013 Jul 06' ]]
    [[ "$(sed -n '10{p;q;}' <<<"$output")" = 'Vim is Charityware.  You can use and copy it as much as you like, but you are' ]]
}

# vim: filetype=sh et sw=4 sts=4 :
