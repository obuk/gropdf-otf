# install groff --prefix=/usr/local

usage:
	@echo usage: ${MAKE} "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

groff.git?=	https://git.savannah.gnu.org/git/groff.git
groff.dir?=	/vagrant/groff
GROFF_TAG?=	refs/tags/${GROFF_VERSION}

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
	[ ! -z "$(GROFF_TAG)" ] && git checkout $(GROFF_TAG); \
	echo git pull origin master; \
	[ -f ./bootstrap ] && ./bootstrap; \
	./configure --prefix=${GROFF_PREFIX}
	touch $@

# https://ja.wikipedia.org/w/index.php?search=CJK+Compatibility+Ideographs
patch_cjk_compat=	perl -i.bak -lne \
	'next if /^\s*(\{\s*)?"F[9A][0-9A-F]{2}|2F[89A][0-9A-F]{2}",/; print'

groff.patch:	groff.configure
	cd $(groff.dir); \
	$(patch_cjk_compat) \
		src/utils/afmtodit/afmtodit.tables \
		src/libs/libgroff/uniuni.cpp
	touch $@

clean::
	-[ -d $(groff.dir) ] && $(MAKE) -C $(groff.dir) $@
	rm -f groff.configure
	rm -f groff.patch
	rm -f groff.all

install:: all
	[ ! -L text.map ] || sudo rm -f text.map
	sudo make -C $(groff.dir) $@
	if [ ! -L "${SITE_TMAC}" -o "$$(readlink ${SITE_TMAC})" != "/etc/groff" ]; then \
		sudo mv ${SITE_TMAC} ${SITE_TMAC}.old; \
		sudo ln -s /etc/groff ${SITE_TMAC}; \
	fi
	cd ${GROFF_FONT}/devps/generate; \
	[ -f text.map ] || sudo ln -s textmap text.map
