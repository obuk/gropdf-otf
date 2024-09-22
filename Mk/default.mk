HOME?=		$(shell getent passwd ${USER} |cut -d: -f6)
PERL_VERSION?=		5.34.0
PYTHON_VERSION?=	3.10.12

LOCAL_BIN?=	/usr/local/bin

Font-TTF?=		https://github.com/obuk/font-ttf.git
App-grops-prepro?=	https://github.com/obuk/App-grops-prepro.git

GROFF_PREFIX?=	/usr/local
GROFF_BIN?=	${GROFF_PREFIX}/bin
GROFF_SHARE?=	${GROFF_PREFIX}/share/groff
GROFF_TMAC?=	${GROFF_SHARE}/current/tmac
GROFF_FONT?=	${GROFF_SHARE}/current/font
SITE_TMAC?=	${GROFF_SHARE}/site-tmac
SITE_FONT?=	${GROFF_SHARE}/site-font
AFMTODIT?=	perl ${GROFF_BIN}/afmtodit
PAPERSIZE?=	a4
