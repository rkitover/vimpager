#!/usr/bin/env bats

load helpers

teardown () {
  rm -f output.*
}

@test "symlink to vimpager finds the correct project directory" {
  script -q -e -c "$fixtures/bin/vimpager-relative-symlink-to-git -v" output.1
  run sed 1d output.1
  status_ok
  [[ "$output" =~ vimpager.*\(git\) ]]
}
@test "symlink to vimcat finds the correct project directory" {
  script -q -e -c "$fixtures/bin/vimcat-relative-symlink-to-git -v" output.1
  run sed 1d output.1
  status_ok
  [[ "$output" =~ vimcat.*\(git\) ]]
}

# vim: filetype=sh
