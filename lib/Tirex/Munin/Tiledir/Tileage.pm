#-----------------------------------------------------------------------------
#
#  Tirex/Munin/Tiledir/Tileage.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use List::Util;

use Tirex::Munin::Tiledir;

#-----------------------------------------------------------------------------

package Tirex::Munin::Tiledir::Tileage;
use base qw( Tirex::Munin::Tiledir );

=head1 NAME

Tirex::Munin::Tiledir::Tileage - Age of tiles

=head1 DESCRIPTION

Munin plugin for max age of metatiles on disk for a map and specified zoom levels or zoom level ranges.

=cut

sub config
{
    my $self = shift;

    my $map = $self->{'map'};

    my $config = <<EOF;
graph_title Max age of tiles for map $map
graph_vlabel Max age (hours)
graph_category tirex
graph_info Max age of metatiles on disk for map $map and specified zoom levels or zoom level ranges.
graph_scale no
EOF

    foreach my $zoomrange (@{$self->{'zoomranges'}})
    {
        $config .= sprintf("%s.info Zoomlevel %s\n", $zoomrange->get_id(), $zoomrange->to_s());
        $config .= sprintf("%s.label %s\n", $zoomrange->get_id(), $zoomrange->get_name());
        $config .= sprintf("%s.type GAUGE\n", $zoomrange->get_id());
    }

    return $config;
}

sub fetch
{
    my $self = shift;

    my $data = '';
    foreach my $zoomrange (@{$self->{'zoomranges'}})
    {
        my $max = 0;
        foreach my $z ($zoomrange->get_min() .. $zoomrange->get_max())
        {
            $max = List::Util::max($max, $self->{'stats'}->{$self->{'map'}}->[$z]->{'maxage'} // 0);
        }

        $data .= sprintf("%s.value %d\n", $zoomrange->get_id(), int($max / 3600));
    }

    return $data;
}

1;

#-- THE END ------------------------------------------------------------------
