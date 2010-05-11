#-----------------------------------------------------------------------------
#
#  Tirex/Queue.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;
use Data::Dumper;

use Tirex::Job;
use Tirex::PrioQueue;

#-----------------------------------------------------------------------------

package Tirex::Queue;

=head1 NAME

Tirex::Queue - Job queue for Tirex system

=head1 SYNOPSIS

 use Tirex::Queue;

 my $q = Tirex::Queue->new();
 $q->add( Tirex::Job->new(...) );

 my $job = $q->next();

=head1 DESCRIPTION

Tirex::Queue implements a prioritized queue of L<Tirex::Job> items.

=head1 METHODS

=head2 Tirex::Queue->new()

Create new Tirex queue object. Normally, this can not fail.

=cut

sub new
{
    my $class = shift;
    my %args = ();
    my $self = bless \%args => $class;

    return $self->reset();
}

=head2 $queue->reset()

Reset the queue. All jobs on the queue will be lost!

Returns queue itself, so that calls can be chained.

=cut

sub reset
{
    my $self = shift;
    $self->{'queues'}  = [];
    $self->{'jobs'}    = {};
    $self->{'size'}    = 0;
    $self->{'maxsize'} = 0;
    return $self;
}

=head2 $queue->size()

Returns the size of the queue.

There can be jobs on the queue that are already expired, they will still be counted
in this size value.

=cut

sub size
{
    my $self = shift;
    return $self->{'size'};
}

=head2 $queue->empty()

Is the queue empty?

Returns true if the queue is empty, false otherwise.

=cut

sub empty
{
    my $self = shift;
    return $self->size() == 0;
}

=head2 $queue->status()

Return status of the queue.

=cut

sub status
{
    my $self = shift;

    my @pq = map { $_->status(); } grep { defined($_); } @{$self->{'queues'}};

    my %status = (
        size       => 0 + $self->{'size'},    # force integer for JSON
        maxsize    => 0 + $self->{'maxsize'}, # force integer for JSON
        prioqueues => \@pq,
    );

    return \%status;
}

=head2 $queue->add($job1, $job2, ...)

Adds one or more jobs to the queue. You can also call it with an array reference
and all jobs inside the array will be added to the queue.

Returns queue itself, so that calls can be chained.

=cut

sub add
{
    my $self = shift;

    while (defined(my $job = shift))
    {
        if (ref($job) eq 'ARRAY')
        {
            foreach my $j (@$job)
            {
                Carp::croak('Can only add objects of type Tirex::Job to queue!') unless (ref($j) eq 'Tirex::Job');
                $self->_add($j);
            }
        }
        elsif (ref($job) eq 'Tirex::Job')
        {
            $self->_add($job);
        }
        else
        {
            Carp::croak('Can only add objects of type Tirex::Job to queue!');
        }
    }
    return $self;
}

sub _add
{
    my $self = shift;
    my $newjob = shift;

    my $oldjob = $self->remove($newjob);
    $newjob = $oldjob->merge($newjob) if ($oldjob);

    my $prio = $newjob->get_prio();
    $self->{'queues'}->[$prio] = Tirex::PrioQueue->new(prio => $prio) unless (defined($self->{'queues'}->[$prio]));
    $self->{'queues'}->[$prio]->add($newjob);

    $self->{'jobs'}->{$newjob->hash_key()} = $newjob;
    $self->{'size'}++;
    $self->{'maxsize'} = $self->{'size'} if ($self->{'size'} > $self->{'maxsize'});
}

sub remove
{
    my $self = shift;
    my $job  = shift;

    my $oldjob = $self->{'jobs'}->{$job->hash_key()};

    if (defined $oldjob)
    {
        $self->{'queues'}->[$oldjob->get_prio()]->remove($oldjob);
        delete $self->{'jobs'}->{$oldjob->hash_key()};
        $self->{'size'}--;
    }

    return $oldjob;
}

=head2 $queue->in_queue($job)

Is this metatile already in the queue? Returns the job that is in
the queue or undef, if its not in there.

=cut

sub in_queue
{
    my $self = shift;
    my $job = shift;
    return $self->{'jobs'}->{$job->hash_key()};
}

=head2 $queue->next()

Removes the topmost job from the queue and return it.
Returns undef if the queue is empty.

=cut

sub next
{
    my $self = shift;

    my $q;
    foreach my $q (@{$self->{'queues'}})
    {
        if (defined($q) && !$q->empty())
        {
            my $job = $q->next();
            delete($self->{'jobs'}->{$job->hash_key()});
            $self->{'size'}--;
            return $job;
        }
    }

    return undef;
}

=head2 $queue->peek()

Peek at the topmost job from the queue and return it.
Does not remove the job from queue. Returns undef if the queue is empty.

=cut

sub peek
{
    my $self = shift;

    my $q;
    foreach my $q (@{$self->{'queues'}})
    {
        return $q->peek() if (defined($q) && ! $q->empty());
    }
    return undef;
}

=head2 $pq->reset_maxsize()

Reset maxsize. New maxsize will be equal to current size.

Returns new maxsize;

=cut

sub reset_maxsize
{
    my $self = shift;

    $self->{'maxsize'} = $self->{'size'};
    foreach my $q (@{$self->{'queues'}}) {
        $q->reset_maxsize() if (defined $q);
    }

    return $self->{'maxsize'};
}

# calculate queue size (debugging only)
sub _calc_size
{
    my $self = shift;
    my $sum = 0;

    foreach my $q (@{$self->{'queues'}})
    {
        if (defined($q))
        {
            foreach my $j (@$q)
            {
                $sum++ if (defined($j));
            }
        }
    }

    return $sum;
}

=head2 $pq->remove_jobs_for_unknown_maps()

Remove all jobs from this prioqueue where the map is undefined. This can happen
after a reload of the config file, when a map was deleted from it.

=cut

sub remove_jobs_for_unknown_maps
{
    my $self = shift;

    foreach my $prioqueue (@{$self->{'queues'}})
    {
        $prioqueue->remove_jobs_for_unknown_maps() if (defined $prioqueue);
    }
}

=head1 SEE ALSO

L<Tirex::PrioQueue>, L<Tirex::Job>

=cut


1;

#-- THE END ------------------------------------------------------------------
