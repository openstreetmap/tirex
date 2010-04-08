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

my $r = Tirex::Renderer->new( name => 'mapnik', type => 'mapnik', path => '/x', port => 1234, procs => 3 );

eval { Tirex::Map->new(                               ); }; ($@ =~ qr{missing name}     ) ? pass() : fail();
eval { Tirex::Map->new( name => 'foo'                 ); }; ($@ =~ qr{missing renderer} ) ? pass() : fail();
eval { Tirex::Map->new( name => 'foo', renderer => $r ); }; ($@ =~ qr{missing tiledir}  ) ? pass() : fail();

is(Tirex::Map->get('foo'), undef, 'get');

my $m1 = Tirex::Map->new( name => 'foo', renderer => $r, tiledir => '/var/lib/tirex/tiles/foo', minz => 2, maxz => 10 );

isa_ok($m1, 'Tirex::Map', 'class');
is($m1->get_name(), 'foo', 'name');
is($m1->get_tiledir(), '/var/lib/tirex/tiles/foo', 'tiledir');
is($m1->get_minz(),  2, 'minz');
is($m1->get_maxz(), 10, 'maxz');
is($m1->get_renderer(), $r, 'renderer');

is($m1->to_s(), 'Map foo: renderer=mapnik tiledir=/var/lib/tirex/tiles/foo zoom=2-10', 'to_s');

is(Tirex::Map->get('foo'), $m1, 'get');
is(Tirex::Map->get('bar'), undef, 'get');

is_deeply(Tirex::Map->status(), { 'foo' => {
        name => 'foo',
        tiledir => '/var/lib/tirex/tiles/foo',
        minz => 2,
        maxz => 10,
        renderer => $r,
    }
});

eval { Tirex::Map->new( name => 'foo', renderer => $r, tiledir => '/var/lib/tirex/tiles/foo' ); };
($@ =~ qr{exists}) ? pass() : fail();

my $m2 = Tirex::Map->new( name => 'default_z', renderer => $r, tiledir => '/var/lib/tirex/tiles/foo' );
is($m2->get_minz(),  0, 'minz');
is($m2->get_maxz(), 17, 'maxz');

eval { Tirex::Map->new_from_configfile('does not exist'); };
($@ =~ qr{Can't open map config file}) ? pass() : fail();

my $m3 = Tirex::Map->new_from_configfile('t/map.conf');
is(Tirex::Map->get('baz'), $m3, 'get');

isa_ok($m3, 'Tirex::Map', 'class');
is($m3->get_name(), 'baz', 'name');
is($m3->get_renderer(), $r, 'renderer');
is($m3->get_tiledir(), '/a/b/c', 'tiledir');
is($m3->get_minz(),  0, 'minz');
is($m3->get_maxz(), 14, 'maxz');


#-- THE END ------------------------------------------------------------------
