#-----------------------------------------------------------------------------
#
#  Tirex/Munin/Tiledir.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use JSON;

use Tirex::Munin;

#-----------------------------------------------------------------------------

package Tirex::Munin::Tiledir;
use base qw( Tirex::Munin );

=head1 NAME

Tirex::Munin::Tiledir - Parent class for Tirex munin classes using tiledir stats

=head1 SYNOPSIS

my $m = Tirex::Munin::Tiledir::SomeSubclass->new(...)
$m->init();

=head1 DESCRIPTION


=head1 METHODS

=head2 $m->init_data([ statsfile => '...' ])

Initialize data source from stats file. If no stats file is given, 'stats_dir'
from the config is used.

=cut

sub init_data
{
    my $self = shift;
    my %args = @_;

    $self->{'statsfile'} = $args{'statsfile'} || (Tirex::Config::get('stats_dir', $Tirex::STATS_DIR) . '/tiles.stats');

    open(STATS, '<', $self->{'statsfile'}) or return;
    $self->{'stats'} = JSON::from_json(join('', <STATS>));
    close(STATS);

    return 1;
}


1;

#-- THE END ------------------------------------------------------------------
