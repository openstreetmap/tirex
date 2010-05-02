#-----------------------------------------------------------------------------
#
#  t/renderer_basic.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;
use Tirex::Renderer;

#-----------------------------------------------------------------------------

eval { Tirex::Renderer->new(                                                                                             ); }; ($@ =~ qr{missing name} ) ? pass() : fail();
eval { Tirex::Renderer->new( name => 'mapnik1'                                                                           ); }; ($@ =~ qr{missing type} ) ? pass() : fail();
eval { Tirex::Renderer->new( name => 'mapnik1', type => 'mapnik'                                                         ); }; ($@ =~ qr{missing path} ) ? pass() : fail();
eval { Tirex::Renderer->new( name => 'mapnik1', type => 'mapnik', path => '/usr/bin/tirex-renderer-mapnik'               ); }; ($@ =~ qr{missing port} ) ? pass() : fail();
eval { Tirex::Renderer->new( name => 'mapnik1', type => 'mapnik', path => '/usr/bin/tirex-renderer-mapnik', port => 1234 ); }; ($@ =~ qr{missing procs}) ? pass() : fail();

is(Tirex::Renderer->get('mapnik1'), undef, 'get');

my $r1 = Tirex::Renderer->new( name => 'mapnik1', type => 'mapnik', path => '/usr/bin/tirex-renderer-mapnik', port => 1234, procs => 3, fontdir => '/usr/lib/mapnik/fonts', fontdir_recurse => 0, plugindir => '/usr/lib/mapnik/input' );

isa_ok($r1, 'Tirex::Renderer', 'class');
is($r1->get_name(), 'mapnik1', 'name');
is($r1->get_type(), 'mapnik', 'type');
is($r1->get_path(), '/usr/bin/tirex-renderer-mapnik', 'path');
is($r1->get_port(), 1234, 'port');
is($r1->get_procs(), 3, 'procs');
is_deeply($r1->get_config(), {
    fontdir => '/usr/lib/mapnik/fonts',
    fontdir_recurse => 0,
    plugindir => '/usr/lib/mapnik/input'
}, 'config');

is($r1->to_s(), 'Renderer mapnik1: type=mapnik port=1234 procs=3 path=/usr/bin/tirex-renderer-mapnik fontdir=/usr/lib/mapnik/fonts fontdir_recurse=0 plugindir=/usr/lib/mapnik/input', 'to_s');

is(Tirex::Renderer->get('mapnik1'), $r1, 'get');
is(Tirex::Renderer->get('foo'), undef, 'get');

is_deeply(Tirex::Renderer->status(), [
    {
        name => 'mapnik1',
        type => 'mapnik',
        path => '/usr/bin/tirex-renderer-mapnik',
        port => 1234,
        procs => 3,
        fontdir => '/usr/lib/mapnik/fonts',
        fontdir_recurse => 0,
        plugindir => '/usr/lib/mapnik/input',
    },
], 'status');

eval { Tirex::Renderer->new( name => 'mapnik1', type => 'mapnik', path => '/usr/bin/tirex-renderer-mapnik', port => 1234, procs => 3, fontdir => '/usr/lib/mapnik/fonts', fontdir_recurse => 0, plugindir => '/usr/lib/mapnik/input' ); };
($@ =~ qr{exists}) ? pass() : fail();

eval { Tirex::Renderer->new_from_configfile('does not exist'); };
($@ =~ qr{Can't open renderer config file}) ? pass() : fail();

my $r3 = Tirex::Renderer->new_from_configfile('t/renderer.conf');
is(Tirex::Renderer->get('mapnik2'), $r3, 'get');

isa_ok($r3, 'Tirex::Renderer', 'class');
is($r3->get_name(), 'mapnik2', 'name');
is($r3->get_type(), 'mapnik', 'type');
is($r3->get_path(), '/usr/bin/tirex-renderer-mapnik', 'path');
is($r3->get_port(), 1234, 'port');
is($r3->get_procs(), 3, 'procs');

is($r3->num_workers(), 0, 'num workers 0');
$r3->add_worker(123);
is($r3->num_workers(), 1, 'num workers 1');
$r3->add_worker(345);
is($r3->num_workers(), 2, 'num workers 2');
$r3->remove_worker(123);
is($r3->num_workers(), 1, 'num workers 1');


#-- THE END ------------------------------------------------------------------
