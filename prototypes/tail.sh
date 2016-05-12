#!/bin/sh


if command -v gtail >/dev/null; then
	_tail=gtail
elif [ -x /usr/xpg4/bin/tail ]; then
	_tail=/usr/xpg4/bin/tail
else
	_tail=tail
fi

if [ "$(echo xx | tail -n 1 2>/dev/null)" = "xx" ]; then
	_tail_syntax=new
else
	if ! tail -1 -- "$0" > /dev/null 2>&1; then
		_tail_no_double_dash=1
	fi
fi

tail() {
	_lines=
	case "$1" in
		-[0-9]*)
			_lines="${1#-}"
			shift
	esac

	if [ -z "$_lines" ]; then
		command "$_tail" "$@"
	elif [ "$_tail_syntax" = "new" ]; then
		command "$_tail" -n "$_lines" -- "$@"
	elif [ -z "$_tail_no_double_dash" ]; then
		command "$_tail" -"$_lines" -- "$@"
	else
		command "$_tail" -"$_lines" "$@"
	fi
}

tail "$@"
