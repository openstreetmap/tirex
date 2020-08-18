#-----------------------------------------------------------------------------
#
#  t/metatile_lonlat.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;

#-----------------------------------------------------------------------------

my $z = 10;
my $limit = 2 ** $z;

is(Tirex::Metatile::lon2x(1, $z, -180     ),          0, 'lon2x -180');
is(Tirex::Metatile::lon2x(1, $z, +180     ),   $limit-1, 'lon2x +180');
is(Tirex::Metatile::lon2x(1, $z,   -0.01  ), $limit/2-1, 'lon2x -0.01');
is(Tirex::Metatile::lon2x(1, $z,   +0.01  ),   $limit/2, 'lon2x +0.01');

is(Tirex::Metatile::lat2y(1, $z, -90      ),   $limit-1, 'lat2y -90');
is(Tirex::Metatile::lat2y(1, $z, +90      ),          0, 'lat2y +90');
is(Tirex::Metatile::lat2y(1, $z, -85.05113),   $limit-1, 'lat2y -85.05113');
is(Tirex::Metatile::lat2y(1, $z, +85.05113),          0, 'lat2y +85.05113');
is(Tirex::Metatile::lat2y(1, $z,  -0.01   ),   $limit/2, 'lat2y -0.01');
is(Tirex::Metatile::lat2y(1, $z,  +0.01   ), $limit/2-1, 'lat2y +0.01');

#-----------------------------------------------------------------------------

my $m1 = Tirex::Metatile->new_from_lon_lat( map => 'test', z => 17, lon => -1.616, lat => 49.533 );
isa_ok($m1, 'Tirex::Metatile', 'create m1');

is($m1->get_x(), 64944, 'm1 x');
is($m1->get_y(), 44712, 'm1 y');
is($m1->get_z(),    17, 'm1 z');

my $m2 = Tirex::Metatile->new_from_lon_lat( map => 'test', z => 14, lon => -180, lat => 85.05113 );
isa_ok($m2, 'Tirex::Metatile', 'create m2');

is($m2->get_x(),  0, 'm2 x');
is($m2->get_y(),  0, 'm2 y');
is($m2->get_z(), 14, 'm2 z');

my $m3 = Tirex::Metatile->new_from_lon_lat( map => 'test', z => 4, lon => 180, lat => -85.05112 );
isa_ok($m3, 'Tirex::Metatile', 'create m3');

is($m3->get_x(), 8, 'm3 x');
is($m3->get_y(), 8, 'm3 y');
is($m3->get_z(), 4, 'm3 z');


#-- THE END ------------------------------------------------------------------
