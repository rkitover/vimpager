#!/usr/bin/env bats

load helpers

. "$src/inc/vimcat_functions.sh"

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

@test 'quit kills $vim_pid, $pipeline_pid and $tail_pid' {
    sleep 100000 &
    vim_pid=$!
    sleep 200000 &
    pipeline_pid=$!
    sleep 300000 &
    tail_pid=$!
    run jobs
    [[ ${#lines[@]} -eq 3 ]]
    run quit 1
    sleep 1
    run jobs
    no_output
}

@test "usage prints the help message" {
    run usage
    [[ "$output" = "$(sed 's/\r//' "$fixtures/vimcat-help.txt")" ]]
    status_ok
}

# vim: filetype=sh et sw=4 sts=4 :
