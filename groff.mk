# install groff --prefix=/usr/local

usage:
	@echo usage: ${MAKE} "[install|all|clean]"

include Mk/*.mk

groff.git?=	https://git.savannah.gnu.org/git/groff.git
groff.dir?=	$(CURDIR)/groff
#GROFF_TAG?=	refs/tags/${GROFF_VERSION}

all::	groff.all

groff.all:	groff.patch
	$(MAKE) -C $(groff.dir) all
	touch $@

groff.configure:	groff.git automake.pkg autoconf.pkg libtool.pkg		\
		texinfo.pkg bison.pkg pkgconf.pkg libuchardet-dev.pkg	\
		libxaw7-dev.pkg netpbm.pkg
	[ $(groff.dir) ]
	cd $(groff.dir); \
	git reset --hard; \
	git checkout master; \
	echo git pull; \
	[ ! -z "$(GROFF_VERSION)" ] && git checkout $(GROFF_VERSION); \
	[ -f ./bootstrap ] && ./bootstrap; \
	./configure --prefix=${GROFF_PREFIX}
	touch $@

# https://ja.wikipedia.org/w/index.php?search=CJK+Compatibility+Ideographs
patch-cjk_compat=	perl -i.bak -lne \
	'next if /^\s*(\{\s*)?"F[9A][0-9A-F]{2}|2F[89A][0-9A-F]{2}",/; print'

groff.patch:	patch-cjk_compat.log \
		patch-troff-ja.log

patch-cjk_compat.log:	groff.configure
	cd $(groff.dir); \
	$(patch-cjk_compat) \
		src/utils/afmtodit/afmtodit.tables \
		src/libs/libgroff/uniuni.cpp
	touch $@

O=	$@.tmp && mv $@.tmp $@
patch-troff-ja.log:	files/troff-ja.patch groff.configure
	patch -p1 -d $(groff.dir) <$< >$O 2>&1

clean::
	-[ -d $(groff.dir) ] && $(MAKE) -C $(groff.dir) $@
	rm -f groff.configure
	rm -f patch-cjk_compat.log
	rm -f patch-troff-ja.log
	rm -f groff.all

install:: all
	[ ! -L text.map ] || sudo rm -f text.map
	make -C $(groff.dir) $@
	cd ${GROFF_FONT}/devps/generate; \
	[ -f text.map ] || ln -s textmap text.map
	case "${SITE_TMAC}" in \
	${HOME}|${HOME}/*) \
		;; \
	/usr/share/groff/*|/usr/local/share/groff/*) \
		if [ ! -L "${SITE_TMAC}" -o "$$(readlink ${SITE_TMAC})" != "/etc/groff" ]; then \
			sudo mv ${SITE_TMAC} ${SITE_TMAC}.old; \
			sudo ln -s /etc/groff ${SITE_TMAC}; \
		fi; \
		;; \
	esac
