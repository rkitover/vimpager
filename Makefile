PREFIX=/usr/local
prefix=${PREFIX}
SYSCONFDIR=${prefix}/etc
INSTALL=./scripts/install-sh
MKPATH=${INSTALL} -m 755 -d
INSTALLBIN=${INSTALL} -m 555
INSTALLFILE=${INSTALL} -m 444
INSTALLMAN=${INSTALL} -m 444
INSTALLDOC=${INSTALL} -m 444
INSTALLCONF=${INSTALL} -m 644
PANDOC=./scripts/pandoc-sh

DOC_SRC=markdown_src/vimpager.md markdown_src/vimcat.md

GEN_DOCS=man/vimpager.1 man/vimcat.1 html/vimpager.html html/vimcat.html markdown/vimpager.md markdown/vimcat.md

ANSIESC=autoload/AnsiEsc.vim plugin/AnsiEscPlugin.vim plugin/cecutil.vim

RUNTIME=autoload/vimpager.vim autoload/vimpager_utils.vim autoload/vimcat.vim plugin/vimpager.vim macros/less.vim syntax/perldoc.vim ${ANSIESC}

SRC=vimcat ${RUNTIME}

PROGRAMS=vimpager vimcat

all: ${PROGRAMS:=-vertag-stamp} standalone/vimpager standalone/vimcat docs

# set tag from git or ChangeLog
%-vertag-stamp: %
	@echo updating version tag in $<
	@tag=`git tag 2>/dev/null | tail -1`; \
	[ -z "$$tag" ] && tag=`sed -n '/^[0-9][0-9.]* [0-9-]*:$$/{s/ .*//;p;q;}' ChangeLog_$<.yml`; \
	if [ -n "$$tag" ]; then \
		sed -e 's/^version_tag=.*/version_tag='"$$tag"'/' $< > $<.work; \
		mv -f $<.work $<; \
	fi
	@chmod +x $<
	@touch $@

# other recipes need the version, get it from git describe or ChangeLog
%-version.txt: %
	@echo building $@
	@git describe >$<-version.txt 2>/dev/null \
	|| sed -n '/^[0-9][0-9.]* [0-9-]*:$$/{s/ .*//;p;q;}' ChangeLog_$<.yml >$<-version.txt

standalone/vimpager: vimpager vimpager-version.txt ${SRC:=.uu} inc/* Makefile
	@echo building $@
	@${MKPATH} ${@D}
	@sed \
	    -e '/^ *\. .*inc\/prologue.sh"$$/{' \
	    -e     'r inc/prologue.sh' \
	    -e     d \
	    -e '}' \
	    -e 's/^\( *\)# EXTRACT BUNDLED SCRIPTS HERE$$/\1extract_bundled_scripts/' \
	    -e 's|^version=.*|version="'"`cat vimpager-version.txt`"' (standalone, shell=\$$(command -v \$$POSIX_SHELL))"|' \
	    -e 's!^\( *\)runtime=.*$$!\1runtime='\''\$$tmp/runtime'\''!' \
	    -e 's!^\( *\)vimcat=.*$$!\1vimcat='\''\$$runtime/bin/vimcat'\''!' \
	    -e 's!^\( *\)system_vimpagerrc=.*$$!\1system_vimpagerrc='\'\''!' \
	    -e '/^# INCLUDE BUNDLED SCRIPTS HERE$$/{ q; }' \
	    vimpager > $@
	@cat inc/do_uudecode.sh >> $@
	@cat inc/bundled_scripts.sh >> $@
	@cat ${SRC:=.uu} >> $@
	@sed -n '/^# END OF BUNDLED SCRIPTS$$/,$$p' vimpager >> $@
	@chmod +x $@

standalone/vimcat: vimcat autoload/vimcat.vim vimcat-version.txt inc/prologue.sh Makefile
	@echo building $@
	@${MKPATH} ${@D}
	@nlinit=`echo 'nl="'; echo '"'`; eval "$$nlinit"; \
	sed -e '1a\'"$$nl"': if 0' \
	    -e '/^# FIND REAL PARENT DIRECTORY$$/,/^# END OF FIND REAL PARENT DIRECTORY$$/d' \
	    -e 's/^\( *\)# INSERT VIMCAT_DEBUG PREPARATION HERE$$/\1if [ "$${VIMCAT_DEBUG:-0}" -eq 0 ]; then silent="silent! "; else silent=; fi/' \
	    -e 's|^version=.*|version="'"`cat vimcat-version.txt`"' (standalone, shell=\$$(command -v \$$POSIX_SHELL))"|' \
	    -e '/^runtime=.*/d' \
	    -e '/^ *--cmd "set rtp^=\$$runtime" \\$$/d' \
	    -e '/call vimcat#Init/i\'"$$nl"'--cmd "$$silent source $$0" \\' \
	    -e 's/vimcat#\([^ ]*\)(/\1(/g' \
	    -e '/^ *\. .*inc\/prologue.sh"$$/{' \
	    -e     'r inc/prologue.sh' \
	    -e     d \
	    -e '}' \
	    vimcat > $@
	@cp $@ $@.work
	@awk '/^[ 	]*(if|for|while)/ { print $$1 }' $@ \
	  | sed '1!G;h;$$!d' \
	  | sed -e 's/^/: end/' >> $@.work
	@mv -f $@.work $@
	@echo ': endif' >> $@
	@sed -e 's/vimcat#\([^ ]*\)(/\1(/g' autoload/vimcat.vim >> $@
	@chmod +x $@

