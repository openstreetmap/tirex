#-----------------------------------------------------------------------------
#
#  t/bucket.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;
use Tirex::Manager::Bucket;

#-----------------------------------------------------------------------------

eval { Tirex::Manager::Bucket->new( Xname => 'name', minprio => 1, maxproc => 1, maxload => 1); };
if ($@ =~ /need 'name' parameter/) { pass() } else { fail() }

eval { Tirex::Manager::Bucket->new( name => 'name', Xminprio => 1, maxproc => 1, maxload => 1); };
if ($@ =~ /need 'minprio' parameter/) { pass() } else { fail() }

eval { Tirex::Manager::Bucket->new( name => 'name', minprio => 1, Xmaxproc => 1, maxload => 1); };
if ($@ =~ /need 'maxproc' parameter/) { pass() } else { fail() }

eval { Tirex::Manager::Bucket->new( name => 'name', minprio => 1, maxproc => 1, Xmaxload => 1); };
if ($@ =~ /need 'maxload' parameter/) { pass() } else { fail() }

#-----------------------------------------------------------------------------

my $job = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 1), prio => 2 );
isa_ok($job, 'Tirex::Job', 'job');

my $b_live   = Tirex::Manager::Bucket->new( name => 'live',   minprio =>  1, maxproc => 20, maxload => 50);
isa_ok($b_live, 'Tirex::Manager::Bucket', 'bucket live');

my $b_middle = Tirex::Manager::Bucket->new( name => 'middle', minprio => 10, maxproc => 15, maxload => 20);
isa_ok($b_middle, 'Tirex::Manager::Bucket', 'bucket middle');

my $b_backg  = Tirex::Manager::Bucket->new( name => 'backg',  minprio => 50, maxproc =>  5, maxload => 10);
isa_ok($b_backg, 'Tirex::Manager::Bucket', 'bucket backg');

is($b_live->get_numproc(), 0, 'numproc 0');
is($b_live->get_name, 'live', 'name live');

$b_live->add_job($job);
is($b_live->get_numproc(), 1, 'numproc 1');
is($job->get_bucket(), $b_live, 'get_bucket');

$b_live->remove_job($job);
is($b_live->get_numproc(), 0, 'numproc 0');
is($job->get_bucket(), undef, 'get_bucket');

#-----------------------------------------------------------------------------

ok($b_backg->can_render(4, 0), 'backg can render 4');
is($b_backg->can_render(5, 0), 0, 'backg can not render: procs > maxproc');
is($b_backg->can_render(4, 20), undef, 'backg can not render: load > maxload');

is($b_backg->get_active(), 1, 'active');
$b_backg->set_active(0);
is($b_backg->get_active(), 0, 'not active');
is($b_backg->can_render(4, 0), 0, 'can not render because not active');


#-- THE END ------------------------------------------------------------------
