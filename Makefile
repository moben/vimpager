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
AWK=./scripts/awk-sh
PANDOC=./scripts/pandoc-sh

DOC_SRC=markdown_src/vimpager.md markdown_src/vimcat.md

GEN_DOCS=man/vimpager.1 man/vimcat.1 html/vimpager.html html/vimcat.html markdown/vimpager.md markdown/vimcat.md

ANSIESC=autoload/AnsiEsc.vim plugin/AnsiEscPlugin.vim plugin/cecutil.vim

RUNTIME=autoload/vimpager.vim autoload/vimpager_utils.vim plugin/vimpager.vim macros/less.vim syntax/perldoc.vim ${ANSIESC}

SRC=vimcat ${RUNTIME}

all: balance-shellvim-stamp standalone/vimpager standalone/vimcat docs

balance-shellvim-stamp: vimcat
	@chmod +x scripts/balance-shellvim
	@scripts/balance-shellvim
	@touch balance-shellvim-stamp

standalone/%: ${SRC} inc/*
	@echo building $@
	@${MKPATH} `dirname $@`
	@SRC="$?"; \
	base="`basename $@`"; \
	cp "$$base" $@; \
	if grep '^# INCLUDE BUNDLED SCRIPTS' "$$base" >/dev/null; then \
		cp $@ ${@}.work; \
		sed -e 's|^version=.*|version="'"`git describe`"' (standalone, shell=\$$(command -v \$$POSIX_SHELL))"|' \
		    -e 's/^	stripped=1$$/	stripped=0/' \
		    -e '/^# INCLUDE BUNDLED SCRIPTS HERE$$/{ q; }' \
		    ${@}.work > $@; \
		cat inc/do_uudecode.sh >> $@; \
		cat inc/bundled_scripts.sh >> $@; \
		sed -n '/^# END OF BUNDLED SCRIPTS$$/,$$p' "$$base" >> $@; \
		chmod +x ${AWK} 2>/dev/null || true; \
		for src in $$SRC; do \
		    case "$$src" in \
			inc/*) \
				continue; \
				;; \
		    esac; \
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
	fi
	@cp $@ ${@}.work
	@sed -e '/^[ 	]*\.[ 	]*.*inc\/prologue.sh.*$$/{' \
	    -e     'r inc/prologue.sh' \
	    -e     d \
	    -e '}' ${@}.work > $@
	@rm -f ${@}.work
	@if grep '^: if 0$$' ${@} >/dev/null; then \
		chmod +x scripts/balance-shellvim; \
		scripts/balance-shellvim $@; \
	fi
	@chmod +x $@

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
	if [ -d html ]; then \
		${MKPATH} "${DESTDIR}${prefix}/share/doc/vimpager/html"; \
		echo ${INSTALLDOC} html/vimpager.html "${DESTDIR}${prefix}/share/doc/vimpager/html/vimpager.html"; \
		${INSTALLDOC} html/vimpager.html "${DESTDIR}${prefix}/share/doc/vimpager/html/vimpager.html"; \
		echo ${INSTALLDOC} html/vimcat.html "${DESTDIR}${prefix}/share/doc/vimpager/html/vimcat.html"; \
		${INSTALLDOC} html/vimcat.html "${DESTDIR}${prefix}/share/doc/vimpager/html/vimcat.html"; \
	fi
	${MKPATH} "${DESTDIR}${prefix}/share/vimpager"
	for rt_file in ${RUNTIME}; do \
		if [ ! -d "`dirname "${DESTDIR}${prefix}/share/vimpager/$$rt_file"`" ]; then \
			echo ${MKPATH} "`dirname "${DESTDIR}${prefix}/share/vimpager/$$rt_file"`"; \
			${MKPATH} "`dirname "${DESTDIR}${prefix}/share/vimpager/$$rt_file"`"; \
		fi; \
		echo ${INSTALLFILE} "$$rt_file" "${DESTDIR}${prefix}/share/vimpager/$$rt_file"; \
		${INSTALLFILE} "$$rt_file" "${DESTDIR}${prefix}/share/vimpager/$$rt_file"; \
	done; \
	SYSCONFDIR='${DESTDIR}${SYSCONFDIR}'; \
	if [ '${PREFIX}' = '/usr' ]; then \
		SYSCONFDIR='${DESTDIR}/etc'; \
	fi; \
	${MKPATH} "$${SYSCONFDIR}" 2>/dev/null || true; \
	echo ${INSTALLCONF} vimpagerrc "$${SYSCONFDIR}/vimpagerrc"; \
	${INSTALLCONF} vimpagerrc "$${SYSCONFDIR}/vimpagerrc"

%.configured: %
	@echo configuring $<
	@POSIX_SHELL="`scripts/find_shell`"; \
	sed  -e '1{ s|.*|#!'"$$POSIX_SHELL"'|; }' \
	     -e 's|\$$POSIX_SHELL|'"$$POSIX_SHELL|" \
	     -e '/^[ 	]*\.[ 	]*.*inc\/prologue.sh.*$$/d' \
	     -e 's|^version=.*|version="'"`git describe`"' (configured, shell='"$$POSIX_SHELL"')"|' \
	     -e 's!^	PREFIX=.*!	PREFIX=${PREFIX}!' \
	     -e 's!^	configured=0!	configured=1!' $< > $@
	@chmod +x $@

install-deb:
	@if [ "`id | cut -d= -f2 | cut -d'(' -f1`" -ne 0 ]; then \
	    echo '[1;31mERROR[0m: You must be root, try sudo.' >&2; \
	    echo >&2; \
	    exit 1; \
	fi
	@apt-get update || true
	@apt-get -y install debhelper devscripts equivs gdebi-core
	@mk-build-deps
	@echo y | gdebi vimpager-build-deps*.deb
	@rm -f vimpager-build-deps*.deb
	@orig_tar_ball=../vimpager_"`sed -ne '/^vimpager (/{ s/^vimpager (\([^)-]*\).*/\1/p; q; }' debian/changelog)`".orig.tar; \
		rm -f "$$orig_tar_ball".gz; \
		tar cf "$$orig_tar_ball" * .travis.yml; \
		gzip "$$orig_tar_ball"
	@dpkg-buildpackage -us -uc
	@echo y | gdebi `ls -1t ../vimpager*deb | head -1`
	@dpkg --purge vimpager-build-deps
	@apt-get -y autoremove
	@debian/rules clean

docs: ${GEN_DOCS} docs.tar.gz
	@rm -f docs-warn-stamp doctoc-warn-stamp

docs.tar.gz: ${GEN_DOCS} ${DOC_SRC}
	@rm -f $@
	@if [ "`ls -1 $? 2>/dev/null | wc -l`" -eq "`echo $? | wc -w`" ]; then \
		echo tar cf docs.tar $?; \
		tar cf docs.tar $?; \
		echo gzip -9 docs.tar; \
		gzip -9 docs.tar; \
	fi

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
	rm -rf *.work */*.work *-stamp *.deb *.tar.gz *.configured *.uu */*.uu man html standalone */with_meta_*

.PHONY: all install install-deb uninstall docs realclean distclean clean
