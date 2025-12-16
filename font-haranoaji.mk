usage:
	@echo usage: ${MAKE} "[install|all|clean]"

include Mk/*.mk

HaranoAjiFonts.git?=	https://github.com/trueroad/HaranoAjiFonts
HaranoAjiFonts.dir?=	HaranoAjiFonts

FAM?=	M G
M?=	HaranoAjiMincho
G?=	HaranoAjiGothic
EMBED?=
FOUNDRY?=

R?=	Regular
B?=	Bold

OTF=	$(addprefix ${HaranoAjiFonts.dir}/,$(addsuffix .otf,\
		$(foreach fam,${FAM},$($(fam))-$R $($(fam))-$B)))

all::	${OTF}

${OTF}:	HaranoAjiFonts.git

clean::
	rm -f $(patsubst %.otf, %.afm, $(notdir ${OTF}))
	rm -f HaranoAjiFonts.git

VPATH+=	${HaranoAjiFonts.dir}
include font-common.mk
