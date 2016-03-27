PREFIX=/usr/local
SYSCONFDIR=${PREFIX}/etc
INSTALL=./scripts/install-sh
AWK=./scripts/awk-sh
MKPATH=${INSTALL} -m 755 -d
INSTALLBIN=${INSTALL} -m 555
INSTALLFILE=${INSTALL} -m 444
INSTALLMAN=${INSTALL} -m 444
INSTALLDOC=${INSTALL} -m 444
INSTALLCONF=${INSTALL} -m 644

STRIP_FUNCS=do_uudecode less_vim vimcat_script perldoc_vim ansi_esc_vim ansi_esc_plugin_vim cecutil_plugin_vim autoload_vimpager_vim plugin_vimpager_vim

ANSIESC=autoload/AnsiEsc.vim plugin/AnsiEscPlugin.vim plugin/cecutil.vim
RUNTIME=autoload/vimpager.vim autoload/vimpager_utils.vim plugin/vimpager.vim macros/less.vim syntax/perldoc.vim ${ANSIESC}
SRC=vimcat ${RUNTIME} ${ANSIESC}

all: balance-vimcat-stamp vimpager docs

balance-vimcat-stamp: vimcat
	@scripts/balance-vimcat
	@touch balance-vimcat-stamp

vimpager: ${SRC}
	@SRC="$?"; \
	chmod +x ${AWK} 2>/dev/null || true; \
	for src in $$SRC; do \
	    echo "installing $$src into vimpager"; \
	    mv vimpager vimpager.work; \
	    src_escaped=`echo $$src | sed -e 's!/!\\\\/!g'`; \
	    ${AWK} '\
		/^begin [0-9]* '"$$src_escaped"'/ { exit } \
		{ print } \
	    ' vimpager.work > vimpager; \
	    uuencode "$$src" "$$src" > "$${src}.uu"; \
	    cat "$${src}.uu" >> vimpager; \
	    echo EOF >> vimpager; \
	    ${AWK} '\
		BEGIN { skip = 1 } \
		/^# END OF '"$$src_escaped"'/ { skip = 0 } \
		skip == 1 { next } \
		{ print } \
	    ' vimpager.work >> vimpager; \
	    rm -f vimpager.work "$${src}.uu"; \
	done
	@chmod +x vimpager

uninstall:
	rm -f "${PREFIX}/bin/vimpager"
	rm -f "${PREFIX}/bin/vimcat"
	rm -f "${PREFIX}/share/man/man1/vimpager.1"
	rm -f "${PREFIX}/share/man/man1/vimcat.1"
	rm -rf "${PREFIX}/share/doc/vimpager"
	@if [ '${PREFIX}' = '/usr' ]; then \
		echo rm -f /etc/vimpagerrc; \
		rm -rf /etc/vimpagerrc; \
	else \
		echo rm -f "${PREFIX}/etc/vimpagerrc"; \
		rm -f "${PREFIX}/etc/vimpagerrc"; \
	fi

