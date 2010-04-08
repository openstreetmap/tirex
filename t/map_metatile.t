#-----------------------------------------------------------------------------
#
#  t/map_basic.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;
use Tirex::Map;

#-----------------------------------------------------------------------------

my $map_foo = Tirex::Map->new( name => 'foo', renderer => 'rand', tiledir => '/x', minz => 2, maxz => 10 );
my $map_bar = Tirex::Map->new( name => 'bar', renderer => 'rand', tiledir => '/x', minz => 0, maxz =>  8 );

my $mt1 = Tirex::Metatile->new( map => 'foo', x => 16, y => 17, z =>  8 );
my $mt2 = Tirex::Metatile->new( map => 'bar', x => 16, y => 17, z => 12 );
my $mt3 = Tirex::Metatile->new( map => 'baz', x => 16, y => 17, z =>  8 );

my $map1 = Tirex::Map->get_map_for_metatile($mt1);
is($map1, $map_foo, 'mt1 in foo');

eval { Tirex::Map->get_map_for_metatile($mt2); };
($@ =~ qr{zoom out of range} ) ? pass() : fail();

eval { Tirex::Map->get_map_for_metatile($mt3); };
($@ =~ qr{map with name 'baz' not found} ) ? pass() : fail();


#-- THE END ------------------------------------------------------------------
