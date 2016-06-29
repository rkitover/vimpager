#!/usr/bin/env bats

load helpers

. "$src/inc/vimpager_functions.sh"

@test 'detect_term_size sets $cols and $lines' {
    # detect_term_size will write files to $tmp (assuming it is a direcotry)
    tmp=$BATS_TMPDIR
    [[ -z "$cols" ]]
    [[ -z "$lines" ]]
    detect_term_size
    [[ "$cols" =~ [0-9]+ ]]
    [[ "$lines" =~ [0-9]+ ]]
}

@test 'read_vim_settings may set $use_gvim, $ansiesc_available, $disable_x11 and $no_pass_thru' {
    [[ -z "$use_gvim" ]]
    [[ -z "$ansiesc_available" ]]
    [[ -z "$disable_x11" ]]
    [[ -z "$no_pass_thru" ]]
    read_vim_settings
    [[ "$use_gvim"          -eq 1 || -z "$use_gvim" ]]
    [[ "$ansiesc_available" -eq 1 || -z "$ansiesc_available" ]]
    [[ "$disable_x11"       -eq 1 || -z "$disable_x11" ]]
    [[ "$no_pass_thru"      -eq 1 || -z "$no_pass_thru" ]]
}

@test 'find_vim_executable sets $tvim and $vim_cmd' {
    [[ -z "$tvim" ]]
    [[ -z "$vim_cmd" ]]
    find_vim_executable
    [[ -n "$tvim" ]]
    [[ -n "$vim_cmd" ]]
}

@test "quit returns arguments as return codes" {
    run quit 42
    [[ "$status" -eq 42 ]]
    no_output
    run quit
    status_ok
    no_output
}

@test 'quit cleans up the $tmp direcotry' {
    tmp=$BATS_TMPDIR/quit-test
    mkdir "$tmp"
    touch "$tmp/some-file"
    run quit 1
    [[ ! -e "$tmp/some-file" ]]
    [[ ! -e "$tmp" ]]
}

@test "usage prints the help message" {
    run usage
    [[ "$output" = "$(tr -d '\015' < "$fixtures/vimpager-help.txt")" ]]
    status_ok
}
# vim: filetype=sh et sw=4 sts=4 :
