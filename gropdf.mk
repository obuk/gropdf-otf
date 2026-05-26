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
	echo \#prepro `which pre-grops`; \
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

gropdf-otf:	App-gropdf-plus.cpanm Font-TTF.cpanm plenv

clean::
	rm -f App-gropdf-plus.cpanm
	rm -f Font-TTF.cpanm

pre-grops:	App-grops-prepro.cpanm
	[ -x `which $@` ]

clean::
	rm -f App-grops-prepro.cpanm

pyftsubset:	fonttools.pip
	[ -x `which $@` ]

clean::
	rm -f fonttools.pip
