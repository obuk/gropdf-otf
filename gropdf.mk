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

VPATH+=	./files

all::	tmp/gropdf

GROPDF_PL?=	gropdf.pl
tmp/gropdf:	${GROPDF_PL} gropdf.diff
	mkdir -p tmp
	cat $< | perl -w -e '${GROPDF_CFG}' ${GROFF_BIN}/gropdf >tmp/gropdf
	patch -d tmp <$(word 2,$^)

install::	tmp/gropdf fonttools.pip Inline-C.cpanm Font-TTF.cpanm
	@if ! cmp -s $< ${GROFF_BIN}/gropdf; then \
	  echo sudo install -b -m755 $< ${GROFF_BIN}/gropdf; \
	  sudo install -b -m755 $< ${GROFF_BIN}/gropdf; \
	fi

GROFF_GIT?=	http://git.savannah.gnu.org/cgit/groff.git
GROPDF_HEAD?=	${GROFF_GIT}/plain/src/devices/gropdf/gropdf.pl
GROPDF_URL?=	${GROPDF_HEAD}?h=deri-gropdf-ng
#GROPDF_URL?=	${GROPDF_HEAD}?h=deri-gropdf-ng&id=2e6d61716710aaca2fff9bf37747a455afff22a5

gropdf.pl:
	curl -o $@ -s ${GROPDF_URL}

yagropdf.pl:
	if [ -d groff ]; then \
	  git -C groff reset --hard; \
	  git -C groff switch deri-gropdf-ng; \
	  cp groff/src/devices/gropdf/gropdf.pl $@; \
	  git -C groff switch master; \
	fi

clean::
	rm -f gropdf.pl
	rm -f yagropdf.pl
	rm -rf tmp
