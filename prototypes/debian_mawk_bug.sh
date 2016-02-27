#!/bin/sh

grep_q() {
	_pat="$1"
	shift
	~/src/mawk-1.3.3/mawk '
		BEGIN { exit_val = 1 }
		$0 ~ /'"$_pat"'/ { exit_val = 0; exit(exit_val) }
		END { exit(exit_val) }
	' "$@"
}

ps awo pid=,comm= | grep_q '(^([0-9]*[ \t]*)*|\/)(man|py(thon|doc|doc[0-9]))';
