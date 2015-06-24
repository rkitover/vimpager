PREFIX=/usr/local
SYSCONFDIR=${PREFIX}/etc
INSTALL=./install-sh
MKPATH=${INSTALL} -m 755 -d
INSTALLBIN=${INSTALL} -m 555
INSTALLMAN=${INSTALL} -m 444
INSTALLCONF=${INSTALL} -m 644
AWK=awk

all: vimpager docs

vimpager: ansiesc.tar.uu less.vim.uu perldoc.vim.uu vimcat.uu ConcealRetab.vim.uu
	mv vimpager vimpager.work
	${AWK} '\
	    /^begin [0-9]* ansiesc.tar/ { exit } \
	    { print } \
	' vimpager.work > vimpager
	cat ansiesc.tar.uu >> vimpager
	echo EOF >> vimpager
	${AWK} '\
	    BEGIN { skip = 1 } \
	    /^# END OF ansiesc.tar/ { skip = 0 } \
	    skip == 1 { next } \
	    { print } \
	' vimpager.work >> vimpager
	rm -f vimpager.work ansiesc.tar.uu
	mv vimpager vimpager.work
	${AWK} '\
	    /^begin [0-9]* less.vim/ { exit } \
	    { print } \
	' vimpager.work > vimpager
	cat less.vim.uu >> vimpager
	echo EOF >> vimpager
	${AWK} '\
	    BEGIN { skip = 1 } \
	    /^# END OF less.vim/ { skip = 0 } \
	    skip == 1 { next } \
	    { print } \
	' vimpager.work >> vimpager
	rm -f vimpager.work less.vim.uu
	mv vimpager vimpager.work
	${AWK} '\
	    /^begin [0-9]* vimcat/ { exit } \
	    { print } \
	' vimpager.work > vimpager
	cat vimcat.uu >> vimpager
	echo EOF >> vimpager
	${AWK} '\
	    BEGIN { skip = 1 } \
	    /^# END OF vimcat/ { skip = 0 } \
	    skip == 1 { next } \
	    { print } \
	' vimpager.work >> vimpager
	rm -f vimpager.work vimcat.uu
	mv vimpager vimpager.work
	${AWK} '\
	    /^begin [0-9]* perldoc.vim/ { exit } \
	    { print } \
	' vimpager.work > vimpager
	cat perldoc.vim.uu >> vimpager
	echo EOF >> vimpager
	${AWK} '\
	    BEGIN { skip = 1 } \
	    /^# END OF perldoc.vim/ { skip = 0 } \
	    skip == 1 { next } \
	    { print } \
	' vimpager.work >> vimpager
	rm -f vimpager.work perldoc.vim.uu
	mv vimpager vimpager.work
	${AWK} '\
	    /^begin [0-9]* ConcealRetab.vim/ { exit } \
	    { print } \
	' vimpager.work > vimpager
	cat ConcealRetab.vim.uu >> vimpager
	echo EOF >> vimpager
	${AWK} '\
	    BEGIN { skip = 1 } \
	    /^# END OF ConcealRetab.vim/ { skip = 0 } \
	    skip == 1 { next } \
	    { print } \
	' vimpager.work >> vimpager
	rm -f vimpager.work ConcealRetab.vim.uu
	chmod +x vimpager

less.vim.uu: less.vim
	uuencode less.vim less.vim > less.vim.uu

perldoc.vim.uu: perldoc.vim
	uuencode perldoc.vim perldoc.vim > perldoc.vim.uu

vimcat.uu: vimcat
	uuencode vimcat vimcat > vimcat.uu

ConcealRetab.vim.uu: ConcealRetab.vim
	uuencode ConcealRetab.vim ConcealRetab.vim > ConcealRetab.vim.uu

