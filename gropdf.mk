usage:
	@echo usage: make "[install|all|clean]"

include Mk/*.mk

GROPDF_CFG=	\
	use strict; \
	my %cfg = (PERL => (scalar <ARGV>) =~ /(\/\S*)/); \
	/^\$$cfg\{(\w+)\}\s*=/ and eval while <ARGV>; \
	$$cfg{VERSION} = $$cfg{GROFF_VERSION}; \
	$$cfg{GROFF_FONT_DIR} = $$cfg{GROFF_FONT_PATH}; \
	s|[@](\w+)[@]|$$cfg{$$1}//$$&|eg, print while <>;

VPATH+=	./files

all::	gropdf-otf pre-grops pyftsubset

install::	${GROFF_FONT}/devpdf/DESC gropdf-otf pre-grops
	(sed -E -e '/^((pre|post)pro|papersize)($$|\s)/d' $<; \
	echo papersize ${PAPERSIZE}; \
	echo postpro `which gropdf-otf`; \
	echo prepro `which pre-grops`; \
	) > /tmp/DESC
	cmp -s /tmp/DESC $< || \
		case "$<" in \
		${HOME}|${HOME}/*) \
			install -b -m644 /tmp/DESC $<; \
			;; \
		*) \
			sudo install -b -m644 /tmp/DESC $<; \
			;; \
		esac
	rm -f /tmp/DESC

GROPDF_OTF_PL?=	gropdf-otf.pl
gropdf-otf:	${GROPDF_OTF_PL} Inline-C.cpanm Font-TTF.cpanm Unicode-Normalize.cpanm Time-HiRes.cpanm plenv
	cat $< | perl -w -e '${GROPDF_CFG}' ${GROFF_BIN}/gropdf >/tmp/$@
	install-pl /tmp/$@
	rm -f /tmp/$@

clean::
	rm -f Inline-C.cpanm Font-TTF.cpanm Unicode-Normalize.cpanm Time-HiRes.cpanm

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


pre-grops:	App-grops-prepro.cpanm
	[ -x `which $@` ]

clean::
	rm -f App-grops-prepro.cpanm


pyftsubset:	fonttools.pip
	[ -x `which $@` ]

clean::
	rm -f fonttools.pip
