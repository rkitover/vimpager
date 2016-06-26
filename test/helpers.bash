#!/usr/bin/env bash

fixtures=$BATS_TEST_DIRNAME/fixtures

status_ok() {
    [ "$status" -eq 0 ]
}

no_output() {
    [ -z "$output" ]
}

run_cmd() {
    echo >_cmd.sh \
"#!/bin/sh
$@
echo \"___EXITED___: \$?\""
    chmod +x _cmd.sh

    SHELL=./_cmd.sh script output.0 </dev/tty

    rm -f _cmd.sh

    sed \
    -e '/^Script started/d' \
    -e '/^___EXITED___: /{' \
      -e 's/.*: \([0-9]*\).*/\1/' \
      -e 'w exit-code' \
      -e q \
    -e '}' \
    output.0 | sed '$d' > output.1

    rm -f output.0

    output=$(cat output.1)

    status=$(cat exit-code)
    rm -f exit-code
    return $status
}

# vim: ft=sh et sts=4 sw=4 :
