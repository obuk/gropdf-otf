usage:
	@echo usage: make "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

all::	needrestart-auto
	${MAKE} -f groff.mk clean install
	${MAKE} -f site-tmac.mk clean install
	${MAKE} -f gropdf.mk clean install
	${MAKE} -f prepro.mk clean install
	${MAKE} -f font-haranoaji.mk clean install
	#${MAKE} -f font-han.mk clean install
	#${MAKE} -f font-han-code-jp.mk clean install
	#${MAKE} -f font-noto-cjk.mk clean install
	${MAKE} GROPDF_DEBUG= sample

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
	${MAKE} -f font-han.mk clean
	${MAKE} -f font-han-code-jp.mk clean
	${MAKE} -f font-noto-cjk.mk clean
	rm -f *.git
	rm -f *.pkg
	rm -f *.cpanm
	rm -f *.pip
	rm -f *.afm
	rm -f *.stamp
	rm -f *~

install::	all


# sample
GROFF?=		${GROFF_BIN}/groff -Tpdf -P-e -P-p${PAPERSIZE} -dpaper=${PAPERSIZE}
GROPDF_DEBUG?=	-P-d -P--pdfver=1.4

SAMPLE?=	groff gropdf groff.7 groff_font groff_char groff_out

sample:	$(addsuffix .pdf, $(SAMPLE))

%.pdf:	manpages-ja.pkg
	path=`man -w -Lja $(basename $@)`; \
	case $$path in *.gz) zcat $$path;; *) cat $$path;; esac | \
	${GROFF} ${GROPDF_DEBUG} -Kutf8 -ktp -mja -mandoc - > $@

clean::
	rm -f *.pdf
