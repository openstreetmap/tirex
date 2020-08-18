#-----------------------------------------------------------------------------
#
#  Tirex/Munin/Status/ActiveRequests.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Tirex::Munin::Status;

#-----------------------------------------------------------------------------

package Tirex::Munin::Status::ActiveRequests;
use base qw( Tirex::Munin::Status );

=head1 NAME

Tirex::Munin::Status::ActiveRequests - Currently rendering requests

=head1 DESCRIPTION

Munin plugin for number of metatile requests currently rendering. This is reported per bucket (ie. range of priorities).

=cut

sub config
{
    my $self = shift;

    my $config = <<EOF;
graph_title Active requests
graph_vlabel number of active requests
graph_category tirex
graph_args --lower-limit 0
graph_info Number of metatile requests currently rendering. This is reported per bucket (ie. range of priorities).
EOF

    my $draw = 'AREA';
    foreach my $bucket (sort { $b->{'minprio'} <=> $a->{'minprio'} } @{$self->{'status'}->{'rm'}->{'buckets'}})
    {
        my $id = Tirex::Munin::make_id($bucket->{'name'});

        $config .= sprintf("req_%s.info Number of requests currently processing for bucket %s (stacked graph)\n", $id, $bucket->{'name'});
        $config .= sprintf("req_%s.label rendering in %s\n", $id, $bucket->{'name'});
        $config .= sprintf("req_%s.type GAUGE\n", $id);
        $config .= sprintf("req_%s.draw %s\n", $id, $draw);

        $draw = 'STACK';
    }

    return $config;
}

sub fetch
{
    my $self = shift;

    my $data = '';
    foreach my $bucket (sort { $b->{'minprio'} <=> $a->{'minprio'} } @{$self->{'status'}->{'rm'}->{'buckets'}})
    {
        my $id = Tirex::Munin::make_id($bucket->{'name'});

        $data .= sprintf("req_%s.value %d\n", $id, $bucket->{'numproc'});
    }

    return $data;
}

1;

#-- THE END ------------------------------------------------------------------
