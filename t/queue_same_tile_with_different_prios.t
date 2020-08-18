#-----------------------------------------------------------------------------
#
#  t/queue_same_tile_with_different_prios.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;
use Tirex::Queue;

#-----------------------------------------------------------------------------

my $q = Tirex::Queue->new();

foreach my $prio (5, 3, 10, 8, 1, 9) {
    $q->add( Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 1), prio => $prio ) );
}

is($q->size(), 1, 'only one job');
my $j = $q->next();

is($j->get_prio(), 1, 'prio 1');
is($j->get_map(), 'test', 'map test');

$q->reset();

#-----------------------------------------------------------------------------

my @jobs = (
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x =>  7, y => 1, z => 9), prio => 8),
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x =>  8, y => 1, z => 9), prio => 5),
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 31, y => 1, z => 9), prio => 1),
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 32, y => 1, z => 9), prio => 9),
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 99, y => 1, z => 9), prio => 7),
);

$q->add(@jobs);
is($q->size(), scalar(@jobs), 'all jobs in queue');

is($q->next(), $jobs[2], 'jobs from queue 1');
is($q->next(), $jobs[1], 'jobs from queue 2');
is($q->next(), $jobs[4], 'jobs from queue 3');
is($q->next(), $jobs[0], 'jobs from queue 4');
is($q->next(), $jobs[3], 'jobs from queue 5');

ok($q->empty(), 'queue empty again');


#-- THE END ------------------------------------------------------------------