vimcat.uu: vimcat vimcat-version.txt
	@echo uuencoding vimcat
	@echo 'vimcat_script() {' > $@
	@printf "\t(cat <<'EOF') | do_uudecode > bin/vimcat\n" >> $@
	@sed \
	    -e 's|^version=.*|version="'"`cat vimcat-version.txt`"' (bundled, shell=\$$(command -v \$$POSIX_SHELL))"|' \
	    -e '/^ *\. .*inc\/prologue.sh"$$/{' \
	    -e     'r inc/prologue.sh' \
	    -e     d \
	    -e '}' \
	    vimcat > $@.work
	@uuencode $@.work vimcat >> $@
	@echo EOF >> $@
	@echo '}' >> $@
	@rm $@.work

%.uu: %
	@echo uuencoding $<
	@echo '$<() {' | sed 's|[/.]|_|g' > $@
	@printf "\t(cat <<'EOF') | do_uudecode > $<\n" >> $@
	@uuencode $< $< >> $@
	@echo EOF >> $@
	@echo '}' >> $@

uninstall:
	rm -f "${prefix}/bin/vimpager"
	rm -f "${prefix}/bin/vimcat"
	rm -f "${prefix}/share/man/man1/vimpager.1"
	rm -f "${prefix}/share/man/man1/vimcat.1"
	rm -rf "${prefix}/share/doc/vimpager"
	rm -rf "${prefix}/share/vimpager"
	@if [ '${PREFIX}' = '/usr' ] && diff /etc/vimpagerrc vimpagerrc >/dev/null 2>&1; then \
	    echo rm -f /etc/vimpagerrc; \
	    rm -rf /etc/vimpagerrc; \
	elif diff "${SYSCONFDIR}/vimpagerrc" vimpagerrc >/dev/null 2>&1; then \
	    echo rm -f "${SYSCONFDIR}/vimpagerrc"; \
	    rm -f "${SYSCONFDIR}/vimpagerrc"; \
	fi

