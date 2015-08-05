PREFIX=/usr/local
SYSCONFDIR=${PREFIX}/etc
INSTALL=./scripts/install-sh
AWK=./scripts/awk-sh
MKPATH=${INSTALL} -m 755 -d
INSTALLBIN=${INSTALL} -m 555
INSTALLMAN=${INSTALL} -m 444
INSTALLDOC=${INSTALL} -m 444
INSTALLCONF=${INSTALL} -m 644

ANSIESC=src/ansiesc/autoload/AnsiEsc.vim src/ansiesc/plugin/AnsiEscPlugin.vim src/ansiesc/plugin/cecutil.vim
SRC=src/vimpager.vim src/less.vim vimcat src/perldoc.vim ${ANSIESC}

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
	@chmod +x vimpager

uninstall:
	rm -f ${PREFIX}/bin/vimpager
	rm -f ${PREFIX}/bin/vimcat
	rm -f ${PREFIX}/share/man/man1/vimpager.1
	rm -f ${PREFIX}/share/man/man1/vimcat.1
	rm -rf ${PREFIX}/share/doc/vimpager
	@if [ '${PREFIX}' = '/usr' ]; then \
		echo rm -f /etc/vimpagerrc; \
		rm -rf /etc/vimpagerrc; \
	else \
		echo rm -f ${PREFIX}/etc/vimpagerrc; \
		rm -f ${PREFIX}/etc/vimpagerrc; \
	fi

install: docs
	@chmod +x ./install-sh 2>/dev/null || true; \
	${MKPATH} ${DESTDIR}${PREFIX}/bin; \
	echo ${INSTALLBIN} vimpager ${DESTDIR}${PREFIX}/bin/vimpager; \
	${INSTALLBIN} vimpager ${DESTDIR}${PREFIX}/bin/vimpager; \
	echo ${INSTALLBIN} vimcat ${DESTDIR}${PREFIX}/bin/vimcat; \
	${INSTALLBIN} vimcat ${DESTDIR}${PREFIX}/bin/vimcat; \
	if [ -r vimpager.1 -o -r vimcat.1 ]; then \
		${MKPATH} ${DESTDIR}${PREFIX}/share/man/man1; \
	fi; \
	if [ -r vimpager.1 ]; then \
		echo ${INSTALLMAN} vimpager.1 ${DESTDIR}${PREFIX}/share/man/man1/vimpager.1; \
		${INSTALLMAN} vimpager.1 ${DESTDIR}${PREFIX}/share/man/man1/vimpager.1; \
	fi; \
	if [ -r vimcat.1 ]; then \
		echo ${INSTALLMAN} vimcat.1 ${DESTDIR}${PREFIX}/share/man/man1/vimcat.1; \
		${INSTALLMAN} vimcat.1 ${DESTDIR}${PREFIX}/share/man/man1/vimcat.1; \
	fi; \
	${MKPATH} ${DESTDIR}${PREFIX}/share/doc/vimpager; \
	echo ${INSTALLDOC} doc/vimpager.md ${DESTDIR}${PREFIX}/share/doc/vimpager/vimpager.md; \
	${INSTALLDOC} doc/vimpager.md ${DESTDIR}${PREFIX}/share/doc/vimpager/vimpager.md; \
	echo ${INSTALLDOC} doc/vimcat.md ${DESTDIR}${PREFIX}/share/doc/vimpager/vimcat.md; \
	${INSTALLDOC} doc/vimcat.md ${DESTDIR}${PREFIX}/share/doc/vimpager/vimcat.md; \
	${MKPATH} ${DESTDIR}${PREFIX}/share/doc/vimpager/html; \
	echo ${INSTALLDOC} doc/html/vimpager.html ${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimpager.html; \
	${INSTALLDOC} doc/html/vimpager.html ${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimpager.html; \
	echo ${INSTALLDOC} doc/html/vimcat.html ${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimcat.html; \
	${INSTALLDOC} doc/html/vimcat.html ${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimcat.html; \
	SYSCONFDIR='${DESTDIR}${SYSCONFDIR}'; \
	if [ '${PREFIX}' = '/usr' ]; then \
		SYSCONFDIR='${DESTDIR}/etc'; \
	fi; \
	${MKPATH} $${SYSCONFDIR} 2>/dev/null || true; \
	echo ${INSTALLCONF} vimpagerrc $${SYSCONFDIR}/vimpagerrc; \
	${INSTALLCONF} vimpagerrc $${SYSCONFDIR}/vimpagerrc

docs: vimpager.1 vimcat.1 doc/html/vimpager.html doc/html/vimcat.html
	@rm -f docs-warn-stamp

%.1: doc/%.md
	@if command -v pandoc >/dev/null; then \
		echo 'generating $@'; \
		${MKPATH} `dirname '$@'` 2>/dev/null || true; \
		pandoc -s $< -o $@; \
	else \
		if [ ! -r docs-warn-stamp ]; then \
		    echo >&2; \
		    echo "[1;31mWARNING[0m: pandoc is not available, man pages and html will not be generated. If you want to install the man pages and html, install pandoc and re-run make." >&2; \
		    echo >&2; \
		    touch docs-warn-stamp; \
		fi; \
	fi

# transform markdown links to html links
%.md.work: doc/%.md
	@sed -e 's|\(\[[^]]*\]\)(doc/\([^.]*\)\.md)|\1(\2.html)|g' < $< > $@

doc/html/%.html: %.md.work
	@if command -v pandoc >/dev/null; then \
		echo 'generating $@'; \
		${MKPATH} `dirname '$@'` 2>/dev/null || true; \
		pandoc -s -f Markdown $< -o $@; \
		rm -f $<; \
	else \
		if [ ! -r docs-warn-stamp ]; then \
		    echo >&2; \
		    echo "[1;31mWARNING[0m: pandoc is not available, man pages and html will not be generated. If you want to install the man pages and html, install pandoc and re-run make." >&2; \
		    echo >&2; \
		    touch docs-warn-stamp; \
		fi; \
	fi

realclean distclean clean:
	rm -f *.1 *.work *-stamp
	rm -rf doc/html
	rm -f `find . -name '*.uu'`

.PHONY: all install uninstall docs realclean distclean clean

# vi: set ft=make:
