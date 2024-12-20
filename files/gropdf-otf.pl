#!@PERL@
#
#       gropdf          : PDF post processor for groff
#
# Copyright (C) 2011-2020 Free Software Foundation, Inc.
#      Written by Deri James <deri@chuzzlewit.myzen.co.uk>
#
# This file is part of groff.
#
# groff is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# groff is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
require 5.8.0;
use Getopt::Long qw(:config bundling);
use Encode qw(encode decode);
use POSIX qw(mktime);

our $VERSION = "2024.12.13";

use List::Util qw(min max sum uniq);
use File::Temp qw/tempfile/;
#use feature 'say';
use Data::Dumper qw/Dumper/;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
#use lib qw(/vagrant/font-ttf/lib);
use Font::TTF::Font;
my $reduce_TJ = 1;
my $reduce_d3 = 1;
my $subset_mp = 1;

use constant
{
    WIDTH               => 0,
    CHRCODE             => 1,
    PSNAME              => 2,
    MINOR               => 3,
    MAJOR               => 4,
    UNICODE             => 5,
    RST                 => 6,
    RSB                 => 7,

    CHR                 => 0,
    XPOS                => 1,
    CWID                => 2,
    HWID                => 3,
    NOMV                => 4,
    CHF                 => 5,

    MAGIC1              => 52845,
    MAGIC2              => 22719,
    C_DEF               => 4330,
    E_DEF               => 55665,
    LINE                => 0,
    CALLS               => 1,
    NEWNO               => 2,
    CHARCHAR            => 3,

    NUMBER              => 0,
    LENGTH              => 1,
    STR                 => 2,
    TYPE                => 3,

    SUBSET              => 1,
    USESPACE            => 2,
    COMPRESS            => 4,
    NOFILE              => 8,

};

my %StdEnc=(
            32 => 'space',
            33 => '!',
            34 => 'dq',
            35 => 'sh',
            36 => 'Do',
            37 => '%',
            38 => '&',
            39 => 'cq',
            40 => '(',
            41 => ')',
            42 => '*',
            43 => '+',
            44 => ',',
            45 => 'hy',
            46 => '.',
            47 => 'sl',
            48 => '0',
            49 => '1',
            50 => '2',
            51 => '3',
            52 => '4',
            53 => '5',
            54 => '6',
            55 => '7',
            56 => '8',
            57 => '9',
            58 => ':',
            59 => ';',
            60 => '<',
            61 => '=',
            62 => '>',
            63 => '?',
            64 => 'at',
            65 => 'A',
            66 => 'B',
            67 => 'C',
            68 => 'D',
            69 => 'E',
            70 => 'F',
            71 => 'G',
            72 => 'H',
            73 => 'I',
            74 => 'J',
            75 => 'K',
            76 => 'L',
            77 => 'M',
            78 => 'N',
            79 => 'O',
            80 => 'P',
            81 => 'Q',
            82 => 'R',
            83 => 'S',
            84 => 'T',
            85 => 'U',
            86 => 'V',
            87 => 'W',
            88 => 'X',
            89 => 'Y',
            90 => 'Z',
            91 => 'lB',
            92 => 'rs',
            93 => 'rB',
            94 => 'ha',
            95 => '_',
            96 => 'oq',
            97 => 'a',
            98 => 'b',
            99 => 'c',
            100 => 'd',
            101 => 'e',
            102 => 'f',
            103 => 'g',
            104 => 'h',
            105 => 'i',
            106 => 'j',
            107 => 'k',
            108 => 'l',
            109 => 'm',
            110 => 'n',
            111 => 'o',
            112 => 'p',
            113 => 'q',
            114 => 'r',
            115 => 's',
            116 => 't',
            117 => 'u',
            118 => 'v',
            119 => 'w',
            120 => 'x',
            121 => 'y',
            122 => 'z',
            123 => 'lC',
            124 => 'ba',
            125 => 'rC',
            126 => 'ti',
            161 => 'r!',
            162 => 'ct',
            163 => 'Po',
            164 => 'f/',
            165 => 'Ye',
            166 => 'Fn',
            167 => 'sc',
            168 => 'Cs',
            169 => 'aq',
            170 => 'lq',
            171 => 'Fo',
            172 => 'fo',
            173 => 'fc',
            174 => 'fi',
            175 => 'fl',
            177 => 'en',
            178 => 'dg',
            179 => 'dd',
            180 => 'pc',
            182 => 'ps',
            183 => 'bu',
            184 => 'bq',
            185 => 'Bq',
            186 => 'rq',
            187 => 'Fc',
            188 => 'u2026',
            189 => '%0',
            191 => 'r?',
            193 => 'ga',
            194 => 'aa',
            195 => 'a^',
            196 => 'a~',
            197 => 'a-',
            198 => 'ab',
            199 => 'a.',
            200 => 'ad',
            202 => 'ao',
            203 => 'ac',
            205 => 'a"',
            206 => 'ho',
            207 => 'ah',
            208 => 'em',
            225 => 'AE',
            227 => 'Of',
            232 => '/L',
            233 => '/O',
            234 => 'OE',
            235 => 'Om',
            241 => 'ae',
            245 => '.i',
            248 => '/l',
            249 => '/o',
            250 => 'oe',
            251 => 'ss',
);

my $prog=$0;
unshift(@ARGV,split(' ',$ENV{GROPDF_OPTIONS})) if exists($ENV{GROPDF_OPTIONS});

my $gotzlib=0;
my $gotinline=0;

my $rc = eval
{
    require Compress::Zlib;
    Compress::Zlib->import();
    1;
};

if($rc)
{
    $gotzlib=1;
}
else
{
    Warn("Perl module 'Compress::Zlib' not available; cannot compress"
    . " this PDF");
}

mkdir $ENV{HOME}.'/_Inline' if !-e $ENV{HOME}.'/_Inline' and !exists($ENV{PERL_INLINE_DIRECTORY}) and exists($ENV{HOME});

$rc = eval
{
    require Inline;
    Inline->import (C => Config => DIRECTORY => $ENV{HOME}.'/_Inline') if !exists($ENV{PERL_INLINE_DIRECTORY}) and exists($ENV{HOME});
    Inline->import (C =><<'EOC');

    static const uint32_t MAGIC1 = 52845;
    static const uint32_t MAGIC2 = 22719;

    typedef unsigned char byte;

    char* decrypt_exec_C(char *s, int len)
    {
        static uint16_t er=55665;
        byte clr=0;
        int i;
        er=55665;

        for (i=0; i < len; i++)
        {
            byte cypher = s[i];
            clr = (byte)(cypher ^ (er >> 8));
            er = (uint16_t)((cypher + er) * MAGIC1 + MAGIC2);
            s[i] = clr;
        }

        return(s);
    }

EOC
};

if($rc)
{
    $gotinline=1;
}

my %cfg;

$cfg{GROFF_VERSION}='@VERSION@';
$cfg{GROFF_FONT_PATH}='@GROFF_FONT_DIR@';
$cfg{RT_SEP}='@RT_SEP@';
binmode(STDOUT);

my @obj;        # Array of PDF objects
my $objct=0;    # Count of Objects
my $fct=0;      # Output count
my %fnt;        # Used fonts
my $lct=0;      # Input Line Count
my $src_name='';
my %env;        # Current environment
my %fontlst;    # Fonts Loaded
my $rot=0;      # Portrait
my %desc;       # Contents of DESC
my %download;   # Contents of downlopad file
my $pages;      # Pointer to /Pages object
my $devnm='devpdf';
my $cpage;      # Pointer to current pages
my $cpageno=0;  # Object no of current page
my $cat;        # Pointer to catalogue
my $dests;      # Pointer to Dests
my @mediabox=(0,0,595,842);
my @defaultmb=(0,0,595,842);
my $stream='';  # Current Text/Graphics stream
my $cftsz=10;   # Current font sz
my $cft;        # Current Font
my $lwidth=1;   # current linewidth
my $linecap=1;
my $linejoin=1;
my $textcol=''; # Current groff text
my $fillcol=''; # Current groff fill
my $curfill=''; # Current PDF fill
my $strkcol='';
my $curstrk='';
my @lin=();     # Array holding current line of text
my @ahead=();   # Buffer used to hol the next line
my $mode='g';   # Graphic (g) or Text (t) mode;
my $xpos=0;     # Current X position
my $ypos=0;     # Current Y position
my $tmxpos=0;
my $kernadjust=0;
my $curkern=0;
my $krntbl;     # Pointer to kern table
my $matrix="1 0 0 1";
my $whtsz;      # Current width of a space
my $wt;
my $poschg=0;   # V/H pending
my $fontchg=0;  # font change pending
my $tnum=2;     # flatness of B-Spline curve
my $tden=3;     # flatness of B-Spline curve
my $linewidth=40;
my $w_flg=0;
my $gotT=0;
my $suppress=0; # Suppress processing?
my %incfil;     # Included Files
my @outlev=([0,undef,0,0]);     # Structure pdfmark /OUT entries
my $curoutlev=\@outlev;
my $curoutlevno=0;      # Growth point for @curoutlev
my $Foundry='';
my $xrev=0;     # Reverse x direction of font
my $inxrev=0;
my $matrixchg=0;
my $thislev=1;
my $mark=undef;
my $suspendmark=undef;
my $boxmax=0;
my %missing;    # fonts in download files which are not found/readable
my @PageLabel;  # PageLabels


my $n_flg=1;
my $pginsert=-1;    # Growth point for kids array
my %pgnames;        # 'names' of pages for switchtopage
my @outlines=();    # State of Bookmark Outlines at end of each page
my $custompaper=0;  # Has there been an X papersize
my $textenccmap=''; # CMap for groff text.enc encoding
my @XOstream=();
my @PageAnnots={};
my $noslide=0;
my $transition={PAGE => {Type => '/Trans', S => '', D => 1, Dm => '/H', M => '/I', Di => 0, SS => 1.0, B => 0},
BLOCK => {Type => '/Trans', S => '', D => 1, Dm => '/H', M => '/I', Di => 0, SS => 1.0, B => 0}};
my $firstpause=0;
my $present=0;
my @bgstack;            # Stack of background boxes
my $bgbox='';           # Draw commands for boxes on this page

$noslide=1 if exists($ENV{GROPDF_NOSLIDE}) and $ENV{GROPDF_NOSLIDE};

my %ppsz=(
    'ledger'=>[1224,792],
    'legal'=>[612,1008],
    'letter'=>[612,792],
    'a0'=>[2384,3370],
    'a1'=>[1684,2384],
    'a2'=>[1191,1684],
    'a3'=>[842,1191],
    'a4'=>[595,842],
    'a5'=>[420,595],
    'a6'=>[297,420],
    'a7'=>[210,297],
    'a8'=>[148,210],
    'a9'=>[105,148],
    'a10'=>[73,105],
    'b0'=>[2835,4008],
    'b1'=>[2004,2835],
    'b2'=>[1417,2004],
    'b3'=>[1001,1417],
    'b4'=>[709,1001],
    'b5'=>[499,709],
    'b6'=>[354,499],
    'c0'=>[2599,3677],
    'c1'=>[1837,2599],
    'c2'=>[1298,1837],
    'c3'=>[918,1298],
    'c4'=>[649,918],
    'c5'=>[459,649],
    'c6'=>[323,459],
    'com10'=>[297,684],
);

my $ucmap=<<'EOF';
/CIDInit /ProcSet findresource begin
12 dict begin
begincmap
/CIDSystemInfo
<< /Registry (Adobe)
/Ordering (UCS)
/Supplement 0
>> def
/CMapName /Adobe-Identity-UCS def
/CMapType 2 def
1 begincodespacerange
<0000> <FFFF>
endcodespacerange
1 beginbfrange
<001f> <001f> <002d>
endbfrange
endcmap
CMapName currentdict /CMap defineresource pop
end
end
EOF

sub usage
{
    my $stream = *STDOUT;
    my $had_error = shift;
    $stream = *STDERR if $had_error;
    print $stream
    "usage: $prog [-dels] [-F font-directory] [-I inclusion-directory]" .
    " [-p paper-format] [-u [cmap-file]] [-y foundry] [file ...]\n" .
    "usage: $prog {-v | --version}\n" .
    "usage: $prog --help\n";
    if (!$had_error)
    {
        print $stream "\n" .
        "Translate the output of troff(1) into Portable Document Format.\n" .
        "See the gropdf(1) manual page.\n";
    }
    exit($had_error);
}

my $fd;
my $frot;
my $fpsz;
my $embedall=0;
my $debug=0;
my $want_help=0;
my $version=0;
my $stats=0;
my $unicodemap;
my $options=7;
my $PDFver=1.7;
my @idirs;

