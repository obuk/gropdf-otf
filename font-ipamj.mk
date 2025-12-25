usage:
	@echo usage: ${MAKE} "[install|all|clean]"

include Mk/*.mk

FAM?=	IPAmjM
STY?=	R

D=	/usr/share/fonts/truetype/ipamj
F=	ipamjm
$D/$F.ttf:	fonts-ipamj-mincho.pkg

IPAmjM?=	$F

FOUNDRY?=
EMBED?=

TEXTMAP?=	text.map

# don't specify -S (deletes unnamed glyphs)
# to assign unnamed variation glyphs taken from mji.00602.xlsx.
OTFTODIT_OPTS?=	-c -w 290

VPATH+=		files

ROPTS?=
IOPTS?=		$(ROPTS) -i 50 -m -a 12
VOPTS?=		-V
IVOPTS?=	$(VOPTS) -i 50 -a -12

define make_font?=
all::	$1$2
$1$2:	$($1).afm $F.map otftodit
	otftodit ${OTFTODIT_OPTS} $($(2)OPTS) $$< $F.map $$@
	mkdir -p /tmp/devpdf;
ifeq "${FOUNDRY}" ""
	install -m644 $1$2 /tmp/devpdf
else
	cat $1$2 | sed '/^name $1$2/s//name $(FOUNDRY)-$1$2/' /tmp/devpdf/$(FOUNDRY)-$1$2
endif

all::	$1$2.download
$1$2.download: $1$2
	printf "\t%s\t%s\n" `sed -n '/^internalname\s/{s///;p;q}' $1$2` \
		${EMBED}${SITE_FONT}/devpdf/$($1).pfb >$$@ || rm -f $$@

clean-$1$2:
	rm -f $1$2
	rm -f $1$2.download

clean::	clean-$1$2
endef

clean::
	rm -rf /tmp/devpdf

$(foreach fam,${FAM}, $(foreach sty,${STY}, \
  $(eval $(call make_font,$(fam),$(sty))) \
))

download-files=	\
	$(foreach fam,${FAM},$(foreach sty,${STY},$(fam)$(sty).download))

download:	files/merge-download-files.pl $(download-files)
	perl $< $(if ${FOUNDRY}, -y ${FOUNDRY}) \
		${SITE_FONT}/devpdf/download $(download-files) > $@

install::	all download $F.pfb
	mkdir -p /tmp/devpdf
	cp download $F.pfb /tmp/devpdf
	case "${SITE_FONT}" in \
	${HOME}|${HOME}/*) \
		mkdir -p ${SITE_FONT}/devpdf; \
		install -m644 /tmp/devpdf/* ${SITE_FONT}/devpdf; \
		find ${SITE_FONT}/devpdf -empty -delete; \
		;; \
	*) \
		sudo mkdir -p ${SITE_FONT}/devpdf; \
		sudo install -m644 /tmp/devpdf/* ${SITE_FONT}/devpdf; \
		sudo find ${SITE_FONT}/devpdf -empty -delete; \
		;; \
	esac

clean::
	rm -f download

install::	install-ps.local.ipamj
install-ps.local.ipamj: ps.local.ipamj
	mkdir -p tmp
	cp ${SITE_TMAC}/ps.local tmp
	if grep -qF ps.local.ipamj tmp/ps.local; then \
		(echo /ps[.]local[.]ipamj/; echo //-2,/EOF/d; echo wq) | \
			ed tmp/ps.local; \
	fi
	cp tmp/ps.local tmp/ps.local.bak
	cat tmp/ps.local.bak $< >tmp/ps.local
	cmp -s ${SITE_TMAC}/ps.local tmp/ps.local || \
	case "${SITE_FONT}" in \
	${HOME}|${HOME}/*) \
		install -b -m 644 tmp/ps.local ${SITE_TMAC}; \
		;; \
	*) \
		sudo install -b -m 644 tmp/ps.local ${SITE_TMAC}; \
		;; \
	esac

# Adobe Glyph List, AGL For New Fonts, AGL without afii, AGL with PUA
AGL?=	Adobe Glyph List

# STROKE_TICKER=10 to make match stroke width to HaranoAjiMincho-Medium,
STROKE_TICKER?=

FF_GENERATE=	\
		Open($$1); \
		RenameGlyphs("${AGL}"); \
		ScaleToEm(1000); \
		$(if ${STROKE_TICKER}, \
			SelectAll(); \
			ClearInstrs(); \
			ExpandStroke(${STROKE_TICKER}, 0, 1, 0, 1);) \
		SetFontNames($$2:r); \
		Generate($$2);

$F.pfb $F.afm:	$D/$F.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_GENERATE)' $< $@

clean::
	rm -f $F.pfb
	rm -f $F.afm
	#sudo apt-get remove -y fonts-ipamj-mincho
	rm -f fonts-ipamj-mincho.pkg

textmap+mijmap.pl=\
	my %ucs; \
	while (<ARGV>) { \
	  chop; \
	  my ($$name, $$ucs) = split /;/; \
	  $$ucs{$$name} = $$ucs; \
	} \
	while (<STDIN>) { \
	  chop; \
	  next unless my $$ucs = $$ucs{$$_}; \
	  print "$$_ u$$ucs\n"; \
	}

textmap-hyphen.pl=\
	@F = split /\s+/; \
	$$hyphen++ if $$F[4] eq "hyphen"; \
	END { \
	  unless ($$hyphen) { \
	    print "figuredash -"; \
	    print "figuredash hy"; \
	  } \
	}

# generates $F.map as text.map
$F.map:	$F.afm mji.txt otftodit
	otftodit ${OTFTODIT_OPTS} $< ${TEXTMAP} $F.font
	(cat ${GROFF_FONT}/devps/generate/text.map; \
	echo "# mji.00602.xlsx"; \
	grep '^---' $F.font |cut -f5 | perl -e '${textmap+mijmap.pl}' mji.txt; \
	) >$@
	rm -f $F.font

clean::
	rm -f $F.map
	rm -f $F.err
	rm -f $F.font

mji.txt:	mji.00602.xlsx mji
	mji $< >$@

mji.00602.xlsx:
	curl -O https://moji.or.jp/wp-content/uploads/2024/01/$@

clean::
	rm -f mji.txt
	rm -f mji.00602.xlsx

include font-util.mk
