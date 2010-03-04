#-----------------------------------------------------------------------------
#
#  Tirex/Munin/Status/QueuedRequests.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Tirex::Munin::Status;

#-----------------------------------------------------------------------------

package Tirex::Munin::Status::QueuedRequests;
use base qw( Tirex::Munin::Status );

=head1 NAME

Tirex::Munin::Status::QueuedRequests - Queued requests

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS

=cut

sub config
{
    my $self = shift;

    my $config = <<EOF;
graph_title Queued requests
graph_vlabel queue size
graph_category tirex
graph_args --lower-limit 0
graph_info Number of metatile requests queued for rendering. This is reported per bucket (ie. range of priorities).
EOF

    my $draw = 'AREA';
    foreach my $bucket (sort { $b->{'minprio'} <=> $a->{'minprio'} } @{$self->{'status'}->{'rm'}->{'buckets'}})
    {
        my $id = Tirex::Munin::make_id($bucket->{'name'});

        $config .= sprintf("req_%s.info Number of requests currently queued in bucket %s (prio %s-%s)\n", $id, $bucket->{'name'}, $bucket->{'minprio'}, ($bucket->{'maxprio'} > 0) ? $bucket->{'maxprio'} : '');
        $config .= sprintf("req_%s.label queued in %s\n", $id, $bucket->{'name'});
        $config .= sprintf("req_%s.type GAUGE\n", $id);
        $config .= sprintf("req_%s.draw %s\n", $id, $draw);

        $draw = 'STACK';
    }

    return $config;
}

sub fetch
{
    my $self = shift;

    my @sorted_buckets = sort { $a->{'minprio'} <=> $b->{'minprio'} } @{$self->{'status'}->{'rm'}->{'buckets'}};

    my $sum = {};
    foreach my $pq (@{$self->{'status'}->{'queue'}->{'prioqueues'}})
    {
        my $prio = $pq->{'prio'};
        foreach my $bucket (@sorted_buckets)
        {
            if (($bucket->{'minprio'} <= $prio) && ($bucket->{'maxprio'} == 0 || $bucket->{'maxprio'} >= $prio))
            {
                $sum->{$bucket->{'name'}} += $pq->{'size'};
                last;
            }
        }
    }

    my $data = '';
    foreach my $bucket (@sorted_buckets)
    {
        my $id = Tirex::Munin::make_id($bucket->{'name'});

        $data .= sprintf("req_%s.value %d\n", $id, $sum->{$bucket->{'name'}} // 0);
    }

    return $data;
}


1;

#-- THE END ------------------------------------------------------------------
