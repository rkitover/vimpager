PREFIX?= /usr/local
SYSCONFDIR?= ${PREFIX}/etc
# OSX does not have install -D
MKPATH?= mkdir -p
INSTALL?= install
INSTALLBIN?= ${INSTALL} -m 555
INSTALLMAN?= ${INSTALL} -m 444
INSTALLCONF?= ${INSTALL} -m 644
COPYFILE?= ${INSTALL} -m 644

all: vimpager.1 README README.md

uninstall:
	rm -f ${PREFIX}/bin/vimpager
	rm -f ${PREFIX}/bin/vimcat
	rm -f ${PREFIX}/share/man/man1/vimpager.1
	rm -f ${PREFIX}/etc/vimpagerrc

install:
	${MKPATH} ${DESTDIR}/${PREFIX}/bin
	${INSTALLBIN} vimpager ${DESTDIR}/${PREFIX}/bin/vimpager
	${INSTALLBIN} vimcat ${DESTDIR}/${PREFIX}/bin/vimcat
	${MKPATH} ${DESTDIR}/${PREFIX}/share/man/man1
	${INSTALLMAN} vimpager.1 ${DESTDIR}/${PREFIX}/share/man/man1/vimpager.1
	${INSTALLMAN} vimcat.1 ${DESTDIR}/${PREFIX}/share/man/man1/vimcat.1
	${MKPATH} ${DESTDIR}/${SYSCONFDIR}
	${INSTALLCONF} vimpagerrc ${DESTDIR}/${SYSCONFDIR}/vimpagerrc

man: vimpager.1 vimcat.1

%.1: %.md
	pandoc -s -w man $< -o $@
	dos2unix $@

README: vimpager.md
	pandoc -s -w plain vimpager.md -o README
	dos2unix README

README.md: vimpager.md
	${COPYFILE} vimpager.md README.md

.PHONY: all install uninstall man
