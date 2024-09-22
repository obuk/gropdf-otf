usage:
	@echo usage: ${MAKE} "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

font-ttf.git?=	https://github.com:obuk/font-ttf.git
font-ttf.dir?=	/vagrant/font-ttf

all::	font-ttf.git IO-String.cpanm
	cd ${font-ttf.dir} && \
	bash -lc 'perl Makefile.PL && make manifest && make'

install::	all
	cd ${font-ttf.dir} && \
	bash -lc 'make install'

clean::
	-cd ${font-ttf.dir} && \
	bash -lc 'make clean'
