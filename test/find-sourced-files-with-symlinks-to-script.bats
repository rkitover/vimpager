#!/usr/bin/env bats

load helpers

teardown() {
    rm -f output.*
}

@test "symlink to vimpager finds the correct project directory" {
    run_cmd "$fixtures"/bin/vimpager-relative-symlink-to-git -v
    status_ok
    [[ "$output" =~ vimpager.*\(git\) ]]
}

@test "symlink to vimcat finds the correct project directory" {
    run_cmd "$fixtures"/bin/vimcat-relative-symlink-to-git -v
    status_ok
    [[ "$output" =~ vimcat.*\(git\) ]]
}

# vim: filetype=sh sw=4 sts=4 et :
