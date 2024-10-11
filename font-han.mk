usage:
	@echo usage: ${MAKE} "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

han-serif.git?=	https://github.com/adobe-fonts/source-han-serif
han-serif.dir?=	source-han-serif

han-sans.git?=	https://github.com/adobe-fonts/source-han-sans
han-sans.dir?=	source-han-sans

# override C (experimental)
FAM?=	M G
SERIF?=	SourceHanSerif
SANS?=	SourceHanSans
CN?=	JP
M?=	${SERIF}${CN}
G?=	${SANS}${CN}

OTF-SERIF?=\
	${han-serif.dir}/Masters/Regular/${SERIF}${CN}-Regular.otf \
	${han-serif.dir}/Masters/Bold/${SERIF}${CN}-Bold.otf

OTF-SANS?=\
	${han-sans.dir}/Regular/${SANS}${CN}-Regular.otf \
	${han-sans.dir}/Bold/${SANS}${CN}-Bold.otf

OTF?=	${OTF-SERIF} ${OTF-SANS}

all::	${OTF}

${OTF-SERIF}:	han-serif.git afdko.pip
	$(call build-han,${SERIF},.${CN},.SUBSET)

${OTF-SANS}:	han-sans.git afdko.pip
	$(call build-han,${SANS},.${CN},.SUBSET)

clean::
	rm -f $(addsuffix .afm,$(basename $(notdir ${OTF})))
	rm -f han-serif.git

VPATH+=	$(dir ${OTF})
include font-common-han.mk
