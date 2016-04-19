PREFIX=/usr/local
SYSCONFDIR=${PREFIX}/etc
INSTALL=./scripts/install-sh
MKPATH=${INSTALL} -m 755 -d
INSTALLBIN=${INSTALL} -m 555
INSTALLFILE=${INSTALL} -m 444
INSTALLMAN=${INSTALL} -m 444
INSTALLDOC=${INSTALL} -m 444
INSTALLCONF=${INSTALL} -m 644
AWK=./scripts/awk-sh
PANDOC=./scripts/pandoc-sh

DOC_SRC=markdown_src/vimpager.md markdown_src/vimcat.md

GEN_DOCS=man/vimpager.1 man/vimcat.1 html/vimpager.html html/vimcat.html markdown/vimpager.md markdown/vimcat.md

ANSIESC=autoload/AnsiEsc.vim plugin/AnsiEscPlugin.vim plugin/cecutil.vim

RUNTIME=autoload/vimpager.vim autoload/vimpager_utils.vim plugin/vimpager.vim macros/less.vim syntax/perldoc.vim ${ANSIESC}

SRC=vimcat ${RUNTIME}

all: balance-vimcat-stamp standalone/vimpager standalone/vimcat docs

balance-vimcat-stamp: vimcat
	@scripts/balance-vimcat
	@touch balance-vimcat-stamp

standalone/%: ${SRC} inc/*
	@echo building $@
	@SRC="$?"; \
	${MKPATH} `dirname $@`; \
	base="`basename $@`"; \
	cp "$$base" $@; \
	if grep '^# INCLUDE BUNDLED SCRIPTS' "$$base" >/dev/null; then \
		cp $@ ${@}.work; \
		sed -e 's|^version="\$$(git describe) (git)"$$|version="'"`git describe`"' (standalone, shell='"$$MY_SHELL"')"|' \
		    -e 's/^	stripped=1$$/	stripped=0/' \
		    -e '/^# INCLUDE BUNDLED SCRIPTS HERE$$/{ q; }' \
		    ${@}.work > $@; \
		cat inc/do_uudecode.sh >> $@; \
		cat inc/bundled_scripts.sh >> $@; \
		sed -n '/^# END OF BUNDLED SCRIPTS$$/,$$p' "$$base" >> $@; \
		chmod +x ${AWK} 2>/dev/null || true; \
		for src in $$SRC; do \
		    mv $@ ${@}.work; \
		    src_escaped=`echo $$src | sed -e 's!/!\\\\/!g'`; \
		    ${AWK} '\
			/^begin [0-9]* '"$$src_escaped"'/ { exit } \
			{ print } \
		    ' ${@}.work > $@; \
		    uuencode "$$src" "$$src" > "$${src}.uu"; \
		    cat "$${src}.uu" >> $@; \
		    echo EOF >> $@; \
		    ${AWK} '\
			BEGIN { skip = 1 } \
			/^# END OF '"$$src_escaped"'/ { skip = 0 } \
			skip == 1 { next } \
			{ print } \
		    ' ${@}.work >> $@; \
		    rm -f ${@}.work "$${src}.uu"; \
		done; \
	fi; \
	cp $@ ${@}.work; \
	nlinit="`echo 'nl=\"'; echo '\"'`"; eval "$$nlinit"; \
	sed "/^[ 	]*\.[ 	]*.*inc\/prologue.sh[ 	]*"'$$'"/{$${nl}\
		x$${nl}\
		r inc/prologue.sh$${nl}\
	}" ${@}.work > $@; \
	rm -f ${@}.work; \
	if grep '^: if 0$$' ${@} >/dev/null; then \
		scripts/balance-vimcat $@; \
	fi
	@chmod +x $@

uninstall:
	rm -f "${PREFIX}/bin/vimpager"
	rm -f "${PREFIX}/bin/vimcat"
	rm -f "${PREFIX}/share/man/man1/vimpager.1"
	rm -f "${PREFIX}/share/man/man1/vimcat.1"
	rm -rf "${PREFIX}/share/doc/vimpager"
	rm -rf "${PREFIX}/share/vimpager"
	@if [ '${PREFIX}' = '/usr' ] && diff /etc/vimpagerrc vimpagerrc >/dev/null 2>&1; then \
		echo rm -f /etc/vimpagerrc; \
		rm -rf /etc/vimpagerrc; \
	elif diff "${SYSCONFDIR}/vimpagerrc" vimpagerrc >/dev/null 2>&1; then
		echo rm -f "${SYSCONFDIR}/vimpagerrc"; \
		rm -f "${SYSCONFDIR}/vimpagerrc"; \
	fi

install: docs vimpager.configured vimcat.configured
	@chmod +x ./install-sh 2>/dev/null || true; \
	${MKPATH} "${DESTDIR}${PREFIX}/bin"; \
	echo ${INSTALLBIN} vimpager.configured "${DESTDIR}${PREFIX}/bin/vimpager"; \
	${INSTALLBIN} vimpager.configured "${DESTDIR}${PREFIX}/bin/vimpager"; \
	echo ${INSTALLBIN} vimcat.configured "${DESTDIR}${PREFIX}/bin/vimcat"; \
	${INSTALLBIN} vimcat.configured "${DESTDIR}${PREFIX}/bin/vimcat"; \
	if [ -d man ]; then \
		${MKPATH} "${DESTDIR}${PREFIX}/share/man/man1"; \
		echo ${INSTALLMAN} man/vimpager.1 "${DESTDIR}${PREFIX}/share/man/man1/vimpager.1"; \
		${INSTALLMAN} man/vimpager.1 "${DESTDIR}${PREFIX}/share/man/man1/vimpager.1"; \
		echo ${INSTALLMAN} man/vimcat.1 "${DESTDIR}${PREFIX}/share/man/man1/vimcat.1"; \
		${INSTALLMAN} man/vimcat.1 "${DESTDIR}${PREFIX}/share/man/man1/vimcat.1"; \
	fi; \
	${MKPATH} "${DESTDIR}${PREFIX}/share/doc/vimpager"; \
	echo ${INSTALLDOC} markdown_src/vimpager.md "${DESTDIR}${PREFIX}/share/doc/vimpager/vimpager.md"; \
	${INSTALLDOC} markdown_src/vimpager.md "${DESTDIR}${PREFIX}/share/doc/vimpager/vimpager.md"; \
	echo ${INSTALLDOC} markdown_src/vimcat.md "${DESTDIR}${PREFIX}/share/doc/vimpager/vimcat.md"; \
	${INSTALLDOC} markdown_src/vimcat.md "${DESTDIR}${PREFIX}/share/doc/vimpager/vimcat.md"; \
	echo ${INSTALLDOC} TODO.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/TODO.yml"; \
	${INSTALLDOC} TODO.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/TODO.yml"; \
	echo ${INSTALLDOC} DOC_AUTHORS.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/DOC_AUTHORS.yml"; \
	${INSTALLDOC} DOC_AUTHORS.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/DOC_AUTHORS.yml"; \
	echo ${INSTALLDOC} ChangeLog_vimpager.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/ChangeLog_vimpager.yml"; \
	${INSTALLDOC} ChangeLog_vimpager.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/ChangeLog_vimpager.yml"; \
	echo ${INSTALLDOC} ChangeLog_vimcat.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/ChangeLog_vimcat.yml"; \
	${INSTALLDOC} ChangeLog_vimcat.yml "${DESTDIR}${PREFIX}/share/doc/vimpager/ChangeLog_vimcat.yml"; \
	echo ${INSTALLDOC} uganda.txt "${DESTDIR}${PREFIX}/share/doc/vimpager/uganda.txt"; \
	${INSTALLDOC} uganda.txt "${DESTDIR}${PREFIX}/share/doc/vimpager/uganda.txt"; \
	echo ${INSTALLDOC} debian/copyright "${DESTDIR}${PREFIX}/share/doc/vimpager/copyright"; \
	${INSTALLDOC} debian/copyright "${DESTDIR}${PREFIX}/share/doc/vimpager/copyright"; \
	if [ -d html ]; then \
		${MKPATH} "${DESTDIR}${PREFIX}/share/doc/vimpager/html"; \
		echo ${INSTALLDOC} html/vimpager.html "${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimpager.html"; \
		${INSTALLDOC} html/vimpager.html "${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimpager.html"; \
		echo ${INSTALLDOC} html/vimcat.html "${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimcat.html"; \
		${INSTALLDOC} html/vimcat.html "${DESTDIR}${PREFIX}/share/doc/vimpager/html/vimcat.html"; \
	fi; \
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

%.configured: %
	@echo configuring $<; \
	MY_SHELL="`scripts/find_shell`"; \
	MY_SHELL="`command -v \"$$MY_SHELL\"`"; \
	sed  -e '1{ s|.*|#!'"$$MY_SHELL"'|; }' \
	     -e '/^[ 	]*\.[ 	]*.*inc\/prologue.sh[ 	]*$$/d' \
	     -e 's|^version="\$$(git describe) (git)"$$|version="'"`git describe`"' (configured, shell='"$$MY_SHELL"')"|' \
	     -e 's!^	PREFIX=.*!	PREFIX=${PREFIX}!' \
	     -e 's!^	configured=0!	configured=1!' $< > $@; \
	chmod +x $@

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
	@orig_tar_ball=../vimpager_"`sed -ne '/^vimpager (/{ s/^vimpager (\([^)-]*\).*/\1/p; q; }' debian/changelog)`".orig.tar; \
		rm -f "$$orig_tar_ball".gz; \
		tar cf "$$orig_tar_ball" *; \
		gzip "$$orig_tar_ball"
	@dpkg-buildpackage -us -uc -rfakeroot
	@yes | gdebi `ls -1t ../vimpager*deb | head -1`
	@dpkg --purge vimpager-build-deps
	@apt-get -y autoremove
	@rm -f vimpager-build-deps*.deb
	@debian/rules clean

