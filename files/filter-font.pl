#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use utf8;

use Getopt::Long qw(:config bundling);
use Encode;
use Unicode::Normalize;
use Unicode::UCD qw/charblocks/;

use Data::Dumper qw/Dumper/;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;

GetOptions("1|jis1" => \ my $jis1,
	   "2|jis2" => \ my $jis2,
	   "0|b|base" => \ my $base,
	   "j|joyo" => \ my $joyo,
	   "s|supp" => \ my $supp,
	   "k|kern" => \ my $kern,
	   "n|name=s" => \ my $name,
	   "p1|path_jis0208=s" => \ my $path_jis0208,
	   "p2|path_joyo=s" => \ my $path_joyo,
	   "d|debug" => \ my $debug,
	   "v|verbose" => \ my $verbose)
    or usage();
usage() unless $jis1 || $jis2 || $joyo || $base;

sub usage {
    die("usage: $0 [-12jbsKUdv][-n name]\n",
	"[-p1 path/to/JIS0208.txt][-p2 path/to/joyo-kanji-code-u.csv]\n",
	"groff_font\n");
}

# http://unicode.org/Public/MAPPINGS/OBSOLETE/EASTASIA/JIS/JIS0208.TXT
$path_jis0208 //= "JIS0208.TXT";

# https://x0213.org/joyo-kanji-code/joyo-kanji-code-u.csv
$path_joyo //= "joyo-kanji-code-u.csv";

my %pass;

if ($jis1 || $jis2) {
    if (open my $fd, $path_jis0208) {
	while (<$fd>) {
	    next if /^#/;
	    next unless my $unicode = (split "\t")[2];
	    if ($unicode =~ /0x([\dA-F]{4})/) {
		my $hex = $1;
		my $u8 = pack "U", hex($hex);
		my ($euc) = unpack "n", encode "euc-jp", $u8;
		if (defined $euc) {
		    my $jis = $euc & 0x7f7f;
		    my $jc = $jis <= 0x4fff ? 1: 2;
		    if ($jis1 && $jc == 1 || $jis2 && $jc == 2) {
			$pass{"u$hex"} = $jc;
			my $hex2 = join '_', map sprintf("%04X", $_),
			    unpack "U*", NFD($u8);
			if ($hex ne $hex2) {
			    $pass{"u$hex2"} = $jc;
			}
		    }
		}
	    }
	}
    } else {
	warn "can't open $path_jis0208\n";
	usage();
    }
}

if ($joyo) {
    if (open my $fd, $path_joyo) {
	while (<$fd>) {
	    next if /^#/;
	    next unless my $u = (split /,/)[5];
	    if ($u =~ /^U\+([\dA-F]+)/) {
		my $hex = $1;
		$pass{"u$hex"} = 3;
	    }
	}
    } else {
	warn "can't open $path_joyo\n";
	usage();
    }
}

my $stg = 1;
my @stg1;
my @stg2;
my @stg3;
my @chunk;
my @last_r;
my %kern;
while (<>) {
    chomp;
    s/^ +//;
    if ($stg == 1) {
	push @stg1, $_;
	s/^#.*//;
	next if $_ eq '';
	my ($key, $val) = split ' ', $_, 2;
	if ($name && $key eq 'name') {
	    pop @stg1;
	    push @stg1, "name $name";
	}
	$stg = 2, next if lc($_) eq 'kernpairs';
	$stg = 3, next if lc($_) eq 'charset';

    } elsif ($stg == 2) {
	push @stg2, $_;
	next if $_ eq '';
	$stg = 3, next if lc($_) eq 'charset';

    } elsif ($stg == 3) {
	if (@stg1) {
	    my $stg2 = pop @stg1;
	    unshift @stg2, $stg2;
	    say for @stg1;
	    @stg1 = ();
	}
	if (@stg2) {
	    my $stg3 = pop @stg2;
	    unshift @stg3, $stg3;
	    if ($kern) {
		say for @stg2;
		if (!$supp) {
		    for (@stg2) {
			my ($g1, $g2, $n) = split /\s+/;
			next unless defined $n;
			$kern{$g1} = 1;
			$kern{$g2} = 1;
		    }
		}
	    }
	    @stg2 = ();
	    say for @stg3;
	    @stg3 = ();
	}
	next unless my @r = split "\t";
	unless ($r[1] eq '"') {
	    putchunk(@chunk);
	    @chunk = ();
	}
	push @chunk, { text => $_ };
	if (@chunk == 1 && $r[4] <= 255 ||
	    @chunk >= 2 && $last_r[4] <= 255 ||
	    $r[0] !~ /^u[0-9A-F]{4}/) {
	    $chunk[0]->{pass} = 1 if $base;
	} else {
	    $chunk[0]->{pass} = 1 if $pass{$r[0]} || $kern{$r[0]};
	}
	@last_r = @r if @chunk == 1;
    }
}

putchunk(@chunk);

sub putchunk {
    for (@_) {
	my $chunk;
	if ($_[0]->{pass} && !$supp ||
	    !$_[0]->{pass} && $supp) {
	    say $_->{text};
	} elsif ($debug) {
	    say '# ' . $_->{text};
	}
    }
}


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
# vim: set cindent noexpandtab shiftwidth=4 softtabstop=4 textwidth=72:
