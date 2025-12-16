plenv:	plenv.global plenv.install-cpanm plenv.install-pl

%.cpanm: plenv.install-cpanm
	@[ -f $@ ] || (m=$(shell echo $* |sed s/-/::/g); bash -l -c "cpanm $(or $($*), $$m)")
	@[ -f $@ ] || touch $@

plenv.git?=		https://github.com/tokuhirom/plenv
plenv.dir?=		${HOME}/.plenv

Perl-Build.git?=	https://github.com/tokuhirom/Perl-Build
Perl-Build.dir?=	${HOME}/.plenv/plugins/perl-build

Perl-Build.git:	plenv.git

plenv.repo:	plenv.git Perl-Build.git

plenv.profile?=	/tmp/dot.profile

plenv.profile:	plenv.repo
	@if ! bash -lc plenv >/dev/null 2>/dev/null; then \
	  >${$@}; \
	  if [ -z "`bash -lc 'printenv PLENV_ROOT'`" ]; then \
	    echo 'export PLENV_ROOT="${plenv.dir}"' | \
		  sed 's|${HOME}|$$HOME|' >> ${$@}; \
	  fi; \
	  for d in bin; do \
	    if ! bash -lc 'printenv PATH' | tr : '\n' | \
		  grep -qF "${plenv.dir}/$$d"; then \
	      echo export PATH='"$$PLENV_ROOT/'$$d:'$$PATH"' >> ${$@}; \
	    fi; \
	  done; \
	  echo 'eval "$$(plenv init -)"' >> ${$@}; \
	  if [ -s ${$@} ]; then \
	    (printf "\n# plenv\n"; cat ${$@}) >>${HOME}/.profile; \
	  fi; \
	  rm -f ${$@}; \
	fi

plenv.install-perl:	plenv.profile
	@if ! bash -lc 'plenv versions' |grep -qF "${PERL_VERSION}"; then \
	  bash -lc 'plenv install ${PERL_VERSION}'; \
	fi

plenv.global:	plenv.install-perl
	@if ! bash -lc 'plenv global' |grep -qF "${PERL_VERSION}"; then \
	  bash -lc 'plenv global ${PERL_VERSION}'; \
	fi

plenv.install-cpanm:	plenv.global
	@if [ ! -f ${plenv.dir}/shims/cpanm ]; then \
	  bash -lc 'plenv install-cpanm'; \
	fi

plenv.install-pl:	files/install-pl.sh
	mkdir -p ${HOME}/bin
	install -m755 $< ${HOME}/bin/$(notdir $(basename $<))
