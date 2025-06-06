# font-common.mk

VPATH+=	${GROFF_FONT}/devps/generate

#M=	HaranoAjiMincho
#G=	HaranoAjiGothic

FOUNDRY?=

R?=	Regular
B?=	Bold
I?=	$R
V?=	$R
IV?=	$R
BI?=	$B
BV?=	$B
BIV?=	$B

FAM?=	M G
STY?=	R I B BI V IV BV BIV

TEXTMAP?=	text.map
TEXTENC?=	text.enc
OTFTODIT?=	perl ./files/otftodit.pl
#OTFTODIT_OPTS?=	-e $(TEXTENC)
OTFTODIT_OPTS?=	-s
OTFTODIT_OPTS+=	-c
#OTFTODIT_OPTS+=	-S
EMBED?=

ROPTS?=		-F palt="*,*,palt"
IOPTS?=		$(ROPTS) -i 50 -m -a 12
BOPTS?=		$(ROPTS)
BIOPTS?=	$(IOPTS)
VOPTS?=		-V -F palt="*,*,vpal" -F vert="*,*,vrt2\|vkna"
#VOPTS?=		-V -F palt="*,*,vpal" -F vert="*,*,vert\|vkna"
IVOPTS?=	$(VOPTS) -i 50 -a -12
BVOPTS?=	$(VOPTS)
BIVOPTS?=	$(IVOPTS)

fix-mc:		text.map
	sed '/^mu mc$$/s/^/#/' $< >a.map
	mv a.map text.map

clean::
	rm -f text.map

otftodit.pl:	plenv Encode.cpanm Getopt-Long.cpanm fonttools.pip

define make_font?=
all::	$1$2
$1$2: $($1)-$($2).otf $($1)-$($2).afm otftodit.pl
	@echo cd $(CURDIR) ';' set -x ';' \
	$(OTFTODIT) $(OTFTODIT_OPTS) $($(2)OPTS) $$< $$(word 2,$$^) $(TEXTMAP) $$@ '2>' $$@.err '||' \
	rm -f $$@ | bash -l
	@if grep -q "already mapped to groff name 'mc'" $$@.err; then \
		rm -f $1$2; \
		$(MAKE) -f $(firstword $(MAKEFILE_LIST)) fix-mc; \
		$(MAKE) -f $(firstword $(MAKEFILE_LIST)) clean-$1$2 $1$2; \
	else \
		cat $$@.err; \
	fi
	@[ -f $$@ ]
	@rm -f $$@.err

install:: install-$1$2
install-$1$2:	$1$2
	sudo mkdir -p ${SITE_FONT}/devpdf
ifeq "$(FOUNDRY)" ""
	sudo install -m644 $1$2 $(SITE_FONT)/devpdf/
else
	sudo install -m644 $1$2 $(SITE_FONT)/devpdf/$(FOUNDRY)-$1$2
	sudo sed -i '/^name $1$2/s//name $(FOUNDRY)-$1$2/' \
				$(SITE_FONT)/devpdf/$(FOUNDRY)-$1$2
endif
clean::	clean-$1$2
clean-$1$2:
	rm -f $1$2 $1$2.download

#download-files: $1$2.download
$1$2.download: $($1)-$($2).otf $1$2
	printf "\t%s\t%s\n" `sed -n '/^internalname\s/{s///;p;q}' $(1)$(2)` \
		${EMBED}$$(abspath $$<) >$$@ || rm -f $$@
clean-download::
	rm -f $1$2.download
endef

$(foreach fam,${FAM}, $(foreach sty,${STY}, \
  $(eval $(call make_font,$(fam),$(sty))) \
))

download-files=	\
	$(foreach fam,${FAM},$(foreach sty,${STY},$(fam)$(sty).download))

download:	files/merge-download-files.pl $(download-files)
	perl $< $(if ${FOUNDRY}, -y ${FOUNDRY}) \
		$(SITE_FONT)/devpdf/download $(download-files) >$@

install::	install-download
install-download:	download
	sudo mkdir -p ${SITE_FONT}/devpdf
	sudo install -m644 download $(SITE_FONT)/devpdf/
clean::	clean-download
clean-download::
	rm -f download

%.afm:		%.otf afdko.pip
	bash -lc 'tx -afm $< ' >$@
