#-----------------------------------------------------------------------------
#
#  t/rendering_basic.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );

use JSON;
 
use lib 'lib';

use Tirex;
use Tirex::Queue;
use Tirex::Manager;

#-----------------------------------------------------------------------------

my $queue = Tirex::Queue->new();
isa_ok($queue, 'Tirex::Queue', 'queue');

my $rm = Tirex::Manager->new( queue => $queue );
isa_ok($rm, 'Tirex::Manager', 'rendering manager');

my $bucket1 = $rm->add_bucket( name => 'live',   minprio =>  1, maxproc => 3, maxload => 30 );
my $bucket3 = $rm->add_bucket( name => 'backg',  minprio => 20, maxproc => 1, maxload => 10 );
my $bucket2 = $rm->add_bucket( name => 'middle', minprio => 10, maxproc => 2, maxload => 20 );

isa_ok($bucket1, 'Tirex::Manager::Bucket', 'class');
isa_ok($bucket2, 'Tirex::Manager::Bucket', 'class')   ;
isa_ok($bucket3, 'Tirex::Manager::Bucket', 'class');

is($bucket1->get_maxprio(),     9, 'maxprio 1');
is($bucket2->get_maxprio(),    19, 'maxprio 2');
is($bucket3->get_maxprio(), undef, 'maxprio 3');

#-----------------------------------------------------------------------------

ok( $bucket1->for_prio( 1), 'bucket 1 for prio  1');
ok( $bucket1->for_prio( 9), 'bucket 1 for prio  9');
ok(!$bucket1->for_prio(10), 'bucket 1 for prio 10');
ok(!$bucket1->for_prio(19), 'bucket 1 for prio 19');
ok(!$bucket1->for_prio(20), 'bucket 1 for prio 20');
ok(!$bucket1->for_prio(99), 'bucket 1 for prio 99');

ok(!$bucket2->for_prio( 1), 'bucket 2 for prio  1');
ok(!$bucket2->for_prio( 9), 'bucket 2 for prio  9');
ok( $bucket2->for_prio(10), 'bucket 2 for prio 10');
ok( $bucket2->for_prio(19), 'bucket 2 for prio 19');
ok(!$bucket2->for_prio(20), 'bucket 2 for prio 20');
ok(!$bucket2->for_prio(99), 'bucket 2 for prio 99');

ok(!$bucket3->for_prio( 1), 'bucket 3 for prio  1');
ok(!$bucket3->for_prio( 9), 'bucket 3 for prio  9');
ok(!$bucket3->for_prio(10), 'bucket 3 for prio 10');
ok(!$bucket3->for_prio(19), 'bucket 3 for prio 19');
ok( $bucket3->for_prio(20), 'bucket 3 for prio 20');
ok( $bucket3->for_prio(99), 'bucket 3 for prio 99');

#-----------------------------------------------------------------------------

ok( $bucket1->can_render(0, 0), 'bucket 1 can 0, 0');
ok( $bucket2->can_render(0, 0), 'bucket 2 can 0, 0');
ok( $bucket3->can_render(0, 0), 'bucket 3 can 0, 0');

ok( $bucket1->can_render(1, 0), 'bucket 1 can 1, 0');
ok( $bucket2->can_render(1, 0), 'bucket 2 can 1, 0');
ok(!$bucket3->can_render(1, 0), 'bucket 3 can 1, 0');

ok( $bucket1->can_render(2, 0), 'bucket 1 can 2, 0');
ok(!$bucket2->can_render(2, 0), 'bucket 2 can 2, 0');
ok(!$bucket3->can_render(2, 0), 'bucket 3 can 2, 0');

ok(!$bucket1->can_render(3, 0), 'bucket 1 can 3, 0');
ok(!$bucket2->can_render(3, 0), 'bucket 2 can 3, 0');
ok(!$bucket3->can_render(3, 0), 'bucket 3 can 3, 0');

ok( $bucket1->can_render(0, 10), 'bucket 1 can 0, 10');
ok( $bucket2->can_render(0, 10), 'bucket 2 can 0, 10');
ok(!$bucket3->can_render(0, 10), 'bucket 3 can 0, 10');

ok(!$bucket1->can_render(0, 30), 'bucket 1 can 0, 30');
ok(!$bucket2->can_render(0, 30), 'bucket 2 can 0, 30');
ok(!$bucket3->can_render(0, 30), 'bucket 3 can 0, 30');

#-----------------------------------------------------------------------------

my $expected_status = {
    buckets => [
        { name => 'live',   minprio =>  1, maxprio =>  9, maxproc => 3, maxload => 30, numproc => 0, active => 1, can_render => JSON::true },
        { name => 'middle', minprio => 10, maxprio => 19, maxproc => 2, maxload => 20, numproc => 0, active => 1, can_render => JSON::true },
        { name => 'backg',  minprio => 20, maxprio =>  0, maxproc => 1, maxload => 10, numproc => 0, active => 1, can_render => JSON::true },
    ],
    num_rendering => 0,
    rendering     => [],
    stats         => {
        count_requested => 0,
        count_expired   => 0,
        count_timeouted => 0,
        count_error     => 0,
        count_rendered  => {},
        sum_render_time => {},
    },
};
my $is_status = $rm->status();
delete($is_status->{'load'}); # remove load because we don't know what it is
is_deeply($is_status, $expected_status, 'status');


#-- THE END ------------------------------------------------------------------
