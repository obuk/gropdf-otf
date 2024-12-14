usage:
	@echo usage: ${MAKE} "[install|all|clean]"

include Mk/*.mk

# override C (experimental)
FAM?=	M G
CN?=	jp
jp=	0
M?=	NotoSerifCJK${CN}
G?=	NotoSansCJK${CN}
EMBED=	*

R?=	Regular
B?=	Bold

CTTC?=	perl files/cttc.pl

D=	/usr/share/fonts/opentype/noto
TTC=	$(foreach font,$(foreach fam,${FAM},$(patsubst %${CN},%,$($(fam)))),\
		$D/${font}-$R.ttc $D/${font}-$B.ttc)

${TTC}:	fonts-noto-cjk.pkg

%${CN}-$R.otf:	$D/%-$R.ttc
	bash -lc '$(CTTC) $< $(${CN})' >$@

%${CN}-$B.otf:	$D/%-$B.ttc
	bash -lc '$(CTTC) $< $(${CN})' >$@

FONTNAMES=	$(foreach fam,${FAM},$($(fam))-$R $($(fam))-$B)
OTF=	$(addsuffix .otf,${FONTNAMES})
AFM=	$(addsuffix .afm,${FONTNAMES})

clean::
	rm -f ${OTF}
	rm -f ${AFM}
	sudo apt-get remove -y fonts-noto-cjk
	rm -f fonts-noto-cjk.pkg

include font-common.mk
