#!/usr/bin/env bats

load helpers

. "$src/inc/common_functions.sh"

@test "squeeze_blank_lines" {
    tmp_function () {
        (
            echo The first line is normal
            echo The second as well
            echo # an empty line
            echo Another text line
            echo # empty line
            echo # empty line
            echo third line with text
            echo more text
            echo '  ' # some blanks
            echo '		' # some tabs
            echo last line
        ) | squeeze_blank_lines
    }
    run tmp_function
    status_ok
    [[ "$(wc -l <<<"$output")" -eq 9 ]]
    [[ "${#lines[@]}" -eq 7 ]]
    [[ "${lines[0]}" = 'The first line is normal' ]]
    [[ "${lines[1]}" = 'The second as well' ]]
    [[ "${lines[2]}" = 'Another text line' ]]
    [[ "${lines[3]}" = 'third line with text' ]]
    [[ "${lines[4]}" = 'more text' ]]
    [[ "${lines[5]}" = '		' ]]
    [[ "${lines[6]}" = 'last line' ]]
}

@test 'find_tmp_directory sets $tmp' {
    [[ -z "$tmp" ]]
    find_tmp_directory
    [[ "$tmp" = /* ]]
}
# vim: filetype=sh et sw=4 sts=4 :
