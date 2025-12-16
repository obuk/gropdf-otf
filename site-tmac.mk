
include Mk/*.mk

VPATH+=		${GROFF_TMAC}
VPATH+=		files

all::	tmp/pdf.tmac tmp/ps.tmac

FILES?=	tmp/man.local tmp/mdoc.local \
		pdf.local tmp/ps.tmac tmp/ps.local

ifeq "${GROFF_VERSION}" "1.23.0"
FILES+=	tmp/an.tmac
endif

install:: ${FILES}
	case "${SITE_TMAC}" in \
	${HOME}|${HOME}/*) \
		mkdir -p ${SITE_TMAC}; \
		install -m644 $^ ${SITE_TMAC}; \
		;; \
	*) \
		sudo mkdir -p ${SITE_TMAC}; \
		sudo install -m644 $^ ${SITE_TMAC}; \
		;; \
	esac

clean::
	rm -rf tmp

tmp/pdf.tmac:	pdf.tmac pdf.tmac.patch
	mkdir -p tmp
	cp $< tmp
	sed -E -e '/^[.]\\" Local Variables:/i\
.\\" Load local modifications.\
.do mso $(basename $(notdir $<)).local\
.' $< >$@
	patch -d tmp <$(word 2,$^)

tmp/ps.tmac:	ps.tmac
	mkdir -p tmp
	sed -E -e '/^[.]\\" (Local Variables:|.*? no blank lines creep)/i\
.\\" Load local modifications.\
.do mso $(basename $(notdir $<)).local\
.' $< >$@

tmp/%.local:	%.local
	cd ${SITE_TMAC} && \
	if [ ! -f $(notdir $@).dist ]; then \
		case "${SITE_TMAC}" in \
		${HOME}|${HOME}/*) \
			[ -f $(notdir $@) ] || touch $(notdir $@); \
			mv $(notdir $@) $(notdir $@).dist; \
			;; \
		*) \
			[ -f $(notdir $@) ] || sudo touch $(notdir $@); \
			sudo mv $(notdir $@) $(notdir $@).dist; \
			;; \
		esac; \
	fi
	mkdir -p tmp
	cat ${SITE_TMAC}/$(notdir $@).dist $< >$@

tmp/an.tmac:	an.tmac
	mkdir -p tmp
	sed -E -e '/^[.] *it 1 an-input-trap/s/it /itc /' $< >$@
