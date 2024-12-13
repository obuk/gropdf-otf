usage:
	@echo usage: make "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

all::	needrestart-auto
	${MAKE} -f groff.mk clean install
	${MAKE} -f site-tmac.mk clean install
	${MAKE} -f gropdf.mk clean install
	${MAKE} -f prepro.mk clean install
	#${MAKE} -f font-haranoaji.mk clean install
	${MAKE} -f font-haranoaji.mk FAM=G clean install
	${MAKE} -f font-haranoaji.mk FAM=M R=Medium B=Heavy clean install
	${MAKE} -f font-haranoaji-code.mk clean install

needrestart-auto:
	perl -e "eval for <>; exit 0 if \$$nrconf{restart} eq 'a'; exit 1" \
		/etc/needrestart/conf.d/*.conf || \
	echo "\$$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/50local.conf

clean::
	${MAKE} -f groff.mk clean
	${MAKE} -f site-tmac.mk clean
	${MAKE} -f gropdf.mk clean
	${MAKE} -f prepro.mk clean
	${MAKE} -f font-haranoaji.mk clean
	${MAKE} -f font-haranoaji-code.mk clean
	rm -f *.git
	rm -f *.pkg
	rm -f *.cpanm
	rm -f *.pip
	rm -f *.afm
	rm -f *.stamp
	rm -f *~

install::	all


# sample
GROFF?=		${GROFF_BIN}/groff
GROFF+=		-Tpdf -dpaper=${PAPERSIZE} \
		$(patsubst %,-P%,${GROPDF_EMBED} ${GROPDF_DEBUG}\
			$(if ${GROPDF_UCMAP},-u${GROPDF_UCMAP})\
			$(if ${PAPERSIZE},-p${PAPERSIZE}))\
		${PREPRO_DEBUG}
GROPDF_DEBUG?=	-d --pdfver=1.4
#GROPDF_EMBED?=	-e
GROPDF_UCMAP?=	AUTO
#PREPRO_DEBUG?=	-rpp:debug=1

SAMPLE?=	groff gropdf groff.7 groff_font groff_char groff_out

sample:	$(addsuffix .pdf, $(SAMPLE))

L?=	ja
%.pdf:	manpages-ja.pkg FORCE
	get_path () { \
	  if [ -f files/$* ]; \
	  then echo files/$*; \
	  else man -w `[ -n "$L" ] && echo -L$L` $$1; \
	  fi \
	}; \
	cat_page () { \
	  path=$$(get_path $$1); \
	  case "$$path" in \
	  "")   echo ".ps +2\n.sp\nNo manual entry for $$1";; \
	  *.gz) zcat $$path;; \
	  *)    cat  $$path;; \
	  esac \
	}; \
	cat_page $* | ${GROFF} -Kutf8 -ktp `[ -n "$L" ] && echo -m$L` \
		-mandoc - > $@

FORCE:

clean::
	rm -f *.pdf
