#-----------------------------------------------------------------------------
#
#  Tirex/Munin/Status/QueuedRequestsAge.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use List::Util;

use Tirex::Munin::Status;

#-----------------------------------------------------------------------------

package Tirex::Munin::Status::QueuedRequestsAge;
use base qw( Tirex::Munin::Status );

=head1 NAME

Tirex::Munin::Status::QueuedRequestsAge - Age of queued requests

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS

=cut

sub config
{
    my $self = shift;

    my $config = <<EOF;
graph_title Age of queued requests
graph_vlabel age in seconds
graph_category tirex
graph_args --lower-limit 1 --logarithmic --units=si
graph_info Age of oldest requests in the queue for each bucket (ie. range of priorities)
EOF

    foreach my $bucket (sort { $b->{'minprio'} <=> $a->{'minprio'} } @{$self->{'status'}->{'rm'}->{'buckets'}})
    {
        my $id = Tirex::Munin::make_id($bucket->{'name'});

        $config .= sprintf("age_%s.info Age of oldest request queued in bucket %s (prio %s-%s)\n", $id, $bucket->{'name'}, $bucket->{'minprio'}, ($bucket->{'maxprio'} > 0) ? $bucket->{'maxprio'} : '');
        $config .= sprintf("age_%s.label queued in %s\n", $id, $bucket->{'name'});
        $config .= sprintf("age_%s.type GAUGE\n", $id);
        $config .= sprintf("age_%s.draw LINE2\n", $id);
    }

    return $config;
}

sub fetch
{
    my $self = shift;

    my @sorted_buckets = sort { $a->{'minprio'} <=> $b->{'minprio'} } @{$self->{'status'}->{'rm'}->{'buckets'}};

    my $age = {};
    foreach my $pq (@{$self->{'status'}->{'queue'}->{'prioqueues'}})
    {
        my $prio = $pq->{'prio'};
        foreach my $bucket (@sorted_buckets)
        {
            if (($bucket->{'minprio'} <= $prio) && ($bucket->{'maxprio'} == 0 || $bucket->{'maxprio'} >= $prio))
            {
                $age->{$bucket->{'name'}} += List::Util::max($age->{$bucket->{'name'}} // 0, $pq->{'age_first'} // 0);
                last;
            }
        }
    }

    my $data = '';
    foreach my $bucket (@sorted_buckets)
    {
        my $id = Tirex::Munin::make_id($bucket->{'name'});

        $data .= sprintf("age_%s.value %s\n", $id, $bucket->{'numproc'} == 0 ? 'U' : $age->{$bucket->{'name'}} // 0);
    }

    return $data;
}


1;

#-- THE END ------------------------------------------------------------------
