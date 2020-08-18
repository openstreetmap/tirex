#-----------------------------------------------------------------------------
#
#  t/prioqueue_basic.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;
use Tirex::PrioQueue;

#-----------------------------------------------------------------------------

is(Tirex::PrioQueue->new(), undef, 'failed, no prio');
is(Tirex::PrioQueue->new(prio => 'foo'), undef, 'failed, wrong prio');

my $pq = Tirex::PrioQueue->new(prio => 1);
isa_ok($pq, 'Tirex::PrioQueue', 'class');

is($pq->size(), 0, 'prio queue size 0');
ok($pq->empty(), 'prio queue empty');
is_deeply($pq->status(), { prio => 1, size => 0, maxsize => 0}, 'status empty');

is($pq->add('fail'), undef, 'can only add jobs');

my $j1 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 4), prio => 1 );
my $j2 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 2, z => 4), prio => 1 );
my $j3 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 3, z => 4), prio => 2 );

is($pq->add($j1), $j1, 'add 1');
is($pq->size(), 1, 'prio queue size 1');
ok(!$pq->empty(), 'prio queue not empty');

is($pq->add($j2), $j2, 'add 2');
is($pq->size(), 2, 'prio queue size 2');
ok(!$pq->empty(), 'prio queue not empty');

is($pq->add($j3), undef, 'wrong prio');
is($pq->size(), 2, 'prio queue size 2');
ok(!$pq->empty(), 'prio queue not empty');

is($pq->{'maxsize'}, 2, 'prio queue maxsize 2');

is($pq->remove($j1), $j1, 'remove 1');
is($pq->size(), 1, 'prio queue size 1');
ok(!$pq->empty(), 'prio queue not empty');

is($pq->{'maxsize'}, 2, 'prio queue maxsize 2');
$pq->reset_maxsize();
is($pq->{'maxsize'}, 1, 'prio queue maxsize 1');

is($pq->remove($j2), $j2, 'remove 2');
is($pq->size(), 0, 'prio queue size 0');
ok($pq->empty(), 'prio queue empty');

is($pq->remove($j2), undef, 'remove failed');

#-----------------------------------------------------------------------------

$pq = Tirex::PrioQueue->new(prio => 1);

$pq->add($j1);
$pq->add($j2);

is($pq->reset(), $pq, 'reset');
is($pq->size(), 0, 'prio queue size 0');
ok($pq->empty(), 'prio queue empty');

#-----------------------------------------------------------------------------

$pq = Tirex::PrioQueue->new(prio => 1);

$pq->add($j1);
$pq->add($j2);

$pq->remove($j2);
is($pq->size(), 1, 'prio queue size 1');
ok(!$pq->empty(), 'prio queue not empty');

$pq->add($j2);
is($pq->size(), 2, 'prio queue size 2');
ok(!$pq->empty(), 'prio queue not empty');

is($pq->peek(), $j1, 'peek');
is($pq->size(), 2, 'prio queue size 2');

is($pq->next(), $j1, 'next');
is($pq->size(), 1, 'prio queue size 1');

#-----------------------------------------------------------------------------

$pq = Tirex::PrioQueue->new(prio => 1);

my @jobs;
foreach my $n (0..9) {
    push(@jobs, $pq->add( Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => $n, z => 10), prio => 1 ) ));
}

is($pq->size(), 10, 'prio queue size 10');
is($pq->remove( $jobs[1] ), $jobs[1], 'remove 1');
is($pq->remove( $jobs[2] ), $jobs[2], 'remove 2');

is($pq->next(), $jobs[0], 'next');
is($pq->next(), $jobs[3], 'next');

is($pq->peek(), $jobs[4], 'next');
is($pq->size(), 6, 'prio queue size 6');

#-----------------------------------------------------------------------------

$pq = Tirex::PrioQueue->new(prio => 1);

is($pq->age_first(), undef, 'nothing in queue means no age');
is($pq->age_last(), undef, 'nothing in queue means no age');

my $job1 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 1), prio => 1 );
$pq->add($job1);
like($pq->age_first(), qr{^[01]$}, 'just added');
like($pq->age_last(),  qr{^[01]$}, 'just added');

my $job2 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 2, z => 5), prio => 1 );
$pq->add($job2);
$pq->remove($job2);
like($pq->age_first(), qr{^[01]$}, 'one in queue with age 0 or 1');
like($pq->age_last(),  qr{^[01]$}, 'one in queue with age 0 or 1');


#-- THE END ------------------------------------------------------------------
