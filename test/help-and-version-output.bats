#!/usr/bin/env bats

load helpers

teardown () {
  rm -f output.*
}

@test "vimpager help output of the git version" {
  script -q -e -c './vimpager -h' output.1
  sed 1d output.1 > output.2
  run diff output.2 "$fixtures/vimpager-help.txt"
  status_ok
  no_output
}
@test "vimpager help output of the standalone version" {
  script -q -e -c './standalone/vimpager -h' output.1
  sed 1d output.1 > output.2
  run diff output.2 "$fixtures/vimpager-help.txt"
  status_ok
  no_output
}
@test "vimpager version output of the git version" {
  script -q -e -c './vimpager -v' output.1
  run sed 1d output.1
  status_ok
  [[ "$output" =~ vimpager.*\(git\) ]]
}
@test "vimpager version output of the standalone version" {
  script -q -e -c './standalone/vimpager -v' output.1
  run sed 1d output.1
  status_ok
  [[ "$output" =~ vimpager.*\(standalone,\ shell=.*\) ]]
}
@test "vimcat help output of the git version" {
  script -q -e -c './vimcat -h' output.1
  sed 1d output.1 > output.2
  run diff output.2 "$fixtures/vimcat-help.txt"
  status_ok
  no_output
}
@test "vimcat help output of the standalone version" {
  script -q -e -c './standalone/vimcat -h' output.1
  sed 1d output.1 > output.2
  run diff output.2 "$fixtures/vimcat-help.txt"
  status_ok
  no_output
}
@test "vimcat version output of the git version" {
  script -q -e -c './vimcat -v' output.1
  run sed 1d output.1
  status_ok
  [[ "$output" =~ vimcat.*\(git\) ]]
}
@test "vimcat version output of the standalone version" {
  script -q -e -c './standalone/vimcat -v' output.1
  run sed 1d output.1
  status_ok
  [[ "$output" =~ vimcat.*\(standalone,\ shell=.*\) ]]
}

# vim: filetype=sh
