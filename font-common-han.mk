
build-han=\
	cd `dirname $@`; \
	for d in .. ../..; do \
	  if [ -f $$d/COMMANDS.txt -o -f $$d/commands.sh ]; then \
	    top=$$d; break; \
	  fi; \
	done; \
	makeotf -f cidfont$4.ps$2 \
		-omitMacNames \
		-ff features$2 \
		-fi cidfontinfo$2 \
		-mf $$top/FontMenuNameDB$3 \
		-r -nS -cs 1 \
		-ch $$top/Uni$1${CN}-UTF32-H \
		-ci $$top/$1_${CN}_sequences.txt; \
	tx -cff +S -no_futile cidfont$4.ps$2 CFF$2; \
	sfntedit -a CFF=CFF$2 `basename $@`

include font-common.mk
