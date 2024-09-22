usage:
	@echo usage: ${MAKE} "[install|all|clean]"

.SUFFIXES:	.stamp
include Mk/*.mk

HaranoAjiFonts.git?=	https://github.com/trueroad/HaranoAjiFonts
HaranoAjiFonts.dir?=	/vagrant/HaranoAjiFonts

all::	HaranoAjiFonts.git

FAM=	M G
M=	HaranoAjiMincho
G=	HaranoAjiGothic

VPATH+=	${HaranoAjiFonts.dir}
include font-common.mk
