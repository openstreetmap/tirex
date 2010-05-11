#-----------------------------------------------------------------------------
#
#  t/metatile_basic.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;

#-----------------------------------------------------------------------------

eval { Tirex::Metatile->new( map => 'test', x =>  1, y => 2, z =>   1); }; if ($@ =~ /y must be between 0 and/) { pass(); } else { fail(); }
eval { Tirex::Metatile->new( map => 'test', x =>  1, y => 2, z => 100); }; if ($@ =~ /z must be between 0 and/) { pass(); } else { fail(); }
eval { Tirex::Metatile->new( map => 'test', x => -1, y => 1, z =>   1); }; if ($@ =~ /x must be between 0 and/) { pass(); } else { fail(); }
eval { Tirex::Metatile->new( map => 'test', x => -1, y => 1          ); }; if ($@ =~ /need z for new metatile/) { pass(); } else { fail(); }

my $mt1 = Tirex::Metatile->new( map => 'test', x => 1, y => 2, z => 3 );
isa_ok($mt1, 'Tirex::Metatile');

is($mt1->get_x(),    0,      'mt1 x');
is($mt1->get_y(),    0,      'mt1 y');
is($mt1->get_z(),    3,      'mt1 z');
is($mt1->get_map(),  'test', 'mt1 map');
is($mt1->get_filename(), '3/0/0/0/0/0.meta', 'mt1 get_filename');
is($mt1->filename(), '/test/3/0/0/0/0/0.meta', 'mt1 filename');
is($mt1->to_s(),     'map=test z=3 x=0 y=0', 'mt1 to_s');
ok($mt1->equals($mt1), 'mt1 == mt2');

my $mt2 = Tirex::Metatile->new( map => 'test', x => 23423, y => 1234, z => 15 );
isa_ok($mt2, 'Tirex::Metatile');

is($mt2->get_x(), 23416, 'mt2 x');
is($mt2->get_y(),  1232, 'mt2 y');
is($mt2->get_z(),    15, 'mt2 z');
is($mt2->get_map(),  'test', 'mt2 map');
is($mt2->get_filename(), '15/0/80/180/125/128.meta', 'mt2 get_filename');
is($mt2->filename(), '/test/15/0/80/180/125/128.meta', 'mt2 filename');
is($mt2->to_s(),     'map=test z=15 x=23416 y=1232', 'mt2 to_s');
ok(! $mt2->equals($mt1), 'mt1 != mt2');

my $mt2f = Tirex::Metatile->new_from_filename( $mt2->filename() );
isa_ok($mt2f, 'Tirex::Metatile', 'create mt2f from filename of mt2');
ok($mt2f->equals($mt2), 'mt2f and mt2 are the same');

my $mt2g = Tirex::Metatile->new_from_filename_and_map( $mt2->get_filename(), $mt2->get_map() );
isa_ok($mt2g, 'Tirex::Metatile', 'create mt2g from filename of mt2');
ok($mt2g->equals($mt2), 'mt2g and mt2 are the same');

#-----------------------------------------------------------------------------

my $ZOOM  = 12;
my $LIMIT = 2**$ZOOM;

my $m1 = Tirex::Metatile->new( map => 'test', z => $ZOOM, x => 0, y => $LIMIT-1 );
my $m2 = Tirex::Metatile->new_from_filename_and_map( $m1->get_filename(), $m1->get_map() );
ok($m1->equals($m2), 'm1 and m2 are the same');

$m1 = Tirex::Metatile->new( map => 'test', z => $ZOOM, x => $LIMIT-1, y => 0 );
$m2 = Tirex::Metatile->new_from_filename_and_map( $m1->get_filename(), $m1->get_map() );
ok($m1->equals($m2), 'm1 and m2 are the same');

foreach (1..100)
{
    $m1 = Tirex::Metatile->new( map => 'test', z => $ZOOM, x => int(rand($LIMIT)), y => int(rand($LIMIT)) );
    $m2 = Tirex::Metatile->new_from_filename( $m1->filename() );
    ok($m1->equals($m2), 'm1 and m2 are the same');
}

#-----------------------------------------------------------------------------

my $mz = Tirex::Metatile->new( map => 'test', z => 18, x => 99640, y => 148248 );

is($mz->get_x(),  99640, 'z18 x');
is($mz->get_y(), 148248, 'z18 y');

$mz = $mz->up();
is($mz->get_x(),  49816, 'z17 x');
is($mz->get_y(),  74120, 'z17 y');

$mz = $mz->up()->up()->up();
is($mz->get_x(),   6224, 'z14 x');
is($mz->get_y(),   9264, 'z14 y');

$mz = $mz->up()->up()->up()->up()->up()->up()->up()->up();
is($mz->get_x(),     24, 'z6 x');
is($mz->get_y(),     32, 'z6 y');

$mz = $mz->up()->up()->up()->up()->up()->up();
is($mz->get_x(),      0, 'z0 x');
is($mz->get_y(),      0, 'z0 y');

is($mz->up(), undef, 'no more up');


#-- THE END ------------------------------------------------------------------
