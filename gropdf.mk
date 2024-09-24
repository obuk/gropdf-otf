usage:
	@echo usage: make "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

GROPDF_CFG=	\
	use strict; \
	my %cfg = (PERL => (scalar <ARGV>) =~ /(\/\S*)/); \
	/^\$$cfg\{(\w+)\}\s*=/ and eval while <ARGV>; \
	$$cfg{VERSION} = $$cfg{GROFF_VERSION}; \
	$$cfg{GROFF_FONT_DIR} = $$cfg{GROFF_FONT_PATH}; \
	s|[@](\w+)[@]|$$cfg{$$1}//$$&|eg, print while <>;

all::	gropdf gropdf.plenv

install::	${GROFF_FONT}/devpdf/DESC gropdf.plenv
	(sed -E -e /^postpro/d $<; echo postpro $(word 2, $^)) > /tmp/DESC
	cmp -s /tmp/DESC $< || sudo install -b -m644 /tmp/DESC $<
	rm -f /tmp/DESC

install::	gropdf gropdf.plenv pyftsubset.pyenv
	sudo install -b -m755 $^ ${LOCAL_BIN}/

gropdf.plenv:	gropdf Inline-C.cpanm Font-TTF.cpanm
	echo "#!/bin/sh\n\
	GROFF_USER=\$${GROFF_USER:-\$${USER:-${USER}}}\n\
	HOME=\$$(getent passwd \$${GROFF_USER} | cut -d: -f6)\n\
	export PLENV_ROOT=\"\$$HOME/.plenv\"\n\
	exec \"\$$PLENV_ROOT/libexec/plenv\" exec perl ${LOCAL_BIN}/$< \"\$$@\"" >$@

pyftsubset.pyenv:	pyftsubset
	echo "#!/bin/sh\n\
	GROFF_USER=\$${GROFF_USER:-\$${USER:-${USER}}}\n\
	HOME=\$$(getent passwd \$${GROFF_USER} | cut -d: -f6)\n\
	export PYENV_ROOT=\"\$$HOME/.pyenv\"\n\
	exec \"\$$PYENV_ROOT/libexec/pyenv\" exec $< \"\$$@\"" >$@

pyftsubset:	fonttools.pip

clean::
	rm -f gropdf.plenv
	rm -f pyftsubset.pyenv

VPATH+=	./files

GROPDF_PL?=	gropdf-otf.pl
gropdf:	${GROPDF_PL}
	cat $< | perl -w -e '${GROPDF_CFG}' ${GROFF_BIN}/gropdf >$@

clean::
	rm -f gropdf

GROFF_GIT?=	http://git.savannah.gnu.org/cgit/groff.git
GROPDF_HEAD?=	${GROFF_GIT}/plain/src/devices/gropdf/gropdf.pl
GROPDF_URL?=	${GROPDF_HEAD}?h=deri-gropdf-ng
#GROPDF_URL?=	${GROPDF_HEAD}?h=deri-gropdf-ng&id=2e6d61716710aaca2fff9bf37747a455afff22a5

gropdf-ng.pl:
	curl -o $@ -s ${GROPDF_URL}

gropdf.pl:
	if [ -d groff/.git ]; then \
	  git -C groff reset --hard; \
	  cp groff/src/devices/gropdf/gropdf.pl $@; \
	fi

clean::
	rm -f gropdf-ng.pl
	rm -f gropdf.pl
