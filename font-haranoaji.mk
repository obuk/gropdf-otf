usage:
	@echo usage: ${MAKE} "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

HaranoAjiFonts.git?=	https://github.com/trueroad/HaranoAjiFonts
HaranoAjiFonts.dir?=	HaranoAjiFonts

FAM=	M G
M=	HaranoAjiMincho
G=	HaranoAjiGothic

R=	Regular
B=	Bold

OTF=	$(addprefix ${HaranoAjiFonts.dir}/,$(addsuffix .otf,$M-$R $M-$B $G-$R $G-$B))

all::	${OTF}

${OTF}:	HaranoAjiFonts.git

clean::
	rm -f $(addsuffix .afm,$(basename $(notdir ${OTF})))
	rm -f HaranoAjiFonts.git

VPATH+=	${HaranoAjiFonts.dir}
include font-common.mk
