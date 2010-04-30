#-----------------------------------------------------------------------------
#
#  Tirex/Manager/Bucket.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;
use JSON;

use Tirex;

#-----------------------------------------------------------------------------

package Tirex::Manager::Bucket;

=head1 NAME

Tirex::Manager::Bucket - Rendering buckets for different priorities

=head1 SYNOPSIS

 use Tirex::Manager::Bucket;
 my $bucket = Tirex::Manager::Bucket->new( name => 'test', minprio => 1, maxproc => 8, maxload => 20 );

=head1 DESCRIPTION


=head1 METHODS

=head2 Tirex::Manager::Bucket->new( name => $name, minprio => $minprio, maxproc => $maxproc, maxload => $maxload )

Create new rendering bucket.

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = bless \%args => $class;

    Carp::croak("need 'name' parameter for bucket")    unless ($self->{'name'});
    Carp::croak("need 'minprio' parameter for bucket") unless ($self->{'minprio'});
    Carp::croak("need 'maxproc' parameter for bucket") unless ($self->{'maxproc'});
    Carp::croak("need 'maxload' parameter for bucket") unless ($self->{'maxload'});

    $self->{'numproc'} = 0;
    $self->{'active'} = 1;

    return $self;
}

=head2 $bucket->add_job($job)

Add a Tirex::Job to bucket.

=cut

sub add_job
{
    my $self = shift;
    my $job  = shift;

    $job->set_bucket($self);
    $self->{'numproc'}++;

    return;
}

=head2 $bucket->remove_job($job)

Remove a Tirex::Job from bucket.

=cut

sub remove_job
{
    my $self = shift;
    my $job  = shift;

    $job->set_bucket(undef);
    $self->{'numproc'}--;

    return;
}

=head2 $bucket->get_name()

Get name of bucket.

=cut

sub get_name
{
    my $self = shift;
    return $self->{'name'};
}

=head2 $bucket->get_numproc()

Returns the number of rendering processes currently working on jobs in this bucket.

=cut

sub get_numproc
{
    my $self = shift;
    return $self->{'numproc'};
}

=head2 $bucket->get_minprio()

Get minimum priority for this bucket.

=cut

sub get_minprio
{
    my $self = shift;
    return $self->{'minprio'};
}

=head2 $bucket->get_maxprio()

Get maximum priority for this bucket. The maximum priority has to be set with
set_maxprio() before this works.

=cut

sub get_maxprio
{
    my $self = shift;
    return $self->{'maxprio'};
}

=head2 $bucket->set_maxprio($maxprio)

Set maximum priority for this bucket.

=cut

sub set_maxprio
{
    my $self = shift;
    $self->{'maxprio'} = shift;
    return;
}

=head2 $bucket->get_active()

Get active flag for this bucket.

=cut

sub get_active
{
    my $self = shift;
    return $self->{'active'};
}

=head2 $bucket->set_active($active)

Set active flag for this bucket.

=cut

sub set_active
{
    my $self   = shift;
    my $active = shift;

    $self->{'active'} = $active ? 1 : 0;

    return;
}


=head2 $bucket->for_prio($prio)

Check whether this bucket is the right one for the given priority,
ie. whether the priority is between min- and maxprio.

=cut

sub for_prio
{
    my $self = shift;
    my $prio = shift;

    if (defined $self->{'maxprio'})
    {
        return $self->{'minprio'} <= $prio && $prio <= $self->{'maxprio'};
    }
    else
    {
        return $self->{'minprio'} <= $prio;
    }
}

=head2 $bucket->can_render($num_rendering, $current_load)

Finds out if a job in this rendering bucket can be rendered.

Returns

 1     if it can be rendered
 0     if there are already maxproc or more rendering processes
       or if bucket is not active
 undef if the load is higher or equal than maxload

=cut

sub can_render
{
    my $self          = shift;
    my $num_rendering = shift;
    my $current_load  = shift;

    return 0 if (! $self->{'active'});

    return 0 if ($num_rendering >= $self->{'maxproc'});

    return $current_load >= $self->{'maxload'} ? undef : 1;
}

=head2 $bucket->status($num_rendering, $current_load)

Return status of bucket.

=cut

sub status
{
    my $self          = shift;
    my $num_rendering = shift;
    my $current_load  = shift;

    # 0 + in the following to force numbers for JSON
    return {
        name       =>     $self->{'name'},
        minprio    => 0 + $self->get_minprio(),
        maxprio    => defined($self->get_maxprio()) ? 0 + $self->get_maxprio() : 0,
        numproc    => 0 + $self->get_numproc(),
        maxproc    => 0 + $self->{'maxproc'},
        maxload    => 0 + $self->{'maxload'},
        active     => $self->get_active(),
        can_render => $self->can_render($num_rendering, $current_load) ? JSON::true : JSON::false, 
    };
}


1;

#-- THE END ------------------------------------------------------------------
