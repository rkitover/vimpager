PREFIX?= /usr/local
SYSCONFDIR?= ${PREFIX}/etc
# OSX does not have install -D
MKPATH?= mkdir -p
INSTALL?= install
INSTALLBIN?= ${INSTALL} -m 555
INSTALLMAN?= ${INSTALL} -m 444
INSTALLCONF?= ${INSTALL} -m 644
COPYFILE?= ${INSTALL} -m 644

all: vimpager vimpager.1 vimcat.1 README README.md

vimpager: ansiesc.tar.uu less.vim.uu perldoc.vim.uu
	mv vimpager vimpager.work
	awk '\
	    /^begin [0-9]* ansiesc.tar/ { exit } \
	    { print } \
	' vimpager.work > vimpager
	cat ansiesc.tar.uu >> vimpager
	echo EOF >> vimpager
	awk '\
	    BEGIN { skip = 1 } \
	    /^# END OF ansiesc.tar/ { skip = 0 } \
	    skip == 1 { next } \
	    { print } \
	' vimpager.work >> vimpager
	rm -f vimpager.work ansiesc.tar.uu
	mv vimpager vimpager.work
	awk '\
	    /^begin [0-9]* less.vim/ { exit } \
	    { print } \
	' vimpager.work > vimpager
	cat less.vim.uu >> vimpager
	echo EOF >> vimpager
	awk '\
	    BEGIN { skip = 1 } \
	    /^# END OF less.vim/ { skip = 0 } \
	    skip == 1 { next } \
	    { print } \
	' vimpager.work >> vimpager
	rm -f vimpager.work less.vim.uu
	mv vimpager vimpager.work
	awk '\
	    /^begin [0-9]* perldoc.vim/ { exit } \
	    { print } \
	' vimpager.work > vimpager
	cat perldoc.vim.uu >> vimpager
	echo EOF >> vimpager
	awk '\
	    BEGIN { skip = 1 } \
	    /^# END OF perldoc.vim/ { skip = 0 } \
	    skip == 1 { next } \
	    { print } \
	' vimpager.work >> vimpager
	rm -f vimpager.work perldoc.vim.uu
	chmod +x vimpager

less.vim.uu: less.vim
	uuencode less.vim less.vim > less.vim.uu

perldoc.vim.uu: perldoc.vim
	uuencode perldoc.vim perldoc.vim > perldoc.vim.uu

ansiesc.tar.uu: ansiesc/autoload/AnsiEsc.vim ansiesc/doc/AnsiEsc.txt ansiesc/doc/tags ansiesc/plugin/AnsiEscPlugin.vim ansiesc/plugin/cecutil.vim
	(cd ansiesc; tar cf ../ansiesc.tar .)
	uuencode ansiesc.tar ansiesc.tar > ansiesc.tar.uu
	rm -f ansiesc.tar

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
