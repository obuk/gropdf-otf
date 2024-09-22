usage:
	@echo usage: make "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

prepro?=	pre-grops.plenv

all::	${prepro}

install::	${GROFF_FONT}/devpdf/DESC ${prepro}
	(sed -E -e /^prepro/d -e /^papersize/d $<; \
	 echo prepro $(word 2, $^); \
	 echo papersize ${PAPERSIZE}; \
	) > /tmp/DESC
	cmp -s /tmp/DESC $< || sudo install -b -m644 /tmp/DESC $<
	rm -f /tmp/DESC

install::	${prepro}
	sudo install -m755 $< ${LOCAL_BIN}

${prepro}:	App-grops-prepro.cpanm
	echo "#!/bin/sh\n\
	GROFF_USER=\$${GROFF_USER:-\$${USER:-${USER}}}\n\
	HOME=\$$(getent passwd \$${GROFF_USER} | cut -d: -f6)\n\
	export PLENV_ROOT=\"\$${HOME}/.plenv\"\n\
	#export PERL5LIB=\"$(abspath $(dir $<))/$(basename $<)/lib\"\n\
	exec \"\$${PLENV_ROOT}/libexec/plenv\" exec pre-grops \"\$$@\"" >$@

clean::
	rm -f ${prepro}
