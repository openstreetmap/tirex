#-----------------------------------------------------------------------------
#
#  t/queue_many_jobs.t
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

isa_ok($q, 'Tirex::Queue', 'class');

sub create_job
{
    my ($max_z, $max_prio) = @_;
    my $z = int(rand($max_z+1));
    my $limit = 2 ** $z;
    return Tirex::Job->new( metatile => Tirex::Metatile->new( map => 'test', x => int(rand($limit)), y => int(rand($limit)), z => $z ), prio => int(rand($max_prio))+1 );
}

my @jobs;
my $count = 0;

foreach my $i (1..50) {
    my $job = create_job(10, 10);
    isa_ok($job, 'Tirex::Job', 'prime');

    $count++ unless ($q->in_queue($job));
    $q->add($job);
    is($q->size(), $count, 'size');
}

foreach my $i (0 .. 500) {
    if (rand() < 0.6)
    {
        my $job = create_job(10, 10, 10, 10);
        isa_ok($job, 'Tirex::Job', 'prime');
        $count++ unless ($q->in_queue($job));
        $q->add($job);
        is($q->size(), $count, 'size');
    }
    else
    {
        $count--;
        isa_ok($q->next(), 'Tirex::Job', 'removed');
        is($q->size(), $count, 'size when removing');
    }
}

while ($count > 0) {
    $count--;
    isa_ok($q->next(), 'Tirex::Job', 'removed');
    is($q->size(), $count, 'size when removing');
}

ok($q->empty, 'empty');


#-- THE END ------------------------------------------------------------------
