#!/usr/bin/env perl
use strict;
use warnings;
use feature "say";
use Getopt::Long qw(:config bundling);

GetOptions('y=s' => \ my $FOUNDRY) && @ARGV or
  die <<END;
usage: $0 [-y foundry] download-file files
download-file is usually site-font/devpdf/download,
files are the files to be merged into the download-file.
END

$FOUNDRY //= '';

my $download_file = shift @ARGV;
my %download;
while (<>) {
  chop;
  my (undef, $font, $filename) = split "\t";
  $download{"${FOUNDRY}\t$font"} = $filename;
}
my %seen;
if (open DOWNLOAD, $download_file) {
  while (<DOWNLOAD>) {
    chop;
    if (/^[^\x23]/) {
      my ($foundry, $font, $filename) = split "\t";
      if ($font && $filename) {
        $seen{my $ff = "$foundry\t$font"}++;
        $_ = join "\t", $foundry, $font, $download{$ff} // $filename;
      }
    }
    say;
  }
}
for (sort grep !$seen{$_}, keys %download) {
  say join "\t", $_, $download{$_};
}
