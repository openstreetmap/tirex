#-----------------------------------------------------------------------------
#
#  Tirex/Munin/Status/RenderTime.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Tirex::Munin::Status;

#-----------------------------------------------------------------------------

package Tirex::Munin::Status::RenderTime;
use base qw( Tirex::Munin::Status );

=head1 NAME

Tirex::Munin::Status::RenderTime - Rendering time for requests

=head1 DESCRIPTION

Munin plugin for milliseconds each second spend rendering tiles for a map.

=cut

sub config
{
    my $self = shift;
    my $map = $self->{'map'};

    my $config = '';

    if ($map eq '*')
    {
        $config .= "graph_title Render time\n";
    }
    else
    {
        $config .= sprintf("graph_title Render time for map %s\n", $map);
    }

    $config .= <<EOF;
graph_vlabel millisecond/second
graph_category tirex
graph_args --lower-limit 0
graph_scale no
EOF

    if ($map eq '*')
    {
        $config .= "graph_info Milliseconds each second spend rendering tiles\n";
    }
    else
    {
        $config .= sprintf("graph_info Milliseconds each second spend rendering tiles for map %s\n", $map);
    }

    foreach my $zoomrange (@{$self->{'zoomranges'}})
    {
        my $id   = $zoomrange->get_id();
        $config .= sprintf("%s.info Time spend rendering per second for zoom levels %s\n", $id, $zoomrange->to_s());
        $config .= sprintf("%s.label %s\n",    $id, $zoomrange->get_name());
        $config .= sprintf("%s.type DERIVE\n", $id);
        $config .= sprintf("%s.min 0\n",       $id);
    }

    return $config;
}

sub fetch
{
    my $self = shift;

    my $data = '';
    foreach my $zoomrange (@{$self->{'zoomranges'}})
    {
        my $sum = 0;
        foreach my $z ($zoomrange->get_min() .. $zoomrange->get_max())
        {
            if ($self->{'map'} eq '*')
            {
                my $maps = $self->{'status'}->{'rm'}->{'stats'}->{'sum_render_time'};
                while ( my ($map, $stats) = each( %$maps ) )
                {
                    $sum += ($stats->[$z] // 0);
                }
            }
            else
            {
                $sum += ($self->{'status'}->{'rm'}->{'stats'}->{'sum_render_time'}->{$self->{'map'}}->[$z] // 0);
            }
        }
        $data .= sprintf("%s.value %d\n", $zoomrange->get_id(), $sum);
    }

    return $data;
}

1;

#-- THE END ------------------------------------------------------------------
