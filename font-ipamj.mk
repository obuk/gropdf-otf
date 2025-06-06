usage:
	@echo usage: ${MAKE} "[install|all|clean]"

include Mk/*.mk

FONT?=	IPAmjMR

# Adobe Glyph List, AGL For New Fonts, AGL without afii, AGL with PUA
AGL?=	Adobe Glyph List

# If you want to match the stroke width of IPAmjMincho to HaranoAjiMincho-Medium,
# set STROKE_WIDTH to 10.
STROKE_WIDTH?=

FF_GENERATE=	\
		Open($$1); \
		RenameGlyphs("${AGL}"); \
		ScaleToEm(1000); \
		$(if ${STROKE_WIDTH}, \
			SelectAll(); \
			ClearInstrs(); \
			ExpandStroke(${STROKE_WIDTH}, 0, 1, 0, 1);) \
		SetFontNames($$2:r); \
		Generate($$2);

D=	/usr/share/fonts/truetype/ipamj
$D/ipamjm.ttf:	fonts-ipamj-mincho.pkg
${FONT}.pfb ${FONT}.afm:	$D/ipamjm.ttf fontforge.pkg
	fontforge -lang=ff -c '$(FF_GENERATE)' $< $@

clean::
	rm -f ${FONT}.pfb
	rm -f ${FONT}.afm
	sudo apt-get remove -y fonts-ipamj-mincho
	rm -f fonts-ipamj-mincho.pkg

mji.txt:	mji.00602.xlsx files/mji.pl Spreadsheet-XLSX.cpanm
	bash -lc 'perl files/mji.pl $<' >$@

mji.00602.xlsx:
	curl -O https://moji.or.jp/wp-content/uploads/2024/01/$@

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

TEXTMAP=	${FONT}.map
%.map:	%.afm mji.txt text.map
	@echo cd ${CURDIR} ';' set -x ';' ${OTFTODIT} ${OTFTODIT_OPTS} $< text.map $*.font '2>' $*.err '||' rm -f $*.font | bash -l
	@cat $*.err
	@rm -f $*.err
	(cat $(word 3,$^); \
	echo "# mji.00602.xlsx"; \
	grep '^---' $*.font |cut -f5 | perl -e '${textmap+mijmap.pl}' $(word 2,$^); \
	) >$@
	rm -f $*.font

clean::
	rm -f ${FONT}.map
	rm -f ${FONT}.err
	rm -f ${FONT}.font

VPATH+=	files
install::	install-ps.local.ipamj
install-ps.local.ipamj: ps.local.ipamj
	mkdir -p tmp
	cp $< tmp
	cat tmp/ps.local* >/tmp/ps.local
	cmp -s /etc/groff/ps.local /tmp/ps.local || \
		sudo install -b -m 644 /tmp/ps.local /etc/groff
	rm -f /tmp/ps.local


VPATH+=	${GROFF_FONT}/devps/generate

FOUNDRY?=
EMBED?=

TEXTMAP?=	text.map
TEXTENC?=	text.enc

# don't specify -S (deletes unnamed glyphs)
# to assign unnamed variation glyphs taken from mji.00602.xlsx.
OTFTODIT?=	perl ./files/otftodit.pl
#OTFTODIT_OPTS?=	-e $(TEXTENC)
OTFTODIT_OPTS?=	-s
OTFTODIT_OPTS+=	-c
OTFTODIT_OPTS+=	-w 290

otftodit.pl:	plenv Encode.cpanm Getopt-Long.cpanm fonttools.pip

all::	${FONT}

${FONT}:	${FONT}.afm ${TEXTMAP}
	@echo cd ${CURDIR} ';' set -x ';' ${OTFTODIT} ${OTFTODIT_OPTS} $< ${TEXTMAP} $@ '2>' $@.err '||' rm -f $@ | bash -l
	@[ -f $@ ]
	@cat $@.err
	@rm -f $@.err

install:: install-${FONT}
install-${FONT}:	${FONT}
	sudo mkdir -p ${SITE_FONT}/devpdf
	sudo install -m644 $< ${SITE_FONT}/devpdf/
clean::	clean-${FONT}
clean-${FONT}:
	rm -f ${FONT} ${FONT}.download

#VPATH+=	files
download:	merge-download-files.pl download-files
	perl $< $(if ${FOUNDRY}, -y ${FOUNDRY}) \
		$(SITE_FONT)/devpdf/download *.download >$@

download-files: ${FONT}.download
${FONT}.download: ${FONT}.pfb ${FONT}
	printf "\t%s\t%s\n" `sed -n '/^internalname\s/{s///;p;q}' ${FONT}` \
		${EMBED}${SITE_FONT}/devpdf/$< >$@ || rm -f $@
clean-download::
	rm -f ${FONT}.download

install::	install-pfb
install-pfb:	${FONT}.pfb
	sudo install -m644 $< ${SITE_FONT}/devpdf/

install::	install-download
install-download:	download
	sudo mkdir -p ${SITE_FONT}/devpdf
	sudo install -m644 download $(SITE_FONT)/devpdf/
clean::	clean-download
clean-download::
	rm -f download
