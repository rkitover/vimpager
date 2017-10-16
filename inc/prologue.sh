# try to find a better shell, especially on Solaris

PATH="$PATH:/usr/local/bin:/opt/csw/bin:/opt/local/bin:/usr/xpg6/bin:/usr/xpg4/bin:/usr/dt/bin:/usr/bin:/bin"

# debian lintian bitches if /usr/bin/ash is used instead of /bin/ash
if [ -f /etc/debian_version ]; then
    PATH=$(echo "$PATH" | sed 's,/usr/bin,/bin:/usr/bin,')
fi

export PATH

if [ -z "$POSIX_SHELL" ]; then
	if command -v ash >/dev/null; then
		POSIX_SHELL=ash
	elif command -v dash >/dev/null; then
		POSIX_SHELL=dash
	elif command -v ksh >/dev/null; then
		POSIX_SHELL=ksh
	elif [ -x /usr/xpg4/bin/sh ]; then
		POSIX_SHELL=/usr/xpg4/bin/sh
	elif command -v dtksh >/dev/null; then
		POSIX_SHELL=dtksh
	elif command -v ksh93 >/dev/null; then
		POSIX_SHELL=ksh93
	elif command -v bash >/dev/null; then
		POSIX_SHELL=bash
	elif command -v zsh >/dev/null; then
		POSIX_SHELL=zsh
	fi

	if [ ! -z "$POSIX_SHELL" ]; then
		export POSIX_SHELL
		exec "$POSIX_SHELL" "$0" "$@"
	else
		POSIX_SHELL=/bin/sh # hope for the best
		export POSIX_SHELL
	fi
fi

# hopefully we're now POSIX.
