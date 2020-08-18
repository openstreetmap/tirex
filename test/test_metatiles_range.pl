#!/usr/bin/perl
#-----------------------------------------------------------------------------
#
#  Tirex Tile Rendering System
#
#  test_metatiles_range.pl
#
#-----------------------------------------------------------------------------
#
#  Test program for metatile range.
#
#  Usage:
#  test_metatiles_range.pl map=foo z=3-7 lon=-5,8 lat=60,70
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

use Tirex;

my $init = join(' ', @ARGV);

#-----------------------------------------------------------------------------

my $range = Tirex::Metatiles::Range->new( init => $init );

print " Map                Zoom          X          Y\n";
my $lastmap = '';
my $lastz   = 0;
while (my $metatile = $range->next())
{
    if ($lastmap ne $metatile->get_map() || $lastz != $metatile->get_z())
    {
        print " ---------------------------------------------\n";
    }
    printf(" %-20s %2d %10d %10d\n", $metatile->get_map(), $metatile->get_z(), $metatile->get_x(), $metatile->get_y());
    $lastmap = $metatile->get_map();
    $lastz   = $metatile->get_z();
}


#-- THE END ------------------------------------------------------------------
