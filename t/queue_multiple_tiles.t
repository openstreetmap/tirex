#-----------------------------------------------------------------------------
#
#  t/queue_multiple_tiles.t
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

my $mt1 = Tirex::Metatile->new(map => 'test', x =>  0, y => 1, z => 5);
my $mt2 = Tirex::Metatile->new(map => 'test', x =>  8, y => 1, z => 5);
my $mt3 = Tirex::Metatile->new(map => 'test', x => 16, y => 1, z => 5);

my @jobs = (
    Tirex::Job->new(metatile => $mt1, prio => 1), # prio 1, x 1
    Tirex::Job->new(metatile => $mt2, prio => 2),
    Tirex::Job->new(metatile => $mt3, prio => 3),
    Tirex::Job->new(metatile => $mt2, prio => 1), # prio 1, x 2
    Tirex::Job->new(metatile => $mt1, prio => 2),
    Tirex::Job->new(metatile => $mt2, prio => 3),
    Tirex::Job->new(metatile => $mt1, prio => 1),
    Tirex::Job->new(metatile => $mt1, prio => 2),
    Tirex::Job->new(metatile => $mt3, prio => 2), # prio 2, x 3
    Tirex::Job->new(metatile => $mt2, prio => 2),
);

$q->add(@jobs);
is($q->size(), 3, 'all jobs in queue');

my $j = $q->next();
ok($j->same_tile($jobs[0]), 'jobs from queue 1');

$j = $q->next();
is($j->get_x(), 8, 'x from queue 2');
is($j->get_prio(), 1, 'prio from queue 2');

$j = $q->next();
is($j->get_x(), 16, 'x from queue 3');
is($j->get_prio(), 2, 'prio from queue 3');

ok($q->empty(), 'queue empty again');


#-- THE END ------------------------------------------------------------------
