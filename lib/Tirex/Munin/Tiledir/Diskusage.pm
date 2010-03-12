#-----------------------------------------------------------------------------
#
#  Tirex/Munin/Tiledir/Diskusage.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Tirex::Munin::Tiledir;

#-----------------------------------------------------------------------------

package Tirex::Munin::Tiledir::Diskusage;
use base qw( Tirex::Munin::Tiledir );

=head1 NAME

Tirex::Munin::Tiledir::Diskusage - Diskusage of tiledir

=head1 SYNOPSIS

my $m = Tirex::Munin::Tiledir::Diskusage->new(...)
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

    my $config = <<EOF;
graph_title Tile disk usage for map $map (file size)
graph_vlabel bytes
graph_category tirex
graph_info bytes on disk
graph_args --lower-limit 0 --base 1024
graph_info Sum of bytes in all metatile files for map $map and specified zoom levels or zoom level ranges. Actual disk usage will be a bit higher because of file system blocks.
EOF

    foreach my $zoomrange (@{$self->{'zoomranges'}})
    {
        my $id   = $zoomrange->get_id();
        my $type = $zoomrange eq $self->{'zoomranges'}->[0] ? 'AREA' : 'STACK';

        $config .= sprintf("%s.info Zoomlevel %s\n", $id, $zoomrange->to_s());
        $config .= sprintf("%s.label %s\n",          $id, $zoomrange->get_name());
        $config .= sprintf("%s.type GAUGE\n",        $id);
        $config .= sprintf("%s.draw %s\n",           $id, $type);
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
            $sum += ($self->{'stats'}->{$self->{'map'}}->[$z]->{'sumsize'} // 0);
        }
        $data .= sprintf("%s.value %d\n", $zoomrange->get_id(), $sum);
    }

    return $data;
}

1;

#-- THE END ------------------------------------------------------------------
