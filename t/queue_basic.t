#-----------------------------------------------------------------------------
#
#  t/queue_basic.t
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
isa_ok($q, 'Tirex::Queue', 'type of queue is Tirex::Queue');

#-----------------------------------------------------------------------------

ok($q->empty(), 'empty queue');
$q->add( Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 2), prio => 1 ) );
ok(! $q->empty(), 'non-empty queue');
is($q->size(), 1, 'one job in queue');

my $j = $q->peek();
is($q->size(), 1, 'one job in queue');
isa_ok($j, 'Tirex::Job', 'first element in queue');
is($j->{'prio'}, 1, 'prio still the same');

$j = $q->next();
is($q->size(), 0, 'no job in queue');
isa_ok($j, 'Tirex::Job', 'got job from queue');

$q->add( Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 2), prio => 1 ) );

is($q->size(), 1, 'one job in queue');
isa_ok($q->in_queue( Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 2), prio => 1 ) ), 'Tirex::Job', 'in queue');
$q->reset();
is($q->in_queue( Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 2), prio => 1 ) ), undef, 'not in queue');
ok($q->empty(), 'queue empty after reset');

is($q->next(), undef, 'next on empty queue returns undef');
is($q->peek(), undef, 'peek on empty queue returns undef');

eval {
    $q->add(1);
};

if ($@ =~ /^Can only add objects of type Tirex::Job to queue!/) {
    pass();
} else {
    fail();
}


#-- THE END ------------------------------------------------------------------
