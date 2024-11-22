
include Mk/*.mk

VPATH+=		${GROFF_TMAC}
VPATH+=		files

all::	tmp/pdf.tmac tmp/ps.tmac

FILES?=	tmp/man.local tmp/mdoc.local tmp/pdf.tmac	\
		pdf.local tmp/ps.tmac ps.local
ifeq "${GROFF_VERSION}" "1.23.0"
FILES+=	tmp/an.tmac
endif

install:: ${FILES}
	sudo install -b -m644 $^ /etc/groff
	cd /etc/groff && \
	for f in $(notdir $^); do \
	  if [ -f $$f~ ]; then \
	    cmp -s $$f~ $$f && sudo mv $$f~ $$f; \
	  fi; \
	done

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
	cd /etc/groff && \
	if [ ! -f $(notdir $@).dist ]; then \
		[ -f $(notdir $@) ] && sudo mv $(notdir $@) $(notdir $@).dist; \
	fi
	mkdir -p tmp
	[ -f /etc/groff/$(notdir $@).dist ]
	cat /etc/groff/$(notdir $@).dist $< >$@

tmp/an.tmac:	an.tmac
	mkdir -p tmp
	sed -E -e '/^[.] *it 1 an-input-trap/s/it /itc /' $< >$@
