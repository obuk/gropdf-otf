usage:
	@echo usage: ${MAKE} "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

han-sans.git?=	https://github.com/adobe-fonts/source-han-sans
han-sans.dir?=	source-han-sans

all::	han-sans.git

# override C (experimental)
FAM?=	M
CN?=	JP
SANS?=	SourceHanSans
M?=	${SANS}${CN}

OTF?=	${han-sans.dir}/Regular/${SANS}${CN}-Regular.otf \
	${han-sans.dir}/Bold/${SANS}${CN}-Bold.otf

all::	${OTF}

${OTF}:	han-sans.git afdko.pip
	$(call build-han,${SANS},.${CN},.SUBSET)

VPATH+=	$(dir ${OTF})

include font-common-han.mk
