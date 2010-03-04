#-----------------------------------------------------------------------------
#
#  Tirex/PrioQueue.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;
use Data::Dumper;

use Tirex::Job;

#-----------------------------------------------------------------------------

package Tirex::PrioQueue;

=head1 NAME

Tirex::PrioQueue - Queue for one priority

=head1 SYNOPSIS

 use Tirex::PrioQueue;
 my $pq = Tirex::PrioQueue->new(prio => 7);

 $pq->add($job);
 $pq->remove($job);

 $job = $pq->next();

=head1 DESCRIPTION

PrioQueues hold all jobs with a certain priority. They are never accessed directly, only through a L<Tirex::Queue> object.

=head1 METHODS

=head2 Tirex::PrioQueue->new(prio => $prio);

Create new priority queue object.

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = bless \%args => $class;

    return undef unless (defined($self->{'prio'}) && $self->{'prio'} =~ /^[0-9]+$/);

    return $self->reset();
}

=head2 $pq->size()

Returns the size of the priority queue.

=cut

sub size
{
    my $self = shift;
    return $self->{'size'};
}

=head2 $pq->empty()

Is the priority queue empty?

Returns true if the queue is empty, false otherwise.

=cut

sub empty
{
    my $self = shift;
    return $self->{'size'} == 0;
}

=head2 $pq->reset()

Reset the queue. All jobs on the queue will be lost!

Returns priority queue itself, so that calls can be chained.

=cut

sub reset
{
    my $self = shift;
    $self->{'queue'}   = [];
    $self->{'offset'}  = 0;
    $self->{'size'}    = 0;
    $self->{'maxsize'} = 0;
    return $self;
}

=head2 $pq->add($job)

Add job to priority queue. The job will only be added if the job priority and the queue priority are the same.
This method will *not* check whether a job for the same metatile is already in the queue.

Returns the job if it was added, undef otherwise.

=cut

sub add
{
    my $self = shift;
    my $job  = shift;

    return if (ref($job) ne 'Tirex::Job');
    return if ($job->get_prio() != $self->{'prio'});

    my $q = $self->{'queue'};
    push(@$q, $job);
    $job->set_pos($self->{'offset'} + scalar(@$q) - 1);
    $self->{'size'}++;
    $self->{'maxsize'} = $self->{'size'} if ($self->{'size'} > $self->{'maxsize'});

    return $job;
}

=head2 $pq->remove($job)

Remove a job from the priority queue.

Returns the job or undef if the job was not on this queue.

=cut

sub remove
{
    my $self = shift;
    my $job  = shift;

    return unless (defined $job->get_pos());

    my $pos = $job->get_pos() - $self->{'offset'};

    $self->{'queue'}->[$pos] = undef;
    $job->set_pos(undef);
    $self->{'size'}--;

    $self->clean();
    return $job;
}

=head2 $pq->clean()

The priority queue can have empty (undef) items in it where there was a real job that was
removed when another job for the same metatile came in. This method will clean those empty
items from the beginning and end of the queue. It is called from remove() and next() methods
to ensure that there are no empty items at the beginning or end at any time.

Returns priority queue itself, so that calls can be chained.

=cut

sub clean
{
    my $self = shift;

    my $q = $self->{'queue'};

    # remove undefs from end of queue
    while (scalar(@$q) > 0 && ! defined($q->[-1]))
    {
        pop(@$q);
    }

    # remove undefs from beginning of queue
    while (scalar(@$q) > 0 && ! defined($q->[0]))
    {
        shift(@$q);
        $self->{'offset'}++;
    }

    return $self;
}

=head2 $pq->peek()

Get first element of the priority queue without removing it.

Returns false if the queue is empty.

=cut

sub peek
{
    my $self = shift;

    return $self->{'queue'}->[0];
}

=head2 $pq->next()

Remove and return first element of the priority queue.

Returns false if there are no jobs in the queue.

=cut

sub next
{
    my $self = shift;

    my $q = $self->{'queue'};

    return if ($self->empty());

    $self->{'size'}--;
    $self->{'offset'}++;
   
    my $job = shift(@$q); 
    $job->set_pos(undef);

    $self->clean();
    return $job;
}

=head2 $pq->age_first()

Returns age (in seconds) of first job in the priority queue. Age is the difference between current and request time.

Returns false if the priority queue is empty.

=cut

sub age_first
{
    my $self = shift;

    return if ($self->empty());
    return $self->peek()->age();
}

=head2 $pq->age_last()

Returns age (in seconds) of last job in the priority queue. Age is the difference between current and request time.

Returns false if the priority queue is empty.

=cut

sub age_last
{
    my $self = shift;

    return if ($self->empty());
    return $self->{'queue'}->[-1]->age();
}

=head2 $pq->reset_maxsize()

Reset maxsize. New maxsize will be equal to current size.

Returns new maxsize;

=cut

sub reset_maxsize
{
    my $self = shift;

    $self->{'maxsize'} = $self->{'size'};
    return $self->{'maxsize'};
}

=head2 $pq->status()

Return status of the priority queue.

=cut1

sub status
{
    my $self = shift;

    # 0 + in the following to force integer values for JSON
    my %status = (
        size    => 0 + $self->size(),
        maxsize => 0 + $self->{'maxsize'},
        prio    => 0 + $self->{'prio'},
    );

    unless ($self->empty()) {
        $status{'age_last'}  = 0 + $self->age_last();
        $status{'age_first'} = 0 + $self->age_first();
    }

    return \%status;
}

=head1 SEE ALSO

L<Tirex::Queue>, L<Tirex::Job>

=cut


1;

#-- THE END ------------------------------------------------------------------
