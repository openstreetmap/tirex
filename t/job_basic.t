#-----------------------------------------------------------------------------
#
#  t/job_basic.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;

#-----------------------------------------------------------------------------

my $mt1 = Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 9);

my $j1 = Tirex::Job->new( metatile => $mt1, prio => 1 );
my $j2 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 9), prio => 1 );
my $j3 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 8, y => 1, z => 9), prio => 1 );

isa_ok($j1, 'Tirex::Job', 'class');
is($j1->get_prio(), 1, 'prio');
$j1->set_prio(3);
is($j1->get_prio(), 3, 'prio');
is($j1->get_metatile(), $mt1, 'metatile');

isnt($j1, $j2, 'not identical jobs');
ok($j1->same_tile($j2), 'but same tile');
ok(! $j1->same_tile($j3), 'not same tile');

is($j1->hash_key(), 'map=test z=9 x=0 y=0', 'hash key');

isnt($j1->get_id(), $j2->get_id(), 'ids are different 1');
isnt($j2->get_id(), $j3->get_id(), 'ids are different 2');

#-----------------------------------------------------------------------------

$j1->add_notify('x');
$j1->add_notify('y');
is_deeply($j1->{'notify'}, [ 'x', 'y' ], 'notify');


#-----------------------------------------------------------------------------

my $id1 = $j1->get_id();
my $msg = {
    'foo'  => 'bar',
    'x'    => 0,
    'y'    => 0,
    'z'    => 9,
    'prio' => 3,
    'map'  => 'test',
    'id'   => $id1,
    'type' => 'metatile_request'
};

is_deeply($msg, $j1->to_msg('type' => 'metatile_request', 'foo' => 'bar'), 'message');

is(<<EOF
foo=bar
id=$id1
map=test
prio=3
type=metatile_request
x=0
y=0
z=9
EOF
, $j1->to_s('type' => 'metatile_request', 'foo' => 'bar'), 'message');

#-----------------------------------------------------------------------------

my $job_not_expired = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 2), prio => 1, expire => time() + 10 );
my $job_is_expired  = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 2), prio => 1, expire => time() - 10 );

isa_ok($job_not_expired, 'Tirex::Job', 'create job');
isa_ok($job_is_expired,  'Tirex::Job', 'create job');

ok(!$job_not_expired->expired(), 'not expired');
ok( $job_is_expired->expired(),  'is expired');


#-- THE END ------------------------------------------------------------------
