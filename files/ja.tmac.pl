#!/usr/bin/env perl

use strict;
use warnings;

use utf8;
use Encode;
use Getopt::Long qw(:config gnu_getopt);

my %ot_feature;
GetOptions(
    "w=i" => \ my $space_width,
    "F=s" => sub { my ($k, $v) = split '=', $_[1]; $v //= "*,*"; $ot_feature{$k} = $v },
    "I=s" => \ my @include_path,
    "L=s" => \ my $lang,
    "v" => \ my $verbose,
    "D" => \ my $debug,
);


$lang //= 'ja';

use Unicode::UCD qw/charinfo/;
use Font::TTF::Font;

use feature 'say';
use Test::More;
#use Data::Dumper qw/Dumper/;
#$Data::Dumper::Indent = 1;
#$Data::Dumper::Terse = 1;

my ($prog) = $0 =~ /[^\/](.*)/;
$prog ||= $0;
my $otffile = shift;
unless ($otffile) {
    warn "prog: no otffile\n";
    usage();
}

sub usage {
    die "usage: $prog [-w space-width] [-F opentype-feature][-I tmac_path ] otffile\n";
}

my $otf = Font::TTF::Font->open($otffile);
unless ($otf) {
    die "can't open $otffile\n";
}

my @gsub_index;
my @gpos_index;

while (my ($k, $v) = each %ot_feature) {
    next if $k =~ /liga|kern/;
    my $option = join ',', ((split /,/, $v // "*,*"), $k)[0..2];
    push @gsub_index, grep defined, ot_feature($otf, 'GSUB', $option);
    push @gpos_index, grep defined, ot_feature($otf, 'GPOS', $option);
}

my $gsub = gsub($otf, @gsub_index);
my $gpos = gpos($otf, @gpos_index);

$otf->{'CFF '}->read;
my $gid2cid = $otf->{'CFF '}->Charset->{code};

$otf->{'hmtx'}->read;
$otf->{'cmap'}->read;

use constant {
    PROHIBITS_BREAK_BEFORE => 0x080,
    PROHIBITS_BREAK_AFTER  => 0x100,
    IS_INTERWORD_SPACE     => 0x200,
    HAS_SPACE_AFTER        => 0x400,
    HAS_SPACE_BEFORE       => 0x800,
};

my %re = (
    'cl-03' => qr/Wave Dash|Hyphen|En Dash/i, # $charinfo->{category} =~ /Pd/
    'cl-04' => qr/Exclamation Mark|Question Mark/i,
    'cl-05' => qr/Middle Dot|colon/i,
    'cl-06' => qr/Full Stop/i,
    'cl-07' => qr/Comma/i,
    'cl-08' => qr/Em Dash|Two Dot Leader|Horizontal Ellipsis|Vertical Kana Repeat/i,
    'cl-09' => qr/Ditto Mark|Iteration Mark/i,
    'cl-10' => qr/Prolonged Sound Mark/i,
    'cl-11' => qr/(?:Hiragana|Katakana) Letter Small/i,
);

sub get_flags {
    my $flags = 0;

    my $uv = shift;
    local $_ = pack "U*", $uv;

    return undef unless my $charinfo = charinfo($uv);
    if ($charinfo->{category} =~ /P[si]/) {
	$flags |= PROHIBITS_BREAK_AFTER;
    }
    if ($charinfo->{category} =~ /P[efd]/) {
	$flags |= PROHIBITS_BREAK_BEFORE;
    }
    if ($charinfo->{name} =~ /$re{'cl-04'}|$re{'cl-05'}|$re{'cl-06'}
			     |$re{'cl-07'}|$re{'cl-08'}|$re{'cl-09'}
			     |$re{'cl-10'}|$re{'cl-11'}/x) {
	$flags |= PROHIBITS_BREAK_BEFORE;
    }
    if ($charinfo->{block} =~ /Hiragana|Katakana|CJK|Halfwidth and Fullwidth Forms/i) {
	$flags |= IS_INTERWORD_SPACE;
    }
    if ((!$flags || $charinfo->{name} =~ /xxxxx/) && $debug) {
	printf "U+%04X = 0x%03x\n", $uv, $flags;
	printf "U+%04X = %s\n", $uv, join ' ', explain $charinfo;
    }

    if (my $gid = $otf->{'cmap'}->find_ms->{val}{$uv}) {
	if (my $subst = find_gsub($gid)) {
	    $gid = $subst;
	}

	my %x;
	for ($otf->{'hmtx'}{'advance'}[$gid]) {
	    $x{advance} = $_ if defined;
	}

	if ($gpos) {
	    for my $k (keys %{$gpos->{$gid}}) {
		for ($gpos->{$gid}{$k}) {
		    $x{lc $k} = $_ if defined;
		}
	    }
	}

	if (defined $x{advance} && defined $x{xadvance} && !defined $x{xplacement}) {
	    if (near_eq($x{advance}, 1000) &&
		near_eq($x{xadvance}, -500)) {
		$flags |= HAS_SPACE_AFTER;
	    }
	} elsif (defined $x{advance} && defined $x{xadvance} && defined $x{xplacement}) {
	    if (near_eq($x{advance}, 1000) &&
		near_eq($x{xadvance}, -500) &&
		near_eq($x{xplacement}, -500)) {
		$flags |= HAS_SPACE_BEFORE;
	    } elsif (near_eq($x{advance}, 1000) &&
		     near_eq($x{xadvance}, -500) &&
		     near_eq($x{xplacement}, 0)) {
		$flags |= HAS_SPACE_AFTER;
	    } elsif (near_eq($x{advance}, 1000) &&
		     near_eq($x{xadvance}, -500) &&
		     near_eq($x{xplacement}, -250)) {
		$flags |= HAS_SPACE_AFTER | HAS_SPACE_BEFORE;
	    }
	}
    }
    $flags;
}


sub near_eq {
    my ($a, $b, $e) = @_;
    $e //= 0.03;
    my $d = $b - $a;
    my $eq = ($d / 1000) >= -$e && ($d / 1000) <= +$e;
    #printf STDERR "$a - $b = $d (%g) = %s\n", $d, $eq ? 'eq' : 'neq';
    $eq;
}


#my %gid_hint;

sub find_gsub {
    my ($gid, $hint) = @_;
    if ($gsub) {
	my $start = $gid;
	while (my $subst = $gsub->{$gid}) {
	    if ($subst == $start) {
		warn "gsub $start seems looping." if $debug;
		last;
	    }
	    $gid = $subst;
	}
	if ($gid != $start) {
	    #$gid_hint{$gid} = $hint if $hint;
	    return $gid;
	}
    }
    undef;
}


sub gsub {
    my $otf = shift;
    my $gsub;
    for my $index (grep defined, @_) {
	my $value = $otf->{GSUB}{LOOKUP}[$index];
	if ($value->{TYPE} == 1) {
	    for (@{$value->{SUB}}) {
		while (my ($gid, $i) = each %{$_->{COVERAGE}{val}}) {
		    $gsub->{$gid} = $_->{RULES}[$i][0]{ACTION}[0];
		}
	    }
	} elsif ($value->{TYPE} == 4) {
	    for (@{$value->{SUB}}) {
		while (my ($gid, $i) = each %{$_->{COVERAGE}{val}}) {
		    for (@{$_->{RULES}[$i]}) {
			$gsub->{join $;, @{$_->{ACTION}}} =
			    [ $gid + 0, @{$_->{MATCH}} ];
		    }
		}
	    }
	} else {
	    die "gsub: unknown \$value->{TYPE}: $value->{TYPE}";
	}
    }
    $gsub;
}


sub gpos {
    my $otf = shift;
    my $gpos;
    for my $index (grep defined, @_) {
	my $value = $otf->{GPOS}{LOOKUP}[$index];
	if ($value->{TYPE} == 1) {
	    # Lookup type 1 subtable: single adjustment positioning
	    for (@{$value->{SUB}}) {
		while (my ($gid, $i) = each %{$_->{COVERAGE}{val}}) {
		    $gpos->{$gid} = $_->{RULES}[$i][0]{ACTION}[0];
		}
	    }
	} elsif ($value->{TYPE} == 2) {
	    # Lookup type 2 subtable: pair adjustment positioning
	    for (@{$value->{SUB}}) {
		my @gid;
		while (my ($gid, $i) = each %{$_->{COVERAGE}{val}}) {
		    $gid[$i] = $gid;
		}
		my $MATCH_TYPE  = $_->{MATCH_TYPE};
		my $ACTION_TYPE = $_->{ACTION_TYPE};
		if ($MATCH_TYPE eq 'g' && $ACTION_TYPE eq 'p') {
		    # $_->{FORMAT} = 1: Pair adjustment positioning
		    # MATCH_TYPE = 'g': A glyph array
		    # ACTION_TYPE = 'p': Pair adjustment
		    for my $i (0 ..  $#{$_->{RULES}}) {
			my $gid = $gid[$i];
			for my $j (0 ..  $#{$_->{RULES}[$i]}) {
			    my $gid2 = $_->{RULES}[$i][$j]{MATCH}[0];
			    $gpos->{$gid, $gid2} = $_->{RULES}[$i][$j]{ACTION}[0];
			}
		    }
		} elsif ($MATCH_TYPE eq 'c' && $ACTION_TYPE eq 'p') {
		    # $_->{FORMAT} = 2: Pair adjustment positioning
		    # MATCH_TYPE = 'c': An array of class values
		    # ACTION_TYPE = 'p': Pair adjustment
		    for my $gid (@gid) {
			my $c = $_->{CLASS}{val}{$gid};
			next unless defined $c;
			while (my ($gid2, $c2) = each %{$_->{MATCH}[0]{val}}) {
			    next unless $c2;
			    $gpos->{$gid, $gid2} = $_->{RULES}[$c][$c2]{ACTION}[0];
			}
		    }
		} else {
		    die "gpos: unknown \$_->{FORMAT}: $_->{FORMAT} in TYPE 2";
		}
	    }
	}
	else {
	    die "gpos: unknown \$value->{TYPE}: $value->{TYPE} (index: $index)";
	}
    }
    $gpos;
}


sub ot_feature {
    my ($otf, $tag, $option) = @_;
    return undef unless $otf;
    return undef unless $option;

    my ($script, $lang, $wanted) = split /,\s*/, $option;
    return undef unless defined $script && defined $lang && defined $wanted;

    unless (ref $otf->{$tag} && $otf->{$tag}->read) {
	warn "$prog: can't read $tag table; ignored\n";
	return undef;
    }

    # filter /$script/,
    my %seen;
    my @script = grep !$seen{$_}++,
	grep $script eq '*' || /^$script\s*$/,
	keys %{$otf->{$tag}{SCRIPTS}};

    # filter /lang/, @script
    my @lang;
    my @features = map {
	my $languages = $otf->{$tag}{SCRIPTS}{$_};
	@lang = grep !$seen{$_}++, @{$languages->{LANG_TAGS}};
	@lang = 'DFLT' unless @lang;
	map @{$_->{FEATURES}},
	    map $languages->{$_} || $languages->{DEFAULT},
	    grep $lang eq '*' || /^$lang\s*$/i,
	    @lang;
    } @script;

    # filter  /wanted/, @features
    %seen = ();
    my @index = grep !$seen{$_}++,
	map @{ $otf->{$tag}{FEATURES}{$_}{LOOKUPS} },
	grep /$wanted/,
	@features;

    1 and printf STDERR "$tag: script => '%s', lang => '%s', features => '%s': %s\n",
	$script, $lang, $wanted, join ', ', @index
	if @index;

    @index;
}


my %cflags;

sub parse_lang_tmac {
    my $tmac = shift // "$lang.tmac" ;
    unless (@include_path) {
	push @include_path, grep defined,
	    $ENV{GROFF_TMAC_PATH},
	    map { "$_/site-tmac:$_/current/tmac" }
	    grep -d, "$ENV{HOME}/share/groff", "/usr/local/share/groff", "/usr/share/groff";
    }
    my $include_path = join ':', @include_path;
    open my $fd, "-|", qq[echo '.so $tmac' |soelim -I $include_path];
    local $_ = join '', <$fd>;
    close $fd;
    s/\\".*//gm;
    s/\\(#.*)?\n//gm;
    for (grep /^.\s*cflags/, split "\n") {
	if (s/^[.]\s*cflags\s+(\d+)\s+//) {
	    my $n = $1;
	    my @class;
	    my @char;
	    while (length > 0) {
		if (s/\\C["'](.*?)["']//) {
		    push @class, $1; # class
		} elsif (s/\\\[u(.*?)\]-\\\[u(.*?)\]//) {
		    push @char, map { sprintf "u%04X", $_ } hex($1) .. hex($2);
		} elsif (s/\\\[(u.*?)\]//) {
		    push @char, $1;
		} elsif (s/\\\[(.*?)[\]]// || s/\\\((..)// || s/(\S)//) {
		    #push @char, $1;
		    warn "# .cflags $n $& ignored\n";
		}
		s/\s*//;
	    }
	    $cflags{$n} = [ (map "\\C'$_'", @class), (map "\\[$_]", @char) ];
	}
    }
}


my $error = 0;

sub test_cflags {
    my $n = shift;
    for my $c (@{$cflags{$n}}) {
	say "# $c:";
 	if (my $p = run_pchar($c)) {
	    for (@{$p->{code_points}}) {
		my $hex = sprintf "%04X", $_;
    		if (defined (my $flags = get_flags($_))) {
		    my $ok = $p->{flags} & $flags;
		    $error++ unless $ok;
		    if ($verbose || !$ok) {
			say sprintf "u$hex 0x%03x, 0x%03x - %s",
			    $p->{flags}, $flags, $ok ? 'ok' : 'not ok';
		    }
		} else {
		    say "u$hex ignored" if $verbose;
		}
	    }
	}
   }
}


sub run_pchar {
    my $c = shift;
    open my $fd, "-|", qq[echo ".pchar $c" | groff -Tpdf -m$lang 2>&1];
    my %defined_at;
    my @code_points;
    my $flags;
    while (<$fd>) {
	if (s/defined at:\s*//) {
	    while (s/([^:]*):\s*"([^"]*)"(?:,\s+)?//) {
		$defined_at{$1} = $2;
	    }
	} elsif (s/^\s*contains code points:\s*//) {
	    for (split /\s+/) {
		my ($a, $b) = map { s/U\+//; hex; } split '-';
		push @code_points,  $a .. ($b // $a);
	    }
	} elsif (s/^\s*flags:\s*//) {
	    ($flags) = split /\s+/;
	}
    }
    { defined_at => \%defined_at, code_points => \@code_points, flags => $flags };
}

parse_lang_tmac;
test_cflags HAS_SPACE_AFTER;
test_cflags HAS_SPACE_BEFORE;
test_cflags PROHIBITS_BREAK_BEFORE;
test_cflags PROHIBITS_BREAK_AFTER;
test_cflags IS_INTERWORD_SPACE;

exit 1 if $error;
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