install: docs vimpager.configured vimcat.configured
	@chmod +x ./install-sh 2>/dev/null || true
	@${MKPATH} "${DESTDIR}${prefix}/bin"
	${INSTALLBIN} vimpager.configured "${DESTDIR}${prefix}/bin/vimpager"
	${INSTALLBIN} vimcat.configured "${DESTDIR}${prefix}/bin/vimcat"
	@if [ -d man ]; then \
	    ${MKPATH} "${DESTDIR}${prefix}/share/man/man1"; \
	    echo ${INSTALLMAN} man/vimpager.1 "${DESTDIR}${prefix}/share/man/man1/vimpager.1"; \
	    ${INSTALLMAN} man/vimpager.1 "${DESTDIR}${prefix}/share/man/man1/vimpager.1"; \
	    echo ${INSTALLMAN} man/vimcat.1 "${DESTDIR}${prefix}/share/man/man1/vimcat.1"; \
	    ${INSTALLMAN} man/vimcat.1 "${DESTDIR}${prefix}/share/man/man1/vimcat.1"; \
	fi
	@${MKPATH} "${DESTDIR}${prefix}/share/doc/vimpager"
	${INSTALLDOC} markdown_src/vimpager.md "${DESTDIR}${prefix}/share/doc/vimpager/vimpager.md"
	${INSTALLDOC} markdown_src/vimcat.md "${DESTDIR}${prefix}/share/doc/vimpager/vimcat.md"
	${INSTALLDOC} TODO.yml "${DESTDIR}${prefix}/share/doc/vimpager/TODO.yml"
	${INSTALLDOC} DOC_AUTHORS.yml "${DESTDIR}${prefix}/share/doc/vimpager/DOC_AUTHORS.yml"
	${INSTALLDOC} ChangeLog_vimpager.yml "${DESTDIR}${prefix}/share/doc/vimpager/ChangeLog_vimpager.yml"
	${INSTALLDOC} ChangeLog_vimcat.yml "${DESTDIR}${prefix}/share/doc/vimpager/ChangeLog_vimcat.yml"
	${INSTALLDOC} uganda.txt "${DESTDIR}${prefix}/share/doc/vimpager/uganda.txt"
	${INSTALLDOC} debian/copyright "${DESTDIR}${prefix}/share/doc/vimpager/copyright"
	@if [ -d html ]; then \
	    ${MKPATH} "${DESTDIR}${prefix}/share/doc/vimpager/html"; \
	    echo ${INSTALLDOC} html/vimpager.html "${DESTDIR}${prefix}/share/doc/vimpager/html/vimpager.html"; \
	    ${INSTALLDOC} html/vimpager.html "${DESTDIR}${prefix}/share/doc/vimpager/html/vimpager.html"; \
	    echo ${INSTALLDOC} html/vimcat.html "${DESTDIR}${prefix}/share/doc/vimpager/html/vimcat.html"; \
	    ${INSTALLDOC} html/vimcat.html "${DESTDIR}${prefix}/share/doc/vimpager/html/vimcat.html"; \
	fi
	${MKPATH} "${DESTDIR}${prefix}/share/vimpager"
	@for rt_file in ${RUNTIME}; do \
	    if [ ! -d "`dirname "${DESTDIR}${prefix}/share/vimpager/$$rt_file"`" ]; then \
		echo ${MKPATH} "`dirname "${DESTDIR}${prefix}/share/vimpager/$$rt_file"`"; \
		${MKPATH} "`dirname "${DESTDIR}${prefix}/share/vimpager/$$rt_file"`"; \
	    fi; \
	    echo ${INSTALLFILE} "$$rt_file" "${DESTDIR}${prefix}/share/vimpager/$$rt_file"; \
	    ${INSTALLFILE} "$$rt_file" "${DESTDIR}${prefix}/share/vimpager/$$rt_file"; \
	done
	@SYSCONFDIR='${DESTDIR}${SYSCONFDIR}'; \
	if [ '${PREFIX}' = /usr ]; then \
	    SYSCONFDIR='${DESTDIR}/etc'; \
	fi; \
	${MKPATH} "$${SYSCONFDIR}" 2>/dev/null || true; \
	echo ${INSTALLCONF} vimpagerrc "$${SYSCONFDIR}/vimpagerrc"; \
	${INSTALLCONF} vimpagerrc "$${SYSCONFDIR}/vimpagerrc"

