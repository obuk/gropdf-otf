#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Carp;

#use Encode;
use File::Basename;

use lib "./groff/src/utils/afmtodit";
require "afmtodit.tables";

my $prog = basename $0, ".pl";

my %text_enc;

if (1) {
    my $csv = "$ENV{HOME}/share/groff/current/font/devps/text.enc";
    open my ($fd), $csv or die "$prog: can't open $csv";
    while (<$fd>) {
	s/[\r\n]+$//;
	next if /^#/;
	my ($name, $enc) = split /\s+/;
	$text_enc{$name} = $enc;
    }
}

my %text_cid;

if (1) {
    my $csv = "adobe-type-tools/Adobe-Japan1/Adobe-Japan1-7_ordering.txt";
    open my ($fd), $csv or die "$prog: can't open $csv";
    while (<$fd>) {
	s/[\r\n]+$//;
	next if /^#/;
	my ($cid, $major, $minor, $name) = split "\t";
	#say join "\t", $cid, $major, $minor, $name;
	if (defined $text_enc{$name}) {
	    if (lc($major) eq 'proportional' && lc($minor) eq 'roman') {
		$text_cid{$name} = $cid;
	    }
	}
    }
}


if ($prog eq "diff-aj1") {
    print "# enc order\n";
    printf "%20s %5s %5s\n", "name", "enc", "cid";
    for my $name (sort { $text_enc{$a} <=> $text_enc{$b} } keys %text_enc) {
	printf "%20s %5s %5s\n", $name,
	    $text_enc{$name} // '-',
	    $text_cid{$name} // '-';
    }
    print "# cid order\n";
    printf "%20s %5s %5s\n", "name", "enc", "cid";
    for my $name (sort { $text_cid{$a} <=> $text_cid{$b} } keys %text_cid) {
	printf "%20s %5s %5s\n", $name,
	    $text_enc{$name} // '-',
	    $text_cid{$name} // '-';
    }
    exit 0;
}

die "usage: make-aj1 or diff-aj1"
    unless $prog eq "make-aj1";

say <<'END';
#
# This is the font encoding used by gropdf-otf to encode the standard
# PS text fonts (excluding special fonts and with cid less than 256).
#
# When using adobe-japan1, try using \N'cid' to represent glyphs that
# have cids (but no unicode).
#
# Checking the cids of the glyphs in text.enc in Adobe-Japan1-7_
# ordering.txt, most Western glyphs have cid values of 255 or less
# (Euro, ff, ffi, and ffl have cid values ​​of 256 or more; see below
# for details).
#
#   text.enc  aj1.enc
#   Euro   9    9354
#   ff   139    9358
#   ffi  142    9359
#   ffl  143    9360
#
# \N'cid' prevents the use of glyphs between 230 and 255. 
# think later.
#
END

my $i = 0;
forloop: for my $name (sort { $text_cid{$a} <=> $text_cid{$b} } keys %text_cid) {
    my $cid = $text_cid{$name};
    while ($i < $cid) {
	last forloop if $i >= 256;
	printf "cid%05d %d\n", $i, $i;
	$i++;
    }
    say join ' ', $name, $cid;
    $i++;
}
exit 0;

# Local Variables:
# fill-column: 72
# tab-width: 8
# indent-tabs-mode: t
# mode: CPerl
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-close-paren-offset: -4
# cperl-indent-parens-as-block: t
# End:
# vim: set cindent noexpandtab shiftwidth=2 softtabstop=2 textwidth=72:
