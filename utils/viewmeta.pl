#!/usr/bin/perl

# viewmeta.pl
# -----------
#
# Script to display a meta tile file. 
# The full filename has to be given on the command line:
#
# viewmeta.pl /some/path/0/0/0/68/128.meta
#
# By default, display is scaled by factor 2; use "-s factor" to change.
#
# Written by Frederik Ramm <frederik.ramm@geofabrik.de>, public domain.

use GD;
use Fcntl qw(SEEK_SET SEEK_CUR O_RDONLY);
use strict;

my $filename;
my $scale = 2;

while (my $arg = shift)
{
    if ($arg =~ /^-s(\d*)/)
    {
        $scale = $1 || shift;
        die "-s requires numeric value" if ($scale <= 0);
    }
    elsif ($arg =~ /^-/)
    {
        print "Usage:\nviewmeta.pl [-s n] filename.meta\nDisplays the meta file, scaled by n.\n";
        exit;
    }
    else
    {
        $filename = $arg;
    }
}

die "no filename given" unless defined($filename);
sysopen(F, $filename, O_RDONLY) or die "cannot open $filename for reading";

my $header;
my $offsets;
sysread(F, $header, 20);
die "not a meta file" unless (substr($header, 0, 4) eq "META");

my ($magic, $count, $tilex, $tiley, $tilez) = unpack("lllll", $header);
sysread(F, $offsets, 8 * $count);

my $rows = int(sqrt($count));
my $cols = int(sqrt($count));
die "cannot determine number of rows and colums" unless ($rows * $cols == $count);

my @offset = unpack("ll" x $count, $offsets);
my @img;

my $tilewidth;
my $tileheight;

for (my $i = 0; $i < $count; $i++)
{
    die "problem with file offsets" unless (sysseek(F,0,SEEK_CUR) == $offset[$i*2]);
    my $png;
    sysread(F, $png, $offset[$i*2+1]);
    $img[$i] = GD::Image->newFromPngData($png);
    if (defined($tileheight))
    {
        die "tile $i has non-matching size" 
            unless ($img[$i]->width == $tilewidth && $img[$i]->height == $tileheight);
    }
    else
    {
        $tileheight = $img[$i]->height;
        $tilewidth = $img[$i]->width;
    }
}
close(F);

my $scaled_tilewidth = $tilewidth / $scale;
my $scaled_tileheight = $tileheight / $scale;

my $meta = new GD::Image($cols*$scaled_tilewidth+$cols-1,
    $rows*$scaled_tileheight+$rows-1, 1);
my $black = $meta->colorAllocate(0,0,0);

for (my $i=0; $i<$count; $i++)
{
    my $x = int($i/$rows) * ($scaled_tilewidth+1);
    my $y = ($i%$rows) * ($scaled_tileheight+1);
    $meta->copyResampled($img[$i], $x, $y, 0, 0,
        $scaled_tilewidth, $scaled_tileheight, $tilewidth, $tileheight);
}
for (my $i=0; $i<$rows; $i++)
{
    $meta->string(gdMediumBoldFont, 5, ($i+.5)*($scaled_tileheight+1), $tiley+$i,$black);
}
for (my $i=0; $i<$cols; $i++)
{
    $meta->string(gdMediumBoldFont, ($i+.5)*($scaled_tilewidth+1)-15, 5, $tilex+$i,$black);
}
my $p=int(100/$scale);
$meta->string(gdMediumBoldFont, $cols*($scaled_tilewidth+1)-140,
    $rows*($scaled_tileheight+1)-18, "zoom=$tilez scaled $p%", $black);
open (P, ">/tmp/viewmeta.$$.png");
print P $meta->png;
close(P);
system("display /tmp/viewmeta.$$.png") || system("eog /tmp/viewmeta.$$.png");
unlink "/tmp/viewmeta.$$.png";
