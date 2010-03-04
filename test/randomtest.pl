#!/usr/bin/perl
#-----------------------------------------------------------------------------
#
#  Tirex Tile Rendering System
#
#  randomtest.pl
#
#-----------------------------------------------------------------------------
#
#  Copyright (C) 2010  Frederik Ramm <frederik.ramm@geofabrik.de> and
#                      Jochen Topf <jochen.topf@geofabrik.de>
#  
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; If not, see <http://www.gnu.org/licenses/>.
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Time::HiRes qw(usleep);

use Tirex::Status;

#-----------------------------------------------------------------------------

# germany on z17
my $minx = 34067*2;
my $maxx = 35096*2;
my $miny = 21236*2;
my $maxy = 22739*2;

my $status = eval { Tirex::Status->new(); };
die("Can't connect to shared memory. Is the tirex-master running?\n") if ($@);

my $count = 0;
while (1)
{
    my $x = int($minx + rand($maxx-$minx));
    my $y = int($miny + rand($maxy-$miny));
    my $z = int(rand(10) + 8);

    my $zz=$z;
    while ($zz++ < 17) { $x >>= 2; $y >>= 2; }

    $x = int($x/8)*8;
    $y = int($y/8)*8;

    my $prio = 1 + int(rand(30));
    my $cmd  = "bin/tirex-send --wait=0 metatile_enqueue_request map=tirex x=$x y=$y z=$z prio=$prio";

    print "$cmd\n";
    system($cmd);

    usleep( rand(100000) );

    if ($count++ % 10 == 0)
    {
        my $s = $status->read();
        die("Can't read status\n") unless (defined $s);

        my $queue_size = JSON::from_json($s)->{'queue'}->{'size'};
        print "queue_size=$queue_size\n";
        sleep(60) if ($queue_size > 100);
    }
}


#-- THE END ------------------------------------------------------------------
