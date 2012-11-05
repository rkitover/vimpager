PREFIX?= /usr/local
SYSCONFDIR?= ${PREFIX}/etc
INSTALL?= install
INSTALLDIR= ${INSTALL} -d
INSTALLBIN= ${INSTALL} -m 555
INSTALLMAN= ${INSTALL} -m 444
INSTALLCONF= ${INSTALL} -m 644

all: vimpager.1 README

uninstall:
	rm -f ${PREFIX}/bin/vimpager
	rm -f ${PREFIX}/bin/vimcat
	rm -f ${PREFIX}/share/man/man1/vimpager.1
	rm -f ${PREFIX}/etc/vimpagerrc

install:
	${INSTALLDIR} ${DESTDIR}${PREFIX}/bin
	${INSTALLBIN} vimpager ${DESTDIR}${PREFIX}/bin/
	${INSTALLBIN} vimcat ${DESTDIR}${PREFIX}/bin/
	${INSTALLDIR} ${DESTDIR}${PREFIX}/share/man/man1
	${INSTALLMAN} vimpager.1 ${DESTDIR}${PREFIX}/share/man/man1
	${INSTALLDIR} ${DESTDIR}${SYSCONFDIR}
	${INSTALLCONF} vimpagerrc ${DESTDIR}${SYSCONFDIR}/vimpagerrc

man: vimpager.1

vimpager.1: vimpager.md
	pandoc -s -w man vimpager.md -o vimpager.1
	dos2unix vimpager.1

README: vimpager.md
	pandoc -s -w plain vimpager.md -o README
	dos2unix README

.PHONY: all install uninstall man
