#!bash

fixtures=$BATS_TEST_DIRNAME/fixtures
status_ok () {
  [ "$status" -eq 0 ]
}
no_output () {
  [ -z "$output" ]
}
