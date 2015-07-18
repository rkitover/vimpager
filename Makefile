PREFIX=/usr/local
SYSCONFDIR=${PREFIX}/etc
INSTALL=./scripts/install-sh
AWK=./scripts/awk-sh
MKPATH=${INSTALL} -m 755 -d
INSTALLBIN=${INSTALL} -m 555
INSTALLMAN=${INSTALL} -m 444
INSTALLCONF=${INSTALL} -m 644

ANSIESC=src/ansiesc/autoload/AnsiEsc.vim src/ansiesc/plugin/AnsiEscPlugin.vim src/ansiesc/plugin/cecutil.vim
SRC=${ANSIESC} src/less.vim src/perldoc.vim src/ConcealRetab.vim vimcat

all: vimpager docs
	@chmod +x vimcat

vimpager: ${SRC}
	@SRC="$?"; \
	chmod +x ${AWK} 2>/dev/null || true; \
	for src in $$SRC; do \
	    echo "installing $$src into vimpager"; \
	    mv vimpager vimpager.work; \
	    ${AWK} '\
		$$0 ~ "^begin [0-9]* [^ ]*/*'`basename $$src`'" { exit } \
		{ print } \
	    ' vimpager.work > vimpager; \
	    uuencode "$$src" "$$src" > "$${src}.uu"; \
	    cat "$${src}.uu" >> vimpager; \
	    echo EOF >> vimpager; \
	    ${AWK} '\
		BEGIN { skip = 1 } \
		$$0 ~ "^# END OF [^ ]*/*'`basename $$src`'" { skip = 0 } \
		skip == 1 { next } \
		{ print } \
	    ' vimpager.work >> vimpager; \
	    rm -f vimpager.work "$${src}.uu"; \
	done
	@rm -f src/ansiesc.tar
	@chmod +x vimpager

uninstall:
	rm -f ${PREFIX}/bin/vimpager
	rm -f ${PREFIX}/bin/vimcat
	rm -f ${PREFIX}/share/man/man1/vimpager.1
	rm -f ${PREFIX}/share/man/man1/vimcat.1
	rm -f ${PREFIX}/etc/vimpagerrc

install: docs
	@chmod +x ./install-sh 2>/dev/null || true; \
	${MKPATH} ${DESTDIR}/${PREFIX}/bin; \
	echo ${INSTALLBIN} vimpager ${DESTDIR}/${PREFIX}/bin/vimpager; \
	${INSTALLBIN} vimpager ${DESTDIR}/${PREFIX}/bin/vimpager; \
	echo ${INSTALLBIN} vimcat ${DESTDIR}/${PREFIX}/bin/vimcat; \
	${INSTALLBIN} vimcat ${DESTDIR}/${PREFIX}/bin/vimcat; \
	if [ -r vimpager.1 -o -r vimcat.1 ]; then \
		${MKPATH} ${DESTDIR}/${PREFIX}/share/man/man1; \
	fi; \
	if [ -r vimpager.1 ]; then \
		echo ${INSTALLMAN} vimpager.1 ${DESTDIR}/${PREFIX}/share/man/man1/vimpager.1; \
		${INSTALLMAN} vimpager.1 ${DESTDIR}/${PREFIX}/share/man/man1/vimpager.1; \
	fi; \
	if [ -r vimcat.1 ]; then \
		echo ${INSTALLMAN} vimcat.1 ${DESTDIR}/${PREFIX}/share/man/man1/vimcat.1; \
		${INSTALLMAN} vimcat.1 ${DESTDIR}/${PREFIX}/share/man/man1/vimcat.1; \
	fi; \
	${MKPATH} ${DESTDIR}/${SYSCONFDIR}; \
	echo ${INSTALLCONF} vimpagerrc ${DESTDIR}/${SYSCONFDIR}/vimpagerrc; \
	${INSTALLCONF} vimpagerrc ${DESTDIR}/${SYSCONFDIR}/vimpagerrc

docs: vimpager.1 vimcat.1
	@rm -f docs-warn-stamp

%.1: doc/%.md
	@if command -v pandoc >/dev/null; then \
		echo 'generating $@'; \
		pandoc -s -w man $< -o $@; \
	else \
		if [ ! -r docs-warn-stamp ]; then \
		    echo >&2; \
		    echo "[1;31mWARNING[0m: pandoc is not available, man pages will not be generated. If you want to install the man pages, install pandoc and re-run make." >&2; \
		    echo >&2; \
		    touch docs-warn-stamp; \
		fi; \
	fi

realclean distclean clean:
	rm -f *.1 README man.tar.gz *.work *-stamp *.uu src/*.uu src/ansiesc/autoload/*.uu src/ansiesc/plugin/*.uu

.PHONY: all install uninstall docs realclean distclean clean
