#-----------------------------------------------------------------------------
#
#  Tirex/Job.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;
use List::Util qw();

#-----------------------------------------------------------------------------

package Tirex::Job;

=head1 NAME

Tirex::Job - A Tirex rendering job

=head1 SYNOPSIS

my $job = Tirex::Job->new( metatile => $metatile, prio => 5, expire => time() + 60*60 );

=head1 DESCRIPTION


=head1 METHODS

=head2 Tirex::Job->new( ... )

Create new job.

A job always needs the following parameters:

 metatile -- the metatile
 prio     -- priority (integer >= 1, 1 is highest priority

It can have any or all of the following parameters:

 expire       -- the time when this job will expire (seconds since epoch)
 request_time -- the time when this request came in (seconds since epoch, will be set to current time if not set)

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = bless \%args => $class;

    Carp::croak("need prio for new job")            unless (defined $self->{'prio'});
    Carp::croak("prio must be integer 1 or larger") unless ($self->{'prio'} =~ /^[1-9][0-9]*$/ && $self->{'prio'} >= 1);
    Carp::croak("need metatile for new job")        unless (defined $self->{'metatile'});

    $self->{'notify'} = [];
    $self->{'success'} = 0;
    $self->{'request_time'} = time unless (defined $self->{'request_time'});
    (my $ss = "$self") =~ s/.*\(0x(.*)\).*/$1/;
    $self->{'id'} = $self->{'request_time'} . "_$ss";

    return $self;
}

=head2 $job->same_tile($other_job)

Returns true if both jobs concern the same metatile, false otherwise.

The same tile means: same map, same x and y coordinates and same zoom level.

=cut

sub same_tile
{
    my $self = shift;
    my $other = shift;

    return $self->{'metatile'}->equals($other->{'metatile'});
}

=head2 $job->expired()

Returns 1 if this job is expired, 0 otherwise.

If the job doesn't have an expire time, it returns undef;

=cut

sub expired
{
    my $self = shift;

    return undef unless (defined $self->{'expire'});
    return ($self->{'expire'} < time() ? 1 : 0);
}

=head2 $job->to_s( foo => 'bar' )

Creates a message string from the job. It contains the fields id, map, x, y, and z from the job
plus all the fields given as argument to this method.

=cut

sub to_s
{
    my $self = shift;

    my $m = $self->to_msg(@_);
    my $content = '';
    foreach my $k (sort(keys %$m))
    {
        if ($k eq 'metatile')
        {
            foreach my $mk (sort keys %{$m->{'metatile'}})
            {
                $content .= "$mk=$m->{'metatile'}->{$mk}\n";
            }
        }
        else
        {
            $content .= "$k=$m->{$k}\n";
        }
    }
    return $content;
}

=head2 $job->to_msg( foo => 'bar' )

Creates a message from the job. It contains the fields id, map, x, y, z, prio from the job
and, if available, the field priority.

All the fields given as argument to this method will also be added. You must give a type
argument, otherwise this will croak.

=cut

sub to_msg
{
    my $self = shift;
    my %args = @_;

    $args{'id'}     = $self->get_id() unless (defined $args{'id'});
    $args{'map'}    = $self->get_map();
    $args{'x'}      = $self->get_x();
    $args{'y'}      = $self->get_y();
    $args{'z'}      = $self->get_z();
    $args{'prio'}   = $self->get_prio();
    $args{'expire'} = $self->{'expire'} if ($self->{'expire'});

    return Tirex::Message->new(%args);
}

=head2 $job->get_id()

Get unique id of this job.

=cut

sub get_id
{
    my $self = shift;

    return $self->{'id'};
}

=head2 $job->get_prio()

Get priority of this job.

=cut

sub get_prio
{
    my $self = shift;

    return $self->{'prio'};
}

=head2 $job->set_prio($prio)

Set priority of this job.

=cut

sub set_prio
{
    my $self = shift;

    $self->{'prio'} = shift;
    return;
}

