#!/bin/sh

# Solaris and some other systems have no seq command
if [ -z "${_seq}" ]; then
	if command -v gseq >/dev/null; then
		_seq=gseq
	elif command -v seq >/dev/null; then
		_seq=seq
	else
		# For a fallback implementation of seq in oawk see the file
		# seq.awk.
		_seq=seq.awk
	fi
fi

command "${_seq}" "$@"
