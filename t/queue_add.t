#-----------------------------------------------------------------------------
#
#  t/queue_add.t
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

my @jobs = (
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x =>  1, y => 1, z => 9), prio => 10 ),
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x =>  9, y => 1, z => 9), prio =>  7 ),
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 20, y => 1, z => 9), prio =>  6 ),
);

isa_ok($jobs[0], 'Tirex::Job', 'job in array');

$q->add($jobs[0], $jobs[1]);
is($q->size(), 2, 'added two jobs');
$q->reset();

@jobs = (
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x =>  1, y => 1, z => 9), prio => 10 ),
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x =>  9, y => 1, z => 9), prio =>  7 ),
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 20, y => 1, z => 9), prio =>  6 ),
);
$q->add(@jobs);
is($q->size(), 3, 'added three jobs');
$q->reset();

@jobs = (
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x =>  1, y => 1, z => 9), prio => 10 ),
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x =>  9, y => 1, z => 9), prio =>  7 ),
    Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 20, y => 1, z => 9), prio =>  6 ),
);
$q->add(\@jobs);
is($q->size(), 3, 'added three jobs');
$q->reset();


#-- THE END ------------------------------------------------------------------
