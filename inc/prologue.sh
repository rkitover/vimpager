# try to find a better shell, especially on Solaris

PATH="$PATH:/usr/local/bin:/opt/csw/bin:/opt/local/bin:/usr/xpg6/bin:/usr/xpg4/bin:/usr/dt/bin:/usr/bin:/bin"
export PATH

if [ -z "$MY_SHELL" ]; then
	if command -v ash >/dev/null; then
		MY_SHELL=ash
	elif command -v dash >/dev/null; then
		MY_SHELL=dash
	elif command -v ksh >/dev/null; then
		MY_SHELL=ksh
	elif [ -x /usr/xpg4/bin/sh ]; then
		MY_SHELL=/usr/xpg4/bin/sh
	elif command -v dtksh >/dev/null; then
		MY_SHELL=dtksh
	elif command -v ksh93 >/dev/null; then
		MY_SHELL=ksh93
	elif command -v bash >/dev/null; then
		MY_SHELL=bash
	elif command -v zsh >/dev/null; then
		MY_SHELL=zsh
	fi

	if [ ! -z "$MY_SHELL" ]; then
		export MY_SHELL
		exec "$MY_SHELL" "$0" "$@"
	else
		MY_SHELL=/bin/sh # hope for the best
		export MY_SHELL
	fi
fi

# hopefully we're now POSIX.
