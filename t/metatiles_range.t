#-----------------------------------------------------------------------------
#
#  t/metatiles_range.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;

#-----------------------------------------------------------------------------

eval { Tirex::Metatiles::Range->new( z => 3, zmin => 2 ); }; ($@ =~ qr{you cannot have parameters 'z' and 'zmin'/'zmax'}) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( x => 3, xmin => 2 ); }; ($@ =~ qr{you cannot have parameters 'x' and 'xmin'/'xmax'}) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( y => 3, ymax => 4 ); }; ($@ =~ qr{you cannot have parameters 'y' and 'ymin'/'ymax'}) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( ymax => 4         ); }; ($@ =~ qr{'ymax' but missing 'ymin'}                       ) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( lonmin => 4.0     ); }; ($@ =~ qr{'lonmin' but missing 'lonmax'}                   ) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( foo => 3          ); }; ($@ =~ qr{unknown parameter: 'foo'}                        ) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( xmin => 'x'       ); }; ($@ =~ qr{xmin must be zero or positive integer}           ) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( ymin => 'x'       ); }; ($@ =~ qr{ymin must be zero or positive integer}           ) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( zmax => -1        ); }; ($@ =~ qr{zmax must be zero or positive integer}           ) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( lonmin => 'x'     ); }; ($@ =~ qr{lonmin must be legal degree value}               ) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( latmin => '12.'   ); }; ($@ =~ qr{latmin must be legal degree value}               ) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( lonmax => -1000   ); }; ($@ =~ qr{lonmax must be legal longitude value}            ) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( latmax => 92      ); }; ($@ =~ qr{latmax must be legal latitude value}             ) ? pass() : fail();

#-----------------------------------------------------------------------------

my $r = Tirex::Metatiles::Range->new( map => 'test', z => 3, x => 5, y => 8 );
isa_ok($r, 'Tirex::Metatiles::Range', 'create r1');
is_deeply(['test'], $r->{'maps'}, 'r1 map');
is($r->{'zmin'}, 3, 'r1 zmin');
is($r->{'zmax'}, 3, 'r1 zmax');
is($r->{'xmin'}, 0, 'r1 xmin');
is($r->{'xmax'}, 0, 'r1 xmax');
is($r->{'ymin'}, 8, 'r1 ymin');
is($r->{'ymax'}, 8, 'r1 ymax');
is($r->count(), 1, 'r1 count');

$r = Tirex::Metatiles::Range->new( map => ['t1', 't2'], z => 3, x => '0-6', y => '7-8' );
isa_ok($r, 'Tirex::Metatiles::Range', 'create r2');
is_deeply(['t1', 't2'], $r->{'maps'}, 'r2 map');
is($r->{'zmin'}, 3, 'r2 zmin');
is($r->{'zmax'}, 3, 'r2 zmax');
is($r->{'xmin'}, 0, 'r2 xmin');
is($r->{'xmax'}, 0, 'r2 xmax');
is($r->{'ymin'}, 0, 'r2 ymin');
is($r->{'ymax'}, 8, 'r2 ymax');
is($r->count(), 2*1*2, 'r2 count');

$r = Tirex::Metatiles::Range->new( map => 't', z => 3, xmin => 5, xmax => 7, ymin => 7, ymax => 8 );
isa_ok($r, 'Tirex::Metatiles::Range', 'create r3');
is_deeply(['t'], $r->{'maps'}, 'r3 map');
is($r->{'zmin'}, 3, 'r3 zmin');
is($r->{'zmax'}, 3, 'r3 zmax');
is($r->{'xmin'}, 0, 'r3 xmin');
is($r->{'xmax'}, 0, 'r3 xmax');
is($r->{'ymin'}, 0, 'r3 ymin');
is($r->{'ymax'}, 8, 'r3 ymax');
is($r->count(), 1*1*2, 'r3 count');

$r = Tirex::Metatiles::Range->new( map => 'test', z => 3, lonmin => 8, lonmax => 9, latmin => 48, latmax => 49 );
isa_ok($r, 'Tirex::Metatiles::Range', 'create r4');
is_deeply(['test'], $r->{'maps'}, 'r4 map');
is($r->{'zmin'},    3, 'r4 zmin');
is($r->{'zmax'},    3, 'r4 zmax');
is($r->{'lonmin'},  8, 'r4 lonmin');
is($r->{'lonmax'},  9, 'r4 lonmax');
is($r->{'latmin'}, 48, 'r4 latmin');
is($r->{'latmax'}, 49, 'r4 latmax');
is($r->{'xmin'},    0, 'r4 xmin');
is($r->{'xmax'},    0, 'r4 xmax');
is($r->{'ymin'},    0, 'r4 ymin');
is($r->{'ymax'},    0, 'r4 ymax');
is($r->count(),     1, 'r4 count');

$r = Tirex::Metatiles::Range->new( map => 'test', z => 9, lon => '5.1,6.2', lat => '49.7,48.1' );
isa_ok($r, 'Tirex::Metatiles::Range', 'create r5');
is_deeply($r->{'maps'}, ['test'], 'r5 map');
is($r->{'zmin'},      9, 'r5 zmin');
is($r->{'zmax'},      9, 'r5 zmax');
is($r->{'lonmin'},  5.1, 'r5 lonmin');
is($r->{'lonmax'},  6.2, 'r5 lonmax');
is($r->{'latmin'}, 48.1, 'r5 latmin');
is($r->{'latmax'}, 49.7, 'r5 latmax');
is($r->{'xmin'},    256, 'r5 xmin');
is($r->{'xmax'},    264, 'r5 xmax');
is($r->{'ymin'},    168, 'r5 ymin');
is($r->{'ymax'},    176, 'r5 ymax');
is($r->count(),       4, 'r5 count');

$r = Tirex::Metatiles::Range->new( map => 'test', z => 9, lon => '4,8', lat => '40,50' );
isa_ok($r, 'Tirex::Metatiles::Range', 'create r6');

eval { Tirex::Metatiles::Range->new( init => 'flub' ); }; ($@ =~ qr{can't parse init string}) ? pass() : fail();

eval { Tirex::Metatiles::Range->new(); }; ($@ =~ qr{missing .* parameter}) ? pass() : fail();
eval { Tirex::Metatiles::Range->new( init => '' ); }; ($@ =~ qr{missing .* parameter}) ? pass() : fail();

$r = Tirex::Metatiles::Range->new( init => 'map=test z=9 lon=4,8 lat=40,50' );
isa_ok($r, 'Tirex::Metatiles::Range', 'create r7');
is_deeply($r->{'maps'}, ['test'], 'r7 map');
is($r->{'zmin'},      9, 'r7 zmin');
is($r->{'zmax'},      9, 'r7 zmax');
is($r->{'lonmin'},    4, 'r7 lonmin');
is($r->{'lonmax'},    8, 'r7 lonmax');
is($r->{'latmin'},   40, 'r7 latmin');
is($r->{'latmax'},   50, 'r7 latmax');
is($r->{'xmin'},    256, 'r7 xmin');
is($r->{'xmax'},    264, 'r7 xmax');
is($r->{'ymin'},    168, 'r7 ymin');
is($r->{'ymax'},    192, 'r7 ymax');
is($r->count(),   1*2*4, 'r7 count');


#-- THE END ------------------------------------------------------------------
