#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use Spreadsheet::XLSX;
use Encode;
use utf8;

my $excel = Spreadsheet::XLSX->new($ARGV[0]);
foreach my $sheet (@{$excel->{Worksheet}}) {
  # printf("Sheet: %s\n", $sheet->{Name});
  $sheet->{MaxRow} ||= $sheet->{MinRow};
  foreach my $row ($sheet->{MinRow} + 1 .. $sheet->{MaxRow}) {
    $sheet->{MaxCol} ||= $sheet->{MinCol};
    my ($memo, $name, $ucs);
    ($memo) = map { defined && decode("utf8", $_->{Val}) } $sheet->{Cells}[$row][1];
    next if $memo =~ /実装なし/;
    ($name) = map { defined && $_->{Val} } $sheet->{Cells}[$row][2];
    for (5, 4, 3) {
      ($ucs) = map { defined && $_->{Val} } $sheet->{Cells}[$row][$_];
      last if $ucs;
    }
    next unless $name && $ucs;
    $ucs =~ s/^U\+//;
    say join ';', lc($name), $ucs;
  }
}
