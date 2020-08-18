#-----------------------------------------------------------------------------
#
#  t/rendering_jobs.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;
use Tirex::Manager::RenderingJobs;

#-----------------------------------------------------------------------------

eval { Tirex::Manager::RenderingJobs->new(); };
($@ =~ /missing or illegal timeout/) ? pass() : fail();

eval { Tirex::Manager::RenderingJobs->new( timeout => 'foo' ); };
($@ =~ /missing or illegal timeout/) ? pass() : fail();

my $rj = Tirex::Manager::RenderingJobs->new( timeout => 1 );
isa_ok($rj, 'Tirex::Manager::RenderingJobs', 'create');

my $job1 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 1), prio => 1 );
isa_ok($job1, 'Tirex::Job', 'create job 1');
my $job2 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 2, y => 2, z => 2), prio => 2 );
isa_ok($job2, 'Tirex::Job', 'create job 2');

is($rj->count(), 0, 'count 0');
is($rj->add($job1), $job1, 'add 1');
is($rj->count(), 1, 'count 1');
is($rj->add($job2), $job2, 'add 1');
is($rj->count(), 2, 'count 2');

is($rj->find_by_id($job1->get_id()), $job1, 'find_by_id');
is($rj->find_by_id('foo'), undef, 'find_by_id failed');

is($rj->find_by_metatile($job2->hash_key()), $job2, 'find_by_metatile');
is($rj->find_by_metatile('foo'), undef, 'find_by_metatile failed');

is($rj->remove($job1), $job1, 'remove 1');
is($rj->count(), 1, 'count 1');
is($rj->find_by_id($job1->get_id()), undef, 'find_by_id not any more');
is($rj->find_by_metatile($job1->hash_key()), undef, 'find_by_metatile not any more');

#-----------------------------------------------------------------------------

my $status = [{
    map  => 'test',
    x    => 0,
    y    => 0,
    z    => 2,
    prio => 2,
}];
my $rjstatus = $rj->status();
delete $rjstatus->[0]->{'age'}; # remove age because it is unpredictable
is_deeply($rjstatus, $status, 'status');

#-----------------------------------------------------------------------------

{
    # we redefine the syslog function to an empty function temporarily, so that the
    # check_timeout() method doesn't write to syslog
    no warnings 'redefine';
    local *main::syslog = sub { };

    is($rj->check_timeout(), 0, 'check_timeout');
    is($rj->count(), 1, 'count 1');
    sleep(2);
    is($rj->check_timeout(), 1, 'check_timeout');
    is($rj->count(), 0, 'count 0');
}


#-- THE END ------------------------------------------------------------------