my $alloc=-1;
my $cftmajor=0;
my $lenIV=4;
my %sec;
my $Glyphs='';
my (@glyphused,@subrused,%glyphseen);
my $newsub=4;
my $term="\n";
my @bl;
my %seac;
my $thisfnt;
my $parcln=qr/\[[^\]]*?\]|(?<term>.)((?!\g{term}).)*\g{term}/;
my $parclntyp=qr/(?:[\d\w]|\([+-]?[\S]{2}|$parcln)/;

if (!GetOptions('F=s' => \$fd, 'I=s' => \@idirs, 'l' => \$frot,
    'p=s' => \$fpsz, 'd!' => \$debug, 'help' => \$want_help, 'pdfver=f' => \$PDFver,
    'v' => \$version, 'version' => \$version, 'opt=s' => \$options,
    'e' => \$embedall, 'y=s' => \$Foundry, 's' => \$stats,
    'u:s' => \$unicodemap))
{
    &usage(1);
}

unshift(@idirs,'.');

&usage(0) if ($want_help);

if ($version)
{
    #print "GNU gropdf (groff) version $cfg{GROFF_VERSION}\n";
    print "GNU gropdf (groff) version $cfg{GROFF_VERSION}-$VERSION\n";
    exit;
}

if (defined($unicodemap))
{
    if ($unicodemap eq '')
    {
        $ucmap='';
    }
    elsif (-r $unicodemap)
    {
        local $/;
        open(F,"<$unicodemap") or Die("failed to open '$unicodemap'");
        ($ucmap)=(<F>);
        close(F);
    }
    elsif (lc($unicodemap) eq 'auto')
    {
        Warn("failed to find '$unicodemap'; ignoring");
    }
}

if ($PDFver != 1.4 and $PDFver != 1.7)
{
    Warn("Only pdf versions 1.4 or 1.7 are supported, not '$PDFver'");
    $PDFver=1.7;
}

$PDFver=int($PDFver*10)-10;

# Search for 'font directory': paths in -f opt, shell var
# GROFF_FONT_PATH, default paths

my $fontdir=$cfg{GROFF_FONT_PATH};
$fontdir=$ENV{GROFF_FONT_PATH}.$cfg{RT_SEP}.$fontdir if exists($ENV{GROFF_FONT_PATH});
$fontdir=$fd.$cfg{RT_SEP}.$fontdir if defined($fd);

$rot=90 if $frot;
$matrix="0 1 -1 0" if $frot;

LoadDownload();
LoadDesc();

my $unitwidth=$desc{unitwidth};

$env{FontHT}=0;
$env{FontSlant}=0;
MakeMatrix();

my $possiblesizes = $desc{papersize};
$possiblesizes = $fpsz if $fpsz;
my $papersz;
for $papersz ( split(" ", lc($possiblesizes).' #duff#') )
{
    # No valid papersize found?
    if ($papersz eq '#duff#')
    {
        Warn("ignoring unrecognized paper format(s) '$possiblesizes'");
        last;
    }

    # Check for "/etc/papersize"
    elsif (substr($papersz,0,1) eq '/' and -r $papersz)
    {
        if (open(P,"<$papersz"))
        {
            while (<P>)
            {
                chomp;
                s/# .*//;
                next if $_ eq '';
                $papersz=lc($_);
                last;
            }
            close(P);
        }
    }

    # Allow height,width specified directly in centimeters, inches, or points.
    if ($papersz=~m/([\d.]+)([cipP]),([\d.]+)([cipP])/)
    {
        @defaultmb=@mediabox=(0,0,ToPoints($3,$4),ToPoints($1,$2));
        last;
    }
    # Look $papersz up as a name such as "a4" or "letter".
    elsif (exists($ppsz{$papersz}))
    {
        @defaultmb=@mediabox=(0,0,$ppsz{$papersz}->[0],$ppsz{$papersz}->[1]);
        last;
    }
    # Check for a landscape version
    elsif (substr($papersz,-1) eq 'l' and exists($ppsz{substr($papersz,0,-1)}))
    {
        # Note 'legal' ends in 'l' but will be caught above
        @defaultmb=@mediabox=(0,0,$ppsz{substr($papersz,0,-1)}->[1],$ppsz{substr($papersz,0,-1)}->[0]);
        last;
    }

    # If we get here, $papersz was invalid, so try the next one.
}

my @dt;
if ($ENV{SOURCE_DATE_EPOCH}) {
    @dt=gmtime($ENV{SOURCE_DATE_EPOCH});
} else {
    @dt=localtime;
}
my $dt=PDFDate(\@dt);

my %info=('Creator' => "(groff version $cfg{GROFF_VERSION})",
          'Producer' => "(gropdf version $cfg{GROFF_VERSION})",
          'ModDate' => "($dt)",
          'CreationDate' => "($dt)");
map { $_="< ".$_."\0" } @ARGV;

while (<>)
{
    chomp;
    s/\r$//;
    $lct++;

    do  # The ahead buffer behaves like 'ungetc'
    {{
        if (scalar(@ahead))
        {
            $_=shift(@ahead);
        }


        my $cmd=substr($_,0,1);
        next if $cmd eq '#';    # just a comment
        my $lin=substr($_,1);

        while ($cmd eq 'w')
        {
            $cmd=substr($lin,0,1);
            $lin=substr($lin,1);
            $w_flg=1 if $gotT;
        }

        $lin=~s/^\s+//;
        #               $lin=~s/\s#.*?$//;      # remove comment
        $stream.="\% $_\n" if $debug;

        do_x($lin),next if ($cmd eq 'x');
        next if $suppress;
        do_p($lin),next if ($cmd eq 'p');
        do_f($lin),next if ($cmd eq 'f');
        do_s($lin),next if ($cmd eq 's');
        do_m($lin),next if ($cmd eq 'm');
        do_D($lin),next if ($cmd eq 'D');
        do_V($lin),next if ($cmd eq 'V');
        do_v($lin),next if ($cmd eq 'v');
        do_t($lin),next if ($cmd eq 't');
        do_u($lin),next if ($cmd eq 'u');
        do_C($lin),next if ($cmd eq 'C');
        do_c($lin),next if ($cmd eq 'c');
        do_N($lin),next if ($cmd eq 'N');
        do_h($lin),next if ($cmd eq 'h');
        do_H($lin),next if ($cmd eq 'H');
        do_n($lin),next if ($cmd eq 'n');

        my $tmp=scalar(@ahead);
    }} until scalar(@ahead) == 0;

}

exit 0 if $lct==0;

if ($cpageno > 0)
{
    my $trans='BLOCK';

    $trans='PAGE' if $firstpause;

    if (scalar(@XOstream))
    {
        MakeXO() if $stream;
        $stream=join("\n",@XOstream)."\n";
    }

    my %t=%{$transition->{$trans}};
    $cpage->{MediaBox}=\@mediabox if $custompaper;
    $cpage->{Trans}=FixTrans(\%t) if $t{S};

    if ($#PageAnnots >= 0)
    {
        @{$cpage->{Annots}}=@PageAnnots;
    }

    if ($#bgstack > -1 or $bgbox)
    {
        my $box="q 1 0 0 1 0 0 cm ";

        foreach my $bg (@bgstack)
        {
            # 0=$bgtype # 1=stroke 2=fill. 4=page
            # 1=$strkcol
            # 2=$fillcol
            # 3=(Left,Top,Right,bottom,LineWeight)
            # 4=Start ypos
            # 5=Endypos
            # 6=Line Weight

            my $pg=$bg->[3] || \@mediabox;

            $bg->[5]=$pg->[3];  # box is continuing to next page
            $box.=DrawBox($bg);
            $bg->[4]=$pg->[1];  # will continue from page top
        }

        $stream=$box.$bgbox."Q\n".$stream;
        $bgbox='';
    }

    $boxmax=0;
    PutObj($cpageno);
    OutStream($cpageno+1);
}

$cat->{PageMode}='/UseOutlines' if $#outlev > 0;
$cat->{PageMode}='/FullScreen' if $present;

PutOutlines(\@outlev);

my $info=BuildObj(++$objct,\%info);

PutObj($objct);

foreach my $fontno (sort keys %fontlst)
{
    my $f=$fontlst{$fontno};
    my $fnt=$f->{FNT};

    # Separate the cid font output process into PutCIDFont().
    PutCIDFont($fontno), next if $fnt->{cidfont}; # xxxxx

    # Type1
    my $nam=$fnt->{NAM};
    my ($head,$body,$tail);
    my $objno=$f->{OBJNO};
    my @fontdesc=();
    my $chars=$fnt->{TRFCHAR};
    my $glyphs='/.notdef';
    $glyphs.='/space' if defined($fnt->{NO}->[32]) and $fnt->{NO}->[32] eq 'u0020';
    my $fobj;
    @glyphused=@subrused=%seac=();
    push(@subrused,'#0','#1','#2','#3','#4');
    $newsub=4;
    %sec=();
    $thisfnt=$fnt;

    for (my $j=0; $j<=$#{$chars}; $j++)
    {
        $glyphs.=join('',@{$fnt->{CHARSET}->[$j]});
    }

    if (exists($fnt->{fontfile}) && ($fnt->{embed} || $embedall))
    {
        $fnt->{FONTFILE}=BuildObj(++$objct,
                                   {'Length1' => 0,
                                    'Length2' => 0,
                                    'Length3' => 0
                                   }
        ), $fobj=$objct if !($options & NOFILE);

        ($head,$body,$tail)=GetType1($fnt->{fontfile});
        $head=~s/\/Encoding \d.*?readonly def\b/\/Encoding StandardEncoding def/s;

        if ($options & SUBSET)
        {
            $lenIV=$1 if $head=~m'/lenIV\s+(\d+)';
            my $l=length($body);
            my $b=($gotinline)?decrypt_exec_C($body,$l):decrypt_exec_P(\$body,$l);
	    $body=substr($body,$lenIV);
	    $body=~m/begin([\r\n]+)/;
	    $term=$1;
	    if (defined($term))
	    {
		(@bl)=split("$term",$body);
		map_subrs(\@bl);
		Subset(\@bl,$glyphs);
            }
            else
            {
                Warn("Unable to parse font '$fnt->{internalname}' for subsetting")
            }
        }
    }

    for (my $j=0; $j<=$#{$chars}; $j++)
    {
        my @differ;
        my $firstch;
        my $lastch=0;
        my @widths;
        my $miss=-1;
        my $CharSet=join('',@{$fnt->{CHARSET}->[$j]});
	push(@{$chars->[$j]},'u0020') if $j==0 and $fnt->{NAM}->{u0020}->[PSNAME];

        foreach my $og (sort { $nam->{$a}->[MINOR] <=> $nam->{$b}->[MINOR] } (@{$chars->[$j]}))
        {
            my $g=$og;

            while ($g or $g eq '0')
            {
                my ($glyph,$trf)=GetNAM($fnt,$g);
                my $chrno=$glyph->[MINOR];
                $firstch=$chrno if !defined($firstch);
                $lastch=$chrno;
                $widths[$chrno-$firstch]=$glyph->[WIDTH];

                push(@differ,$chrno) if $chrno > $miss;
                $miss=$chrno+1;
                my $ps=$glyph->[PSNAME];
                push(@differ,$ps);

                if (exists($seac{$trf}))
                {
                    $g=pop(@{$seac{$ps}});
                    $CharSet.=$g if $g;
                }
                else
                {
                    $g='';
                }
            }
        }

        foreach my $w (@widths) {$w=0 if !defined($w);}
        my $fontnm=$fontno.(($j)?".$j":'');
        $fnt->{FirstChar}=$firstch;
        $fnt->{LastChar}=$lastch;
        $fnt->{Differences}=\@differ;
        $fnt->{Widths}=\@widths;
        $fnt->{CharSet}=$CharSet;
        #$fnt->{'ToUnicode'}=$textenccmap if $j==0 and $CharSet=~m'/minus';

        $objct++;
        push(@fontdesc,EmbedFont($fontnm,$fnt));
        $pages->{'Resources'}->{'Font'}->{'F'.$fontnm}=$fontlst{$fontnm}->{OBJ};
        #$obj[$objct-2]->{DATA}->{'ToUnicode'}=$textenccmap if (exists($fnt->{ToUnicode}));
	if (defined $unicodemap && lc($unicodemap) eq 'auto') {
	    if (my $tounicode = $fnt->{' 2uni'}[$j]) {
		my $cmapname = join '-', $fnt->{name}, $j, "Identity",
		    $fnt->{vertical}? "V" : "H";
		if (my $cmap = unicode_cmap($cmapname, $tounicode)) {
		    $fnt->{'ToUnicode'}[$j] = $cmap;
		    $obj[$objct-2]->{DATA}->{'ToUnicode'} = $cmap;
		    if ($debug) {
			print STDERR "# $fnt->{name}.$j: ToUnicode = $cmap -u $unicodemap\n";
		    }
		}
	    }
	} else {
	    if ($j==0 and $CharSet=~m'/minus') {
		if (my $cmap = $fnt->{ToUnicode} = $textenccmap) {
		    $obj[$objct-2]->{DATA}->{'ToUnicode'} = $cmap;
		}
	    }
	}

    }

    if (exists($fnt->{fontfile}) && ($fnt->{embed} || $embedall))
    {
	if ($options & SUBSET and !($options & NOFILE))
	{
	    if (defined($term))
	    {
		$body=encrypt(\@bl);
	    }
	}

	if (defined($fobj))
	{
	    $obj[$fobj]->{STREAM}=$head.$body.$tail;
	    $obj[$fobj]->{DATA}->{Length1}=length($head);
	    $obj[$fobj]->{DATA}->{Length2}=length($body);
	    $obj[$fobj]->{DATA}->{Length3}=length($tail);
        }

        foreach my $o (@fontdesc)
        {
            $obj[$o]->{DATA}->{FontFile}=$fnt->{FONTFILE} if !($options & NOFILE);
            if ($options & SUBSET)
            {
                my $nm='/'.SubTag().$fnt->{internalname};
                $obj[$o]->{DATA}->{FontName}=$nm;
                $obj[$o-2]->{DATA}->{BaseFont}=$nm;
            }
        }
    }
}


# pass2
my %DOWNLOAD;   # xxxxx

foreach my $fontno (sort keys %fontlst)
{
    my $f = $fontlst{$fontno};
    my $fnt = $f->{FNT};
    if ($fnt->{cidfont}) {
        my $DOWNLOAD = $DOWNLOAD{$fnt->{' FontName'}};
        $fnt->{' cid2uni'} = $DOWNLOAD->{' cid2uni'};
        $DOWNLOAD->{ucmap} //= unicode_cmap(
	    $fnt->{' CMapName'}, $fnt->{' cid2uni'});
        GetObj($fnt->{font_resource})->{ToUnicode} = $DOWNLOAD->{ucmap}
            if $DOWNLOAD->{ucmap};
	if ($fnt->{embed} || $embedall) {
	    unless ($DOWNLOAD->{fontfile}) {
		unless ($DOWNLOAD->{' FontName'}) {
		    $DOWNLOAD->{' FontName'} = SubTag().$fnt->{' FontName'};
		    $DOWNLOAD->{' tempfile'} = [
			tempfile(DIR => '/tmp', SUFFIX => '.otf') ];
		    my $sub_font = $DOWNLOAD->{' tempfile'}[1];
		    if (!$subset_mp) {
			subset_start($f->{NM}, $fnt, $sub_font);
		    } else {
			my $pid = fork;
			if (!defined $pid) {
			    die "can't fork for $fnt->{fontfile}";
			} elsif ($pid == 0) {
			    subset_start($f->{NM}, $fnt, $sub_font);
			    exit 0;
			} else {
			    $DOWNLOAD->{' pid'} = $pid;
			    print STDERR "# pid = $pid\n" if 0 && $debug;
			}
		    }
		}
	    }
        }
    }
}


foreach my $fontno (sort keys %fontlst) {
    my $f = $fontlst{$fontno};
    my $fnt = $f->{FNT};
    if ($fnt->{cidfont}) {
	my $DOWNLOAD = $DOWNLOAD{$fnt->{' FontName'}};
	if ($fnt->{embed} || $embedall) {
	    unless ($DOWNLOAD->{fontfile}) {
		if ($subset_mp) {
		    if (my $pid = $DOWNLOAD->{' pid'}) {
			$DOWNLOAD->{' pid'} = undef;
			print STDERR "# waitpid($pid, 0)\n" if 0 && $debug;
			waitpid($pid, 0);
		    }
		}
		my $sub_font = $DOWNLOAD->{' tempfile'}[1];
		$DOWNLOAD->{fontfile} = subset_end($sub_font);
		unlink $sub_font;
		delete $DOWNLOAD->{' tempfile'};
	    }
	    my $p = GetObj($fnt->{font_descriptor});
	    for ($DOWNLOAD->{fontfile}) {
		$p->{FontFile3} = $_ if defined;
	    }
	    $p->{'FontName'} = "/".$DOWNLOAD->{' FontName'};
	}
    }

}


sub subset_start {
    my ($fn, $fnt, $sub_font) = @_;

    my @cids = keys %{$fnt->{' cid2uni'}};
    return undef if !@cids || @cids == 1 && $cids[0] == 0;;
    my @gids = map { $fnt->{' CID2GID'}->[$_] } @cids; # xxxxx

    my ($gh, $gid_file) = tempfile(DIR => '/tmp', SUFFIX => '.txt');
    #my $gids = join ',', @gids;
    print $gh join(',', @gids), "\n";
    close $gh;
    my @pyftsubset = (
        'pyftsubset.pyenv', $fnt->{fontfile}, # $PATH_otf,
        "--output-file=$sub_font",
        #"--gids=$gids",
        "--gids-file=$gid_file",
        #'--retain-gids',
        '--notdef-outline',

        #'--notdef-glyph',
        #'--recommended-glyphs',
        #'--layout-features=*',
        #'--glyph-names',
        #'--symbol-cmap',
        #'--legacy-cmap',
        #'--desubroutinize',
        #'--passthrough-tables',
    );

    print STDERR "# @pyftsubset\n" if 0 && $debug;
    my $rc = system @pyftsubset;
    unlink $gid_file;

    $rc;
}


sub subset_end {
    my ($sub_font) = @_;

    my $font_stream;
    my $subtype;
    my $otf = Font::TTF::Font->open($sub_font);
    if ($otf && $otf->{'CFF '}) {
        my $fh = $otf->{'CFF '}{' INFILE'};
        $fh->seek($otf->{'CFF '}{' OFFSET'}, 0);
        $fh->read($font_stream, $otf->{'CFF '}{' LENGTH'});
        $subtype = "/CIDFontType0C";
    } else {
        if (open my $fd, $sub_font) {
            local $/ = undef;
            $font_stream = <$fd>;
        } else {
            Warn("can't open '$sub_font'");
            $font_stream = '';
        }
        $subtype = "/OpenType";
    }
    #unlink $sub_font;

    my $fontfile = BuildObj(++$objct, {
        "Subtype" => $subtype,
    });
    $obj[$objct]->{STREAM} = $font_stream;
    $obj[$objct]->{DATA}{Length} = length $font_stream;

    $fontfile;
}

foreach my $j (0..$#{$pages->{Kids}})
{
    my $pg=GetObj($pages->{Kids}->[$j]);

    if (defined($PageLabel[$j]))
    {
        push(@{$cat->{PageLabels}->{Nums}},$j,$PageLabel[$j]);
    }
}

if (exists($cat->{PageLabels}) and $cat->{PageLabels}->{Nums}->[0] != 0)
{
    unshift(@{$cat->{PageLabels}->{Nums}},0,{S => "/D"});
}

PutObj(1);
PutObj(2);

my $objidx=-1;
my @obji;
my $tobjct=$objct;
my $omaj=-1;

foreach my $o (3..$objct)
{
    if (!exists($obj[$o]->{XREF}))
    {
	if ($PDFver!=4 and !exists($obj[$o]->{STREAM}) and ref($obj[$o]->{DATA}) eq 'HASH')
	{
	    # This can be put into an ObjStm
	    my $maj=int(++$objidx/128);
	    my $min=$objidx % 128;

	    if ($maj > $omaj)
	    {
		$omaj=$maj;
		BuildObj(++$tobjct,
		{
		    'Type' => '/ObjStm',
		}
		);

		$obji[$maj]=[$tobjct,0,'',''];
		$obj[$tobjct]->{DATA}->{Extends}=($tobjct-1)." 0 R" if $maj > 0;
	    }

	    $obj[$o]->{INDIRECT}=[$tobjct,$min];
	    $obji[$maj]->[1]++;
	    $obji[$maj]->[2].=' ' if $obji[$maj]->[2];
	    $obji[$maj]->[2].="$o ".length($obji[$maj]->[3]);
	    PutObj($o,\$obji[$maj]->[3]);
	}
	else
	{
	    PutObj($o);
	}
    }
}

foreach my $maj (0..$#obji)
{
    my $obji=$obji[$maj];
    my $objno=$obji->[0];

    $obj[$objno]->{DATA}->{N}=$obji->[1];
    $obj[$objno]->{DATA}->{First}=length($obji->[2]);
    $obj[$objno]->{STREAM}=$obji->[2].$obji->[3];
    PutObj($objno);
}

$objct=$tobjct;

#my $encrypt=BuildObj(++$objct,{'Filter' => '/Standard', 'V' => 1, 'R' => 2, 'P' => 252});
#PutObj($objct);

my $xrefct=$fct;

$objct+=1;

if ($PDFver == 4)
{
    print "xref\n0 $objct\n0000000000 65535 f \n";

    foreach my $j (1..$#obj)
    {
        my $xr=$obj[$j];
        next if !defined($xr);
        printf("%010d 00000 n \n",$xr->{XREF});
    }

    print "trailer\n<<\n/Info $info\n/Root 1 0 R\n/Size $objct\n>>\n";
}
else
{
    BuildObj($objct++,
    {
        'Type' => '/XRef',
        'W' => [1, 4, 1],
        'Info' => $info,
        'Root' => "1 0 R",
        'Size' => $objct,
    });

    $stream=pack('CNC',0,0,0);

    foreach my $j (1..$#obj)
    {
        my $xr=$obj[$j];
        next if !defined($xr);

        if (exists($xr->{INDIRECT}))
        {
            $stream.=pack('CNC',2,@{$xr->{INDIRECT}});
        }
        else
        {
            if (exists($xr->{XREF}))
            {
                $stream.=pack('CNC',1,$xr->{XREF},0);
            }
        }
    }

    $stream.=pack('CNC',1,$fct,0);
    $obj[$objct-1]->{STREAM}=$stream;
    PutObj($objct-1);
    print "trailer\n<<\n/Root 1 0 R\n/Size $objct\n>>\n";
}

print "startxref\n$xrefct\n\%\%EOF\n";
print "\% Pages=$pages->{Count}\n" if $stats;


sub PutCIDFont
{
    my $fontno = shift;
    my $fontnm = $fontno;

    my $f = $fontlst{$fontno};

    my $fnt = $f->{FNT};
    my $otf = $fnt->{' OTF'};

    0 and print STDERR 'keys %{$f->{FNT}}: ', "@{[ sort keys %{$f->{FNT}} ]}", "\n";

=begin comment

ALLOC CHARSET DIFF NAM NO TRFCHAR WIDTH ascent capheight cidfont encoding
fntbbox fontfile internalname lastchr ligatures name nospace opentype slant
spacewidth t1flags

=end comment

=cut

    0 and print STDERR "ref \$f->{FNT}{$_}: ", ref $f->{FNT}{$_}, "\n"
        for sort keys %{$f->{FNT}};


=begin comment

ref $f->{FNT}{ALLOC}: 
ref $f->{FNT}{CHARSET}: ARRAY
ref $f->{FNT}{DIFF}: ARRAY
ref $f->{FNT}{NAM}: HASH

The keys are the names (names of the characters) and the values ​​are the
charsets of the groff_fonts.

ref $f->{FNT}{NO}: ARRAY

The index is code (character number), the value is name (character name).

ref $f->{FNT}{TRFCHAR}: ARRAY
ref $f->{FNT}{WIDTH}: ARRAY
ref $f->{FNT}{ascent}: 
ref $f->{FNT}{capheight}: 
ref $f->{FNT}{cidfont}: 
ref $f->{FNT}{encoding}: 
ref $f->{FNT}{fntbbox}: ARRAY
ref $f->{FNT}{fontfile}: 
ref $f->{FNT}{internalname}: 
ref $f->{FNT}{lastchr}: 
ref $f->{FNT}{ligatures}: 
ref $f->{FNT}{name}: 
ref $f->{FNT}{nospace}: 
ref $f->{FNT}{opentype}: 
ref $f->{FNT}{slant}: 
ref $f->{FNT}{spacewidth}: 
ref $f->{FNT}{t1flags}: 

=end comment

=cut

    0 and print STDERR "ref \$f->{FNT}{WIDTH}: ", Dumper($f->{FNT}{WIDTH});

    if ($fnt->{usespace}) {
        my $space = 'u0020';
        my ($chf, $ch) = GetNAM($fnt, $space);
        AssignGlyph($fnt, $chf, $ch);
    }

    # Type 0 Font Dictionaries (Table 121)
    my $font_resource = BuildObj(++$objct, {
        Type => "/Font",
        Subtype => "/Type0",
        BaseFont => "/" . join('-', $fnt->{' FontName'}, $fnt->{' CMapName'}),
        Encoding => "/".$fnt->{' Encoding'},
        # DescendantFonts => [ $cid_font ], # [ 7 0 R ],
        # ToUnicode => undef, # 8 0 R,
    });
    $fontlst{$fontnm}->{OBJ} = $font_resource;

    #push(@fontdesc, EmbedFont($fontnm,$fnt));
    $pages->{Resources}->{Font}->{'F'.$fontnm} = $fontlst{$fontnm}->{OBJ};
    # $obj[$objct-2]->{DATA}->{'ToUnicode'} = $textenccmap if exists($fnt->{ToUnicode});


    # CIDFonts (Table 117)
    my $cid_font = BuildObj(++$objct, {
        Type => "/Font",
        Subtype => "/CIDFontType0", # if OpenType
        BaseFont => "/".$fnt->{' FontName'}, # CIDFontName
        CIDSystemInfo => $fnt->{' CIDSystemInfo'},
        # FontDescriptor => undef, # 8 0 R
    });
    GetObj($font_resource)->{DescendantFonts} = [ $cid_font ];

    my $flags = 0;
    #$flags += 1 << ( 1 - 1); # FixedPitch
    $flags += 1 << ( 1 - 1) if $fnt->{' isFixedPitch'};
    #$flags += 1 << ( 2 - 1); # Serif
    $flags += 1 << ( 2 - 1) if $fnt->{' FontName'} =~ /Serif/i;
    #$flags += 1 << ( 3 - 1); # Symbolic
    $flags += 1 << ( 3 - 1) if $fnt->{special};
    #$flags += 1 << ( 4 - 1); # Script
    #$flags += 1 << ( 6 - 1); # Nonsymbolic
    $flags += 1 << ( 6 - 1) if !$fnt->{special};
    #$flags += 1 << ( 7 - 1); # Italic
    $flags += 1 << ( 7 - 1) if $fnt->{slant};
    #$flags += 1 << (17 - 1); # AllCap
    #$flags += 1 << (18 - 1); # SmallCap
    #$flags += 1 << (19 - 1); # ForceBold

    # Entries common to all font descriptors (Table 122)
    my $font_descriptor = BuildObj(++$objct, {
        Type        => "/FontDescriptor",
        Flags       => $flags,
        FontName    => "/".$fnt->{' FontName'},
        FontBBox    => $fnt->{' FontBBox'},
        ItalicAngle => $fnt->{slant},
        Ascent      => $fnt->{' Ascender'},
        Descent     => $fnt->{' Descender'},
        CapHeight   => $fnt->{' CapHeight'},
        StemV       => 0,
        #FontFile3"  => "", # 9 0 R
    });
    GetObj($cid_font)->{FontDescriptor} = $font_descriptor;

    my $p = GetObj($cid_font);
    if ($fnt->{vertical}) {
        $p->{DW2} = $fnt->{' DW2'};
        $p->{W2} = w2_array($fnt);
    } else {
        $p->{DW} = $fnt->{' DW'};
        $p->{W} = w_array($fnt);
    }

    $fnt->{font_descriptor} = $font_descriptor;
    $fnt->{font_resource} = $font_resource;

    my $DOWNLOAD = $DOWNLOAD{$fnt->{' FontName'}} //= {};
    $DOWNLOAD->{' cid2uni'} = {
        %{$DOWNLOAD->{' cid2uni'} // {}},
        %{$fnt->{' cid2uni'} // {}},
    };

    0 and print STDERR Dumper({
        #'$font_resource' => GetObj($font_resource),
        #'$cid_font' => GetObj($cid_font),
        #'$font_descriptor' => GetObj($font_descriptor),
        #'$pages' => GetObj($pages), # xxxxx
    });

}


sub w_array {
    my ($fnt) = @_;

    my @w;
    my $n = 0;
    my $lastc = -1;
    for my $c (sort { $a <=> $b } keys %{$fnt->{' cid2nam'}}) {
        my ($chf, $ch) = GetNAM($fnt, $fnt->{' cid2nam'}{$c});
        my $w = $chf->[WIDTH] // $fnt->{' DW'};
        if ($w == $fnt->{' DW'}) {
            $n++;
            next;
        }
        if (@w && $lastc + 1 == $c && $n == 0) {
            if (ref $w[-1] eq 'ARRAY') {
                push @{$w[-1]}, $w;
                $lastc = $c;
                next;
            }
        }
        push @w, $c, [ $w ];
        $lastc = $c;
        $n = 0;
    }

    if (1) {
        my $thresh = 4;
        my @w2 = ();
        my @t = ();
        while (my ($c, $list) = splice @w, 0, 2) {
            @t = ($c, [shift @$list]);
            while (defined (my $w = shift @$list)) {
                $c++;
                if (@t == 3) {
                    if ($t[2] == $w) {
                        $t[1] = $c;
                    } else {
                        push @w2, @t;
                        @t = ($c, [ $w ]);
                    }
                } elsif (@t == 2) {
                    my $cons = 1;
                    for (1 .. $thresh) {
                        $cons = 0, last unless @{$t[1]} >= $_ && $t[1]->[-$_] == $w;
                    }
                    if ($cons) {
                        pop @{$t[1]} for 1 .. $thresh;
                        push @w2, @t if @{$t[1]} > 0;
                        @t = ($c - $thresh, $c, $w);
                    } else {
                        push @{$t[1]}, $w;
                    }
                } else {
                    die "program error: t = ", str_w(\@t);
                }
            }
            push @w2, @t;
            @t = ();
        }
        push @w2, @t;
        @w = @w2;
    }

    \@w;
}


sub w2_array {
    my ($fnt) = @_;

    my @w2;
    my $lastc = -1;
    for my $c (sort { $a <=> $b } keys %{$fnt->{' cid2nam'}}) {
        my ($chf, $ch) = GetNAM($fnt, $fnt->{' cid2nam'}{$c});
        my $w = $chf->[WIDTH] // $fnt->{' DW'};

	# PDF 32000-1:2008 PP.271-272
	# The default position vector and vertical displacement vector shall be
	# specified by the DW2 entry in the CIDFont dictionary. DW2 shall be an
	# array of two values: the vertical component of the position vector v
	# and the vertical component of the displacement vector w1 (see Figure
	# 40). The horizontal component of the position vector shall be half the
	# glyph width, and that of the displacement vector shall be 0.
	#
	# EXAMPLE 2	If the DW2 entry is
	#    /DW2 [ 880 −1000 ]
	# then a glyph’s position vector and vertical displacement vector are
	#    v = (w0 ÷ 2, 880)
	#   w1 = (0, –1000)
	# where w0 is the width (horizontal displacement) for the same glyph.

        # w0 = (1000, 0)
        # w1 = (0, -1000)
        # v  = (c.width / 2 - 0,  c.height + c.descender) = (500, 880)
        # dw2 = (v.y, w1.y) = (880, -1000)

        my ($w1_x, $w1_y, $v_x, $v_y) = (
            0,                    # w1_x
            $fnt->{' DW2'}[1],    # w1_y
            $fnt->{' DW'} / 2,    # v_x
            $fnt->{' DW2'}[0]     # v_y
        );

        if ($fnt->{vertical}) {
            $w1_y = -$w;
        } else {
            print STDERR "can't happen near line ", __LINE__, " in ", __FILE__, ".\n";
            $w1_x = $w;
        }

        if (!ref $w2[-1] && @w2 >= 4 && $w2[-3] == $w1_y && $w2[-2] == $v_x && $w2[-1] == $v_y) {
            $w2[-4] = $c;
            $lastc = $c;
            next;
        }

        if ($lastc + 1 == $c && ref $w2[-1] eq 'ARRAY') {
            push @{$w2[-1]}, $w1_y, $v_x, $v_y;
            $lastc = $c;
            next;
        }

        push @w2, $c, [ $w1_y, $v_x, $v_y ];
        $lastc = $c;
    }

    \@w2;
}


sub unicode_cmap {
    my ($cmapname, $tounicode) = @_;
    return undef unless $tounicode && %$tounicode;

    my $cmaptype = 2;
    my $CIDSystemInfo = {
        "Registry" => "(Adobe)",
        "Ordering" => "(UCS)",
        "Supplement" => 0,
    };
    my $ucmap = BuildObj(++$objct, {
        "Type" => "/CMap",
        "CMapName" => "/$cmapname",
        "CIDSystemInfo" => $CIDSystemInfo,
    });
    PutField(\ my ($CIDSystemInfo_text), $CIDSystemInfo);
    chop($CIDSystemInfo_text);
    $obj[$objct]->{STREAM} = join "\n", grep !/^[%]/, split /\n/, <<endstream;
/CIDInit /ProcSet findresource begin
12 dict begin
begincmap
/CMapName /$cmapname def
/CMapType $cmaptype def
/CIDSystemInfo $CIDSystemInfo_text def
@{[ codespacerange([ map pack("U*", $_), keys %{$tounicode} ]) ]}
@{[ bfrange($tounicode) ]}
endcmap
CMapName currentdict /CMap defineresource pop
end
end
endstream
    $obj[$objct]->{DATA}{Length} = length $obj[$objct]->{STREAM};

    $ucmap;
}


sub bfrange {
    my ($bfchar) = @_;
    my $chunksize = 100;
    my @bfrange;
    my @bfchar;

    my @k = sort { $a <=> $b } keys %{$bfchar};
    while (@k > 0) {
        my $i = 0;
        while ($i + 1 <= $#k) {
            last if $k[$i] + 1 != $k[$i + 1];
            my $a = [ map ord($_), split //, $bfchar->{$k[$i]} ];
            my $b = [ map ord($_), split //, $bfchar->{$k[$i + 1]} ];
            my $j = $#{$a};
            last if $#{$a} != $#{$b};
            last if $a->[$j] + 1 != $b->[$j];
            1 while (--$j >= 0 && $a->[$j] == $b->[$j]);
            last if $j >= 0;
            $i++;
        }
        if ($i > 0) {
            my @t = splice @k, 0, $i + 1;
            push @bfrange, [ $t[0], $t[-1] ];
        } elsif ($i <= $#k) {
            push @bfchar, shift @k;
            $i++;
        }
    }

    0 and print STDERR Dumper({ bfrange => \@bfrange, bfchar => \@bfchar}); # xxxxx

    join "\n", (
        blocking('bfrange', map {
            my @hex = map sprintf('%04X', $_), unpack 'n*',
                encode 'UTF16-BE', $bfchar->{$_->[0]};
            join ' ', sprintf("<%04X>", $_->[0]), sprintf("<%04X>", $_->[1]), "<@hex>";
        } @bfrange),
        blocking('bfchar', map {
            my @hex = map sprintf("%04X", $_), unpack "n*",
                encode "UTF16-BE", $bfchar->{$_};
            join ' ', sprintf("<%04X>", $_), "<@hex>";
        } @bfchar),
    );
}


sub codespacerange {
    my ($code) = @_;
    my @list;
    my %seen;
    for (sort grep !$seen{$_}++, @$code) {
        if (@list) {
            if (length $list[-1]->[0] == length) {
                my @s = $list[-1]->[0] =~ /^(.*?)(.|\n)$/;
                my @x = /^(.*?)(.|\n)$/;
                if ($x[0] eq $s[0]) {
                    $list[-1]->[1] = $_;
                    next;
                }
            }
        }
        if (@list) {
            my @s = unpack 'n*', encode 'UTF16-BE', $list[-1]->[0];
            my @e = unpack 'n*', encode 'UTF16-BE', $list[-1]->[1];
            my @n = unpack 'n*', encode 'UTF16-BE', $_;
            if ($e[0] == $n[0]) {
                print STDERR join ' ', 'codespacerange:',
                    "<@{[ map sprintf('%04X', $_), @e ]}>",
                    'and',
                    "<@{[ map sprintf('%04X', $_), @n ]}>",
                    'overlapped',
		    "\n";
            }
        }
        push @list, [ $_, $_ ];
    }
    blocking('codespacerange', map {
        my @s = map sprintf("%04X", $_), unpack 'n*', encode 'UTF16-BE', $_->[0];
        my @e = map sprintf("%04X", $_), unpack 'n*', encode 'UTF16-BE', $_->[1];
        "<@s> <@e>";
    } @list);
}


sub cidrange {
    my ($tounicode) = @_;
    my @list;
    for (sort { $tounicode->{$a} cmp $tounicode->{$b} } keys %{$tounicode}) {
        if (@list) {
            if (length $list[-1]->[0] == length $tounicode->{$_}) {
                my @s = $list[-1]->[0] =~ /^(.*?)(.|\n)$/;
                my @x = $tounicode->{$_} =~ /^(.*?)(.|\n)$/;
                if ($x[0] eq $s[0] && $list[-1]->[2] + (ord($x[1]) - ord($s[1])) == $_) {
                    $list[-1]->[1] = $tounicode->{$_};
                    next;
                }
            }
        }
        push @list, [ $tounicode->{$_}, $tounicode->{$_}, $_ ];
    }
    join "\n", (
        blocking('cidrange', map {
            my @s = map sprintf("%04X", $_), unpack 'n*', encode 'UTF16-BE', $_->[0];
            my @e = map sprintf("%04X", $_), unpack 'n*', encode 'UTF16-BE', $_->[1];
            join ' ', "<@s>", "<@e>", $_->[2];
        } grep $_->[0] ne $_->[1], @list),
        blocking('cidchar', map {
            my @s = map sprintf("%04X", $_), unpack 'n*', encode 'UTF16-BE', $_->[0];
            "<@s> $_->[2]";
        } grep $_->[0] eq $_->[1], @list),
    );
}


sub blocking {
    my ($name, @in) = @_;
    my $size = 100;
    my @out = ();
    while (@in) {
        my $n = min($size, scalar @in);
        push @out, "$n begin${name}";
        push @out, splice @in, 0, $n;
        push @out, "end${name}";
    }
    join "\n", @out;
}


sub MakeMatrix
{
    my $fontxrev=shift||0;
    my @mat=($frot)?(0,1,-1,0):(1,0,0,1);

    my ($a, $b, $c, $d);

    if ($thisfnt) {
        if (!$frot) {
            if (!($thisfnt->{vertical})) {
                ($a, $b, $c, $d) = (1, 0, 0, 1);
                $c = $thisfnt->{' skew'} // 0;
            } else {
                ($a, $b, $c, $d) = (0, 1, -1, 0);
                $a = $thisfnt->{' skew'} // 0;
            }
        } else {
            if (!($thisfnt->{vertical})) {
                ($a, $b, $c, $d) = (0, 1, -1, 0);
                $d = $thisfnt->{' skew'} // 0;
            } else {
                ($a, $b, $c, $d) = (-1, 0, 0, -1);
                $b = $thisfnt->{' skew'} // 0;
            }
        }
        @mat = ($a, $b, $c, $d);
    }

    if (!$frot)
    {
        if ($env{FontHT} != 0)
        {
            $mat[3]=sprintf('%.3f',$env{FontHT}/$cftsz);
        }

        if ($env{FontSlant} != 0)
        {
            my $slant=$env{FontSlant};
            $slant*=$env{FontHT}/$cftsz if $env{FontHT} != 0;
            my $ang=rad($slant);

            $mat[2]=sprintf('%.3f',sin($ang)/cos($ang));
        }

        if ($fontxrev)
        {
            $mat[0]=-$mat[0];
        }
    }

    $matrix=join(' ',@mat);
    $matrixchg=1;
}

sub PutOutlines
{
    my $o=shift;
    my $outlines;

    if ($#{$o} > 0)
    {
        # We've got Outlines to deal with
        my $openct=$curoutlev->[0]->[2];

        while ($thislev-- > 1)
        {
            my $nxtoutlev=$curoutlev->[0]->[1];
            $nxtoutlev->[0]->[2]+=$openct if $curoutlev->[0]->[3]==1;
            $openct=0 if $nxtoutlev->[0]->[3]==-1;
            $curoutlev=$nxtoutlev;
        }

        $cat->{Outlines}=BuildObj(++$objct,{'Count' => abs($o->[0]->[0])+$o->[0]->[2]});
        $outlines=$obj[$objct]->{DATA};
    }
    else
    {
        return;
    }

    SetOutObj($o);

    $outlines->{First}=$o->[1]->[2];
    $outlines->{Last}=$o->[$#{$o}]->[2];

    LinkOutObj($o,$cat->{Outlines});
}

sub SetOutObj
{
    my $o=shift;

    for my $j (1..$#{$o})
    {
        my $ono=BuildObj(++$objct,$o->[$j]->[0]);
        $o->[$j]->[2]=$ono;

        SetOutObj($o->[$j]->[1]) if $#{$o->[$j]->[1]} > -1;
    }
}

sub LinkOutObj
{
    my $o=shift;
    my $parent=shift;

    for my $j (1..$#{$o})
    {
        my $op=GetObj($o->[$j]->[2]);

        $op->{Next}=$o->[$j+1]->[2] if ($j < $#{$o});
        $op->{Prev}=$o->[$j-1]->[2] if ($j > 1);
        $op->{Parent}=$parent;

        if ($#{$o->[$j]->[1]} > -1)
        {
            $op->{Count}=$o->[$j]->[1]->[0]->[2]*$o->[$j]->[1]->[0]->[3];# if exists($op->{Count}) and $op->{Count} > 0;
            $op->{First}=$o->[$j]->[1]->[1]->[2];
            $op->{Last}=$o->[$j]->[1]->[$#{$o->[$j]->[1]}]->[2];
            LinkOutObj($o->[$j]->[1],$o->[$j]->[2]);
        }
    }
}

sub GetObj
{
    my $ono=shift;
    ($ono)=split(' ',$ono);
    return($obj[$ono]->{DATA});
}



sub PDFDate
{
    my $dt=shift;
    my $offset;
    if ($ENV{SOURCE_DATE_EPOCH}) {
	$offset=0;
    } else {
	$offset=mktime((localtime $dt)[0..5]) - mktime((gmtime $dt)[0..5]);
    }
    return(sprintf("D:%04d%02d%02d%02d%02d%02d%+03d'%+03d'",$dt->[5]+1900,$dt->[4]+1,$dt->[3],$dt->[2],$dt->[1],$dt->[0],int($offset/3600),int(($offset%3600)/60)));
}

sub ToPoints
{
    my $num=shift;
    my $unit=shift;

    if ($unit eq 'i')
    {
        return($num*72);
    }
    elsif ($unit eq 'c')
    {
        return int($num*72/2.54);
    }
    elsif ($unit eq 'm')        # millimetres
    {
        return int($num*72/25.4);
    }
    elsif ($unit eq 'p')
    {
        return($num);
    }
    elsif ($unit eq 'P')
    {
        return($num*6);
    }
    elsif ($unit eq 'z')
    {
        return($num/$unitwidth);
    }
    else
    {
        Die("invalid scaling unit '$unit'");
    }
}

sub LoadDownload
{
    my $f;
    my $found=0;

    my (@dirs)=split($cfg{RT_SEP},$fontdir);

    foreach my $dir (@dirs)
    {
        $f=undef;
        OpenFile(\$f,$dir,"download");
        next if !defined($f);
        $found++;

        while (<$f>)
        {
            chomp;
            s/#.*$//;
            next if $_ eq '';
            my ($foundry,$name,$file)=split(/\t+/);
            my $star = 0;
            if (substr($file,0,1) eq '*')
            {
                #next if !$embedall;
                $star = 1;
                $file=substr($file,1);
            }

            my $pth=$file;
            $pth=$dir."/$devnm/$file" if substr($file,0,1) ne '/';

            if (!-r $pth)
            {
                $missing{"$foundry $name"}="$dir/$devnm";
                next;
            }

            #$download{"$foundry $name"}=$file if !exists($download{"$foundry $name"});

            if (!exists($download{"$foundry $name"})) {
                $download{"$foundry $name"} = {
                    fontfile => $file,
                    embed => !$star,
                };
            }
        }

        close($f);
    }

    Die("failed to open 'download' file") if !$found;
}

sub OpenFile
{
    my $f=shift;
    my $dirs=shift;
    my $fnm=shift;

    if (substr($fnm,0,1)  eq '/' or substr($fnm,1,1) eq ':') # dos
    {
        return if -r "$fnm" and open($$f,"<$fnm");
    }

    my (@dirs)=split($cfg{RT_SEP},$dirs);

    foreach my $dir (@dirs)
    {
        last if -r "$dir/$devnm/$fnm" and open($$f,"<$dir/$devnm/$fnm");
    }
}

sub LoadDesc
{
    my $f;

    OpenFile(\$f,$fontdir,"DESC");
    Die("failed to open device description file 'DESC'")
    if !defined($f);

    while (<$f>)
    {
        chomp;
        s/#.*$//;
        next if $_ eq '';
        my ($name,$prms)=split(' ',$_,2);
        $desc{lc($name)}=$prms;
    }

    close($f);

    foreach my $directive ('unitwidth', 'res', 'sizescale')
    {
        Die("device description file 'DESC' missing mandatory directive"
        . " '$directive'") if !exists($desc{$directive});
    }

    foreach my $directive ('unitwidth', 'res', 'sizescale')
    {
        my $val=$desc{$directive};
        Die("device description file 'DESC' directive '$directive'"
        . " value must be positive; got '$val'")
        if ($val !~ m/^\d+$/ or $val <= 0);
    }

    if (exists($desc{'hor'}))
    {
        my $hor=$desc{'hor'};
        Die("device horizontal motion quantum must be 1, got '$hor'")
        if ($hor != 1);
    }

    if (exists($desc{'vert'}))
    {
        my $vert=$desc{'vert'};
        Die("device vertical motion quantum must be 1, got '$vert'")
        if ($vert != 1);
    }

    my ($res,$ss)=($desc{'res'},$desc{'sizescale'});
    Die("device resolution must be a multiple of 72*sizescale, got"
    . " '$res' ('sizescale'=$ss)") if (($res % ($ss * 72)) != 0);
}

sub rad  { $_[0]*3.14159/180 }

my $InPicRotate=0;

sub do_x
{
    my $l=shift;
    my ($xcmd,@xprm)=split(' ',$l);
    $xcmd=substr($xcmd,0,1);

    if ($xcmd eq 'T')
    {
        Warn("expecting a PDF pipe (got $xprm[0])")
        if $xprm[0] ne substr($devnm,3);
    }
    elsif ($xcmd eq 'f')        # Register Font
    {
        $xprm[1]="${Foundry}-$xprm[1]" if $Foundry ne '';
        LoadFont($xprm[0],$xprm[1]);
    }
    elsif ($xcmd eq 'F')        # Source File (for errors)
    {
        $env{SourceFile}=$xprm[0];
    }
    elsif ($xcmd eq 'H')        # FontHT
    {
        $xprm[0]/=$unitwidth;
        $xprm[0]=0 if $xprm[0] == $cftsz;
        $env{FontHT}=$xprm[0];
        MakeMatrix();
    }
    elsif ($xcmd eq 'S')        # FontSlant
    {
        $env{FontSlant}=$xprm[0];
        MakeMatrix();
    }
    elsif ($xcmd eq 'i')        # Initialise
    {
        if ($objct == 0)
        {
            $objct++;
            @defaultmb=@mediabox;
            BuildObj($objct,{'Pages' => BuildObj($objct+1,
                {'Kids' => [],
                    'Count' => 0,
                    'Type' => '/Pages',
                    'Rotate' => $rot,
                    'MediaBox' => \@defaultmb,
                    'Resources' => {'Font' => {},
                    'ProcSet' => ['/PDF', '/Text', '/ImageB', '/ImageC', '/ImageI']}
                }
            ),
            'Type' =>  '/Catalog'});

            $cat=$obj[$objct]->{DATA};
            $objct++;
            $pages=$obj[2]->{DATA};
            Put("%PDF-1.$PDFver\n\x25\xe2\xe3\xcf\xd3\n");
        }
    }
    elsif ($xcmd eq 'X')
    {
        # There could be extended args
        do
        {{
            LoadAhead(1);
            if (substr($ahead[0],0,1) eq '+')
            {
                $l.="\n".substr($ahead[0],1);
                shift(@ahead);
            }
        }} until $#ahead==0;

        ($xcmd,@xprm)=split(' ',$l);
        $xcmd=substr($xcmd,0,1);

        if ($xprm[0]=~m/^(.+:)(.+)/)
        {
            splice(@xprm,1,0,$2);
            $xprm[0]=$1;
        }

        my $par=join(' ',@xprm[1..$#xprm]);

        if ($xprm[0] eq 'ps:')
        {
            if ($xprm[1] eq 'invis')
            {
                $suppress=1;
            }
            elsif ($xprm[1] eq 'endinvis')
            {
                $suppress=0;
            }
            elsif ($par=~m/exec gsave currentpoint 2 copy translate (.+) rotate neg exch neg exch translate/)
            {
                # This is added by gpic to rotate a single object

                my $theta=-rad($1);

                IsGraphic();
                my ($curangle,$hyp)=RtoP($xpos,GraphY($ypos));
                my ($x,$y)=PtoR($theta+$curangle,$hyp);
                my ($tx, $ty) = ($xpos - $x, GraphY($ypos) - $y);
                if ($frot) {
                    ($tx, $ty) = ($tx *  sin($theta) + $ty * -cos($theta),
                                  $tx * -cos($theta) + $ty * -sin($theta));
                }
                $stream.="q\n".sprintf("%.3f %.3f %.3f %.3f %.3f %.3f cm",cos($theta),sin($theta),-sin($theta),cos($theta),$tx,$ty)."\n";
                $InPicRotate=1;
            }
            elsif ($par=~m/exec grestore/ and $InPicRotate)
            {
                IsGraphic();
                $stream.="Q\n";
                $InPicRotate=0;
            }
            elsif ($par=~m/exec.*? (\d) setlinejoin/)
            {
                IsGraphic();
                $linejoin=$1;
                $stream.="$linejoin j\n";
            }
            if ($par=~m/exec.*? (\d) setlinecap/)
            {
                IsGraphic();
                $linecap=$1;
                $stream.="$linecap J\n";
            }
            elsif ($par=~m/exec %%%%PAUSE/i and !$noslide)
            {
                my $trans='BLOCK';

                if ($firstpause)
                {
                    $trans='PAGE';
                    $firstpause=0;
                }
                MakeXO();
                NewPage($trans);
                $present=1;
            }
            elsif ($par=~m/exec %%%%BEGINONCE/)
            {
                if ($noslide)
                {
                    $suppress=1;
                }
                else
                {
                    my $trans='BLOCK';

                    if ($firstpause)
                    {
                        $trans='PAGE';
                        $firstpause=0;
                    }
                    MakeXO();
                    NewPage($trans);
                    $present=1;
                }
            }
            elsif ($par=~m/exec %%%%ENDONCE/)
            {
                if ($noslide)
                {
                    $suppress=0;
                }
                else
                {
                    MakeXO();
                    NewPage('BLOCK');
                    $present=1;
                    pop(@XOstream);
                }
            }
            elsif ($par=~m/\[(.+) pdfmark/)
            {
                my $pdfmark=$1;
                $pdfmark=~s((\d{4,6}) u)(sprintf("%.1f",$1/$desc{sizescale}))eg;
                $pdfmark=~s(\\\[u00(..)\])(chr(hex($1)))eg;
                $pdfmark=~s/\\n/\n/g;

                if ($pdfmark=~m/(.+) \/DOCINFO\s*$/s)
                {
                    my @xwds=split(/ /,"<< $1 >>");
                    my $docinfo=ParsePDFValue(\@xwds);

                    foreach my $k (sort keys %{$docinfo})
                    {
                        $info{$k}='('.utf16(substr($docinfo->{$k},1,-1)).')' if $k ne 'Producer';
                    }
                }
                elsif ($pdfmark=~m/(.+) \/DOCVIEW\s*$/)
                {
                    my @xwds=split(' ',"<< $1 >>");
                    my $docview=ParsePDFValue(\@xwds);

                    foreach my $k (sort keys %{$docview})
                    {
                        $cat->{$k}=$docview->{$k} if !exists($cat->{$k});
                    }
                }
                elsif ($pdfmark=~m/(.+) \/DEST\s*$/)
                {
                    my @xwds=split(' ',"<< $1 >>");
                    my $dest=ParsePDFValue(\@xwds);
		    $dest->{Dest}=UTFName($dest->{Dest});
                    $dest->{View}->[1]=GraphY($dest->{View}->[1]*-1);
                    unshift(@{$dest->{View}},"$cpageno 0 R");

                    if (!defined($dests))
                    {
                        $cat->{Dests}=BuildObj(++$objct,{});
                        $dests=$obj[$objct]->{DATA};
                    }

                    my $k=substr($dest->{Dest},1);
                    $dests->{$k}=$dest->{View};
                }
                elsif ($pdfmark=~m/(.+) \/ANN\s*$/)
                {
                    my $l=$1;
                    $l=~s/Color/C/;
                    $l=~s/Action/A/;
                    $l=~s/Title/T/;
                    $l=~s'/Subtype /URI'/S /URI';
                    my @xwds=split(' ',"<< $l >>");
                    my $annotno=BuildObj(++$objct,ParsePDFValue(\@xwds));
                    my $annot=$obj[$objct];
                    $annot->{DATA}->{Type}='/Annot';
                    FixRect($annot->{DATA}->{Rect}); # Y origin to ll
                    FixPDFColour($annot->{DATA});
		    $annot->{DATA}->{Dest}=UTFName($annot->{DATA}->{Dest}) if exists($annot->{DATA}->{Dest});
		    $annot->{DATA}->{A}->{URI}=URIName($annot->{DATA}->{A}->{URI}) if exists($annot->{DATA}->{A}->{URI});
                    push(@PageAnnots,$annotno);
                }
                elsif ($pdfmark=~m/(.+) \/OUT\s*$/)
                {
                    my $t=$1;
                    $t=~s/\\\) /\\\\\) /g;
                    $t=~s/\\e/\\\\/g;
                    $t=~m/(^.*\/Title \()(.*)(\).*)/;
                    my ($pre,$title,$post)=($1,$2,$3);
                    $title=utf16($title);

                    my @xwds=split(' ',"<< $pre$title$post >>");
                    my $out=ParsePDFValue(\@xwds);
		    $out->{Dest}=UTFName($out->{Dest});

                    my $this=[$out,[]];

                    if (exists($out->{Level}))
                    {
                        my $lev=abs($out->{Level});
                        my $levsgn=sgn($out->{Level});
                        delete($out->{Level});

                        if ($lev > $thislev)
                        {
                            my $thisoutlev=$curoutlev->[$#{$curoutlev}]->[1];
                            $thisoutlev->[0]=[0,$curoutlev,0,$levsgn];
                            $curoutlev=$thisoutlev;
                            $curoutlevno=$#{$curoutlev};
                            $thislev++;
                        }
                        elsif ($lev < $thislev)
                        {
                            my $openct=$curoutlev->[0]->[2];

                            while ($thislev > $lev)
                            {
                                my $nxtoutlev=$curoutlev->[0]->[1];
                                $nxtoutlev->[0]->[2]+=$openct if $curoutlev->[0]->[3]==1;
                                $openct=0 if $nxtoutlev->[0]->[3]==-1;
                                $curoutlev=$nxtoutlev;
                                $thislev--;
                            }

                            $curoutlevno=$#{$curoutlev};
                        }

                        #                       push(@{$curoutlev},$this);
                        splice(@{$curoutlev},++$curoutlevno,0,$this);
                        $curoutlev->[0]->[2]++;
                    }
                    else
                    {
                        # This code supports old pdfmark.tmac, unused by pdf.tmac
                        while ($curoutlev->[0]->[0] == 0 and defined($curoutlev->[0]->[1]))
                        {
                            $curoutlev=$curoutlev->[0]->[1];
                        }

                        $curoutlev->[0]->[0]--;
                        $curoutlev->[0]->[2]++;
                        push(@{$curoutlev},$this);


                        if (exists($out->{Count}) and $out->{Count} != 0)
                        {
                            push(@{$this->[1]},[abs($out->{Count}),$curoutlev,0,sgn($out->{Count})]);
                            $curoutlev=$this->[1];

                            if ($out->{Count} > 0)
                            {
                                my $p=$curoutlev;

                                while (defined($p))
                                {
                                    $p->[0]->[2]+=$out->{Count};
                                    $p=$p->[0]->[1];
                                }
                            }
                        }
                    }
                }
            }
        }
        elsif (lc($xprm[0]) eq 'pdf:')
        {
            if (lc($xprm[1]) eq 'import')
            {
                my $fil=$xprm[2];
                my $llx=$xprm[3];
                my $lly=$xprm[4];
                my $urx=$xprm[5];
                my $ury=$xprm[6];
                my $wid=GetPoints($xprm[7]);
                my $hgt=GetPoints($xprm[8])||-1;
                my $mat=[1,0,0,1,0,0];

                if (!exists($incfil{$fil}))
                {
                    if ($fil=~m/\.pdf$/)
                    {
                        $incfil{$fil}=LoadPDF($fil,$mat,$wid,$hgt,"import");
                    }
                    elsif ($fil=~m/\.swf$/)
                    {
                        my $xscale=$wid/($urx-$llx+1);
                        my $yscale=($hgt<=0)?$xscale:($hgt/($ury-$lly+1));
                        $hgt=($ury-$lly+1)*$yscale;

                        if ($rot)
                        {
                            $mat->[3]=$xscale;
                            $mat->[0]=$yscale;
                        }
                        else
                        {
                            $mat->[0]=$xscale;
                            $mat->[3]=$yscale;
                        }

                        $incfil{$fil}=LoadSWF($fil,[$llx,$lly,$urx,$ury],$mat);
                    }
                    else
                    {
                        Warn("unrecognized 'import' file type '$fil'");
                        return undef;
                    }
                }

                if (defined($incfil{$fil}))
                {
                    IsGraphic();
                    if ($fil=~m/\.pdf$/)
                    {
                        my $bbox=$incfil{$fil}->[1];
                        my $xscale=d3($wid/($bbox->[2]-$bbox->[0]+1));
                        my $yscale=d3(($hgt<=0)?$xscale:($hgt/($bbox->[3]-$bbox->[1]+1)));
                        $wid=($bbox->[2]-$bbox->[0])*$xscale;
                        $hgt=($bbox->[3]-$bbox->[1])*$yscale;
                        $ypos+=$hgt;
                        $stream.="q $xscale 0 0 $yscale ".PutXY($xpos,$ypos)." cm";
                        $stream.=" 0 1 -1 0 0 0 cm" if $rot;
                        $stream.=" /$incfil{$fil}->[0] Do Q\n";
                    }
                    elsif ($fil=~m/\.swf$/)
                    {
                        $stream.=PutXY($xpos,$ypos)." m /$incfil{$fil} Do\n";
                    }
                }
            }
            elsif (lc($xprm[1]) eq 'pdfpic')
            {
                my $fil=$xprm[2];
                my $flag=uc($xprm[3]||'-L');
                my $wid=GetPoints($xprm[4])||-1;
                my $hgt=GetPoints($xprm[5]||-1);
                my $ll=GetPoints($xprm[6]||0);
                my $mat=[1,0,0,1,0,0];

                if (!exists($incfil{$fil}))
                {
                    $incfil{$fil}=LoadPDF($fil,$mat,$wid,$hgt,"pdfpic");
                }

                if (defined($incfil{$fil}))
                {
                    IsGraphic();
                    my $bbox=$incfil{$fil}->[1];
                    $wid=($bbox->[2]-$bbox->[0]) if $wid <= 0;
                    my $xscale=d3($wid/($bbox->[2]-$bbox->[0]));
                    my $yscale=d3(($hgt<=0)?$xscale:($hgt/($bbox->[3]-$bbox->[1])));
                    $xscale=($wid<=0)?$yscale:$xscale;
                    $xscale=$yscale if $yscale < $xscale;
                    $yscale=$xscale if $xscale < $yscale;
                    $wid=($bbox->[2]-$bbox->[0])*$xscale;
                    $hgt=($bbox->[3]-$bbox->[1])*$yscale;

                    if ($flag eq '-C' and $ll > $wid)
                    {
                        $xpos+=int(($ll-$wid)/2);
                    }
                    elsif ($flag eq '-R' and $ll > $wid)
                    {
                        $xpos+=$ll-$wid;
                    }

                    $ypos+=$hgt;
                    $stream.="q $xscale 0 0 $yscale ".PutXY($xpos,$ypos)." cm";
                    $stream.=" 0 1 -1 0 0 0 cm" if $rot;
                    $stream.=" /$incfil{$fil}->[0] Do Q\n";
                }
            }
            elsif (lc($xprm[1]) eq 'xrev')
            {
                $xrev=!$xrev;
            }
            elsif (lc($xprm[1]) eq 'markstart')
            {
                $mark={'rst' => ($xprm[2]+$xprm[4])/$unitwidth, 'rsb' => ($xprm[3]-$xprm[4])/$unitwidth, 'xpos' => $xpos-($xprm[4]/$unitwidth),
                    'ypos' => $ypos, 'lead' => $xprm[4]/$unitwidth, 'pdfmark' => join(' ',@xprm[5..$#xprm])};
            }
            elsif (lc($xprm[1]) eq 'markend')
            {
                PutHotSpot($xpos) if defined($mark);
                $mark=undef;
            }
            elsif (lc($xprm[1]) eq 'marksuspend')
            {
                $suspendmark=$mark;
                $mark=undef;
            }
            elsif (lc($xprm[1]) eq 'markrestart')
            {
                $mark=$suspendmark;
                $suspendmark=undef;
            }
            elsif (lc($xprm[1]) eq 'pagename')
            {
                if ($pginsert > -1)
                {
                    $pgnames{$xprm[2]}=$pages->{Kids}->[$pginsert];
                }
                else
                {
                    $pgnames{$xprm[2]}='top';
                }
            }
            elsif (lc($xprm[1]) eq 'switchtopage')
            {
                my $ba=$xprm[2];
                my $want=$xprm[3];

                if ($pginsert > -1)
                {
                    if (!defined($want) or $want eq '')
                    {
                        # no before/after
                        $want=$ba;
                        $ba='before';
                    }

                    if (!defined($ba) or $ba eq '' or $want eq 'bottom')
                    {
                        $pginsert=$#{$pages->{Kids}};
                    }
                    elsif ($want eq 'top')
                    {
                        $pginsert=-1;
                    }
                    else
                    {
                        if (exists($pgnames{$want}))
                        {
                            my $ref=$pgnames{$want};

                            if ($ref eq 'top')
                            {
                                $pginsert=-1;
                            }
                            else
                            {
                                FIND: while (1)
                                {
                                    foreach my $j (0..$#{$pages->{Kids}})
                                    {
                                        if ($ref eq $pages->{Kids}->[$j])
                                        {
                                            if ($ba eq 'before')
                                            {
                                                $pginsert=$j-1;
                                                last FIND;
                                            }
                                            elsif ($ba eq 'after')
                                            {
                                                $pginsert=$j;
                                                last FIND;
                                            }
                                            else
                                            {
                                                # XXX: indentation wince
                                                Warn(
                                                    "expected 'switchtopage' parameter to be one of"
                                                    . "'top|bottom|before|after', got '$ba'");
                                                last FIND;
                                            }
                                        }

                                    }

                                    Warn("cannot find page ref '$ref'");
                                    last FIND

                                }
                            }
                        }
                        else
                        {
                            Warn("cannot find page named '$want'");
                        }
                    }

                    if ($pginsert < 0)
                    {
                        ($curoutlev,$curoutlevno,$thislev)=(\@outlev,0,1);
                    }
                    else
                    {
                        ($curoutlev,$curoutlevno,$thislev)=(@{$outlines[$pginsert]});
                        $curoutlevno--;
                    }
                }
            }
            elsif (lc($xprm[1]) eq 'transition' and !$noslide)
            {
                if (uc($xprm[2]) eq 'PAGE' or uc($xprm[2] eq 'SLIDE'))
                {
                    $transition->{PAGE}->{S}='/'.ucfirst($xprm[3]) if $xprm[3] and $xprm[3] ne '.';
                    $transition->{PAGE}->{D}=$xprm[4] if $xprm[4] and $xprm[4] ne '.';
                    $transition->{PAGE}->{Dm}='/'.$xprm[5] if $xprm[5] and $xprm[5] ne '.';
                    $transition->{PAGE}->{M}='/'.$xprm[6] if $xprm[6] and $xprm[6] ne '.';
                    $xprm[7]='/None' if $xprm[7] and uc($xprm[7]) eq 'NONE';
                    $transition->{PAGE}->{Di}=$xprm[7] if $xprm[7] and $xprm[7] ne '.';
                    $transition->{PAGE}->{SS}=$xprm[8] if $xprm[8] and $xprm[8] ne '.';
                    $transition->{PAGE}->{B}=$xprm[9] if $xprm[9] and $xprm[9] ne '.';
                }
                elsif (uc($xprm[2]) eq 'BLOCK')
                {
                    $transition->{BLOCK}->{S}='/'.ucfirst($xprm[3]) if $xprm[3] and $xprm[3] ne '.';
                    $transition->{BLOCK}->{D}=$xprm[4] if $xprm[4] and $xprm[4] ne '.';
                    $transition->{BLOCK}->{Dm}='/'.$xprm[5] if $xprm[5] and $xprm[5] ne '.';
                    $transition->{BLOCK}->{M}='/'.$xprm[6] if $xprm[6] and $xprm[6] ne '.';
                    $xprm[7]='/None' if $xprm[7] and uc($xprm[7]) eq 'NONE';
                    $transition->{BLOCK}->{Di}=$xprm[7] if $xprm[7] and $xprm[7] ne '.';
                    $transition->{BLOCK}->{SS}=$xprm[8] if $xprm[8] and $xprm[8] ne '.';
                    $transition->{BLOCK}->{B}=$xprm[9] if $xprm[9] and $xprm[9] ne '.';
                }

                $present=1;
            }
            elsif (lc($xprm[1]) eq 'background')
            {
                splice(@xprm,0,2);
                my $type=shift(@xprm);
                #               print STDERR "ypos=$ypos\n";

                if (lc($type) eq 'off')
                {
                    my $sptr=$#bgstack;
                    if ($sptr > -1)
                    {
                        if ($sptr == 0 and $bgstack[0]->[0] & 4)
                        {
                            pop(@bgstack);
                        }
                        else
                        {
                            $bgstack[$sptr]->[5]=GraphY($ypos);
                            $bgbox=DrawBox(pop(@bgstack)).$bgbox;
                        }
                    }
                }
                elsif (lc($type) eq 'footnote')
                {
                    my $t=GetPoints($xprm[0]);
                    $boxmax=($t<0)?abs($t):GraphY($t);
                }
                else
                {
                    my $bgtype=0;

                    foreach (@xprm)
                    {
                        $_=GetPoints($_);
                    }

                    $bgtype|=2 if $type=~m/box/i;
                    $bgtype|=1 if $type=~m/fill/i;
                    $bgtype|=4 if $type=~m/page/i;
                    $bgtype=5 if $bgtype==4;
                    my $bgwt=$xprm[4];
                    $bgwt=$xprm[0] if !defined($bgwt) and $#xprm == 0;
                    my (@bg)=(@xprm);
                    my $bg=\@bg;

                    if (!defined($bg[3]) or $bgtype & 4)
                    {
                        $bg=undef;
                    }
                    else
                    {
                        FixRect($bg);
                    }

                    if ($bgtype)
                    {
                        if ($bgtype & 4)
                        {
                            shift(@bgstack) if $#bgstack >= 0 and $bgstack[0]->[0] & 4;
                            unshift(@bgstack,[$bgtype,$strkcol,$fillcol,$bg,GraphY($ypos),GraphY($bg[3]||0),$bgwt || 0.4]);
                        }
                        else
                        {
                            push(@bgstack,[$bgtype,$strkcol,$fillcol,$bg,GraphY($ypos),GraphY($bg[3]||0),$bgwt || 0.4]);
                        }
                    }
                }
            }
            elsif (lc($xprm[1]) eq 'pagenumbering')
            {
                # 2=type of [D=decimal,R=Roman,r=roman,A=Alpha (uppercase),a=alpha (lowercase)
                # 3=prefix label
                # 4=start number

                my ($S,$P,$St);

                $xprm[2]='' if !$xprm[2] or $xprm[2] eq '.';
                $xprm[3]='' if defined($xprm[3]) and $xprm[3] eq '.';

                if ($xprm[2] and index('DRrAa',substr($xprm[2],0,1)) == -1)
                {
                    Warn("Page numbering type '$xprm[2]' is not recognised");
                }
                else
                {
                    $S=substr($xprm[2],0,1) if $xprm[2];
                    $P=$xprm[3];
                    $St=$xprm[4] if length($xprm[4]);

                    if (!defined($S) and !length($P))
                    {
                        $P=' ';
                    }

                    if ($St and $St!~m/^-?\d+$/)
                    {
                        Warn("Page numbering start '$St' must be numeric");
                        return;
                    }

                    $cat->{PageLabels}={Nums => []} if !exists($cat->{PageLabels});

                    my $label={};
                    $label->{S} = "/$S" if $S;
                    $label->{P} = "($P)" if length($P);
                    $label->{St} = $St if length($St);

                    $#PageLabel=$pginsert if $pginsert > $#PageLabel;
                    splice(@PageLabel,$pginsert,0,$label);
                }
            }

        }
        elsif (lc(substr($xprm[0],0,9)) eq 'papersize')
        {
            if (!($xprm[1] and $xprm[1] eq 'tmac' and $fpsz))
            {
                my ($px,$py)=split(',',substr($xprm[0],10));
                $px=GetPoints($px);
                $py=GetPoints($py);
                @mediabox=(0,0,$px,$py);
                my @mb=@mediabox;
                $matrixchg=1;
                $custompaper=1;
                $cpage->{MediaBox}=\@mb;
            }
        }
    }
}

sub URIName
{
    my $s=shift;

    $s=Clean($s);
    $s=~s/\\\[u((?i)D[89AB]\p{AHex}{2})\] # High surrogate in range 0xD800–0xDBFF
              \\\[u((?i)D[CDEF]\p{AHex}{2})\] #  Low surrogate in range 0xDC00–0xDFFF
             /chr( ((hex($1) - 0xD800) * 0x400) + (hex($2) - 0xDC00) + 0x10000 )/xge;
    $s=~s/\\\[u(\p{AHex}{4})]/chr hex $1/ge;

    return(join '', map {(m/[-\w.~_]/)?chr($_):'%'.sprintf("%02X", $_)} unpack "C*", encode('utf8',$s));
}

sub Clean
{
    my $p=shift;

    $p=~s/\\c?$//g;
    $p=~s/\\[eE]/\\/g;
    $p=~s/\\[ 0~t]/ /g;
    $p=~s/\\[,!"#\$%&’.0:?{}ˆ_‘|^prud]//g;
    $p=~s/\\'/\\[aa]/g;
    $p=~s/\\`/\\[ga]/g;
    $p=~s/\\_/\\[ul]/g;
    $p=~s/\\-/-/g;

    $p=~s/\\[Oz].//g;
    $p=~s/\\[ABbDHlLoRSvwXZ]$parcln//g;
    $p=~s/\\[hs][-+]?$parclntyp//g;
    $p=~s/\\[FfgkMmnVY]$parclntyp//g;

    $p=~s/\\\((\w\w)/\\\[$1\]/g;        # convert \(xx to \[xx]

    return $p;
}

sub utf16
{
    my $p=Clean(shift);

    $p=~s/\\\[(.*?)\]/FindChr($1,0)/eg;
    $p=~s/\\C($parcln)/FindChr($1,1)/eg;
#     $p=~s/\\\((..)/FindChr($1)/eg;
    $p=~s/\\N($parcln)/FindChr($1,1,1)/eg;

    if ($p =~ /[^[:ascii:]]/)
    {
        $p = join '', map sprintf("\\%o", $_),
            unpack "C*", encode('utf16', $p);
    }

    $p=~s/(?<!\\)\(/\\\(/g;
    $p=~s/(?<!\\)\)/\\\)/g;

    return($p);
}

sub FindChr
{
    my $ch=shift;
    my $subsflg=shift;
    my $cn=shift;

    return('') if !defined($ch);
    $ch=substr($ch,1,-1) if $subsflg;
    $ch=$thisfnt->{NO}->[$ch] if defined($cn);
    return('') if !defined($ch);
    return pack('U',hex($1)) if $ch=~m/^u([0-9A-F]{4,5})$/;

    if (exists($thisfnt->{NAM}->{$ch}))
    {
        if ($thisfnt->{NAM}->{$ch}->[PSNAME]=~m/\\u(?:ni)?([0-9A-F]{4,5})/)
        {
            return pack('U',hex($1));
        }
        elsif (defined($thisfnt->{NAM}->{$ch}->[UNICODE]))
        {
            return pack('U',hex($thisfnt->{NAM}->{$ch}->[UNICODE]))
        }
    }
    elsif ($ch=~m/^\w+$/)       # ligature not in font i.e. \(ff
    {
        return $ch;
    }

    Warn("Can't convert '$ch' to unicode");

    return('');
}

sub UTFName
{
    my $s=shift;
    my $r='';

    $s=substr($s,1);
    return '/'.join '', map { MakeLabel($_) } unpack('C*',$s);

}

sub MakeLabel
{
    my $c=chr(shift);
    return($c) if $c=~m/[\w:]/;
    return(sprintf("#%02x",ord($c)));
}

sub FixPDFColour
{
    my $o=shift;
    my $a=$o->{C};
    my @r=();
    my $c=$a->[0];

    if ($#{$a}==3)
    {
        if ($c > 1)
        {
            foreach my $j (0..2)
            {
                push(@r,sprintf("%1.3f",$a->[$j]/0xffff));
            }

            $o->{C}=\@r;
        }
    }
    elsif (substr($c,0,1) eq '#')
    {
        if (length($c) == 7)
        {
            foreach my $j (0..2)
            {
                push(@r,sprintf("%1.3f",hex(substr($c,$j*2+1,2))/0xff));
            }

            $o->{C}=\@r;
        }
        elsif (length($c) == 14)
        {
            foreach my $j (0..2)
            {
                push(@r,sprintf("%1.3f",hex(substr($c,$j*4+2,4))/0xffff));
            }

            $o->{C}=\@r;
        }
    }
}

sub PutHotSpot
{
    my $endx=shift;
    my $l=$mark->{pdfmark};
    $l=~s/Color/C/;
    $l=~s/Action/A/;
    $l=~s'/Subtype /URI'/S /URI';
    $l=~s(\\\[u00(..)\])(chr(hex($1)))eg;
    my @xwds=split(' ',"<< $l >>");
    my $annotno=BuildObj(++$objct,ParsePDFValue(\@xwds));
    my $annot=$obj[$objct];
    $annot->{DATA}->{Type}='/Annot';
    $annot->{DATA}->{Rect}=[$mark->{xpos},$mark->{ypos}-$mark->{rsb},$endx+$mark->{lead},$mark->{ypos}-$mark->{rst}];
    FixPDFColour($annot->{DATA});
    FixRect($annot->{DATA}->{Rect}); # Y origin to ll
    $annot->{DATA}->{Dest}=UTFName($annot->{DATA}->{Dest}) if exists($annot->{DATA}->{Dest});
    $annot->{DATA}->{A}->{URI}=URIName($annot->{DATA}->{A}->{URI}) if exists($annot->{DATA}->{A});
    push(@PageAnnots,$annotno);
}

sub sgn
{
    return(1) if $_[0] > 0;
    return(-1) if $_[0] < 0;
    return(0);
}

sub FixRect
{
    my $rect=shift;

    return if !defined($rect);
    $rect->[1]=GraphY($rect->[1]);
    $rect->[3]=GraphY($rect->[3]);

    if ($rot)
    {
        ($rect->[0],$rect->[1])=Rotate($rect->[0],$rect->[1]);
        ($rect->[2],$rect->[3])=Rotate($rect->[2],$rect->[3]);
    }
}

sub Rotate
{
    my ($tx,$ty)=(@_);
    my $theta=rad($rot);

    ($tx,$ty)=(d3($tx * cos(-$theta) - $ty * sin(-$theta)),
               d3($tx * sin( $theta) + $ty * cos( $theta)));
    return($tx,$ty);
}

sub GetPoints
{
    my $val=shift;

    $val=ToPoints($1,$2) if ($val and $val=~m/(-?[\d.]+)([cipnz])/);

    return $val;
}

# Although the PDF reference mentions XObject/Form as a way of
# incorporating an external PDF page into the current PDF, it seems not
# to work with any current PDF reader (although I am told (by Leonard
# Rosenthol, who helped author the PDF ISO standard) that Acroread 9
# does support it, empirical observation shows otherwise!!).  So... do
# it the hard way - full PDF parser and merge required objects!!!

# sub BuildRef
# {
#       my $fil=shift;
#       my $bbox=shift;
#       my $mat=shift;
#       my $wid=($bbox->[2]-$bbox->[0])*$mat->[0];
#       my $hgt=($bbox->[3]-$bbox->[1])*$mat->[3];
#
#       if (!open(PDF,"<$fil"))
#       {
#               Warn("failed to open '$fil'");
#               return(undef);
#       }
#
#       my (@f)=(<PDF>);
#
#       close(PDF);
#
#       $objct++;
#       my $xonm="XO$objct";
#
#       $pages->{'Resources'}->{'XObject'}->{$xonm}=BuildObj($objct,{'Type' => '/XObject',
#                                                                   'Subtype' => '/Form',
#                                                                   'BBox' => $bbox,
#                                                                   'Matrix' => $mat,
#                                                                   'Resources' => $pages->{'Resources'},
#                                                                   'Ref' => {'Page' => '1',
#                                                                               'F' => BuildObj($objct+1,{'Type' => '/Filespec',
#                                                                                                         'F' => "($fil)",
#                                                                                                         'EF' => {'F' => BuildObj($objct+2,{'Type' => '/EmbeddedFile'})}
#                                                                               })
#                                                                   }
#                                                               });
#
#       $obj[$objct]->{STREAM}="q 1 0 0 1 0 0 cm
# q BT
# 1 0 0 1 0 0 Tm
# .5 g .5 G
# /F5 20 Tf
# (Proxy) Tj
# ET Q
# 0 0 m 72 0 l s
# Q\n";
#
# #     $obj[$objct]->{STREAM}=PutXY($xpos,$ypos)." m ".PutXY($xpos+$wid,$ypos)." l ".PutXY($xpos+$wid,$ypos+$hgt)." l ".PutXY($xpos,$ypos+$hgt)." l f\n";
#       $obj[$objct+2]->{STREAM}=join('',@f);
#       PutObj($objct);
#       PutObj($objct+1);
#       PutObj($objct+2);
#       $objct+=2;
#       return($xonm);
# }

sub LoadSWF
{
    my $fil=shift;
    my $bbox=shift;
    my $mat=shift;
    my $wid=($bbox->[2]-$bbox->[0])*$mat->[0];
    my $hgt=($bbox->[3]-$bbox->[1])*$mat->[3];
    my (@path)=split('/',$fil);
    my $node=pop(@path);

    if (!open(PDF,"<$fil"))
    {
        Warn("failed to open SWF '$fil'");
        return(undef);
    }

    my (@f)=(<PDF>);

    close(PDF);

    $objct++;
    my $xonm="XO$objct";

    $pages->{'Resources'}->{'XObject'}->{$xonm}=BuildObj($objct,{'Type' => '/XObject', 'BBox' => $bbox, 'Matrix' => $mat, 'FormType' => 1, 'Subtype' => '/Form', 'Length' => 0, 'Type' => "/XObject"});
    $obj[$objct]->{STREAM}='';
    PutObj($objct);
    $objct++;
    my $asset=BuildObj($objct,{'EF' => {'F' => BuildObj($objct+1,{})},
                       'F' => "($node)",
                       'Type' => '/Filespec',
                       'UF' => "($node)"});

    PutObj($objct);
    $objct++;
    $obj[$objct]->{STREAM}=join('',@f);
    PutObj($objct);
    $objct++;
    my $config=BuildObj($objct,{'Instances' => [BuildObj($objct+1,{'Params' => { 'Binding' => '/Background'}, 'Asset' => $asset})],
                        'Subtype' => '/Flash'});

    PutObj($objct);
    $objct++;
    PutObj($objct);
    $objct++;

    my ($x,$y)=split(' ',PutXY($xpos,$ypos));

    push(@{$cpage->{Annots}},BuildObj($objct,{'RichMediaContent' => {'Subtype' => '/Flash', 'Configurations' => [$config], 'Assets' => {'Names' => [ "($node)", $asset ] }},
                                      'P' => "$cpageno 0 R",
                                      'RichMediaSettings' => { 'Deactivation' => { 'Condition' => '/PI',
                                          'Type' => '/RichMediaDeactivation'},
                                      'Activation' => { 'Condition' => '/PV',
                                          'Type' => '/RichMediaActivation'}},
                                      'F' => 68,
                                      'Subtype' => '/RichMedia',
                                      'Type' => '/Annot',
                                      'Rect' => "[ $x $y ".($x+$wid)." ".($y+$hgt)." ]",
                                      'Border' => [0,0,0]}));

    PutObj($objct);

    return $xonm;
}

sub OpenInc
{
    my $fn=shift;
    my $fnm=$fn;
    my $F;

    if (substr($fnm,0,1)  eq '/' or substr($fnm,1,1) eq ':') # dos
    {
        if (-r $fnm and open($F,"<$fnm"))
        {
            return($F,$fnm);
        }
    }
    else
    {
        foreach my $dir (@idirs)
        {
            $fnm="$dir/$fn";

            if (-r "$fnm" and open($F,"<$fnm"))
            {
                return($F,$fnm);
            }
        }
    }

    return(undef,$fn);
}

sub LoadPDF
{
    my $pdfnm=shift;
    my $mat=shift;
    my $wid=shift;
    my $hgt=shift;
    my $type=shift;
    my $pdf;
    my $pdftxt='';
    my $strmlen=0;
    my $curobj=-1;
    my $instream=0;
    my $cont;
    my $adj=0;
    my $keepsep=$/;

    my ($PD,$PDnm)=OpenInc($pdfnm);

    if (!defined($PD))
    {
        Warn("failed to open PDF '$pdfnm'");
        return undef;
    }

    my $hdr=<$PD>;

    $/="\r",$adj=1 if (length($hdr) > 10);

    while (<$PD>)
    {
        chomp;

        s/\n//;

        if (m/endstream(\s+.*)?$/)
        {
            $instream=0;
            $_="endstream";
            $_.=$1 if defined($1)
        }

        next if $instream;

        if (m'/Length\s+(\d+)(\s+\d+\s+R)?')
        {
            if (!defined($2))
            {
                $strmlen=$1;
            }
            else
            {
                $strmlen=0;
            }
        }

        if (m'^(\d+) \d+ obj')
        {
            $curobj=$1;
            $pdf->[$curobj]->{OBJ}=undef;
        }

        if (m'stream\s*$' and ! m/^endstream/)
        {
            if ($curobj > -1)
            {
                $pdf->[$curobj]->{STREAMPOS}=[tell($PD)+$adj,$strmlen];
                seek($PD,$strmlen,1);
                $instream=1;
            }
            else
            {
                Warn("parsing PDF '$pdfnm' failed");
                return undef;
            }
        }

        s/%.*?$//;
        $pdftxt.=$_.' ';
    }

    close($PD);

    open(PD,"<$PDnm");
    #   $pdftxt=~s/\]/ \]/g;
    my (@pdfwds)=split(' ',$pdftxt);
    my $wd;
    my $root;

    while ($wd=nextwd(\@pdfwds),length($wd))
    {
        if ($wd=~m/\d+/ and defined($pdfwds[1]) and $pdfwds[1]=~m/^obj(.*)/)
        {
            $curobj=$wd;
            shift(@pdfwds); shift(@pdfwds);
            unshift(@pdfwds,$1) if defined($1) and length($1);
            $pdf->[$curobj]->{OBJ}=ParsePDFObj(\@pdfwds);
            my $o=$pdf->[$curobj];

            if (ref($o->{OBJ}) eq 'HASH' and exists($o->{OBJ}->{Type}) and $o->{OBJ}->{Type} eq '/ObjStm')
            {
                LoadStream($o,$pdf);
                my $pos=$o->{OBJ}->{First};
                my $s=$o->{STREAM};
                my @o=split(' ',substr($s,0,$pos));
                substr($s,0,$pos)='';
                push(@o,-1,length($s));

                for (my $j=0; $j<=$#o-2; $j+=2)
                {
                    my @w=split(' ',substr($s,$o[$j+1],$o[$j+3]-$o[$j+1]));
                    $pdf->[$o[$j]]->{OBJ}=ParsePDFObj(\@w);
                }

                $pdf->[$curobj]=undef;
            }

            $root=$curobj if ref($pdf->[$curobj]->{OBJ}) eq 'HASH' and exists($pdf->[$curobj]->{OBJ}->{Type}) and $pdf->[$curobj]->{OBJ}->{Type} eq '/XRef';
        }
        elsif ($wd eq 'trailer' and !exists($pdf->[0]->{OBJ}))
        {
            $pdf->[0]->{OBJ}=ParsePDFObj(\@pdfwds);
        }
        else
        {
            #                   print "Skip '$wd'\n";
        }
    }

    $pdf->[0]=$pdf->[$root] if !defined($pdf->[0]);
    my $catalog=${$pdf->[0]->{OBJ}->{Root}};
    my $page=FindPage(1,$pdf);
    my $xobj=++$objct;

    # Load the streamas

    foreach my $o (@{$pdf})
    {
        if (exists($o->{STREAMPOS}) and !exists($o->{STREAM}))
        {
            LoadStream($o,$pdf);
        }
    }

    close(PD);

    # Find BBox
    my $BBox;
    my $insmap={};

    foreach my $k (qw( ArtBox TrimBox BleedBox CropBox MediaBox ))
    {
        $BBox=FindKey($pdf,$page,$k);
        last if $BBox;
    }

    $BBox=[0,0,595,842] if !defined($BBox);

    $wid=($BBox->[2]-$BBox->[0]+1) if $wid==0;
    my $xscale=d3(abs($wid)/($BBox->[2]-$BBox->[0]+1));
    my $yscale=d3(($hgt<=0)?$xscale:(abs($hgt)/($BBox->[3]-$BBox->[1]+1)));
    $hgt=($BBox->[3]-$BBox->[1]+1)*$yscale;

    if ($type eq "import")
    {
        $mat->[0]=$xscale;
        $mat->[3]=$yscale;
    }

    # Find Resource

    my $res=FindKey($pdf,$page,'Resources');
    my $xonm="XO$xobj";

    # Map inserted objects to current PDF

    MapInsValue($pdf,$page,'',$insmap,$xobj,$pdf->[$page]->{OBJ});
    #
    #   Many PDFs include 'Resources' at the 'Page' level but if 'Resources' is held at a higher level (i.e 'Pages')
    #   then we need to include its objects as well.
    #
    MapInsValue($pdf,$page,'',$insmap,$xobj,$res) if !exists($pdf->[$page]->{OBJ}->{Resources});

    # Copy Resources

    my %incres=%{$res};

    $incres{ProcSet}=['/PDF', '/Text', '/ImageB', '/ImageC', '/ImageI'];

    ($mat->[4],$mat->[5])=split(' ',PutXY($xpos,$ypos));
    $pages->{'Resources'}->{'XObject'}->{$xonm}=BuildObj($xobj,{'Type' => '/XObject', 'BBox' => $BBox, 'Name' => "/$xonm", 'FormType' => 1, 'Subtype' => '/Form', 'Length' => 0, 'Type' => "/XObject", 'Resources' => \%incres});

    if ($BBox->[0] != 0 or $BBox->[1] != 0)
    {
        my (@matrix)=(1,0,0,1,-$BBox->[0],-$BBox->[1]);
        $obj[$xobj]->{DATA}->{Matrix}=\@matrix;
    }

    BuildStream($xobj,$pdf,$pdf->[$page]->{OBJ}->{Contents});

    $/=$keepsep;
    return([$xonm,$BBox] );
}

sub LoadStream
{
    my $o=shift;
    my $pdf=shift;
    my $l;

    $l=$o->{OBJ}->{Length} if exists($o->{OBJ}->{Length});

    $l=$pdf->[$$l]->{OBJ} if (defined($l) && ref($l) eq 'OBJREF');

    Die("unable to determine length of stream \@$o->{STREAMPOS}->[0]")
    if !defined($l);

    sysseek(PD,$o->{STREAMPOS}->[0],0);
    Warn("failed to read all of the stream")
    if $l != sysread(PD,$o->{STREAM},$l);

    if ($gotzlib and exists($o->{OBJ}->{'Filter'}) and $o->{OBJ}->{'Filter'} eq '/FlateDecode')
    {
        $o->{STREAM}=Compress::Zlib::uncompress($o->{STREAM});
        delete($o->{OBJ }->{'Filter'});
    }
}

sub BuildStream
{
    my $xobj=shift;
    my $pdf=shift;
    my $val=shift;
    my $strm='';
    my $objs;
    my $refval=ref($val);

    if ($refval eq 'OBJREF')
    {
        push(@{$objs}, $val);
    }
    elsif ($refval eq 'ARRAY')
    {
        $objs=$val;
    }
    else
    {
        Warn("unexpected 'Contents'");
    }

    foreach my $o (@{$objs})
    {
        $strm.="\n" if $strm;
        $strm.=$pdf->[$$o]->{STREAM} if exists($pdf->[$$o]->{STREAM});
    }

    $obj[$xobj]->{STREAM}=$strm;
}


sub MapInsHash
{
    my $pdf=shift;
    my $o=shift;
    my $insmap=shift;
    my $parent=shift;
    my $val=shift;


    foreach my $k (sort keys(%{$val}))
    {
        MapInsValue($pdf,$o,$k,$insmap,$parent,$val->{$k}) if $k ne 'Contents';
    }
}

sub MapInsValue
{
    my $pdf=shift;
    my $o=shift;
    my $k=shift;
    my $insmap=shift;
    my $parent=shift;
    my $val=shift;
    my $refval=ref($val);

    if ($refval eq 'OBJREF')
    {
        if ($k ne 'Parent')
        {
            if (!exists($insmap->{IMP}->{$$val}))
            {
                $objct++;
                $insmap->{CUR}->{$objct}=$$val;
                $insmap->{IMP}->{$$val}=$objct;
                $obj[$objct]->{DATA}=$pdf->[$$val]->{OBJ};
                $obj[$objct]->{STREAM}=$pdf->[$$val]->{STREAM} if exists($pdf->[$$val]->{STREAM});
                MapInsValue($pdf,$$val,'',$insmap,$o,$pdf->[$$val]->{OBJ});
            }

            $$val=$insmap->{IMP}->{$$val};
        }
        else
        {
            $$val=$parent;
        }
    }
    elsif ($refval eq 'ARRAY')
    {
        foreach my $v (@{$val})
        {
            MapInsValue($pdf,$o,'',$insmap,$parent,$v)
        }
    }
    elsif ($refval eq 'HASH')
    {
        MapInsHash($pdf,$o,$insmap,$parent,$val);
    }

}

sub FindKey
{
    my $pdf=shift;
    my $page=shift;
    my $k=shift;

    if (exists($pdf->[$page]->{OBJ}->{$k}))
    {
        my $val=$pdf->[$page]->{OBJ}->{$k};
        $val=$pdf->[$$val]->{OBJ} if ref($val) eq 'OBJREF';
        return($val);
    }
    else
    {
        if (exists($pdf->[$page]->{OBJ}->{Parent}))
        {
            return(FindKey($pdf,${$pdf->[$page]->{OBJ}->{Parent}},$k));
        }
    }

    return(undef);
}

sub FindPage
{
    my $wantpg=shift;
    my $pdf=shift;
    my $catalog=${$pdf->[0]->{OBJ}->{Root}};
    my $pages=${$pdf->[$catalog]->{OBJ}->{Pages}};

    return(NextPage($pdf,$pages,\$wantpg));
}

sub NextPage
{
    my $pdf=shift;
    my $pages=shift;
    my $wantpg=shift;
    my $ret;

    if ($pdf->[$pages]->{OBJ}->{Type} eq '/Pages')
    {
        foreach my $kid (@{$pdf->[$pages]->{OBJ}->{Kids}})
        {
            $ret=NextPage($pdf,$$kid,$wantpg);
            last if $$wantpg<=0;
        }
    }
    elsif ($pdf->[$pages]->{OBJ}->{Type} eq '/Page')
    {
        $$wantpg--;
        $ret=$pages;
    }

    return($ret);
}

sub nextwd
{
    my $pdfwds=shift;
    my $instring=shift || 0;

    my $wd=shift(@{$pdfwds});

    return('') if !defined($wd);
    return($wd) if $instring;

    if ($wd=~m/^(.*?)(<<|>>|(?:(?<!\\)\[|\]))(.*)/)
    {
        my ($p1,$p2,$p3)=($1,$2,$3);

        if (defined($p1) and length($p1))
        {
            if (!($p2 eq ']' and $p1=~m/\[/))
            {
                unshift(@{$pdfwds},$p3) if defined($p3) and length($p3);
                unshift(@{$pdfwds},$p2);
                $wd=$p1;
            }
        }
        else
        {
            unshift(@{$pdfwds},$p3) if defined($p3) and length($p3);
            $wd=$p2;
        }
    }

    return($wd);
}

sub ParsePDFObj
{

    my $pdfwds=shift;
    my $rtn;
    my $wd;

    while ($wd=nextwd($pdfwds),length($wd))
    {
        if ($wd eq 'stream' or $wd eq 'endstream')
        {
            next;
        }
        elsif ($wd eq 'endobj' or $wd eq 'startxref')
        {
            last;
        }
        else
        {
            unshift(@{$pdfwds},$wd);
            $rtn=ParsePDFValue($pdfwds);
        }
    }

    return($rtn);
}

sub ParsePDFHash
{
    my $pdfwds=shift;
    my $rtn={};
    my $wd;

    while ($wd=nextwd($pdfwds),length($wd))
    {
        if ($wd eq '>>')
        {
            last;
        }

        my (@w)=split('/',$wd,3);

        if ($w[0])
        {
            Warn("PDF Dict Key '$wd' does not start with '/'");
            exit 1;
        }
        else
        {
            unshift(@{$pdfwds},"/$w[2]") if $w[2];
            $wd=$w[1];
            (@w)=split('\(',$wd,2);
            $wd=$w[0];
            unshift(@{$pdfwds},"($w[1]") if defined($w[1]);
            (@w)=split('\<',$wd,2);
            $wd=$w[0];
            unshift(@{$pdfwds},"<$w[1]") if defined($w[1]);

            $rtn->{$wd}=ParsePDFValue($pdfwds);
        }
    }

    return($rtn);
}

sub ParsePDFValue
{
    my $pdfwds=shift;
    my $rtn;
    my $wd=nextwd($pdfwds);

    if ($wd=~m/^\d+$/ and $pdfwds->[0]=~m/^\d+$/ and $pdfwds->[1]=~m/^R(\]|\>|\/)?/)
    {
        shift(@{$pdfwds});
        if (defined($1) and length($1))
        {
            $pdfwds->[0]=substr($pdfwds->[0],1);
        }
        else
        {
            shift(@{$pdfwds});
        }
        return(bless(\$wd,'OBJREF'));
    }

    if ($wd eq '<<')
    {
        return(ParsePDFHash($pdfwds));
    }

    if ($wd eq '[')
    {
        return(ParsePDFArray($pdfwds));
    }

    if ($wd=~m/(.*?)(\(.*)$/)
    {
        if (defined($1) and length($1))
        {
            unshift(@{$pdfwds},$2);
            $wd=$1;
        }
        else
        {
            return(ParsePDFString($wd,$pdfwds));
        }
    }

    if ($wd=~m/(.*?)(\<.*)$/)
    {
        if (defined($1) and length($1))
        {
            unshift(@{$pdfwds},$2);
            $wd=$1;
        }
        else
        {
            return(ParsePDFHexString($wd,$pdfwds));
        }
    }

    if ($wd=~m/(.+?)(\/.*)$/)
    {
        if (defined($2) and length($2))
        {
            unshift(@{$pdfwds},$2);
            $wd=$1;
        }
    }

    return($wd);
}

sub ParsePDFString
{
    my $wd=shift;
    my $rtn='';
    my $pdfwds=shift;
    my $lev=0;

    while (length($wd))
    {
        $rtn.=' ' if length($rtn);

        while ($wd=~m/(?<!\\)\(/g) {$lev++;}
        while ($wd=~m/(?<!\\)\)/g) {$lev--;}


        if ($lev<=0 and $wd=~m/^(.*?\))([^)]+)$/)
            {
                unshift(@{$pdfwds},$2) if defined($2) and length($2);
                $wd=$1;
            }

            $rtn.=$wd;

        last if $lev <= 0;

        $wd=nextwd($pdfwds,1);
    }

    return($rtn);
}

sub ParsePDFHexString
{
    my $wd=shift;
    my $rtn='';
            my $pdfwds=shift;
            my $lev=0;

            if ($wd=~m/^(<.+?>)(.*)/)
            {
                unshift(@{$pdfwds},$2) if defined($2) and length($2);
                $rtn=$1;
            }

            return($rtn);
}

sub ParsePDFArray
{
    my $pdfwds=shift;
    my $rtn=[];
    my $wd;

    while (1)
    {
        $wd=ParsePDFValue($pdfwds);
        last if $wd eq ']' or length($wd)==0;
        push(@{$rtn},$wd);
    }

    return($rtn);
}

sub Warn
{
    Msg(0,(@_));
}

sub Die
{
    Msg(1,(@_));
}

sub Msg
{
    my ($fatal,$msg)=@_;

    print STDERR "$prog:";
    print STDERR "$env{SourceFile}:" if exists($env{SourceFile});
    print STDERR " ";

    if ($fatal)
    {
        print STDERR "fatal error: ";
    }
    else
    {
        print STDERR "warning: ";
    }

    print STDERR "$msg\n";
    exit 1 if $fatal;
}

sub PutXY
{
    my ($x,$y)=(@_);

    if ($frot)
    {
        return(d3($y)." ".d3($x));
    }
    else
    {
        $y=$mediabox[3]-$y;
        return(d3($x)." ".d3($y));
    }
}

sub GraphY
{
    my $y=shift;

    if ($frot)
    {
        return($y);
    }
    else
    {
        return($mediabox[3]-$y);
    }
}

sub Put
{
    my $msg=shift;

    print $msg;
    $fct+=length($msg);
}

my $thisono;
sub PutObj
{
    my $ono=shift;

    # $thisono is the object number being processed by PutField.  It is
    # used in the error message output when $fld is undef in
    # PutField. -- obuk

    $thisono = $ono;            # xxxxx
    my $inmem=shift;

    if ($inmem)
    {
        PutField($inmem,$obj[$ono]->{DATA});
        return;
    }

    my $msg="$ono 0 obj ";
    $obj[$ono]->{XREF}=$fct;
    if (exists($obj[$ono]->{STREAM}))
    {
        if ($gotzlib && ($options & COMPRESS) && !$debug && !exists($obj[$ono]->{DATA}->{'Filter'}))
        {
            $obj[$ono]->{STREAM}=Compress::Zlib::compress($obj[$ono]->{STREAM});
            $obj[$ono]->{DATA}->{'Filter'}='/FlateDecode';
        }

        $obj[$ono]->{DATA}->{'Length'}=length($obj[$ono]->{STREAM});
    }
    PutField(\$msg,$obj[$ono]->{DATA});
    PutStream(\$msg,$ono) if exists($obj[$ono]->{STREAM});
    $thisono = undef;
    Put($msg."endobj\n");
}

sub PutStream
{
    my $msg=shift;
    my $ono=shift;

    # We could 'flate' here
    $$msg.="stream\n$obj[$ono]->{STREAM}endstream\n";
}

sub PutField
{
    my $pmsg=shift;
    my $fld=shift;
    my $term=shift||"\n";
    my $typ=ref($fld);

    unless (defined $fld) {
        Warn("PutField: fld is undef; check '$thisono 0 obj'") unless defined $fld;
        return;
    }
    if ($typ eq '')
    {
        $$pmsg.="$fld$term";
    }
    elsif ($typ eq 'ARRAY')
    {
        $$pmsg.='[';
            foreach my $cell (@{$fld})
            {
                PutField($pmsg,$cell,' ');
            }
            $$pmsg.="]$term";
    }
    elsif ($typ eq 'HASH')
    {
        $$pmsg.='<< ';
            foreach my $key (sort keys %{$fld})
            {
                $$pmsg.="/$key ";
                PutField($pmsg,$fld->{$key});
            }
            $$pmsg.=">>$term";
    }
    elsif ($typ eq 'OBJREF')
    {
        $$pmsg.="$$fld 0 R$term";
    }
}

sub BuildObj
{
    my $ono=shift;
    my $val=shift;

    $obj[$ono]->{DATA}=$val;

    return("$ono 0 R ");
}

sub EmbedFont
{
    my $fontno=shift;
    my $fnt=shift;
    my $st=$objct;

    $fontlst{$fontno}->{OBJ}=BuildObj($objct,
            {
                'Type' => '/Font',
                'Subtype' => '/Type1',
                'BaseFont' => '/'.$fnt->{internalname},
                'Widths' => $fnt->{Widths},
                'FirstChar' => $fnt->{FirstChar},
                'LastChar' => $fnt->{LastChar},
                'Encoding' => BuildObj($objct+1,
                {
                    'Type' => '/Encoding',
                    'Differences' => $fnt->{Differences}
                }),
                'FontDescriptor' => BuildObj($objct+2,
                {
                    'Type' => '/FontDescriptor',
                    'FontName' => '/'.$fnt->{internalname},
                    'Flags' => $fnt->{t1flags},
                    'FontBBox' => $fnt->{fntbbox},
                    'ItalicAngle' => $fnt->{slant},
                    'Ascent' => $fnt->{ascent},
                    'Descent' => $fnt->{fntbbox}->[1],
                    'CapHeight' => $fnt->{capheight},
                    'StemV' => 0,
                    'CharSet' => "($fnt->{CharSet})",
                } )
            }
    );

    $fontlst{$fontno}->{OBJNO}=$objct;

    $objct+=2;
    $fontlst{$fontno}->{NM}='/F'.$fontno;
    $pages->{'Resources'}->{'Font'}->{'F'.$fontno}=$fontlst{$fontno}->{OBJ};
    #     $fontlst{$fontno}->{FNT}=$fnt;
    #     $obj[$objct]->{STREAM}=$t1stream;

    return($st+2);
}

sub LoadFont
{
    my $fontno=shift;
    my $fontnm=shift;
    my $ofontnm=$fontnm;

    return $fontlst{$fontno}->{OBJ} if (exists($fontlst{$fontno}) and $fontnm eq $fontlst{$fontno}->{FNT}->{name}) ;

    my $f;
    OpenFile(\$f,$fontdir,"$fontnm");

    if (!defined($f) and $Foundry)
    {
        # Try with no foundry
        $fontnm=~s/.*?-//;
        OpenFile(\$f,$fontdir,$fontnm);
    }

    Die("unable to open font '$ofontnm' for mounting") if !defined($f);

    my $foundry='';
    $foundry=$1 if $fontnm=~m/^(.*?)-/;
    my $stg=1;
    my %fnt;
    my %ngpos;

    if ($stg == 1) {
	while (<$f>) {
	    chomp;

	    s/^ +//;
	    s/^#.*//;
	    next if $_ eq '';

            my ($key,$val)=split(' ',$_,2);

            $key=lc($key);
            $stg=2,last if $key eq 'kernpairs';
            $stg=3,last if lc($_) eq 'charset';

	    # Lines in the groff_font file that have only $key and no
	    # $val should evaluate to defined($key).  When prototyping,
	    # it's a pain to write "defined", so I store '1' for the
	    # time being. This may have side effects. -- obuk

            #$fnt{$key}=$val;
            $fnt{$key} = $val // '1';
        }
    }

    if ($stg == 2) {
	while (<$f>) {
	    chomp;

	    s/^ +//;
	    next if $_ eq '';

	    $stg=3,last if lc($_) eq 'charset';

	    my ($ch1,$ch2,$k)=split;
	}
    }

    if ($stg == 3) {
	while (<$f>) {
	    chomp;

	    s/^ +//;
	    next if $_ eq '';

            my (@r)=split;
            my (@p)=split(',',$r[1]);

	    if ($r[1] eq '"')
	    {
		#$fnt{NAM}->{$r[0]}=$fnt{NAM}->{$lastnm};
		$fnt{NAM}->{$r[0]}=$fnt{NAM}->{$fnt{NO}->[-1]};
		next;
	    }

            $r[3]=oct($r[3]) if substr($r[3],0,1) eq '0';
            $r[0]='u0020' if $r[3] == 32;

	    # When $r[0] (name of char) is ---, the reason for setting
	    # $r[0] to "u00".hex($r[3]) is to register the glyph using
	    # $r[0] as the key.  However, $r[3] (code of char) does not
	    # store the hexadecimal string, so for example, when $r[3]
	    # is 14, $t[0] becomes u0020 (space). -- obuk

            #$r[0] = "u00".hex($r[3]) if $r[0] eq '---';
            $r[0] = "N'$r[3]'" if $r[0] eq '---';

            $r[4]=$r[0] if !defined($r[4]);

	    my %opts;
	    if ($r[5] && $r[5] eq '--') {
		for (splice(@r, 6)) {
		    my ($k, $v) = split '=';
		    $opts{$k} = $v;
		}
		$r[5] = undef;
	    }
	    unless ($r[5]) {
		if ($opts{unicode}) {
		    $r[5] = $opts{unicode};
		    delete $opts{unicode};
		} elsif ($r[0] =~ /^u([\dA-F_]+)$/) {
		    $r[5] = join '_', map { sprintf "%04X", $_ }
			unpack "n*", encode "UTF16-BE",
			pack "U*", map hex($_), split '_', $1;
		}
	    }

            if ($fnt{cidfont}) {
                my $cid = $r[4];
                my $gid = $opts{gid} // $cid;
                $ngpos{$gid} = \%opts;
                delete $opts{gid};

                # The PSNAME also stores the cid, which does not have a
                # leading '/' for visual distinction. -- obuk
                $fnt{NAM}->{$r[0]}=[$p[0],$r[3],$cid,     undef,undef,$r[5],$p[1]||0,$p[2]||0];
            } else {
                $fnt{NAM}->{$r[0]}=[$p[0],$r[3],'/'.$r[4],undef,undef,$r[5],$p[1]||0,$p[2]||0];
            }

            $fnt{NO}->[$r[3]]=$r[0];
	}
    }

    close($f);

    $fnt{NAM}->{u0020}->[MINOR]=32;
    $fnt{NAM}->{u0020}->[MAJOR]=0;
    my $fno=0;
    my $slant=0;
    $fnt{DIFF}=[];
    $fnt{WIDTH}=[];
    my $lastchr = $#{$fnt{NO}};
    $fnt{lastchr}=$lastchr;
    $fnt{NAM}->{''}=[0,-1,'/.notdef',-1,0,0,0];
    $slant=-$fnt{'slant'} if exists($fnt{'slant'});
    $fnt{slant}=$slant;

    # $fnt{nospace}=(!defined($fnt{NAM}->{u0020}->[PSNAME]) or $fnt{NAM}->{u0020}->[PSNAME] ne '/space' or !exists($fnt{'spacewidth'}))?1:0;

    # Set nospace to 1 in cidfont.  Because cidfont requires character
    # CID numbers to be expressed in hexadecimal. (e.g. [ <XXXX> ] TJ)
    # So the USESPACE option will not have the desired effect.
    $fnt{nospace} //= 0;

    # To see the effect of the USESPACE option in cidfont, comment out.
    $fnt{nospace} = 1 if $fnt{cidfont}; # xxxxx

    $fnt{nospace} = 1 if
        !defined($fnt{NAM}->{u0020}->[PSNAME]) or
        !$fnt{cidfont} && $fnt{NAM}->{u0020}->[PSNAME] ne '/space' or
        !exists($fnt{'spacewidth'});

    $fnt{'spacewidth'}=270 if !exists($fnt{'spacewidth'});
    Warn("Using nospace mode for font '$ofontnm'") if $fnt{nospace} == 1 and $options & USESPACE;

    my $fontkey="$foundry $fnt{internalname}";

    Warn("\nFont '$fnt{internalname} ($ofontnm)' has $lastchr glyphs\n"
        ."You would see a noticeable speedup if you install the perl module Inline::C\n") if !$gotinline and $lastchr > 1000;

    if (exists($download{$fontkey}))
    {
        # Real font needs subsetting
	#$fnt{fontfile}=$download{$fontkey};
	$fnt{fontfile} = $download{$fontkey}{fontfile};
	$fnt{embed} = $download{$fontkey}{embed};
        if ($fnt{opentype} || $fnt{cidfont}) {
            my $otf = Font::TTF::Font->open($fnt{fontfile});
            $fnt{' OTF'} = $otf;

            $fnt{' GPOS'} = \%ngpos if %ngpos;
            $fnt{' GSUB'} = 'not used';
            if ($fnt{opentype}) {
                for (split /\s+/, $fnt{opentype}) {
                    my ($f, $x) = split /=/;
                    next if defined $fnt{" \U$f\E"};
                    next if !defined $x;
                    die "cant $f; $@" unless __PACKAGE__->can($f);
                    no strict 'refs';
                    $otf->{uc $f}->read;
                    $fnt{" \U$f\E"} = &$f($otf, split /,/, $x);
                }
            }

            $otf->{'CFF '}->read;
            my $gid2cid = $otf->{'CFF '}->Charset->{code};
            my $cid2gid;
            for my $gid (0 .. $#{$gid2cid}) {
                my $cid = $gid2cid->[$gid];
                $cid2gid->[$cid] = $gid if defined $cid;
            }
            $fnt{' CID2GID'} = $cid2gid;
            #$fnt{' GID2CID'} = $gid2cid;

            $fnt{' CIDSystemInfo'} = {
                Registry => "(Adobe)",
                Ordering => "(Identity)",
                Supplement => 0,
            };

            $fnt{' Encoding'} = $fnt{vertical}? "Identity-V" : "Identity-H";
            $fnt{' CMapName'} = join '-', $fnt{name}, $fnt{' Encoding'};

            $otf->{name}->read;
            $fnt{' FontName'}   = get_name($otf, 6);
            $fnt{' FamilyName'} = get_name($otf, 1);
            $fnt{' Notice'}     = get_name($otf, 0);
            $fnt{' Weight'}     = get_name($otf, 2);

            $otf->{'post'}->read;
            for (qw/isFixedPitch ItalicAngle/) {
                $fnt{" $_"} =
                    exists $otf->{'post'}{STRINGS}{lcfirst $_} ?
                    $otf->{'post'}{STRINGS}{lcfirst $_} :
                    exists $otf->{'post'}{lcfirst $_} ?
                    $otf->{'post'}{lcfirst $_} :
                    exists $otf->{'CFF '}->TopDICT->{lcfirst $_} ?
                    $otf->{'CFF '}->TopDICT->{lcfirst $_} :
                    exists $otf->{'CFF '}->TopDICT->{ucfirst $_} ?
                    $otf->{'CFF '}->TopDICT->{ucfirst $_} :
                    undef;
		#$fnt{" $_"} = $fnt{" $_"}? 'true' : 'false' if /^[iI]s/;
            }

            if ($fnt{' ItalicAngle'} == 0 && $fnt{slant}) {
                my $angle = -$fnt{slant};
                $angle = rad($angle);
		# see Figure 13 in PDF 32000-1:2008
                $fnt{' skew'} = sin($angle)/cos($angle);
            }

            $fnt{' FontBBox'} = $otf->{'CFF '}->TopDICT->{FontBBox};

            $otf->{'OS/2'}->read;
            $fnt{' Ascender'}  = $otf->{'OS/2'}{sTypoAscender};
            $fnt{' Descender'} = $otf->{'OS/2'}{sTypoDescender};
            $fnt{' CapHeight'} = $otf->{'OS/2'}{CapHeight};

            $fnt{' DW'} = 1000;
            $fnt{' DW2'} = [ 1000 + $fnt{' Descender'}, -1000 ];
        } else {

	    my $fixwid = -1;
	    while (my ($k, $v) = each %{$fnt{NAM}}) {
		if (ref $v && defined $v->[WIDTH]) {
		    $fixwid = $v->[WIDTH] if $fixwid == -1;
		    $fixwid = -2, last if $fixwid > 0 and $v->[WIDTH] != $fixwid;
		}
	    }

	    my $capheight = -1;
	    for ('A' .. 'Z') {
		my $v = $fnt{NAM}{$_};
		if (ref $v && defined $v->[RST]) {
		    $capheight = $v->[RST] if $v->[RST] > $capheight;
		}
	    }

	    my $ascent = 0;
	    for my $code (32 .. 127) {
		if (my $name = $fnt{NO}[$code]) {
		    if (my $v = $fnt{NAM}{$name}) {
			if (ref $v && defined $v->[RST]) {
			    $ascent = $v->[RST] if $v->[RST] > $ascent;
			}
		    }
		}
	    }

	    my @fntbbox = (0,0,0,0);
	    while (my ($k, $v) = each %{$fnt{NAM}}) {
		$fntbbox[1] = -$v->[RSB]  if defined($v->[RSB]) and -$v->[RSB] < $fntbbox[1];
		$fntbbox[2] = $v->[WIDTH] if defined($v->[WIDTH]) and $v->[WIDTH] > $fntbbox[2];
		$fntbbox[3] = $v->[RST]   if defined($v->[RST]) and $v->[RST] > $fntbbox[3];
	    }

	    $fnt{fntbbox} =   \@fntbbox;
	    $fnt{ascent} =    $ascent;
	    $fnt{capheight} = $capheight;

	    my $t1flags = 0;
	    $t1flags |= 2**0 if $fixwid > -1;
	    $t1flags |= (exists($fnt{'special'}))? 2**2 : 2**5;
	    $t1flags |= 2**6 if $fnt{slant} != 0;
	    $fnt{t1flags} = $t1flags;

#         my ($head,$body,$tail)=GetType1($download{$fontkey});
#         $head=~s/\/Encoding .*?readonly def\b/\/Encoding StandardEncoding def/s;
#         $fontlst{$fontno}->{HEAD}=$head;
#         $fontlst{$fontno}->{BODY}=$body;
#         $fontlst{$fontno}->{TAIL}=$tail;
        #         $fno=++$objct;
        #       EmbedFont($fontno,\%fnt);
	}
    }
    else
    {
        if (exists($missing{$fontkey}))
        {
            Warn("The download file in '$missing{$fontkey}' "
            . " has erroneous entry for '$fnt{internalname} ($ofontnm)'");
        }
        else
        {
            Warn("unable to embed font file for '$fnt{internalname}'"
            . " ($ofontnm) (missing entry in 'download' file?)")
            if $embedall;
        }
    }

    $fontlst{$fontno}->{NM}='/F'.$fontno;
    $fontlst{$fontno}->{FNT}=\%fnt;

    if (defined($fnt{encoding}) and $fnt{encoding} eq 'text.enc' and $ucmap ne '')
    {
        if ($textenccmap eq '')
        {
            $textenccmap = BuildObj($objct+1,{});
            $objct++;
            $obj[$objct]->{STREAM}=$ucmap;
        }
    }

    #     PutObj($fno);
    #     PutObj($fno+1);
    #     PutObj($fno+2) if defined($obj[$fno+2]);
    #     PutObj($fno+3) if defined($obj[$fno+3]);
}

sub GetType1
{
    my $file=shift;
    my ($l1,$l2,$l3);           # Return lengths
    my ($head,$body,$tail);             # Font contents
    my $f;

    OpenFile(\$f,$fontdir,"$file");
    Die("unable to open font '$file' for embedding") if !defined($f);

    $head=GetChunk($f,1,"currentfile eexec");
    $body=GetChunk($f,2,"00000000") if !eof($f);
    $tail=GetChunk($f,3,"cleartomark") if !eof($f);

    return($head,$body,$tail);
}

sub GetChunk
{
    my $F=shift;
    my $segno=shift;
    my $ascterm=shift;
    my ($type,$hdr,$chunk,@msg);
    binmode($F);
    my $enc="ascii";

    while (1)
    {
        # There may be multiple chunks of the same type

        my $ct=read($F,$hdr,2);

        if ($ct==2)
        {
            if (substr($hdr,0,1) eq "\x80")
            {
                # binary chunk

                my $chunktype=ord(substr($hdr,1,1));
                $enc="binary";

                if (defined($type) and $type != $chunktype)
                {
                    seek($F,-2,1);
                    last;
                }

                $type=$chunktype;
                return if $chunktype == 3;

                $ct=read($F,$hdr,4);
                Die("failed to read binary segment length") if $ct != 4;
                my $sl=unpack('V',$hdr);
                my $data;
                my $chk=read($F,$data,$sl);
                Die("failed to read binary segment") if $chk != $sl;
                $chunk.=$data;
            }
            else
            {
                # ascii chunk

                my $hex=0;
                seek($F,-2,1);
                my $ct=0;

                while (1)
                {
                    my $lin=<$F>;

                    last if !$lin;

                    $hex=1,$enc.=" hex" if $segno == 2 and !$ct and $lin=~m/^[A-F0-9a-f]{4,4}/;

                    if ($segno !=2 and $lin=~m/^(.*$ascterm[\n\r]?)(.*)/)
                    {
                        $chunk.=$1;
                        seek($F,-length($2)-1,1) if $2;
                        last;
                    }
                    elsif ($segno == 2 and $lin=~m/^(.*?)($ascterm.*)/)
                    {
                        $chunk.=$1;
                        seek($F,-length($2)-1,1) if $2;
                        last;
                    }

                    chomp($lin), $lin=pack('H*',$lin) if $hex;
                    $chunk.=$lin; $ct++;
                }

                last;
            }
        }
        else
        {
            push(@msg,"Failed to read 2 header bytes");
        }
    }

    return $chunk;
}

sub OutStream
{
    my $ono=shift;

    IsGraphic();
    $stream.="Q\n";
    $obj[$ono]->{STREAM}=$stream;
    $obj[$ono]->{DATA}->{Length}=length($stream);
    $stream='';
    PutObj($ono);
}

sub do_p
{
    my $trans='BLOCK';

    $trans='PAGE' if $firstpause;
    NewPage($trans);
    @XOstream=();
    @PageAnnots=();
    $firstpause=1;
}

sub FixTrans
{
    my $t=shift;
    my $style=$t->{S};

    if ($style)
    {
        delete($t->{Dm}) if $style ne '/Split' and $style ne '/Blinds';
        delete($t->{M})  if !($style eq '/Split' or $style eq '/Box' or $style eq '/Fly');
        delete($t->{Di}) if !($style eq '/Wipe' or $style eq '/Glitter' or $style eq '/Fly' or $style eq '/Cover' or $style eq '/Uncover' or $style eq '/Push') or ($style eq '/Fly' and $t->{Di} eq '/None' and $t->{SS} != 1);
        delete($t->{SS}) if !($style eq '/Fly');
        delete($t->{B})  if !($style eq '/Fly');
    }

    return($t);
}

sub NewPage
{
    my $trans=shift;
    # Start of pages

    if ($cpageno > 0)
    {
        if ($#XOstream>=0)
        {
            MakeXO() if $stream;
            $stream=join("\n",@XOstream,'');
        }

        my %t=%{$transition->{$trans}};
        $cpage->{MediaBox}=\@mediabox if $custompaper;
        $cpage->{Trans}=FixTrans(\%t) if $t{S};

        if ($#PageAnnots >= 0)
        {
            @{$cpage->{Annots}}=@PageAnnots;
        }

        if ($#bgstack > -1 or $bgbox)
        {
            my $box="q 1 0 0 1 0 0 cm ";

            foreach my $bg (@bgstack)
            {
                # 0=$bgtype # 1=stroke 2=fill. 4=page
                # 1=$strkcol
                # 2=$fillcol
                # 3=(Left,Top,Right,bottom,LineWeight)
                # 4=Start ypos
                # 5=Endypos
                # 6=Line Weight

                my $pg=$bg->[3] || \@defaultmb;

                $bg->[5]=$pg->[3];      # box is continuing to next page
                $box.=DrawBox($bg);
                $bg->[4]=$pg->[1];      # will continue from page top
            }

            $stream=$box.$bgbox."Q\n".$stream;
            $bgbox='';
            $boxmax=0;
        }

        PutObj($cpageno);
        OutStream($cpageno+1);
    }

    $cpageno=++$objct;

    my $thispg=BuildObj($objct,
            {
                'Type' => '/Page',
                'Group' =>
                {
                    'CS' => '/DeviceRGB',
                    'S' => '/Transparency'
                },
                'Parent' => '2 0 R',
                'Contents' =>
                [
                    BuildObj($objct+1,
                    {
                        'Length' => 0
                    } )
                ],
            }
    );

    splice(@{$pages->{Kids}},++$pginsert,0,$thispg);
    splice(@outlines,$pginsert,0,[$curoutlev,$#{$curoutlev}+1,$thislev]);

    $objct+=1;
    $cpage=$obj[$cpageno]->{DATA};
    $pages->{'Count'}++;
    $stream="q 1 0 0 1 0 0 cm\n$linejoin J\n$linecap j\n0.4 w\n";
    $stream.=$strkcol."\n", $curstrk=$strkcol if $strkcol ne '';
            $mode='g';
            $curfill='';
            #    @mediabox=@defaultmb;
}

sub DrawBox
{
    my $bg=shift;
    my $res='';
    my $pg=$bg->[3] || \@mediabox;
    $bg->[4]=$pg->[1], $bg->[5]=$pg->[3] if $bg->[0] & 4;
    my $bot=$bg->[5];
    $bot=$boxmax if $boxmax > $bot;
    my $wid=$pg->[2]-$pg->[0];
    my $dep=$bot-$bg->[4];

    $res="$bg->[1] $bg->[2] $bg->[6] w\n";
    $res.="$pg->[0] $bg->[4] $wid $dep re f " if $bg->[0] & 1;
    $res.="$pg->[0] $bg->[4] $wid $dep re s " if $bg->[0] & 2;

    return("$res\n");
}

sub MakeXO
{
    $stream.="%mode=$mode\n";
    IsGraphic();
    $stream.="Q\n";
    my $xobj=++$objct;
    my $xonm="XO$xobj";
    $pages->{'Resources'}->{'XObject'}->{$xonm}=BuildObj($xobj,{'Type' => '/XObject', 'BBox' => \@mediabox, 'Name' => "/$xonm", 'FormType' => 1, 'Subtype' => '/Form', 'Length' => 0, 'Type' => "/XObject"});
    $obj[$xobj]->{STREAM}=$stream;
    $stream='';
    push(@XOstream,"q") if $#XOstream==-1;
    push(@XOstream,"/$xonm Do");
}

sub do_f
{
    my $par=shift;
    my $fnt=$fontlst{$par}->{FNT};
    PutLine() if $thisfnt;
    $thisfnt=$fnt;

    #   IsText();
    $cft="$par";
    $fontchg=1;
    my $matrix_save = $matrix;
    MakeMatrix();
    $matrixchg = 0 if $matrix eq $matrix_save;
    PutLine();
}

sub IsText
{
    if ($mode eq 'g')
    {
        my $dy = 0;
        $dy = $cftsz / 1000 * (500 + $thisfnt->{' Descender'})
            if $thisfnt && $thisfnt->{vertical};
        $stream.="q BT\n$matrix ".PutXY($xpos,$ypos - $dy)." Tm\n";
        #$stream.="q BT\n$matrix ".PutXY($xpos,$ypos)." Tm\n";
        $poschg=0;
        $matrixchg=0;
        $tmxpos=$xpos;
        $stream.=$textcol."\n", $curfill=$textcol if $textcol ne $curfill;

        if (defined($cft))
        {
            $fontchg=1;
#           $stream.="/F$cft $cftsz Tf\n";
        }

        $stream.="$curkern Tc\n";
    }

    if ($poschg or $matrixchg)
    {
        PutLine(0) if $matrixchg;
        shift(@lin) if $#lin==0 and !defined($lin[0]->[CHR]);
        my $dy = 0;
        $dy = $cftsz / 1000 * (500 + $thisfnt->{' Descender'})
            if $thisfnt && $thisfnt->{vertical};
        $stream.="$matrix ".PutXY($xpos,$ypos - $dy)." Tm\n", $poschg=0;
        #$stream.="$matrix ".PutXY($xpos,$ypos)." Tm\n", $poschg=0;
        $tmxpos=$xpos;
        $matrixchg=0;
        $stream.="$curkern Tc\n";
    }

    $mode='t';
}

sub IsGraphic
{
    if ($mode eq 't')
    {
        PutLine();
        $stream.="ET Q\n";
        $stream.=$strkcol."\n", $curstrk=$strkcol if $strkcol ne $curstrk;
        $curfill=$fillcol;
    }
    $mode='g';
}

sub do_s
{
    my $par=shift;
    $par/=$unitwidth;

    $whtsz=$fontlst{$cft}->{FNT}->{spacewidth}*$par if !defined($whtsz) and defined($cft);

    if ($par != $cftsz and defined($cft))
    {
        PutLine();
        $cftsz=$par;
        Set_LWidth() if $lwidth < 1;
        $fontchg=1;
    }
    else
    {
        $cftsz=$par;
        Set_LWidth() if $lwidth < 1;
    }
}

sub Set_LWidth
{
    IsGraphic();
    $stream.=((($desc{res}/(72*$desc{sizescale}))*$linewidth*$cftsz)/1000)." w\n";
    return;
}

sub do_m
{
    # Groff uses /m[] for text & graphic stroke, and /M[] (DF?) for graphic fill.
    # PDF uses G/RG/K for graphic stroke, and g/rg/k for text & graphic fill.
    #
    # This means that we must maintain g/rg/k state separately for text colour & graphic fill (this is
    # probably why 'gs' maintains separate graphic states for text & graphics when distilling PS -> PDF).
    #
    # To facilitate this:-
    #
    #   $textcol        = current groff stroke colour
    #   $fillcol        = current groff fill colour
    #   $curfill        = current PDF fill colour

    my $par=shift;
    my $mcmd=substr($par,0,1);

    $par=substr($par,1);
    $par=~s/^ +//;

    #   IsGraphic();

    $textcol=set_col($mcmd,$par,0);
    $strkcol=set_col($mcmd,$par,1);

    if ($mode eq 't')
    {
        PutLine();
        $stream.=$textcol."\n";
        $curfill=$textcol;
    }
    else
    {
        $stream.="$strkcol\n";
        $curstrk=$strkcol;
    }
}

sub set_col
{
    my $mcmd=shift;
    my $par=shift;
    my $upper=shift;
    my @oper=('g','k','rg');

    @oper=('G','K','RG') if $upper;

    if ($mcmd eq 'd')
    {
        # default colour
        return("0 $oper[0]");
    }

    my (@c)=split(' ',$par);

    if ($mcmd eq 'c')
    {
        # Text CMY
        return(d3($c[0]/65535).' '.d3($c[1]/65535).' '.d3($c[2]/65535)." 0 $oper[1]");
    }
    elsif ($mcmd eq 'k')
    {
        # Text CMYK
        return(d3($c[0]/65535).' '.d3($c[1]/65535).' '.d3($c[2]/65535).' '.d3($c[3]/65535)." $oper[1]");
    }
    elsif ($mcmd eq 'g')
    {
        # Text Grey
        return(d3($c[0]/65535)." $oper[0]");
    }
    elsif ($mcmd eq 'r')
    {
        # Text RGB0
        return(d3($c[0]/65535).' '.d3($c[1]/65535).' '.d3($c[2]/65535)." $oper[2]");
    }
}

sub do_D
{
    my $par=shift;
    my $Dcmd=substr($par,0,1);

    $par=substr($par,1);

    IsGraphic();

    if ($Dcmd eq 'F')
    {
        my $mcmd=substr($par,0,1);

        $par=substr($par,1);
        $par=~s/^ +//;

        $fillcol=set_col($mcmd,$par,0);
        $stream.="$fillcol\n";
        $curfill=$fillcol;
    }
    elsif ($Dcmd eq 'f')
    {
        my $mcmd=substr($par,0,1);

        $par=substr($par,1);
        $par=~s/^ +//;
        ($par)=split(' ',$par);

        if ($par >= 0 and $par <= 1000)
        {
            $fillcol=set_col('g',int((1000-$par)*65535/1000),0);
        }
        else
        {
            $fillcol=lc($textcol);
        }

        $stream.="$fillcol\n";
        $curfill=$fillcol;
    }
    elsif ($Dcmd eq '~')
    {
        # B-Spline
        my (@p)=split(' ',$par);
        my ($nxpos,$nypos);

        foreach my $p (@p) { $p/=$unitwidth; }
        $stream.=PutXY($xpos,$ypos)." m\n";
        $xpos+=($p[0]/2);
        $ypos+=($p[1]/2);
        $stream.=PutXY($xpos,$ypos)." l\n";

        for (my $i=0; $i < $#p-1; $i+=2)
        {
            $nxpos=(($p[$i]*$tnum)/(2*$tden));
            $nypos=(($p[$i+1]*$tnum)/(2*$tden));
            $stream.=PutXY(($xpos+$nxpos),($ypos+$nypos))." ";
            $nxpos=($p[$i]/2 + ($p[$i+2]*($tden-$tnum))/(2*$tden));
            $nypos=($p[$i+1]/2 + ($p[$i+3]*($tden-$tnum))/(2*$tden));
            $stream.=PutXY(($xpos+$nxpos),($ypos+$nypos))." ";
            $nxpos=(($p[$i]-$p[$i]/2) + $p[$i+2]/2);
            $nypos=(($p[$i+1]-$p[$i+1]/2) + $p[$i+3]/2);
            $stream.=PutXY(($xpos+$nxpos),($ypos+$nypos))." c\n";
            $xpos+=$nxpos;
            $ypos+=$nypos;
        }

        $xpos+=($p[$#p-1]-$p[$#p-1]/2);
        $ypos+=($p[$#p]-$p[$#p]/2);
        $stream.=PutXY($xpos,$ypos)." l\nS\n";
        $poschg=1;
    }
    elsif ($Dcmd eq 'p' or $Dcmd eq 'P')
    {
        # Polygon
        my (@p)=split(' ',$par);
        my ($nxpos,$nypos);

        foreach my $p (@p) { $p/=$unitwidth; }
        $stream.=PutXY($xpos,$ypos)." m\n";

        for (my $i=0; $i < $#p; $i+=2)
        {
            $xpos+=($p[$i]);
            $ypos+=($p[$i+1]);
            $stream.=PutXY($xpos,$ypos)." l\n";
        }

        if ($Dcmd eq 'p')
        {
            $stream.="s\n";
        }
        else
        {
            $stream.="f\n";
        }

        $poschg=1;
    }
    elsif ($Dcmd eq 'c')
    {
        # Stroke circle
        $par=substr($par,1);
        my (@p)=split(' ',$par);

        DrawCircle($p[0],$p[0]);
        $stream.="s\n";
        $poschg=1;
    }
    elsif ($Dcmd eq 'C')
    {
        # Fill circle
        $par=substr($par,1);
        my (@p)=split(' ',$par);

        DrawCircle($p[0],$p[0]);
        $stream.="f\n";
        $poschg=1;
    }
    elsif ($Dcmd eq 'e')
    {
        # Stroke ellipse
        $par=substr($par,1);
        my (@p)=split(' ',$par);

        DrawCircle($p[0],$p[1]);
        $stream.="s\n";
        $poschg=1;
    }
    elsif ($Dcmd eq 'E')
    {
        # Fill ellipse
        $par=substr($par,1);
        my (@p)=split(' ',$par);

        DrawCircle($p[0],$p[1]);
        $stream.="f\n";
        $poschg=1;
    }
    elsif ($Dcmd eq 'l')
    {
        # Line To
        $par=substr($par,1);
        my (@p)=split(' ',$par);

        foreach my $p (@p) { $p/=$unitwidth; }
        $stream.=PutXY($xpos,$ypos)." m\n";
        $xpos+=$p[0];
        $ypos+=$p[1];
        $stream.=PutXY($xpos,$ypos)." l\n";

        $stream.="S\n";
        $poschg=1;
    }
    elsif ($Dcmd eq 't')
    {
        # Line Thickness
        $par=substr($par,1);
        my (@p)=split(' ',$par);

        foreach my $p (@p) { $p/=$unitwidth; }
        #               $xpos+=$p[0]*100;               # WTF!!!
        #int lw = ((font::res/(72*font::sizescale))*linewidth*env->size)/1000;
        $p[0]=(($desc{res}/(72*$desc{sizescale}))*$linewidth*$cftsz)/1000 if $p[0] < 0;
        $lwidth=$p[0];
        $stream.="$p[0] w\n";
        $poschg=1;
        $xpos+=$lwidth;
    }
    elsif ($Dcmd eq 'a')
    {
        # Arc
        $par=substr($par,1);
        my (@p)=split(' ',$par);
        my $rad180=3.14159;
        my $rad360=$rad180*2;
        my $rad90=$rad180/2;

        foreach my $p (@p) { $p/=$unitwidth; }

        # Documentation is wrong. Groff does not use Dh1,Dv1 as centre of the circle!

        my $centre=adjust_arc_centre(\@p);

        # Using formula here : http://www.tinaja.com/glib/bezcirc2.pdf
        # First calculate angle between start and end point

        my ($startang,$r)=RtoP(-$centre->[0],$centre->[1]);
        my ($endang,$r2)=RtoP(($p[0]+$p[2])-$centre->[0],-($p[1]+$p[3]-$centre->[1]));
        $endang+=$rad360 if $endang < $startang;
        my $totang=($endang-$startang)/4;       # do it in 4 pieces

        # Now 1 piece

        my $x0=cos($totang/2);
        my $y0=sin($totang/2);
        my $x3=$x0;
        my $y3=-$y0;
        my $x1=(4-$x0)/3;
        my $y1=((1-$x0)*(3-$x0))/(3*$y0);
        my $x2=$x1;
        my $y2=-$y1;

        # Rotate to start position and draw 4 pieces

        foreach my $j (0..3)
        {
            PlotArcSegment($totang/2+$startang+$j*$totang,$r,$xpos+$centre->[0],GraphY($ypos+$centre->[1]),$x0,$y0,$x1,$y1,$x2,$y2,$x3,$y3);
        }

        $xpos+=$p[0]+$p[2];
        $ypos+=$p[1]+$p[3];

        $poschg=1;
    }
}

sub deg
{
    return int($_[0]*180/3.14159);
}

sub adjust_arc_centre
{
    # Taken from geometry.cpp

    # We move the center along a line parallel to the line between
    # the specified start point and end point so that the center
    # is equidistant between the start and end point.
    # It can be proved (using Lagrange multipliers) that this will
    # give the point nearest to the specified center that is equidistant
    # between the start and end point.

    my $p=shift;
    my @c;
    my $x = $p->[0] + $p->[2];  # (x, y) is the end point
    my $y = $p->[1] + $p->[3];
    my $n = $x*$x + $y*$y;
    if ($n != 0)
    {
        $c[0]= $p->[0];
        $c[1] = $p->[1];
        my $k = .5 - ($c[0]*$x + $c[1]*$y)/$n;
        $c[0] += $k*$x;
        $c[1] += $k*$y;
        return(\@c);
    }
    else
    {
        return(undef);
    }
}


sub PlotArcSegment
{
    my ($ang,$r,$transx,$transy,$x0,$y0,$x1,$y1,$x2,$y2,$x3,$y3)=@_;
    my $cos=cos($ang);
    my $sin=sin($ang);
    my @mat=($cos,$sin,-$sin,$cos,0,0);
    my $lw=$lwidth/$r;

    if ($frot)
    {
	$stream.="q $r 0 0 $r $transy $transx cm ".join(' ',@mat)." cm $lw w $y0 $x0 m $y1 $x1 $y2 $x2 $y3 $x3 c S Q\n";
    }
    else
    {
	$stream.="q $r 0 0 $r $transx $transy cm ".join(' ',@mat)." cm $lw w $x0 $y0 m $x1 $y1 $x2 $y2 $x3 $y3 c S Q\n";
    }
}

sub DrawCircle
{
    my $hd=shift;
    my $vd=shift;
    my $hr=$hd/2/$unitwidth;
    my $vr=$vd/2/$unitwidth;
    my $kappa=0.5522847498;
    $hd/=$unitwidth;
    $vd/=$unitwidth;
    $stream.=PutXY(($xpos+$hd),$ypos)." m\n";
    $stream.=PutXY(($xpos+$hd),($ypos+$vr*$kappa))." ".PutXY(($xpos+$hr+$hr*$kappa),($ypos+$vr))." ".PutXY(($xpos+$hr),($ypos+$vr))." c\n";
    $stream.=PutXY(($xpos+$hr-$hr*$kappa),($ypos+$vr))." ".PutXY(($xpos),($ypos+$vr*$kappa))." ".PutXY(($xpos),($ypos))." c\n";
    $stream.=PutXY(($xpos),($ypos-$vr*$kappa))." ".PutXY(($xpos+$hr-$hr*$kappa),($ypos-$vr))." ".PutXY(($xpos+$hr),($ypos-$vr))." c\n";
    $stream.=PutXY(($xpos+$hr+$hr*$kappa),($ypos-$vr))." ".PutXY(($xpos+$hd),($ypos-$vr*$kappa))." ".PutXY(($xpos+$hd),($ypos))." c\n";
    $xpos+=$hd;

    $poschg=1;
}

sub FindCircle
{
    my ($x1,$y1,$x2,$y2,$x3,$y3)=@_;
    my ($Xo, $Yo);

    my $x=$x2+$x3;
    my $y=$y2+$y3;
    my $n=$x**2+$y**2;

    if ($n)
    {
        my $k=.5-($x2*$x + $y2*$y)/$n;
        return(sqrt($n),$x2+$k*$x,$y2+$k*$y);
    }
    else
    {
        return(-1);
    }

}

sub PtoR
{
    my ($theta,$r)=@_;

    return($r*cos($theta),$r*sin($theta));
}

sub RtoP
{
    my ($x,$y)=@_;

    return(atan2($y,$x),sqrt($x**2+$y**2));
}

sub PutLine
{

    my $f=shift;

    IsText() if !defined($f);

    return if (scalar(@lin) == 0 or ($#lin == 0 and !defined($lin[0]->[CHR])));

    my @TJ;
    my $len=0;
    my $rev=0;

    if (($lin[0]->[CHR]||0) < 0)
    {
        $len=($lin[$#lin]->[XPOS]-$lin[0]->[XPOS]+$lin[$#lin]->[HWID])*100;
        push_TJ(\@TJ, $len);
    $rev=1;
    }

    if ($thisfnt->{cidfont}) {
        # In cidfont, word spacing (Tw) does not seem to work because spaces
        # are represented as <0001>, so we will suppress word spacing here.
        $wt = 0;
    }

    $stream.="%! wht0sz=".d3($whtsz/$unitwidth).", wt=".((defined($wt))?d3($wt/$unitwidth):'--')."\n" if $debug;

    foreach my $c (@lin)
    {
        my $chr=$c->[CHR];
        my $char;
        my $placement;

        my $chrc=defined($chr)?$c->[CHF]->[MAJOR].'/'.$chr:'';
        #$chrc.="(".chr(abs($chr)).")" if defined($chr) and $cftmajor==0 and $chr<128;
        #$chrc.="[$c->[CHF]->[PSNAME]]" if defined($chr);

        if (defined($chr))
        {
            my $psname = $c->[CHF]->[PSNAME];
            if (substr($psname, 0, 1) eq '/') {
                $chr=abs($chr);
                $char=chr($chr);
                $char="\\\\" if $char eq "\\";
                $char="\\(" if $char eq "(";
                $char="\\)" if $char eq ")";
                $char = "($char)";
                $chrc.="(".chr(abs($chr)).")" if $cftmajor==0 and $chr < 128;
            } else {
                my $gid = $thisfnt->{' CID2GID'}->[$psname];
                if (my $gpos = $thisfnt->{' GPOS'}) {
                    if (my $v = $gpos->{$gid}) {
                        if ($thisfnt->{vertical}) {
                            for ($v->{'YPlacement'}) {
                                $placement = $_ if defined;
                            }
                        } else {
                            for ($v->{'XPlacement'}) {
                                $placement = $_ if defined;
                            }
                        }
                    }
                }
                $char = sprintf "<%04X>", $psname;
                $chrc.=$char;
            }
            $chrc .= "[$psname]";
        }

        $stream.="%! PutLine: XPOS=$c->[XPOS], CHR=$chrc, CWID=$c->[CWID], HWID=$c->[HWID], NOMV=$c->[NOMV]\n" if $debug;

        if (!defined($chr) and defined($wt))
        {
            # white space

            my $gap = $c->[HWID]*$unitwidth;

            if ($options & USESPACE and $thisfnt->{nospace}==0)
            {
                $stream.="%!! GAP=".($gap)."\n" if $debug;

                #           while ($gap >= $whtsz+$wt)
                #           while (abs($gap - ($whtsz+$wt)) > 1)
                if ($wt >= 0)
                {
                    my $i=int(($gap+1) / ($whtsz+$wt));

                    if ($i < 6)
                    {
                        if ($thisfnt->{cidfont}) {
                            if ($i > 0) {
                                $thisfnt->{usespace}++;
                                my ($chf, $ch) = GetNAM($thisfnt, 'u0020');
                                push_TJ(\@TJ, "<" . sprintf("%04X", $chf->[PSNAME]) x $i . ">");
                            }
                        } else {
                            push_TJ(\@TJ, "(" . ' ' x $i . ")");
                        }
                        $gap-=($whtsz+$wt) * $i;
                    }
                }
                else
                {
                    $wt=0;
                }
            }

            if (abs($gap) > 1)
            {
                my $w = -$gap/$cftsz;
                $w = -$w if $thisfnt->{vertical};
                push_TJ(\@TJ, $w);
            }
        }
        elsif ($c->[CWID] != $c->[HWID])
        {
            if ($rev)
            {
                my $w = ($c->[CWID]-$c->[HWID])*100;
                $w = -$w if $thisfnt->{vertical};
                push_TJ(\@TJ, $w); # xxxxx (not covered)
            }

            if (defined($chr))
            {
                if (defined $placement) {
                    push_TJ(\@TJ, -$placement, $char, $placement);
                } else {
                    push_TJ(\@TJ, $char);
                }
            }

            if (!$rev)
            {
                my $w = (($c->[CWID]-$c->[HWID])*1000)/$cftsz;
                $w = -$w if $thisfnt->{vertical};
                push_TJ(\@TJ, $w);
            }


        }
        else
        {
            if (defined $placement) {
                push_TJ(\@TJ, -$placement, $char, $placement);
            } else {
                push_TJ(\@TJ, $char);
            }
        }
    }

    push_TJ(\@TJ, -$len) if $len;
    $wt=0 if !defined($wt);
    $stream.=d3($wt/$unitwidth)." Tw " if $options & USESPACE;
    $stream.="[ @TJ ] TJ\n";
    @lin=();
    $wt=undef;
    $whtsz=$fontlst{$cft}->{FNT}->{spacewidth}*$cftsz;
}

sub push_TJ {
    my $TJ = shift;
    return undef unless ref $TJ;
    if (!$reduce_TJ) {
        push @$TJ, map { /^[-+]?\d/? d3($_) : $_ } @_;
        return $TJ;
    }
    for (@_) {
        my $t = substr($_, 0, 1);
        if ($t eq '(' || $t eq '<') {
            if (@$TJ && substr($TJ->[-1], 0, 1) eq $t) {
                substr($TJ->[-1], -1, 1) = substr($_, 1);
            } else {
                push @$TJ, $_;
            }
        } else {
            if (@$TJ && $TJ->[-1] =~ /^[-+]?[.\d]/) {
                my $num = d3(pop(@$TJ) + $_);
                push @$TJ, $num if $num != 0;
            } else {
                push @$TJ, d3($_);
            }
        }
    }
    return $TJ;
}

sub d3
{
    my $d3 = sprintf("%.3f",shift || 0);
    return $d3 if !$reduce_d3;
    my ($int, $prec) = split /\./, $d3;
    $int += 0;
    if ($prec != 0) {
        $prec =~ s/0{1,2}$//;
        return join '.', $int, $prec;
    }
    return $int;
}

sub  LoadAhead
{
    my $no=shift;

    foreach my $j (1..$no)
    {
        my $lin=<>;
        chomp($lin);
        $lin=~s/\r$//;
        $lct++;

        push(@ahead,$lin);
        $stream.="%% $lin\n" if $debug;
    }
}

sub do_V
{
    my $par=shift;

    if ($mode eq 't')
    {
        PutLine();
    }

    $ypos=$par/$unitwidth;

    $poschg=1;
}

sub do_v
{
    my $par=shift;

    PutLine() if $mode eq 't';

    $ypos+=$par/$unitwidth;

    $poschg=1;
}

sub GetNAM
{
    my ($f,$c)=(@_);

    my $r=$f->{NAM}->{$c};
    return($r,$c) if ref($r) eq 'ARRAY';
    return($f->{NAM}->{$r},$r);
}

sub AssignGlyph
{
    my ($fnt,$chf,$ch)=(@_);

    if ($chf->[CHRCODE] > 32 and $chf->[CHRCODE] < 128)
    {
        ($chf->[MINOR],$chf->[MAJOR])=($chf->[CHRCODE],0);
    }
    elsif ($chf->[CHRCODE] == 173)
    {
        ($chf->[MINOR],$chf->[MAJOR])=(31,0);
    }
    else
    {
        ($chf->[MINOR],$chf->[MAJOR])=NextAlloc($fnt);
    }

    #   $fnt->{SUB}->[$chf->[MAJOR]]->{CHARSET}.=$chf->[PSNAME];

    my $uc;

    # Add ToUnicode CMap entry - requires change to afmtodit

    push(@{$fnt->{CHARSET}->[$chf->[MAJOR]]},$chf->[PSNAME]);
    push(@{$fnt->{TRFCHAR}->[$chf->[MAJOR]]},$ch);
    $stream.="% Assign: $chf->[PSNAME] to $chf->[MAJOR]/$chf->[MINOR]\n" if $debug;

    if (my $u16 = $chf->[UNICODE]) {
	my $u = decode "UTF16-BE", pack "n*", map hex($_), split '_', $u16;
	if ($fnt->{cidfont}) {
	    my $cid = $chf->[PSNAME];
	    $fnt->{' cid2nam'}{$cid} = $ch;
	    $fnt->{' cid2uni'}{$cid} = $u;
	} else {
	    $fnt->{' 2nam'}[$chf->[MAJOR]]{$chf->[MINOR]} = $ch;
	    $fnt->{' 2uni'}[$chf->[MAJOR]]{$chf->[MINOR]} = $u;
	}
    }
}

sub PutGlyph
{
    my ($fnt,$ch,$nowidth)=@_;
    my $chf;
    ($chf,$ch)=GetNAM($fnt,$ch);

    IsText();

    if ($n_flg and defined($mark))
    {
        $mark->{ypos}=$ypos;
        $mark->{xpos}=$xpos;
    }

    $n_flg=0;

    if (!defined($chf->[MINOR]))
    {
        AssignGlyph($fnt,$chf,$ch);
    }

    if ($fontchg or $chf->[MAJOR] != $cftmajor && !$fnt->{cidfont})
    {
        PutLine();
        $cftmajor=$chf->[MAJOR];
        #       $whtsz=$fontlst{$cft}->{FNT}->{spacewidth}*$cftsz;
        my $c=$cft;
        $c.=".".$cftmajor if $cftmajor && !$fnt->{cidfont};
        $stream.="/F$c $cftsz Tf\n";
        $fontchg=0;
    }

    my $cn=$chf->[MINOR];
    my $chr=chr($cn);
    my $cwid=($chf->[WIDTH]*$cftsz)/$unitwidth+$curkern;
    my $hwid=($nowidth)?0:$cwid;

    $gotT=1;

    if ($xrev)
    {
        PutLine(0) if $#lin > -1 and ($lin[$#lin]->[CHR]||0) > 0;
        $cn=-$cn;
    }
    else
    {
        PutLine(0) if $#lin > -1 and ($lin[$#lin]->[CHR]||0) < 0;
    }

    if ($#lin < 1)
    {
        if (!$inxrev and $cn < 0) # in xrev
        {
            MakeMatrix(1);
            $inxrev=1;
        }
        elsif ($inxrev and $cn > 0)
        {
            MakeMatrix(0);
            $inxrev=0;
        }

        if ($matrixchg or $poschg)
        {
            my $dy = 0;
            $dy = $cftsz / 1000 * (500 + $thisfnt->{' Descender'})
                if $thisfnt && $thisfnt->{vertical};
            $stream.="$matrix ".PutXY($xpos,$ypos - $dy)." Tm\n", $poschg=0;
            $tmxpos=$xpos;
            $matrixchg=0;
            $stream.="$curkern Tc\n";
        }
    }

    $whtsz=$fontlst{$cft}->{FNT}->{spacewidth}*$cftsz if $#lin==-1;
#     $stream.="%!!! Put: font=$cft, char=$chf->[PSNAME]\n" if $debug;

    push(@lin,[$cn,$xpos,$cwid,$hwid,$nowidth,$chf]);

    $xpos+=$hwid;
}

sub do_t
{
    my $par=shift;
    my $fnt=$fontlst{$cft}->{FNT};

    if ($kernadjust != $curkern)
    {
        PutLine();
        $stream.="$kernadjust Tc\n";
        $curkern=$kernadjust;
    }

    IsText();

    foreach my $j (0..length($par)-1)
    {
        my $ch=substr($par,$j,1);

        PutGlyph($fnt,$ch,0);
    }

}

sub do_u
{
    my $par=shift;

    $par=m/([+-]?\d+) (.*)/;
    $kernadjust=$1/$unitwidth;
    do_t($2);
    $kernadjust=0;
}

sub do_h
{
    my $v=shift;

    $v/=$unitwidth;

    if ( $mode eq 't')
    {
        if ($w_flg)
        {
            if ($#lin > -1 and $lin[$#lin]->[NOMV]==1)
            {
                $lin[$#lin]->[HWID]=$v;
            }
            else
            {
                push(@lin,[undef,$xpos,$v,$v,0]);
            }

            if (!defined($wt))
            {
                $whtsz=$fontlst{$cft}->{FNT}->{spacewidth}*$cftsz;
                $wt=($v * $unitwidth) - $whtsz;
                $stream.="%!! wt=$wt, whtsz=$whtsz\n" if $debug;
            }

            $w_flg=0;
        }
        else
        {
            if ($#lin > -1 and $lin[$#lin]->[NOMV]==1)
            {
                $lin[$#lin]->[HWID]=$v;
            }
            else
            {
                push(@lin,[undef,$xpos,0,$v,0]);
            }
        }
    }

    $xpos+=$v;
}

sub do_H
{
    my $par=shift;
    $xpos=($par/$unitwidth);

    if ($mode eq 't')
    {
        #       PutLine();
        if ($#lin > -1)
        {
            $lin[$#lin]->[HWID]=d3($xpos-$lin[$#lin]->[XPOS]);
        }
        else
        {
            $stream.=d3($xpos-$tmxpos)." 0 Td\n" if $mode eq 't';
                $tmxpos=$xpos;
        }
    }
}

sub do_C
{
    my $par=shift;
    my $fnt=$fontlst{$cft}->{FNT};

    PutGlyph($fnt,$par,1);
}

sub do_c
{
    my $par=shift;

    push(@ahead,substr($par,1));
    $par=substr($par,0,1);
    do_C($par);
}

sub do_N
{
    my $par=shift;
    my $fnt=$fontlst{$cft}->{FNT};

    if (!defined($fnt->{NO}->[$par]))
    {
        Warn("no chr($par) in font $fnt->{internalname}");
        return;
    }

    my $chnm=$fnt->{NO}->[$par];
    PutGlyph($fnt,$chnm,1);
}

sub do_n
{
    $gotT=0;
    PutLine(0);
    $n_flg=1;
    @lin=();
    PutHotSpot($xpos) if defined($mark);
}

sub NextAlloc
{
    my $fnt=shift;

    $alloc=++$fnt->{ALLOC};

    my $maj=$alloc >> 8;
    my $min=$alloc & 0xff;

    my $start=($maj == 0)?128:33;
    $min=$start if $min < $start;
    $min++ if $min == ord('(');
    $min++ if $min == ord(')');
    $maj++,$min=$start if $min > 255;

    $fnt->{ALLOC}=($maj << 8) + $min;

    return($min,$maj);
}

sub decrypt_char
{
    my $l=shift;
    my (@la)=unpack('C*',$l);
    my @res;

    if ($lenIV >= 0)
    {
        my $clr;
        my $cr=C_DEF;
        my $skip=$lenIV;

        foreach my $cypher (@la)
        {
            $clr=($cypher ^ ($cr >> 8)) & 0xFF;
            $cr=(($cypher + $cr) * MAGIC1 + MAGIC2) & 0xFFFF;
            push(@res,$clr) if --$skip < 0;
        }

        return(\@res);
    }
    else
    {
        return(\@la);
    }
}

sub decrypt_exec_P
{
    my $e=shift;
    my $l=shift;
    $l--;
    my $clr;
    my $er=E_DEF;

    foreach my $j (0..$l)
    {
        my $cypher=ord(substr($$e,$j,1));
        $clr=($cypher ^ ($er >> 8)) & 0xFF;
        $er=(($cypher + $er) * MAGIC1 + MAGIC2) & 0xFFFF;
        substr($$e,$j,1)=chr($clr);
    }

    return($e);
}

sub encrypt_exec
{
    my $la=shift;
    unshift(@{$la},0x44,0x65,0x72,0x69);
    my $res;
    my $cypher;
    my $er=E_DEF;

    foreach my $clr (@{$la})
    {
        $cypher=($clr ^ ($er >> 8)) & 0xFF;
        $er=(($cypher + $er) * MAGIC1 + MAGIC2) & 0xFFFF;
        $res.=pack('C',$cypher);
    }

    return($res);
}

sub encrypt_char
{
    my $la=shift;
    unshift(@{$la},0x44,0x65,0x72,0x69);
    my $res;
    my $cypher;
    my $cr=C_DEF;

    foreach my $clr (@{$la})
    {
        $cypher=($clr ^ ($cr >> 8)) & 0xFF;
        $cr=(($cypher + $cr) * MAGIC1 + MAGIC2) & 0xFFFF;
        $res.=pack('C',$cypher);
    }

    return($res);
}

sub map_subrs
{
    my $lines=shift;
    my $stage=0;
    my $lin=$lines->[0];
    my $i=0;

    for (my $j=0; $j<=$#{$lines}; $lin=$lines->[++$j] )
    {
        #       next if !defined($lines->[$j]);

        if ($stage == 0)
        {
            if ($lin=~m/^\s*\/Subrs \d+/)
            {
                $sec{'#Subrs'}=$j;
                $stage=1;
            }
        }
        elsif ($stage == 1)
        {
            if ($lin=~m/^\s*\d index \/CharStrings \d+/)
            {
                $sec{'#CharStrings'}=$j;
                $stage=2;
		$i=0;
            }
            elsif ($lin=~m/^\s*dup\s+(\d+)\s+(\d+)\s+RD (.*)/s)
            {
                my $n=$1;
                my $l=$2;
                my $s=$3;

                if (!exists($sec{"#$n"}))
                {
                    $sec{"#$n"}=[$j,{}];
                    $i=$j;
                    $sec{"#$n"}->[NEWNO]=$n if $n<=$newsub;
                }

                if (length($s) > $l)
                {
                    $s=substr($s,0,$l);
                }
                else
                {
                    $lin.=$term.$lines->[++$j];
                    $lines->[$j]=undef;
                    redo;
                }

                #               $s=decrypt_char($s);
                #               subs_call($s,"#$n");
                $lines->[$i]=["#$n",$l,$s,'NP'];
            }
            elsif ($lin=~m/^ND/)
            {}
            else
            {
                Warn("Don't understand '$lin'");
            }
        }
        elsif ($stage == 2)
        {
            if ($lin=~m/^0{64}/)
            {
                $sec{'#Pad'}=$j;
                $stage=3;
            }
            elsif ($lin=~m/^\s*\/([-.\w]*)\s+(\d+)\s+RD (.*)/s)
            {
                my $n=$1;
                my $l=$2;
                my $s=$3;

                $sec{"/$n"}=[$j,{}] if !exists($sec{"/$n"});

                if (length($s) > $l)
                {
                    $s=substr($s,0,$l);
                }
                else
                {
                    $lin.=$term.$lines->[++$j];
                    $lines->[$j]=undef;
		    $i--;
                    redo;
                }

                $i+=$j;

                if ($sec{"/$n"}->[0] != $i)
		{
		    # duplicate glyph name !!! discard ???
		    $lines->[$i]=undef;
		}
		else
		{
		    $lines->[$i]=["/$n",$l,$s,'ND'];
		}

		$i=0;
            }
            #       else
            #       {
            #           Warn("Don't understand '$lin'");
            #       }
        }
        elsif ($stage == 3)
        {
            if ($lin=~m/cleartomark/)
            {
                $sec{'#cleartomark'}=[$j];
                $stage=4;
            }
            elsif ($lin!~m/^0+$/)
            {
                Warn("Expecting padding - got '$lin'");
            }
        }
    }
}

sub subs_call
{
    my $charstr=shift;
    my $key=shift;
    my $lines=shift;
    my @c;

    for (my $j=0; $j<=$#{$charstr}; $j++)
    {
        my $n=$charstr->[$j];

        if ($n >= 32 and $n <= 246)
        {
            push(@c,[$n-139,1]);
        }
        elsif ($n >= 247 and $n <= 250)
        {
            push(@c,[(($n-247) << 8)+$charstr->[++$j]+108,1]);
        }
        elsif ($n >= 251 and $n <= 254)
        {
            push(@c,[-(($n-251) << 8)-$charstr->[++$j]-108,1]);
        }
        elsif ($n == 255)
        {
            $n=($charstr->[++$j] << 24)+($charstr->[++$j] << 16)+($charstr->[++$j] << 8)+$charstr->[++$j];
            $n=~$n if $n & 0x8000;
            push(@c,[$n,1]);
        }
        elsif ($n == 10)
        {
            if ($c[$#c]->[1])
            {
                $c[$#c]->[0]=MarkSub("#$c[$#c]->[0]");
                $c[$#c-1]->[0]=MarkSub("#$c[$#c-1]->[0]") if ($c[$#c]->[0] == 4 and $c[$#c-1]->[1]);
            }
            push(@c,[10,0]);
        }
        elsif ($n == 12)
        {
            push(@c,[12,0]);
            my $n2=$charstr->[++$j];
            push(@c,[$n2,0]);

            if ($n2==6)         # seac
            {
                my $ch=$StdEnc{$c[$#c-2]->[0]};
                my $chf;

                #               if ($ch ne 'space')
                {
                    ($chf)=GetNAM($thisfnt,$ch);

                    if (!defined($chf->[MINOR]))
                    {
                        AssignGlyph($thisfnt,$chf,$ch);
                        Subset($lines,"$chf->[PSNAME]");
                        push(@{$seac{$key}},"$ch");
                    }
                }

                $ch=$StdEnc{$c[$#c-3]->[0]};

                if ($ch ne 'space')
                {
                    ($chf)=GetNAM($thisfnt,$ch);

                    if (!defined($chf->[MINOR]))
                    {
                        AssignGlyph($thisfnt,$chf,$ch);
                        Subset($lines,"$chf->[PSNAME]");
                        push(@{$seac{$key}},"$ch");
                    }
                }
            }
        }
        else
        {
            push(@c,[$n,0]);
        }
    }

    $sec{$key}->[CHARCHAR]=\@c;

    #     foreach my $j (@c) {Warn("Undefined op in $key") if !defined($j);}
}

sub Subset
{
    my $lines=shift;
    my $glyphs=shift;
    my $extra=shift;

    foreach my $g ($glyphs=~m/(\/[.\w]+)/g)
    {
        if (exists($sec{$g}))
        {
            $glyphseen{$g}=1;
            $g='/space' if $g eq '/ ';

            my $ln=$lines->[$sec{$g}->[LINE]];
            subs_call($sec{$g}->[CHARCHAR]=decrypt_char($ln->[STR]),$g,$lines);

            push(@glyphused,$g);
        }
        else
        {
            Warn("Can't locate glyph '$g' in font") if $g ne '/space';
        }
    }
}

sub MarkSub
{
    my $k=shift;

    if (exists($sec{$k}))
    {
        if (!defined($sec{$k}->[NEWNO]))
        {
            $sec{$k}->[NEWNO]=++$newsub;
            push(@subrused,$k);

            my $ln=$bl[$sec{$k}->[LINE]];
            subs_call($sec{$k}->[CHARCHAR]=decrypt_char($ln->[STR]),$k,\@bl);
        }

        return($sec{$k}->[NEWNO]);
    }
    else
    {
        Log(1,"Missing Subrs '$k'");
    }
}

sub encrypt
{
    my $lines=shift;

    if (exists($sec{'#Subrs'}))
    {
        $newsub++;
        $lines->[$sec{'#Subrs'}]=~s/\d+\s+array/$newsub array/;
    }
    else
    {
        Warn("Unable to locate /Subrs");
    }

    if (exists($sec{'#CharStrings'}))
    {
        my $n=$#glyphused+1;
        $lines->[$sec{'#CharStrings'}]=~s/\d+\s+dict /$n dict /;
    }
    else
    {
        Warn("Unable to locate /CharStrings");
    }

    my $bdy;

    for (my $j=0; $j<=$#{$lines}; $j++)
    {
        my $lin=$lines->[$j];

        next if !defined($lin);

        if (ref($lin) eq 'ARRAY' and $lin->[TYPE] eq 'NP')
        {
            foreach my $sub (@subrused)
            {
                if (exists($sec{$sub}))
                {
                    subs_call($sec{$sub}->[CHARCHAR]=decrypt_char($lines->[$sec{$sub}->[LINE]]->[STR]),$sub,$lines) if (!defined($sec{$sub}->[CHARCHAR]));
                    my $cs=encode_charstr($sec{$sub}->[CHARCHAR],$sub);
                    $bdy.="dup ".$sec{$sub}->[NEWNO].' '.length($cs)." RD $cs NP\n";
                }
                else
                {
                    Warn("Failed to locate Subr '$sub'");
                }
            }

            while (!defined($lines->[$j+1]) or ref($lines->[$j+1]) eq 'ARRAY') {$j++;};
        }
        elsif (ref($lin) eq 'ARRAY' and $lin->[TYPE] eq 'ND')
        {
            foreach my $chr (@glyphused)
            {
                if (exists($sec{$chr}))
                {
                    my $cs=encode_charstr($sec{$chr}->[CHARCHAR],$chr);
                    $bdy.="$chr ".length($cs)." RD $cs ND\n";
                }
                else
                {
                    Warn("Failed to locate glyph '$chr'");
                }
            }

            while (!defined($lines->[$j+1]) or ref($lines->[$j+1]) eq 'ARRAY') {$j++;};
        }
        else
        {
            $bdy.="$lin\n";
        }
    }

    my @bdy=unpack('C*',$bdy);
    return(encrypt_exec(\@bdy));
}

sub encode_charstr
{
    my $ops=shift;
    my $key=shift;
    my @c;

    foreach my $c (@{$ops})
    {
        my $n=$c->[0];
        my $num=$c->[1];

        if ($num)
        {
            if ($n >= -107 and $n <= 107)
            {
                push(@c,$n+139);
            }
            elsif ($n >= 108 and $n <= 1131)
            {
                my $hi=($n - 108)>>8;
                my $lo=($n - 108) & 0xff;
                push(@c,$hi+247,$lo);
            }
            elsif ($n <= -108 and $n >= -1131)
            {
                my $hi=abs($n + 108)>>8;
                my $lo=abs($n + 108) & 0xff;
                push(@c,$hi+251,$lo);
            }
            #       elsif ($n >= -32768 and $n <= 32767)
            #       {
            #           push(@c,28,($n>>8) & 0xff,$n & 0xff);
            #       }
            else
            {
                push(@c,255,($n >> 24) & 0xff, ($n >> 16) & 0xff, ($n >> 8) & 0xff, $n & 0xff );
            }
        }
        else
        {
            push(@c, $n);
        }
    }

    return(encrypt_char(\@c));
}

sub SubTag
{
    my $res;

    foreach (1..6)
    {
        $res.=chr(int((rand(26)))+65);
    }

    return($res.'+');
}


sub get_name {
    my ($otf, $number, $platform_id, $encoding_id, $language_id) = @_;
    $platform_id //= 3;
    $encoding_id //= 1;
    $language_id //= 0x409;
    $otf->{name}->read;
    $otf->{name}{strings}[$number][$platform_id][$encoding_id]{$language_id};
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
                    for (@{$_->{RULES}[$i]}) {
                        for (@{$_->{ACTION}}) {
                            while (my ($k, $v) = each %$_) {
                                $gpos->{$gid}{$k} = $v;
                            }
                        }
                    }
                }
            }

        } elsif ($value->{TYPE} == 2) {

            # Lookup type 2 subtable: pair adjustment positioning

            my $sub_index = 0;
            for (@{$value->{SUB}}) {

                my @gid;
                while (my ($gid, $i) = each %{$_->{COVERAGE}{val}}) {
                    $gid[$i] = $gid;
                }

                my $MATCH_TYPE  = $_->{MATCH_TYPE};
                my $ACTION_TYPE = $_->{ACTION_TYPE};

                if ($MATCH_TYPE eq 'g' && $ACTION_TYPE eq 'p') {

                    my $PairSetCount = @{$_->{RULES}};
                    for my $i (0 ..  $PairSetCount - 1) {
                        my $PairValueCount = @{$_->{RULES}[$i]};
                        for my $j (0 ..  $PairValueCount - 1) {
                            my $gid2 = $_->{RULES}[$i][$j]{MATCH}[0];
                            $gpos->{$gid[$i], $gid2} =
                                $_->{RULES}[$i][$j]{ACTION}[0];
                        }
                    }

                } elsif ($MATCH_TYPE eq 'c' && $ACTION_TYPE eq 'p') {

                    # $_->{FORMAT} = 2: Pair adjustment positioning
                    # format 2: class pair adjustment

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

        } else {
            die "gpos: unknown \$value->{TYPE}: $value->{TYPE}";
        }
    }

    $gpos;
}

1;

# Local Variables:
# fill-column: 72
# mode: CPerl
# End:
# vim: set cindent noexpandtab shiftwidth=4 softtabstop=4 textwidth=72:
