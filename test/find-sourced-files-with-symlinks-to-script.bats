#!/usr/bin/env bats

load helpers

teardown() {
    rm -f output.* "$fixtures"/bin/absolute-symlink-*
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

@test "absolute symlink to vimpager finds the correct project directory" {
    local link="$fixtures"/bin/absolute-symlink-vimpager
    rm -f "$link"
    ln -s "$(pwd)"/vimpager "$link"
    run_cmd "$link" -v
    status_ok
    [[ "$output" =~ vimpager.*\(git\) ]]
}

@test "absolute symlink to vimcat finds the correct project directory" {
    local link="$fixtures"/bin/absolute-symlink-vimcat
    rm -f "$link"
    ln -s "$(pwd)"/vimcat "$link"
    run_cmd "$link" -v
    status_ok
    [[ "$output" =~ vimcat.*\(git\) ]]
}

# vim: filetype=sh sw=4 sts=4 et :
