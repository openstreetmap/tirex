#-----------------------------------------------------------------------------
#
#  t/zoomrange.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;

#-----------------------------------------------------------------------------

my $zr = Tirex::Zoomrange->new('z4-7', 4, 7);
isa_ok($zr, 'Tirex::Zoomrange', 'create');
is($zr->get_min(), 4, 'min');
is($zr->get_max(), 7, 'max');
is($zr->to_s(), '4-7', 'range');
is($zr->get_name(), 'z4-7', 'name');
is($zr->get_id(), 'z4_7', 'id');

$zr = Tirex::Zoomrange->new('foo', 8, 8);
is($zr->get_min(), 8, 'min');
is($zr->get_max(), 8, 'max');
is($zr->to_s(), '8', 'range');
is($zr->get_name(), 'foo', 'name');
is($zr->get_id(), 'foo', 'id');

$zr = Tirex::Zoomrange->new(undef, 6);
is($zr->get_min(), 6, 'min');
is($zr->get_max(), 6, 'max');
is($zr->get_name(), 'z6', 'name');

$zr = Tirex::Zoomrange->new(undef, 6, 8);
is($zr->get_min(), 6, 'min');
is($zr->get_max(), 8, 'max');
is($zr->get_name(), 'z6-8', 'name');


#-- THE END ------------------------------------------------------------------