sub get_x   { my $self = shift; return $self->{'metatile'}->get_x();   }
sub get_y   { my $self = shift; return $self->{'metatile'}->get_y();   }
sub get_z   { my $self = shift; return $self->{'metatile'}->get_z();   }
sub get_map { my $self = shift; return $self->{'metatile'}->get_map(); }

=head2 $job->get_pos()

Get position of this job in the priority queue. Returns undef if the job is in no queue.

=cut

sub get_pos
{
    my $self = shift;

    return $self->{'pos'};
}

=head2 $job->set_pos($pos)

Set position of this job in the priority queue. Set to undef if the job is in no queue.

=cut

sub set_pos
{
    my $self = shift;

    $self->{'pos'} = shift;
    return;
}

=head2 $job->get_bucket()

Get bucket for this job.

=cut

sub get_bucket
{
    my $self = shift;

    return $self->{'bucket'};
}

=head2 $job->set_bucket($bucket)

Set bucket for this job.

=cut

sub set_bucket
{
    my $self = shift;

    $self->{'bucket'} = shift;
    return;
}

=head2 $job->get_success()

Get success flag for this job.

=cut

sub get_success
{
    my $self = shift;

    return $self->{'success'};
}

=head2 $job->set_success($success)

Set success flag for this job.

=cut

sub set_success
{
    my $self = shift;

    $self->{'success'} = shift;
    return;
}


=head2 $job->hash_key()

Create a hash key (string) from the contents of this job. Only the attributes describing the tile are included. So that this hash key is unique for any tile.

=cut

sub hash_key
{
    my $self = shift;

    return $self->{'metatile'}->to_s();
}

=head2 $job->merge($secondjob)

Merge two jobs for the same metatile into one. This method will look into both jobs and create a new job from the data. The old jobs are not changed.

 * priority of the new job will be the minimum of the priorities of the old jobs
 * expire will be the maximum of the expire times of the old jobs, if there is no expire time for at least one job, the result will have no expire time either
 * notify will be the concatenation of both notifies
 * request_time will be the minimum of both request times

This methods assumes that the metatiles are the same, it does no check.

=cut

sub merge
{
    my $self  = shift;
    my $other = shift;

    my $job = Tirex::Job->new(
        metatile     => $self->{'metatile'},
        request_time => List::Util::min($self->{'request_time'}, $other->{'request_time'}),
        prio         => List::Util::min($self->get_prio(),       $other->get_prio()),
        expire       => (defined($self->{'expire'}) && defined($other->{'expire'})) ? List::Util::max($self->{'expire'}, $other->{'expire'}) : undef,
    );

    foreach my $n (@{$self->{'notify'} }) { $job->add_notify($n); }
    foreach my $n (@{$other->{'notify'}}) { $job->add_notify($n); }

    return $job;
}

=head2 $job->add_notify($source)

Add a Tirex::Source to be notified when this job is done.

=cut

sub add_notify
{
    my $self   = shift;
    my $notify = shift;

    push(@{$self->{'notify'}}, $notify);
}

=head2 $job->has_notify()

Returns true if any sources are waiting to be notified of this job's completion.

=cut

sub has_notify
{
    my $self = shift;
    return defined($self->{'notify'}) && scalar(@{$self->{'notify'}}) > 0;
}

=head2 $job->notify()

Notify all sources that this job is done. Returns an array reference with the result of the notify calls on the sources.

Clears the notify list.

=cut

sub notify
{
    my $self = shift;

    my @results = ();
    foreach my $source (@{$self->{'notify'}})
    {
        push(@results, $source->notify($self));
    }
    $self->{'notify'} = [];
    return \@results;
}

=head2 $job->sources_as_string()

The sources of this job as a string (for logging).

=cut

sub sources_as_string
{
    my $self = shift;

    return join('', map { $_->name($self); } @{$self->{'notify'}});
}

=head2 $job->age()

Returns age of this job in seconds (ie. the difference between current and request time).

=cut

sub age
{
    my $self = shift;

    return time() - $self->{'request_time'};
}


1;

#-- THE END ------------------------------------------------------------------
