usage:
	@echo usage: ${MAKE} "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

# override C (experimental)
FAM=	M G
CN=	jp
SERIF=	NotoSerifCJK
SANS=	NotoSansCJK
M=	${SERIF}${CN}
G=	${SANS}${CN}
#EMBED=	*

CTTC?=	perl files/cttc.pl

all::	fonts-noto-cjk.pkg

/usr/share/fonts/opentype/noto/${SERIF}-Regular.ttc:	fonts-noto-cjk.pkg
/usr/share/fonts/opentype/noto/${SERIF}-Bold.ttc:	fonts-noto-cjk.pkg
/usr/share/fonts/opentype/noto/${SANS}-Regular.ttc:	fonts-noto-cjk.pkg
/usr/share/fonts/opentype/noto/${SANS}-Bold.ttc:	fonts-noto-cjk.pkg

VPATH+=	/usr/share/fonts/opentype/noto

OTF=	${SERIF}${CN}-Regular.otf \
	${SERIF}${CN}-Bold.otf \
	${SANS}${CN}-Regular.otf \
	${SANS}${CN}-Bold.otf

%${CN}-Regular.otf:	%-Regular.ttc
	bash -lc '$(CTTC) $< 0' >$@

%${CN}-Bold.otf:	%-Bold.ttc
	bash -lc '$(CTTC) $< 0' >$@

clean::
	rm -f ${OTF}
	rm -f $(addsuffix .afm,${OTF})

include font-common.mk
