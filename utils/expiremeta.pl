#!/usr/bin/perl

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
# time offset in days to go back from current date
# when touching files 8000 ~= 22 years 
my $timeoffset = 8000;
my $map = undef;
my $configdir = "/etc/tirex";
my $dryrun = 0;

GetOptions("map=s" => \$map, "minzoom=i" => \$minz, "config=s" => \$configdir, "dryrun" => \$dryrun);

Tirex::Config::init("$configdir/tirex.conf");
Tirex::Renderer->read_config_dir($configdir);

if (!defined($map))
{
    printf STDERR "usage: $0 --map=mapname [--minzoom=z] [--config=configdir]\n";
    exit(1);
}

my $limit = [];
my $touched = 0;
my $nonex = 0;
my $recursed = 0;
my $reported = 0;
for (my $i=0; $i<21; $i++) { $limit->[$i] = 2**$i-1 };
my $time = time() - $timeoffset * 86400;
my $touch = File::Touch->new(mtime_only => 1, time => $time, no_create => 1);
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

printf("%d meta tiles reported, %d added through recursion, %d did not exist, %d %s\n",
   $reported, $recursed, $nonex, $touched,
   $dryrun ? "would have been touched if this hadn't been a dry run" : "touched");

sub touch_with_recurse {
    my ($x, $y, $z, $rec) = @_;

    my $mt = Tirex::Metatile->new(map => $map, x=>$x, y=>$y, z=>$z);
    my $fn = $mt->get_filename();
    $recursed++ if ($rec);
    my $fullname = $tiledir . '/' . $fn;
    if (-e $fullname) {
       $touch->touch($fullname) unless ($dryrun);
       $touched++;
    }
    else
    {
       $nonex++;
    }
    return if ($z<=$minz);
    touch_with_recurse(($x>>4)<<3,($y>>4)<<3,$z-1,1);
}