%.configured: % %-version.txt
	@echo configuring $<
	@POSIX_SHELL="`scripts/find_shell`"; \
	if [ '${PREFIX}' = /usr ]; then \
	    vimpagerrc=/etc/vimpagerrc; \
	else \
	    vimpagerrc='${SYSCONFDIR}/vimpagerrc'; \
	fi; \
	sed -e '1{ s|.*|#!'"$$POSIX_SHELL"'|; }' \
	    -e 's|\$$POSIX_SHELL|'"$$POSIX_SHELL|" \
	    -e '/^ *\. .*inc\/prologue.sh"$$/d' \
	    -e 's|^version=.*|version="'"`cat $<-version.txt`"' (configured, shell='"$$POSIX_SHELL"')"|' \
	    -e '/^# FIND REAL PARENT DIRECTORY$$/,/^# END OF FIND REAL PARENT DIRECTORY$$/d' \
	    -e 's!^\( *\)runtime=.*!\1runtime='\''${PREFIX}/share/vimpager'\''!' \
	    -e 's!^\( *\)vimcat=.*!\1vimcat='\''${PREFIX}/bin/vimcat'\''!' \
	    -e 's!^\( *\)system_vimpagerrc=.*!\1system_vimpagerrc='\'"$$vimpagerrc"\''!' \
	    $< > $@
	@chmod +x $@

install-deb:
	@if [ "`id | cut -d= -f2 | cut -d'(' -f1`" -ne 0 ]; then \
	    echo '[1;31mERROR[0m: You must be root, try sudo.' >&2; \
	    echo >&2; \
	    exit 1; \
	fi
	@-apt-get -qq update
	@apt-get -yqq install debhelper devscripts equivs gdebi-core
	@$(MAKE) clean
	@mk-build-deps
	@echo y | gdebi vimpager-build-deps*.deb
	@rm -f vimpager-build-deps*.deb
	@orig_tar_ball=../vimpager_"`sed -ne '/^vimpager (/{ s/^vimpager (\([^)-]*\).*/\1/p; q; }' debian/changelog)`".orig.tar; \
	    rm -f "$$orig_tar_ball".gz; \
	    tar cf "$$orig_tar_ball" * .travis.yml .mailmap .gitignore; \
	    gzip "$$orig_tar_ball"
	@dpkg-buildpackage -us -uc
	@echo y | gdebi `ls -1t ../vimpager*deb | head -1`
	@dpkg --purge vimpager-build-deps
	@-[ "$${CLEAN_BUILD_DEPS:-1}" -ne 0 ] && apt-get -yqq autoremove
	@debian/rules clean

docs: ${GEN_DOCS} docs.tar.gz Makefile
	@rm -f docs-warn-stamp doctoc-warn-stamp

docs.tar.gz: ${GEN_DOCS} ${DOC_SRC}
	@rm -f $@
	@if [ "`ls -1 $? 2>/dev/null | wc -l`" -eq "`echo $? | wc -w`" ]; then \
	    echo tar cf docs.tar $?; \
	    tar cf docs.tar $?; \
	    echo gzip -9 docs.tar; \
	    gzip -9 docs.tar; \
	fi

# Build markdown with TOCs and gitter.im badge
markdown/%.md: markdown_src/%.md
	@if command -v doctoc >/dev/null; then \
	    echo 'generating $@'; \
	    ${MKPATH} `dirname '$@'` 2>/dev/null || true; \
	    cp $< $@.work; \
	    doctoc --title '### Vimpager User Manual' $@.work >/dev/null; \
	    cat markdown_src/gitter-im-badge.md $@.work > $@; \
	    rm -f $@.work; \
	else \
	    if [ ! -r doctoc-warn-stamp ]; then \
		echo >&2; \
		echo "[1;31mWARNING[0m: doctoc is not available, markdown with Tables Of Contents will not be generated. If you want to generate them, install doctoc with: npm install -g doctoc" >&2; \
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

.SECONDARY: vimpager.md.work vimcat.md.work

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
	rm -rf *.work */*.work *-stamp *-version.txt *.deb *.tar.gz *.configured *.uu */*.uu man html standalone */with_meta_*

test: standalone/vimpager standalone/vimcat
	@if command -v bats >/dev/null; then \
	    bats test; \
	else \
	    echo "[1;31mWARNING[0m: bats is not available, tests will not be run. If you want to run tests, install bats from https://github.com/sstephenson/bats.git or your distribution and rerun \`make test\`." >&2; \
	    echo >&2; \
	fi

.PHONY: all install install-deb uninstall docs realclean distclean clean test
# vim: sw=4
