#!/usr/bib/perl

# script to reset the time of all expired meta tiles to 1970-01-01,
# reads an expiry output file from osm2pgsql. 
# 
# if you are interested in e.g. expiring zoom 12-19 then use the -e9-16
# flag with osm2pgsql and load the resulting file into this program.

use strict;
use Tirex::Metatile;
use Tirex::Map;
use Tirex;
use File::Touch;
use Getopt::Long;

my $minz = 12;
my $map = undef;
my $configdir = "/etc/tirex";

GetOptions("map=s" => \$map, "minzoom=i" => \$minz, "config=s" => \$configdir);

Tirex::Config::init("$configdir/tirex.conf");
Tirex::Renderer->read_config_dir($configdir);

if (!defined($map))
{
    printf STDERR "usage: $0 --map=mapname [--minzoom=z] [--config=configdir]\n";
    exit(1);
}

my $limit = [];
my $processed = {};
my $touched = 0;
my $nonex = 0;
my $recursed = 0;
my $already = 0;
my $reported = 0;
for (my $i=0; $i<$minz; $i++) { $limit->[$i] = 2**$i-1 };
my $touch = File::Touch->new(time => 0, no_create => 1);
my $tiledir = Tirex::Map->get($map)->get_tiledir();

while(<STDIN>)
{
    my ($z, $x, $y) = split(/\//);
    if ($z < 0 or $z > 20 or $x < 0 or $y < 0 or $x > $limit->[$z] or $y > $limit->[$z])
    {
        die("invalid line on input: $_");
    }
    $reported++;
    touch_with_recurse($x<<3, $y<<3, $z+3, 0);
}

printf("%d meta tiles reported, %d added through recursion (%d duplicate), %d did not exist, %d touched\n",
   $reported, $recursed, $already, $nonex, $touched);

sub touch_with_recurse {
    my ($x, $y, $z, $rec) = @_;

    my $mt = Tirex::Metatile->new(map => $map, x=>$x, y=>$y, z=>$z);
    my $fn = $mt->get_filename();
    $recursed++ if ($rec);
    if (defined($processed->{$fn})) { $already++; return; }
    my $fullname = $tiledir . '/' . $fn;
    if (-e $fullname) {
       $touch->touch($fullname);
       $touched++;
       $processed->{$fn}=1;
    }
    else
    {
       $nonex++;
    }
    return if ($z<=$minz);
    touch_with_recurse(($x>>4)<<3,($y>>4)<<3,$z-1,1);
}