docs: ${GEN_DOCS} docs.tar.gz
	@rm -f docs-warn-stamp doctoc-warn-stamp

docs.tar.gz: ${GEN_DOCS} ${DOC_SRC}
	@rm -f $@
	tar cf docs.tar ${GEN_DOCS} ${DOC_SRC}
	gzip -9 docs.tar

# Build markdown with TOCs
markdown/%.md: markdown_src/%.md
	@if command -v doctoc >/dev/null; then \
		echo 'generating $@'; \
		${MKPATH} `dirname '$@'` 2>/dev/null || true; \
		cp $< $@; \
		doctoc --title '### Vimpager User Manual' $@ >/dev/null; \
	else \
		if [ ! -r doctoc-warn-stamp ]; then \
		    echo >&2; \
		    echo "[1;31mWARNING[0m: doctoc is not available, markdown with Tables Of Contents will not be generated. If you want to generate them, install doctoc with: npm instlal -g doctoc" >&2; \
		    echo >&2; \
		    touch doctoc-warn-stamp; \
		fi; \
	fi

man/%.1: markdown_src/%.md
	@if command -v pandoc >/dev/null; then \
		echo 'generating $@'; \
		${MKPATH} `dirname '$@'` 2>/dev/null || true; \
		${PANDOC} -Ss -f markdown_github $< -o $@; \
	else \
		if [ ! -r docs-warn-stamp ]; then \
		    echo >&2; \
		    echo "[1;31mWARNING[0m: pandoc is not available, man pages and html will not be generated. If you want to install the man pages and html, install pandoc and re-run make." >&2; \
		    echo >&2; \
		    touch docs-warn-stamp; \
		fi; \
	fi

# transform markdown links to html links
%.md.work: markdown_src/%.md
	@sed -e 's|\(\[[^]]*\]\)(markdown/\([^.]*\)\.md)|\1(\2.html)|g' < $< > $@

html/%.html: %.md.work
	@if command -v pandoc >/dev/null; then \
		echo 'generating $@'; \
		${MKPATH} `dirname '$@'` 2>/dev/null || true; \
		${PANDOC} -Ss --toc -f markdown_github $< -o $@; \
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
	rm -rf *.work */*.work *-stamp *.deb *.configured *.uu */*.uu man html standalone

.PHONY: all install uninstall docs gen-TOCs realclean distclean clean

# vim: ft=make :
