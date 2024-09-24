usage:
	@echo usage: make "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

# App-grops-prepro script name
prepro?=	pre-grops

all::	${prepro}.plenv

install::	${GROFF_FONT}/devpdf/DESC ${prepro}.plenv
	(sed -E -e /^prepro/d $<; echo prepro $(word 2, $^)) > /tmp/DESC
	cmp -s /tmp/DESC $< || sudo install -b -m644 /tmp/DESC $<
	rm -f /tmp/DESC

install::	${prepro}.plenv
	sudo install -m755 $< ${LOCAL_BIN}

${prepro}.plenv:	App-grops-prepro.cpanm
	echo "#!/bin/sh\n\
	GROFF_USER=\$${GROFF_USER:-\$${USER:-${USER}}}\n\
	HOME=\$$(getent passwd \$$GROFF_USER | cut -d: -f6)\n\
	export PLENV_ROOT=\"\$$HOME/.plenv\"\n\
	exec \"\$$PLENV_ROOT/libexec/plenv\" exec ${prepro} \"\$$@\"" >$@

clean::
	rm -f ${prepro}.plenv
