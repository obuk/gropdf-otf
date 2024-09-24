usage:
	@echo usage: ${MAKE} "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

han-serif.git?=	https://github.com/adobe-fonts/source-han-serif
han-serif.dir?=	source-han-serif

# override C (experimental)
FAM?=	M
CN?=	JP
SERIF?=	SourceHanSerif
M?=	${SERIF}${CN}

OTF?=	${han-serif.dir}/Masters/Regular/${SERIF}${CN}-Regular.otf \
	${han-serif.dir}/Masters/Bold/${SERIF}${CN}-Bold.otf

all::	${OTF}

${OTF}:	han-serif.git afdko.pip
	$(call build-han,${SERIF},.${CN},.SUBSET)

clean::
	rm -f $(addsuffix .afm,$(basename $(notdir ${OTF})))
	rm -f han-serif.git

VPATH+=	$(dir ${OTF})
include font-common-han.mk
