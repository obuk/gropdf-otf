usage:
	@echo usage: ${MAKE} "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

han-code-jp.git?=	https://github.com/adobe-fonts/source-han-code-jp
han-code-jp.dir?=	source-han-code-jp

all::	han-code-jp.git

# override C (experimental)
FAM?=	Code
STY?=	R I B BI
CN?=	JP
CODE?=	SourceHanCode
Code?=	${CODE}${CN}

OTF?=	${han-code-jp.dir}/Regular/${Code}-Regular.otf \
	${han-code-jp.dir}/Bold/${Code}-Bold.otf

all::	${OTF}

${OTF}:	han-code-jp.git afdko.pip
	$(call build-han,${CODE},,,_fs)

VPATH+=	$(dir ${OTF})

include font-common-han.mk
