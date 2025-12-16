# font-common.mk

#M=	HaranoAjiMincho
#G=	HaranoAjiGothic

FOUNDRY?=
NOKERNPAIRS?=

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

TEXTMAP?=	${GROFF_FONT}/devps/generate/text.map
TEXTENC?=	${GROFF_FONT}/devps/text.enc
DESC?=		${GROFF_FONT}/devps/DESC

OTFTODIT_OPTS?=	-e $(TEXTENC) -d $(DESC) -cS
FILTERFONT_OPTS?=	-012k
SUPP_SUFFIX?=	.s

EMBED?=
SPLIT?=

ROPTS?=		-F palt="*,*,palt"
IOPTS?=		$(ROPTS) -i 50 -m -a 12
BOPTS?=		$(ROPTS)
BIOPTS?=	$(IOPTS)
VOPTS?=		-V -F palt="*,*,vpal" -F vert="*,*,vrt2|vkna"
IVOPTS?=	$(VOPTS) -i 50 -a -12
BVOPTS?=	$(VOPTS)
BIVOPTS?=	$(IVOPTS)

define make_font?=
all::	$1$2
$1$2: $($1)-$($2).otf $($1)-$($2).afm otftodit filter-font
	otftodit $(OTFTODIT_OPTS) $($(2)OPTS) $$< $$(word 2,$$^) $(TEXTMAP) $$@ 2> $$@.err
	if grep -q "already mapped to groff name 'mc'" $$@.err; then \
		sed '/^mu mc$$$$/s/^/#/' $(TEXTMAP) >text.map; \
		$(MAKE) -f $(firstword $(MAKEFILE_LIST)) TEXTMAP=text.map clean-$1$2 $1$2; \
		rm -f text.map; \
	else \
		cat $$@.err; \
	fi
	@rm -f $$@.err
	mkdir -p /tmp/devpdf
ifeq "$(FOUNDRY)" ""
ifeq "$(SPLIT)" ""
	cat $1$2 \
	> /tmp/devpdf/$1$2
	> /tmp/devpdf/$1$2${SUPP_SUFFIX}
else
	filter-font $(FILTERFONT_OPTS) $1$2 > /tmp/devpdf/$1$2
	filter-font $(FILTERFONT_OPTS) -s -n $1$2${SUPP_SUFFIX} $1$2 > /tmp/devpdf/$1$2${SUPP_SUFFIX}
endif
ifneq "$(NOKERNPAIRS)" ""
	sed -i -e '/^kernpairs/,/^$$$$/d' /tmp/devpdf/$1$2
endif
	sed -i -e '/^kernpairs/,/^$$$$/d' /tmp/devpdf/$1$2${SUPP_SUFFIX}
else
ifeq "$(SPLIT)" ""
	cat $1$2 | sed \
	-e '/^name $1$2/s//name ${FOUNDRY}-$1$2/' \
	> /tmp/devpdf/${FOUNDRY}-$1$2
	> /tmp/devpdf/${FOUNDRY}-$1$2${SUPP_SUFFIX}
else
	filter-font $(FILTERFONT_OPTS) -n ${FOUNDRY}-$1$2 $1$2 > /tmp/devpdf/${FOUNDRY}-$1$2
	filter-font $(FILTERFONT_OPTS) -s -n ${FOUNDRY}-$1$2${SUPP_SUFFIX} $1$2 > /tmp/devpdf/${FOUNDRY}-$1$2${SUPP_SUFFIX}
endif
ifneq "$(NOKERNPAIRS)" ""
	sed -i -e '/^kernpairs/,/^$$$$/d' /tmp/devpdf/${FOUNDRY}-$1$2
endif
	sed -i -e '/^kernpairs/,/^$$$$/d' /tmp/devpdf/${FOUNDRY}-$1$2${SUPP_SUFFIX}
endif

all::	$1$2.download
$1$2.download: $($1)-$($2).otf $1$2
	printf "\t%s\t%s\n" `sed -n '/^internalname\s/{s///;p;q}' $1$2` \
		${EMBED}$$(abspath $$<) >$$@ || rm -f $$@

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

install::	all download
	mkdir -p /tmp/devpdf
	cp download /tmp/devpdf
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

%.afm:	%.otf tx
	[ -f $@ ] || tx -afm $< >$@

include font-util.mk
