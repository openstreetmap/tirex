#!/usr/bin/perl
#-----------------------------------------------------------------------------
#
#  Tirex Tile Rendering System
#
#  randomtest.pl
#
#-----------------------------------------------------------------------------
#
#  Send rendering requests for random metatiles and random priorities to
#  master in random intervals.
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

use Socket;
use IO::Socket;
use Time::HiRes;

use Tirex;
use Tirex::Status;

#-----------------------------------------------------------------------------

my $MAX_QUEUE_SIZE =     100;
my $SLEEP_TIME     =      60;
my $MAX_PRIO       =      20;
my $MIN_ZOOM       =       8;
my $MAX_ZOOM       =      18;
my $RANDOM_SLEEP   = 100_000;

# germany on z17
my $minx = 34067*2;
my $maxx = 35096*2;
my $miny = 21236*2;
my $maxy = 22739*2;

my $status = eval { Tirex::Status->new(); };
die("Cannot connect to shared memory. Is the tirex-master running?\n") if ($@);

my $socket = IO::Socket::INET->new(LocalAddr => 'localhost', Proto => 'udp') or die("Cannot open UDP socket: $!\n");
$socket->connect( Socket::pack_sockaddr_in($Tirex::MASTER_UDP_PORT, Socket::inet_aton('localhost')) );

my $count = 0;
while (1)
{
    my $x = int($minx + rand($maxx-$minx));
    my $y = int($miny + rand($maxy-$miny));
    my $z = int(rand($MAX_ZOOM - $MIN_ZOOM + 1)) + $MIN_ZOOM;

    my $zz=$z;
    while ($zz++ < 17) { $x >>= 2; $y >>= 2; }

    $x = int($x/8)*8;
    $y = int($y/8)*8;

    my $prio = 1 + int(rand($MAX_PRIO));

    my $msg = Tirex::Message->new( type => 'metatile_enqueue_request', prio => $prio, map => 'test', z => $z, x => $x, y => $y );
    print "sending msg ", $msg->to_s(), "\n";
    $msg->send($socket);

    Time::HiRes::usleep( rand($RANDOM_SLEEP) );

    if ($count++ % 10 == 0)
    {
        my $s = $status->read();
        die("Cannot read status\n") unless (defined $s);

        my $queue_size = JSON::from_json($s)->{'queue'}->{'size'};
        print "queue_size=$queue_size\n";

        if ($queue_size >= $MAX_QUEUE_SIZE)
        {
            print "queue size > $MAX_QUEUE_SIZE. sleeping for $SLEEP_TIME seconds.\n";
            sleep($SLEEP_TIME);
        }
    }
}


#-- THE END ------------------------------------------------------------------
