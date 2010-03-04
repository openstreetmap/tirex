#!/usr/bin/perl
#-----------------------------------------------------------------------------
#
#  Tirex Tile Rendering System
#
#  queue_speed_test.pl
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

use lib 'lib';

use Tirex;
use Tirex::Queue;

use Time::HiRes;

#-----------------------------------------------------------------------------

my $NUMJOBS = 100000;
my $MAXZOOM = 14;
my $MAXPRIO = 3;

#-----------------------------------------------------------------------------

my $q = Tirex::Queue->new();

my $t0 = [ Time::HiRes::gettimeofday() ];

print "filling queue...\n";

foreach my $n (0 .. $NUMJOBS-1) {
    my $z = int(rand($MAXZOOM));
    my $limit = 2 ** $z;
    my $mt = Tirex::Metatile->new( map => 'test', x => int(rand($limit)), y => int(rand($limit)), z => $z );
    $q->add( Tirex::Job->new( metatile => $mt, prio => int(rand($MAXPRIO))+1) );
}

print "queue filled with ", $q->size(), " jobs of ", $NUMJOBS , " added in ", Time::HiRes::tv_interval($t0), " seconds\n";

$t0 = [ Time::HiRes::gettimeofday() ];

until ($q->empty()) {
    my $job = $q->next();
}

print "queue empty again after ", Time::HiRes::tv_interval($t0), " seconds\n";


#-- THE END ------------------------------------------------------------------
