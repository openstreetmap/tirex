#-----------------------------------------------------------------------------
#
#  t/job_notify.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;
use Tirex::Source::Test;

#-----------------------------------------------------------------------------

my $j = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 1, z => 1), prio => 1);

$j->add_notify( Tirex::Source::Test->new('x') );
$j->add_notify( Tirex::Source::Test->new('y') );

is_deeply($j->notify(), [ 'x', 'y' ], 'notify');


#-- THE END ------------------------------------------------------------------
