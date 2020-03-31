#!/usr/bin/perl
#-----------------------------------------------------------------------------
#
#  Tirex Tile Rendering System
#
#  viewmeta.pl
#
#-----------------------------------------------------------------------------
#
#  Script to display a meta tile file. 
#  The full filename has to be given on the command line:
#
#  viewmeta.pl /some/path/0/0/0/68/128.meta
#
#  By default, display is scaled by factor 2; use "-s factor" to change.
#
#  Written by Frederik Ramm <frederik.ramm@geofabrik.de>, public domain.
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use GD;
use Fcntl qw(SEEK_SET SEEK_CUR O_RDONLY);

#-----------------------------------------------------------------------------

my $VIEWER = 'eog';

my $filename;
my $scale = 2;

while (my $arg = shift)
{
    if ($arg =~ /^-s(\d*)/)
    {
        $scale = $1 || shift;
        die("-s requires numeric value") if ($scale <= 0);
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

die("no filename given") unless defined($filename);
sysopen(META, $filename, O_RDONLY) or die("cannot open $filename for reading: $!");

my $header;
my $offsets;
sysread(META, $header, 20);
die("not a meta file") unless (substr($header, 0, 4) eq "META");

my ($magic, $count, $tilex, $tiley, $tilez) = unpack("lllll", $header);
sysread(META, $offsets, 8 * $count);

my $rows = int(sqrt($count));
my $cols = $rows;
die("cannot determine number of rows and colums") unless ($rows * $cols == $count);

my @offset = unpack("ll" x $count, $offsets);
my @img;

my $tilewidth;
my $tileheight;

foreach my $i (0 .. $count-1)
{
    die("problem with file offsets") unless (sysseek(META, 0, SEEK_CUR) == $offset[$i*2]);
    if ($offset[$i*2+1])
    {
        my $png;
        sysread(META, $png, $offset[$i*2+1]);
        $img[$i] = GD::Image->newFromPngData($png);
        if (defined $tileheight)
        {
            die("tile $i has non-matching size") 
                unless ($img[$i]->width == $tilewidth && $img[$i]->height == $tileheight);
        }
        else
        {
            $tileheight = $img[$i]->height;
            $tilewidth  = $img[$i]->width;
        }
    }
}
close(META);

my $scaled_tilewidth  = $tilewidth  / $scale;
my $scaled_tileheight = $tileheight / $scale;

my $meta = new GD::Image($cols*$scaled_tilewidth  + $cols - 1,
                         $rows*$scaled_tileheight + $rows - 1, 1);

$meta->saveAlpha(1);
$meta->alphaBlending(0);

my $black = $meta->colorAllocate(0, 0, 0);

for (my $i=0; $i<$count; $i++)
{
    if (defined($img[$i]))
    {
        my $x = int($i/$rows) * ($scaled_tilewidth  + 1);
        my $y =    ($i%$rows) * ($scaled_tileheight + 1);
        $meta->copyResampled($img[$i], $x, $y, 0, 0,
            $scaled_tilewidth, $scaled_tileheight, $tilewidth, $tileheight);
    }
}

for (my $i=0; $i<$rows; $i++)
{
    $meta->string(gdMediumBoldFont, 5, ($i+.5)*($scaled_tileheight+1), $tiley+$i, $black);
}

for (my $i=0; $i<$cols; $i++)
{
    $meta->string(gdMediumBoldFont, ($i+.5)*($scaled_tilewidth+1)-15, 5, $tilex+$i, $black);
}

my $p=int(100/$scale);

$meta->string(gdMediumBoldFont, $cols*($scaled_tilewidth+1)-140,
    $rows*($scaled_tileheight+1)-18, "zoom=$tilez scaled $p%", $black);

my $imagefile = "/tmp/viewmeta.$$.png";
open(IMAGE, '>', $imagefile) or die("cannot open $imagefile: $!");
binmode(IMAGE);
print IMAGE $meta->png();
close(IMAGE);

system("$VIEWER $imagefile");

unlink($imagefile);


#-- THE END ----------------------------------------------------------------------------
