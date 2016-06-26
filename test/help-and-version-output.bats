#!/usr/bin/env bats

load helpers

teardown() {
    rm -f output.*
}

@test "vimpager help output of the git version" {
    run_cmd ./vimpager -h
    run diff output.1 "$fixtures/vimpager-help.txt"
    status_ok
    no_output
}

@test "vimpager help output of the standalone version" {
    run_cmd ./standalone/vimpager -h
    run diff output.1 "$fixtures/vimpager-help.txt"
    status_ok
    no_output
}

@test "vimpager version output of the git version" {
    run_cmd ./vimpager -v
    status_ok
    [[ "$output" =~ vimpager.*\(git\) ]]
}

@test "vimpager version output of the standalone version" {
    run_cmd ./standalone/vimpager -v
    status_ok
    [[ "$output" =~ vimpager.*\(standalone,\ shell=.*\) ]]
}

@test "vimcat help output of the git version" {
    run_cmd ./vimcat -h
    run diff output.1 "$fixtures/vimcat-help.txt"
    status_ok
    no_output
}

@test "vimcat help output of the standalone version" {
    run_cmd ./standalone/vimcat -h
    run diff output.1 "$fixtures/vimcat-help.txt"
    status_ok
    no_output
}

@test "vimcat version output of the git version" {
    run_cmd ./vimcat -v
    status_ok
    [[ "$output" =~ vimcat.*\(git\) ]]
}

@test "vimcat version output of the standalone version" {
    run_cmd ./standalone/vimcat -v
    status_ok
    [[ "$output" =~ vimcat.*\(standalone,\ shell=.*\) ]]
}

# vim: filetype=sh et sw=4 sts=4 :
