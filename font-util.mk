
otftodit:	files/otftodit.pl plenv Encode.cpanm Getopt-Long.cpanm \
		fonttools.pip plenv
ifdef GROFF_FONT
	sed s,/usr/local/share/groff/current/font,${GROFF_FONT}, $< >/tmp/$@
	install-pl /tmp/$@ $@
	rm -f /tmp/$@
else
	install-pl $< $@
endif

filter-font:	files/filter-font.pl JIS0208.TXT joyo-kanji-code-u.csv \
		Unicode-Normalize.cpanm Encode.cpanm Getopt-Long.cpanm plenv
	install-pl $< $@

JIS0208.TXT:
	[ -f $@ ] || curl -O https://unicode.org/Public/MAPPINGS/OBSOLETE/EASTASIA/JIS/$@

joyo-kanji-code-u.csv:
	[ -f $@ ] || curl -O https://x0213.org/joyo-kanji-code/$@

cttc:	files/cttc.pl plenv
	install-pl $< $@

mji:	mji.pl Spreadsheet-XLSX.cpanm plenv
	install-pl $< $@

tx:	afdko.pip
