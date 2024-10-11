#!/home/vagrant/.plenv/shims/perl
# -*- Perl -*-

use warnings;
use strict;

use feature 'say';
use File::Basename;
use Getopt::Long qw(:config bundling);
#use File::Temp qw/tempfile/;
use Font::TTF::Font;
use Font::TTF::Ttc;

use Data::Dumper qw/Dumper/;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;

my $prog = basename $0;

usage(1) unless GetOptions(
    'v|verbose' => \ my $verbose,
);

my ($fontfile, $index) = @ARGV;
usage(1) unless $fontfile;

sub usage {
    my ($err) = @_;
    warn "usage: $prog [-v] fontfile.ttc [index]";
    exit $err;
}

my $ttc = Font::TTF::Ttc->open($fontfile);
my $otf;
my $list;
if ($ttc) {
    if (defined $index) {
        $otf = $ttc->{directs}[$index];
    } else {
        $list = 1;
    }
} elsif (-f $fontfile) {
    $otf = Font::TTF::Font->open($fontfile);
}
usage(1) unless $otf || $list;

if ($list) {
    my @directs = @{$ttc->{directs}};
    for my $i (0 .. $#{$ttc->{directs}}) {
        my $otf = $ttc->{directs}[$i];
        my $psname     = get_name($otf, 6);
        my $notice     = get_name($otf, 0);
        my $version    = get_name($otf, 5);
        my $fullname   = get_name($otf, 4);
        my $familyname = get_name($otf, 1);
        say "$i: /$psname ($fullname)";
    }
    exit 0;
}

unless ($otf) {
    warn "$prog: can't open $fontfile";
    usage(1);
}

my $can_output = !-t STDOUT;
my $align;

my @table = map { $_->[0] } sort { $a->[1] <=> $b->[1] } map [ $_, $otf->{$_}{' OFFSET'} ],
    grep !/^ /, keys %$otf;

my $version;
if (exists $otf->{'CFF '}) {
    $version = 0x4f54544f;
} elsif (exists $otf->{'loca'}) {
    $version = 0x00010000;
} else {
    die "$prog: unknown fontfile";
}

my $numTables = @table;
my $entrySelector = int(log($numTables)/log(2));
my $searchRange = 2 ** $entrySelector * 16;
my $rangeShift = $numTables * 16 - $searchRange;

if ($verbose) {
    my $format = join "\n", "version 0x%08x", "numTables 0x%04x",
        "searchRange 0x%04x", "entrySelector 0x%04x", "rangeShift 0x%04x";
    printf STDERR $format."\n", $version, $numTables,
        $searchRange, $entrySelector, $rangeShift;
}

my $otf_header = pack "N1n4", $version, $numTables, $searchRange,
    $entrySelector, $rangeShift;
print $otf_header if $can_output;
my $pos1 = length $otf_header;
my $pos2 = $pos1 + (4 + 4 * 3) * @table;
my $pos2_start = $pos2;

# pass 1
if ($verbose) {
    printf STDERR "%-4s %10s %10s %10s\n", qw/tag checksum offset length/;
}
for (@table) {
    my $padding = (4 - ($pos2 & 3)) & 3;
    $pos2 += $padding;

    #my $infile = $otf->{$_}{' INFILE'};
    #my $offset = $otf->{$_}{' OFFSET'};
    my $length = $otf->{$_}{' LENGTH'};
    my $csum   = $otf->{$_}{' CSUM'};

    if ($verbose) {
        printf STDERR "%-4s 0x%08x 0x%08x 0x%08x\n", $_, $csum, $pos2, $length;
    }
    my $header = $_ . pack "N3", $csum, $pos2, $length;
    if ($can_output) {
        print $header;
    }
    $pos1 += length $header;
    $pos2 += $length;
}

unless ($pos1 == $pos2_start) {
    die "$prog: unexpected pass2 start address";
}

$pos2 = $pos2_start;
# pass 2
for (@table) {
    my $padding = (4 - ($pos2 & 3)) & 3;
    if ($can_output) {
        print chr(0) x $padding;
    }
    $pos2 += $padding;

    my $infile = $otf->{$_}{' INFILE'};
    my $offset = $otf->{$_}{' OFFSET'};
    my $length = $otf->{$_}{' LENGTH'};
    #my $csum   = $otf->{$_}{' CSUM'};

    if ($can_output) {
        $infile->seek($offset, 0);
        $infile->read(my ($buffer), $length);
        print $buffer;
    }
    $pos2 += $length;
}

exit 0;


sub get_name {
    my ($otf, $number, $platform_id, $encoding_id, $language_id) = @_;
    $platform_id //= 3;
    $encoding_id //= 1;
    $language_id //= 0x409;
    $otf->{name}->read;
    $otf->{name}{strings}[$number][$platform_id][$encoding_id]{$language_id};
}


sub checksum {
    my ($buffer) = @_;
    my @byte = unpack "C*", $buffer;
    push @byte, (0) x (4 - @byte & 3);
    my $checksum = 0;
    while (my @b = splice @byte, 0, 4) {
        $checksum += $b[3];
        $checksum += $b[2] <<  8;
        $checksum += $b[1] << 16;
        $checksum += $b[0] << 24;
    }
    $checksum &= 0xffff_ffff;
}

# Local Variables:
# fill-column: 72
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-close-paren-offset: -4
# mode: CPerl
# End:
# vim: set cindent noexpandtab shiftwidth=2 softtabstop=2 textwidth=72:
