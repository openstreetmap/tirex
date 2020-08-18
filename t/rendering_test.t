#-----------------------------------------------------------------------------
#
#  t/rendering_test.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;
use Tirex::Queue;
use Tirex::Manager::Test;

#-----------------------------------------------------------------------------

my $queue = Tirex::Queue->new();
isa_ok($queue, 'Tirex::Queue', 'queue');

# we use the Tirex::Manager::Test class instead of Tirex::Manager because we can simulate different loads on the machine and fake sending and receiving of messages
my $rm = Tirex::Manager::Test->new( queue => $queue );
isa_ok($rm, 'Tirex::Manager', 'rendering manager');

my $bucket1 = $rm->add_bucket( name => 'live',   minprio =>  1, maxproc => 3, maxload => 30 );
my $bucket3 = $rm->add_bucket( name => 'backg',  minprio => 20, maxproc => 1, maxload => 10 );
my $bucket2 = $rm->add_bucket( name => 'middle', minprio => 10, maxproc => 2, maxload => 20 );

#-----------------------------------------------------------------------------

my $job = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'm', x => 1, y => 1, z => 1), prio => 1 );

is($rm->run(), undef, 'nothing to run');

$queue->add($job);

is($rm->run(), 1, 'ok to run');
is($rm->run(), undef, 'nothing to run');

is($rm->get_load(), 0, 'get load');
$rm->set_load(5.5);
is($rm->get_load(), 5.5, 'set load');

#-----------------------------------------------------------------------------

$job = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'm', x => 1, y => 1, z => 1), prio => 1, expire => time() + 10 );
$queue->add($job);
is($rm->run(), 1, 'job not expired');

$job = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'm', x => 1, y => 1, z => 1), prio => 1, expire => time() - 10 );
$queue->add($job);
is($rm->run(), 2, 'job expired');


#-- THE END ------------------------------------------------------------------