install: docs vimpager.stripped
	@chmod +x ./install-sh 2>/dev/null || true; \
	${MKPATH} "${DESTDIR}${PREFIX}/bin"; \
	echo ${INSTALLBIN} vimpager.stripped "${DESTDIR}${PREFIX}/bin/vimpager"; \
	${INSTALLBIN} vimpager.stripped "${DESTDIR}${PREFIX}/bin/vimpager"; \
	echo ${INSTALLBIN} vimcat "${DESTDIR}${PREFIX}/bin/vimcat"; \
	${INSTALLBIN} vimcat "${DESTDIR}${PREFIX}/bin/vimcat"; \
	if [ -r vimpager.1 -o -r vimcat.1 ]; then \
		${MKPATH} "${DESTDIR}${PREFIX}/share/man/man1"; \
	fi; \
	if [ -r vimpager.1 ]; then \
		echo ${INSTALLMAN} vimpager.1 "${DESTDIR}${PREFIX}/share/man/man1/vimpager.1"; \
		${INSTALLMAN} vimpager.1 "${DESTDIR}${PREFIX}/share/man/man1/vimpager.1"; \
	fi; \
	if [ -r vimcat.1 ]; then \
		echo ${INSTALLMAN} vimcat.1 "${DESTDIR}${PREFIX}/share/man/man1/vimcat.1"; \
		${INSTALLMAN} vimcat.1 "${DESTDIR}${PREFIX}/share/man/man1/vimcat.1"; \
	fi; \
	${MKPATH} "${DESTDIR}${PREFIX}/share/doc/vimpager"; \
	echo ${INSTALLDOC} doc/vimpager.md "${DESTDIR}${PREFIX}/share/doc/vimpager/vimpager.md"; \
	${INSTALLDOC} doc/vimpager.md "${DESTDIR}${PREFIX}/share/doc/vimpager/vimpager.md"; \
	echo ${INSTALLDOC} doc/vimcat.md "${DESTDIR}${PREFIX}/share/doc/vimpager/vimcat.md"; \
	${INSTALLDOC} doc/vimcat.md "${DESTDIR}${PREFIX}/share/doc/vimpager/vimcat.md"; \
	echo ${INSTALLDOC} TODO.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/TODO.yml"; \
	${INSTALLDOC} TODO.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/TODO.yml"; \
	echo ${INSTALLDOC} ChangeLog_vimpager.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/ChangeLog_vimpager.yml"; \
	${INSTALLDOC} ChangeLog_vimpager.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/ChangeLog_vimpager.yml"; \
	echo ${INSTALLDOC} ChangeLog_vimcat.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/ChangeLog_vimcat.yml"; \
	${INSTALLDOC} ChangeLog_vimcat.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/ChangeLog_vimcat.yml"; \
	echo ${INSTALLDOC} uganda.txt "${DESTDIR}${PREFIX}/share/doc/vimpager/uganda.txt"; \
	${INSTALLDOC} uganda.txt "${DESTDIR}${PREFIX}/share/doc/vimpager/uganda.txt"; \
	echo ${INSTALLDOC} debian/copyright "${DESTDIR}${PREFIX}/share/doc/vimpager/copyright"; \
	${INSTALLDOC} debian/copyright "${DESTDIR}${PREFIX}/share/doc/vimpager/copyright"; \
	${MKPATH} "${DESTDIR}${PREFIX}/share/doc/vimpager/html"; \
	echo ${INSTALLDOC} doc/html/vimpager.html "${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimpager.html"; \
	${INSTALLDOC} doc/html/vimpager.html "${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimpager.html"; \
	echo ${INSTALLDOC} doc/html/vimcat.html "${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimcat.html"; \
	${INSTALLDOC} doc/html/vimcat.html "${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimcat.html"; \
	echo ${MKPATH} "${DESTDIR}${PREFIX}/share/vimpager"; \
	${MKPATH} "${DESTDIR}${PREFIX}/share/vimpager"; \
	for rt_file in ${RUNTIME}; do \
		if [ ! -d "`dirname "${DESTDIR}${PREFIX}/share/vimpager/$$rt_file"`" ]; then \
			echo ${MKPATH} "`dirname "${DESTDIR}${PREFIX}/share/vimpager/$$rt_file"`"; \
			${MKPATH} "`dirname "${DESTDIR}${PREFIX}/share/vimpager/$$rt_file"`"; \
		fi; \
		echo ${INSTALLFILE} "$$rt_file" "${DESTDIR}${PREFIX}/share/vimpager/$$rt_file"; \
		${INSTALLFILE} "$$rt_file" "${DESTDIR}${PREFIX}/share/vimpager/$$rt_file"; \
	done; \
	SYSCONFDIR='${DESTDIR}${SYSCONFDIR}'; \
	if [ '${PREFIX}' = '/usr' ]; then \
		SYSCONFDIR='${DESTDIR}/etc'; \
	fi; \
	${MKPATH} "$${SYSCONFDIR}" 2>/dev/null || true; \
	echo ${INSTALLCONF} vimpagerrc "$${SYSCONFDIR}/vimpagerrc"; \
	${INSTALLCONF} vimpagerrc "$${SYSCONFDIR}/vimpagerrc"

vimpager.stripped: vimpager
	@sed_script=`echo ${STRIP_FUNCS} | sed -e 's!\([^ ]*\) *!/\1() {$$/,/^}$$/d;!g'`; \
	echo stripping vimpager; \
	sed -e "$${sed_script}" \
		-e 's/^	stripped=0$$/	stripped=1/' \
		-e 's!^	PREFIX=.*!	PREFIX=${PREFIX}!' \
		vimpager > vimpager.stripped; \
	chmod +x vimpager.stripped

install-deb:
	@if [ "`id | cut -d'=' -f2 | cut -d'(' -f1`" -ne "0" ]; then \
	    echo '[1;31mERROR[0m: You must be root, try sudo.' >&2; \
	    echo >&2; \
	    exit 1; \
	fi
	@apt-get update || true
	@apt-get -y install debhelper devscripts equivs fakeroot gdebi-core
	@mk-build-deps
	@yes | gdebi vimpager-build-deps*.deb
	@tar zcf ../vimpager_"`sed -ne '/^vimpager (/{ s/^vimpager (\([^)-]*\).*/\1/p; q; }' debian/changelog)`".orig.tar.gz *
	@dpkg-buildpackage -us -uc -rfakeroot
	@yes | gdebi `ls -1t ../vimpager*deb | head -1`
	@dpkg --purge vimpager-build-deps
	@apt-get -y autoremove
	@rm -f vimpager-build-deps*.deb
	@debian/rules clean

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
		pandoc -f markdown_github -s $< -o $@; \
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
	rm -f *.1 *.work *-stamp *.deb *.stripped
	rm -rf doc/html
	rm -f `find . -name '*.uu'`

.PHONY: all install uninstall docs realclean distclean clean

# vi: set ft=make:
