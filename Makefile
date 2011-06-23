PREFIX?= /usr/local
INSTALL?= install
INSTALLDIR= ${INSTALL} -d
INSTALLBIN= ${INSTALL} -m 555
INSTALLMAN= ${INSTALL} -m 444

uninstall:
	rm -f ${PREFIX}/bin/vimpager

install: 
	${INSTALLDIR} ${DESTDIR}${PREFIX}/bin
	${INSTALLBIN} vimpager ${DESTDIR}${PREFIX}/bin/