ansiesc.tar.uu: ansiesc/autoload/AnsiEsc.vim ansiesc/plugin/AnsiEscPlugin.vim ansiesc/plugin/cecutil.vim
	(cd ansiesc; tar cf ../ansiesc.tar .)
	uuencode ansiesc.tar ansiesc.tar > ansiesc.tar.uu
	rm -f ansiesc.tar

uninstall:
	rm -f ${PREFIX}/bin/vimpager
	rm -f ${PREFIX}/bin/vimcat
	rm -f ${PREFIX}/share/man/man1/vimpager.1
	rm -f ${PREFIX}/share/man/man1/vimcat.1
	rm -f ${PREFIX}/etc/vimpagerrc

install: docs
	@INSTALL="${INSTALL}"; \
	INSTALLBIN="${INSTALLBIN}"; \
	INSTALLMAN="${INSTALLMAN}"; \
	INSTALLCONF="${INSTALLCONF}"; \
	chmod +x ./install-sh 2>/dev/null || true; \
	${MKPATH} ${DESTDIR}/${PREFIX}/bin; \
	echo $$INSTALLBIN vimpager ${DESTDIR}/${PREFIX}/bin/vimpager; \
	$$INSTALLBIN vimpager ${DESTDIR}/${PREFIX}/bin/vimpager; \
	echo $$INSTALLBIN vimcat ${DESTDIR}/${PREFIX}/bin/vimcat; \
	$$INSTALLBIN vimcat ${DESTDIR}/${PREFIX}/bin/vimcat; \
	if [ -r vimpager.1 -o -r vimcat.1 ]; then \
		${MKPATH} ${DESTDIR}/${PREFIX}/share/man/man1; \
	fi; \
	if [ -r vimpager.1 ]; then \
		echo $$INSTALLMAN vimpager.1 ${DESTDIR}/${PREFIX}/share/man/man1/vimpager.1; \
		$$INSTALLMAN vimpager.1 ${DESTDIR}/${PREFIX}/share/man/man1/vimpager.1; \
	fi; \
	if [ -r vimcat.1 ]; then \
		echo $$INSTALLMAN vimcat.1 ${DESTDIR}/${PREFIX}/share/man/man1/vimcat.1; \
		$$INSTALLMAN vimcat.1 ${DESTDIR}/${PREFIX}/share/man/man1/vimcat.1; \
	fi; \
	${MKPATH} ${DESTDIR}/${SYSCONFDIR}; \
	echo $$INSTALLCONF vimpagerrc ${DESTDIR}/${SYSCONFDIR}/vimpagerrc; \
	$$INSTALLCONF vimpagerrc ${DESTDIR}/${SYSCONFDIR}/vimpagerrc

docs:
	@if command -v pandoc >/dev/null; then \
		printf '%s' 'Generating vimpager.1...'; \
		pandoc -s -w man vimpager.md -o vimpager.1; \
		tr -d '\015' < vimpager.1 > vimpager.1.tmp; \
		mv vimpager.1.tmp vimpager.1; \
		echo 'done.'; \
		printf '%s' 'Generating vimcat.1...'; \
		pandoc -s -w man vimcat.md -o vimcat.1; \
		tr -d '\015' < vimcat.1 > vimcat.1.tmp; \
		mv vimcat.1.tmp vimcat.1; \
		echo 'done.'; \
		printf '%s' 'Generating README...'; \
		pandoc -s -w plain vimpager.md -o README; \
		tr -d '\015' < README > README.tmp; \
		mv README.tmp README; \
		echo 'done.'; \
		printf '%s' 'Generating man.tar.gz...'; \
		tar cf - vimpager.1 vimcat.1 | gzip -c > man.tar.gz; \
		echo 'done.'; \
	else \
		echo; \
		echo "[1;31mWARNING[0m: pandoc is not available, man pages will not be generated. If you want to install the man pages, install pandoc and re-run make." >&2; \
		echo; \
	fi

realclean distclean clean:
	rm -f *.1 README man.tar.gz *.uu *.work

.PHONY: all install uninstall docs realclean distclean clean
