HOME?=		$(shell getent passwd ${USER} |cut -d: -f6)
PYTHON_VERSION?=	3.10.12

%.pip:	pyenv pip
	@[ -f $@ ] || bash -lc 'pip install $*'
	@[ -f $@ ] || touch $@

pip:	pyenv
	@[ -x `bash -lc 'pyenv which pip'` ]

pyenv:	pyenv.global

pyenv.dir?=	${HOME}/.pyenv

pyenv.repo:	git.pkg
	[ -d "${pyenv.dir}" ] || curl https://pyenv.run | bash

pyenv.profile?=	/tmp/dot.profile

pyenv.profile:	pyenv.repo
	@if ! bash -lc 'pyenv version' >/dev/null 2>/dev/null; then \
	  >${$@}; \
	  if [ -z "`bash -lc 'printenv PYENV_ROOT'`" ]; then \
	    echo 'export PYENV_ROOT="${pyenv.dir}"' | \
		  sed 's|${HOME}|$$HOME|' >> ${$@}; \
	  fi; \
	  for d in bin; do \
	    if ! bash -lc 'printenv PATH' | tr : '\n' | \
		  grep -qF "${pyenv.dir}/$$d"; then \
	      echo export PATH='"$$PYENV_ROOT/'$$d:'$$PATH"' >> ${$@}; \
	    fi; \
	  done; \
	  echo 'eval "$$(pyenv init -)"' >> ${$@}; \
	  if [ -s ${$@} ]; then \
	    (printf "\n# pyenv\n"; cat ${$@}) >>${HOME}/.profile; \
	  fi; \
	  rm -f ${$@}; \
	fi

PYTHON_DEPENDS?= git.pkg gcc.pkg make.pkg openssl.pkg libssl-dev.pkg	\
	zlib1g-dev.pkg libbz2-dev.pkg libreadline-dev.pkg		\
	libsqlite3-dev.pkg libffi-dev.pkg liblzma-dev.pkg		\
	python3-tk.pkg tk-dev.pkg

pyenv.install-python:	pyenv.profile ${PYTHON_DEPENDS}
	@if ! bash -lc 'pyenv versions' |grep -qF "${PYTHON_VERSION}"; then \
	  bash -lc 'pyenv install ${PYTHON_VERSION}'; \
	fi

pyenv.global:	pyenv.install-python
	@if ! bash -lc 'pyenv global' | grep -qF "${PYTHON_VERSION}"; then \
	  bash -lc 'pyenv global ${PYTHON_VERSION}'; \
	fi
