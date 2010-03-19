#-----------------------------------------------------------------------------
#
#  Tirex/Munin/Tiledir/Tilecount.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Tirex::Munin::Tiledir;

#-----------------------------------------------------------------------------

package Tirex::Munin::Tiledir::Tilecount;
use base qw( Tirex::Munin::Tiledir );

=head1 NAME

Tirex::Munin::Tiledir::Tilecount - Number of tiles

=head1 SYNOPSIS

my $m = Tirex::Munin::Tiledir::Tilecount->new(...)
$m->init()
print $m->config()
print $m->fetch()

=head1 DESCRIPTION


=head1 METHODS

=cut

sub config
{
    my $self = shift;

    my $map = $self->{'map'};

    my $rel   = $self->{'relative'} ? 'relative' : 'absolute/stacked';
    my $label = $self->{'relative'} ? 'percentage of world covered' : 'number of meta tiles';

    my $config = <<EOF;
graph_title Tile count for map $map ($rel)
graph_vlabel $label
graph_category tirex
graph_info Number of meta tiles on disk for map $map and specified zoom levels or zoom level ranges.
graph_args --lower-limit 0
EOF
    $config .= "graph_scale no\n" if ($self->{'relative'});

    foreach my $zoomrange (@{$self->{'zoomranges'}})
    {
        my $id = $zoomrange->get_id();
        $config .= sprintf("%s.info Zoomlevel %s\n", $id, $zoomrange->to_s());
        $config .= sprintf("%s.label %s\n",          $id, $zoomrange->get_name());
        $config .= sprintf("%s.type GAUGE\n",        $id);
        if (! $self->{'relative'})
        {
            my $type = $zoomrange eq $self->{'zoomranges'}->[0] ? 'AREA' : 'STACK';
            $config .= sprintf("%s.draw %s\n", $id, $type);
        }
    }

    return $config;
}

sub fetch
{
    my $self = shift;

    my $data = '';
    foreach my $zoomrange (@{$self->{'zoomranges'}})
    {
        my $sum   = 0;
        my $total = 0;
        foreach my $z ($zoomrange->get_min() .. $zoomrange->get_max())
        {
            $sum   += ($self->{'stats'}->{$self->{'map'}}->[$z]->{'count'} // 0);
            $total += ($z < 4) ? 1 : 4 ** ($z - 3); # XXX metatile size
        }

        if ($self->{'relative'})
        {
            $sum *= 100 / $total if ($self->{'relative'});
            $sum = sprintf("%.2f", $sum);
        }
        else
        {
            $sum = sprintf("%d", $sum);
        }

        $data .= sprintf("%s.value %s\n", $zoomrange->get_id(), $sum);
    }

    return $data;
}

1;

#-- THE END ------------------------------------------------------------------
