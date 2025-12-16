usage:
	@echo usage: make "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

all::	needrestart-auto

install::	install-groff
install-groff:	needrestart-auto
	${MAKE} -f groff.mk install
	${MAKE} -f site-tmac.mk install

install::	install-gropdf
install-gropdf:	needrestart-auto install-groff
	${MAKE} -f gropdf.mk install

install:: install-fonts
install-fonts:	install-groff install-gropdf
	${MAKE} -f font-haranoaji.mk clean install
	${MAKE} -f font-haranoaji-code.mk clean install
	#${MAKE} -f font-haranoaji.mk FOUNDRY=H FAM=G clean install
	#${MAKE} -f font-haranoaji.mk FOUNDRY=H FAM=M R=Medium B=Heavy clean install
	${MAKE} -f font-noto-cjk.mk FOUNDRY=N clean install
	${MAKE} -f font-noto-code-cjk.mk FOUNDRY=N clean install
	#${MAKE} -f font-ipamj.mk clean install

needrestart-auto:
	perl -e "eval for <>; exit 0 if \$$nrconf{restart} eq 'a'; exit 1" \
		/etc/needrestart/conf.d/*.conf || \
	echo "\$$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/50local.conf

clean::
	${MAKE} -f groff.mk clean
	${MAKE} -f site-tmac.mk clean
	${MAKE} -f gropdf.mk clean
	${MAKE} -f font-haranoaji.mk clean
	${MAKE} -f font-haranoaji-code.mk clean
	${MAKE} -f font-haranoaji.mk FOUNDRY=H FAM=G clean
	${MAKE} -f font-haranoaji.mk FOUNDRY=H FAM=M R=Medium B=Heavy clean
	${MAKE} -f font-noto-cjk.mk FOUNDRY=N clean
	${MAKE} -f font-noto-code-cjk.mk FOUNDRY=N clean
	${MAKE} -f font-ipamj.mk clean
	${MAKE} -f man-db.mk clean
	rm -f *.git
	rm -f *.pkg
	rm -f *.cpanm
	rm -f *.pip
	rm -f *.afm
	rm -f *.stamp
	rm -f *~

install::	all

# sample
#GROFF?=		env GROPDF_OPTIONS= ${GROFF_BIN}/groff $(GROFF_OPTIONS)
GROFF?=		env GROPDF_OPTIONS= GROFF_BIN_PATH=${GROFF_BIN} \
			${GROFF_BIN}/groff $(GROFF_OPTIONS)
GROFF+=		-Tpdf -dpaper=${PAPERSIZE} \
			$(patsubst %,-P%,${GROPDF_OPTIONS} ${GROPDF_DEBUG})

GROFF_OPTIONS?=
#GROFF_OPTIONS+=	-rmy:debug-font=1
#GROFF_OPTIONS+=	-rpp:debug=1
#GROFF_OPTIONS+=	-rpp:hemsp-width=12

GROPDF_OPTIONS?=
#GROPDF_OPTIONS+=	-e
#GROPDF_OPTIONS+=	--opt=5

GROPDF_DEBUG?=	-d --pdfver=1.4

SAMPLE?=	groff gropdf groff.7 groff_font groff_char groff_out


sample:	$(addsuffix .pdf, $(SAMPLE))

L?=	ja
%.pdf:	manpages-ja.pkg FORCE
	get_path () { \
	  if [ -f files/$* ]; \
	  then echo files/$*; \
	  else man -w $$([ -n "$L" ] && echo -L$L) $$1; \
	  fi \
	}; \
	cat_page () { \
	  path=$$(get_path $$1); \
	  case "$$path" in \
	  "")   echo ".ps +2\n.sp\nNo manual entry for $$1";; \
	  *.gz) echo \# $$path >&2; zcat $$path;; \
	  *)    echo \# $$path >&2; cat  $$path;; \
	  esac \
	}; \
	cat_page $* | ${GROFF} -Kutf8 -ktp $$([ -n "$L" ] && echo -m$L) \
		-mandoc - > $@ \
	&& cp $@ a.pdf

FORCE:

clean::
	rm -f *.pdf
