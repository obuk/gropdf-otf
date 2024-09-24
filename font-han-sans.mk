usage:
	@echo usage: ${MAKE} "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

han-sans.git?=	https://github.com/adobe-fonts/source-han-sans
han-sans.dir?=	source-han-sans

# override C (experimental)
FAM?=	G
CN?=	JP
SANS?=	SourceHanSans
G?=	${SANS}${CN}

OTF?=	${han-sans.dir}/Regular/${SANS}${CN}-Regular.otf \
	${han-sans.dir}/Bold/${SANS}${CN}-Bold.otf

all::	${OTF}

${OTF}:	han-sans.git afdko.pip
	$(call build-han,${SANS},.${CN},.SUBSET)

clean::
	rm -f $(addsuffix .afm,$(basename $(notdir ${OTF})))
	rm -f han-sans.git

VPATH+=	$(dir ${OTF})
include font-common-han.mk
