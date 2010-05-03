#-----------------------------------------------------------------------------
#
#  Tirex/Manager/RenderingJobs.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;

use Tirex;

#-----------------------------------------------------------------------------

package Tirex::Manager::RenderingJobs;

=head1 NAME

Tirex::Manager::Rendering - Hold currently rendering jobs

=head1 SYNOPSIS

 use Tirex::Manager:RenderingJobs;

=head1 DESCRIPTION

Keeps the list of currently rendering jobs.

=head1 METHODS

=head2 Tirex::Manager::RenderingJobs->new( timeout => 120 )

Create new object.

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = bless \%args => $class;

    Carp::croak('missing or illegal timeout parameter when creating object of class Tirex::Manager::RenderingJobs') unless (defined($self->{'timeout'}) && $self->{'timeout'} =~ /^[0-9]+$/);

    $self->{'requests_by_id'}       = {};
    $self->{'requests_by_metatile'} = {};

    return $self;
}

=head2 $rj->count()

Returns the number of jobs currently rendering.

=cut

sub count
{
    my $self = shift;

    return scalar(keys %{$self->{'requests_by_id'}});
}

=head2 $rj->add($job)

Add a job. Returns the job added.

=cut

sub add
{
    my $self = shift;
    my $job  = shift;

    $job->{'rendering_requested'} = time();
    $self->{'requests_by_id'      }->{ $job->get_id()   } = $job;
    $self->{'requests_by_metatile'}->{ $job->hash_key() } = $job;

    return $job;
}

=head2 $rj->remove($job)

Remove a job. Returns the job removed.

=cut

sub remove
{
    my $self = shift;
    my $job  = shift;

    delete($self->{'requests_by_id'      }->{ $job->get_id()   });
    delete($self->{'requests_by_metatile'}->{ $job->hash_key() });

    return $job;
}

=head2 $rj->find_by_id($id)

Find a currently rendering job by its id.

=cut

sub find_by_id
{
    my $self = shift;
    my $id   = shift;

    return $self->{'requests_by_id'}->{$id};
}

=head2 $rj->find_by_metatile($hash)

Find a currently rendering job for some metatile by the metatile hash.

=cut

sub find_by_metatile
{
    my $self = shift;
    my $hash = shift;

    return $self->{'requests_by_metatile'}->{$hash};
}

=head2 $rj->check_timeout()

Check if there are any jobs older than the timeout and remove them. They will have been killed
by tirex-renderd-manager in the mean time.

Returns the number of jobs removed.

=cut

sub check_timeout
{
    my $self = shift;

    my $count = 0;

    my $timeout = time() - $self->{'timeout'};
    foreach my $job (values %{$self->{'requests_by_id'}})
    {
        if ($job->{'rendering_requested'} < $timeout) {
            my $bucket = $job->get_bucket();
            $bucket->remove_job($job) if (defined $bucket);
            $self->remove($job);
            ::syslog('err', 'Job with id=%s timed out on rendering list (%s)', $job->get_id(), $job->get_metatile()->to_s());
            $count++;
            $job->notify();
        }
    }

    return $count;
}

=head2 $rj->status()

Return status.

=cut

sub status
{
    my $self = shift;

    # 0 + in the following to force numbers for JSON
    my @status = map {
        {
            map  =>     $_->get_map(),
            x    => 0 + $_->get_x(),
            y    => 0 + $_->get_y(),
            z    => 0 + $_->get_z(),
            prio => 0 + $_->get_prio(),
            age  => time() - $_->{'rendering_requested'},
        };
    } sort {
        $a->get_prio() == $b->get_prio()
            ? $a->{'rendering_requested'} <=> $b->{'rendering_requested'}
            : $a->get_prio() <=> $b->get_prio();
    } values %{$self->{'requests_by_id'}};

    return \@status;
}


1;

#-- THE END ------------------------------------------------------------------
