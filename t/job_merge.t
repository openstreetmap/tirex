#-----------------------------------------------------------------------------
#
#  t/job_merge.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;

#-----------------------------------------------------------------------------

my $j1 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 2, z => 3), prio =>  1, expire => 10);
my $j2 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 2, z => 3), prio => 10, expire => 20);
my $j3 = Tirex::Job->new( metatile => Tirex::Metatile->new(map => 'test', x => 1, y => 2, z => 3), prio => 10);

my $j = $j1->merge($j2);

is($j->get_map(), 'test', 'map');
is($j->get_x(),        0, 'x');
is($j->get_y(),        0, 'y');
is($j->get_z(),        3, 'z');
is($j->get_prio(),     1, 'prio');
is($j->{'expire'},    20, 'expire');

is($j->{'request_time'}, $j1->{'request_time'}, 'request_time');
is_deeply($j->{'notify'}, [], 'notify');

isnt($j->get_id(), $j1->get_id(), 'id different 1');
isnt($j->get_id(), $j2->get_id(), 'id different 1');

#-----------------------------------------------------------------------------

is($j1->merge($j3)->{'expire'}, undef, 'expire undef');

#-----------------------------------------------------------------------------

$j1->add_notify('n1a');
$j1->add_notify('n1b');
$j2->add_notify('n2');

is_deeply($j1->merge($j2)->{'notify'}, ['n1a', 'n1b', 'n2'], 'notify j1/j2');
is_deeply($j1->merge($j3)->{'notify'}, ['n1a', 'n1b'], 'notify j1/j3');


#-- THE END ------------------------------------------------------------------
