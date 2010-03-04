#-----------------------------------------------------------------------------
#
#  Tirex/Manager.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;
use IO::Socket::INET;

use Tirex;
use Tirex::Manager::Bucket;
use Tirex::Manager::RenderingJobs;

#-----------------------------------------------------------------------------

package Tirex::Manager;

=head1 NAME

Tirex::Manager - Rendering manager

=head1 SYNOPSIS

 use Tirex::Manager;
 my $queue = Tirex::Queue->new();
 my $rm = Tirex::Manager->new( queue => $queue );

=head1 DESCRIPTION

The rendering manager takes jobs from the queue and runs them. It takes into account
how many parallel renderings are allowed, the priority of the jobs etc.

=head1 METHODS

=head2 Tirex::Manager->new( queue => $queue )

Create a new rendering manager. Parameters are:

 queue   the queue with the rendering requests (see Tirex::Queue)

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = bless \%args => $class;

    Carp::croak("need queue parameter") unless (defined $self->{'queue'});

    $self->{'stats'} = {
        'count_requested' => 0,
        'count_expired'   => 0,
        'count_timeouted' => 0,
        'count_error'     => 0,
        'count_rendered'  => {},
        'sum_render_time' => {},
    };

    $self->{'rendering_timeout'} = Tirex::Config::get('master_rendering_timeout', $Tirex::MASTER_RENDERING_TIMEOUT) * 60; # config is in minutes, but we need in seconds
    $self->{'next_timeout_check'} = time() + $self->{'rendering_timeout'};
    $self->{'rendering_jobs'} = Tirex::Manager::RenderingJobs->new( timeout => $self->{'rendering_timeout'} );

    $self->{'socket'} = IO::Socket::INET->new( LocalAddr => 'localhost', Proto => 'udp') or Carp::croak("Can't open renderd return UDP socket: $!\n");
    $self->{'to'}     = Socket::pack_sockaddr_in($Tirex::RENDERD_UDP_PORT, Socket::inet_aton('localhost'));

    $self->{'buckets'} = [];

    $self->{'load'} = 0;
    $self->{'last_load_check'} = 0;

    return $self;
}

=head2 $rm->add_bucket(name => $name, minprio => $minprio, maxproc => $maxproc, maxload => $maxload)

Creates and adds a bucket with the given config. It always keeps buckets sorted according to minprio.

Returns the created bucket or undef on error.

=cut

sub add_bucket
{
    my $self = shift;
    my @config = @_;

    my $bucket = Tirex::Manager::Bucket->new(@config);

    if ($bucket) {
        # re-sort all buckets including the new one
        my @buckets = sort { $a->get_minprio() <=> $b->get_minprio() } (@{$self->{'buckets'}}, $bucket);

        # re-calculate maxprio for all buckets
        foreach my $n (1 .. scalar(@buckets)-1)
        {
            $buckets[$n-1]->set_maxprio( $buckets[$n]->get_minprio() - 1 );
        }

        $self->{'buckets'} = \@buckets;
    }

    return $bucket;
}

=head2 $rm->set_active_flag_on_bucket($active, $bucketname)

Returns true if successful, ie. the bucket did exists, false
if unsuccessful.

=cut

sub set_active_flag_on_bucket
{
    my $self   = shift;
    my $active = shift;
    my $name   = shift;

    foreach my $bucket (@{$self->{'buckets'}})
    {
        if ($bucket->get_name() eq $name)
        {
            $bucket->set_active($active);
            return 1;
        }
    }

    return;
}


=head2 $rm->get_socket()

Return socket where the rendering manager expects responses from renderd. This should be added to select calls in main loop.

=cut

sub get_socket
{
    my $self = shift;

    return $self->{'socket'};
}

sub requests_by_metatile
{
    my $self = shift;
    my $job = shift;

    return $self->{'rendering_jobs'}->find_by_metatile($job->hash_key());
}

=head2 $rm->schedule()

Runs as many jobs as there are in the queue (as long as the resources don't run out).

This will also check for timeouts on the jobs that are currently rendering.

=cut

sub schedule
{
    my $self = shift;

    # if we haven't done this for a while check currently rendering jobs for timeouts
    if (time() >= $self->{'next_timeout_check'})
    {
        $self->{'stats'}->{'count_timeouted'} += $self->{'rendering_jobs'}->check_timeout();
        $self->{'next_timeout_check'} = time() + $self->{'rendering_timeout'} / 10;
    }

    while ($self->run()) {};
}

=head2 $rm->run()

Check whether there is a job that can be rendered and that there are enough resources and then render the job.

Returns

 undef if there is no job to run
 0     if there aren't enough resources
 1     if a job was started
 2     if a job was expired

=cut

sub run
{
    my $self = shift;

    my $job = $self->{'queue'}->peek();
    return undef unless (defined $job);

    # if the job is expired, just remove it from the queue and return
    if ($job->expired())
    {
        $self->{'queue'}->next(); # ignore result, we already got the job from call to peek() above
        ::syslog('debug', 'job is expired id=%s prio=%s map=%s x=%d y=%d z=%d', $job->get_id(), $job->get_prio(), $job->get_map(), $job->get_x(), $job->get_y(), $job->get_z()) if ($Tirex::DEBUG);
        $self->{'stats'}->{'count_expired'}++;
        return 2;
    }

    my $prio = $job->get_prio();
    my $bucket;

    # the current system load
    my $current_load = $self->get_load();

    # Check if buckets can render. Start at bucket with lowest priority and end at the
    # bucket with the right priority for this job. If any of the buckets can't render
    # we stop there. If all of them can render we go on.
    foreach my $b (@{$self->{'buckets'}})
    {
        return 0 unless ( $b->can_render($self->{'rendering_jobs'}->count(), $current_load) );
        # break from loop if the currently looked at bucket is the right for the priority of this job
        if ($b->for_prio($prio))
        {
            $bucket = $b;
            last;
        }
    }

    # we found the right bucket and it can render
    # remove job from queue, ignore result, we already got the job from call to peek() above
    $self->{'queue'}->next();

    ::syslog('debug', 'request rendering of job id=%s prio=%s map=%s x=%d y=%d z=%d', $job->get_id(), $job->get_prio(), $job->get_map(), $job->get_x(), $job->get_y(), $job->get_z()) if ($Tirex::DEBUG);

    # do all the necessary housekeeping...
    $self->{'rendering_jobs'}->add($job);
    $bucket->add_job($job);

    # update statistics
    $self->{'stats'}->{'count_requested'}++;

    # and actually send the job to the renderer
    $self->send($job);

    # return success
    return 1;
}

=head2 $rm->send($job)

Send a job to the rendering daemon.

=cut

sub send
{
    my $self = shift;
    my $job  = shift;

    return $self->{'socket'}->send( $job->to_s( type => 'metatile_render_request' ), undef, $self->{'to'} );
}

=head2 $rm->done($msg)

This is called when a message comes back from the renderd that a job was rendered.

Returns the job or undef if the job was not found.

=cut

sub done
{
    my $self = shift;
    my $msg  = shift;

    my $job = $self->{'rendering_jobs'}->find_by_id($msg->{'id'});

    # if the job is found in our records, we remove it.
    if ($job)
    {
        my $success = (defined($msg->{'result'}) && $msg->{'result'} eq 'ok');
        $job->set_success($success);
        if ($success)
        {
            ::syslog('debug', 'job rendering done id=%s map=%s x=%d y=%d z=%d', $job->get_id(), $job->get_map(), $job->get_x(), $job->get_y(), $job->get_z()) if ($Tirex::DEBUG);

            # update statistics
            $self->{'stats'}->{'count_rendered' }->{$job->get_map()}->[$job->get_z()] ||= 0;
            $self->{'stats'}->{'count_rendered' }->{$job->get_map()}->[$job->get_z()]++;
            $self->{'stats'}->{'sum_render_time'}->{$job->get_map()}->[$job->get_z()] ||= 0;
            $self->{'stats'}->{'sum_render_time'}->{$job->get_map()}->[$job->get_z()] += $msg->{'render_time'};

            $job->{'render_time'} = $msg->{'render_time'};
        }
        else
        {
            ::syslog('warning', 'job rendering error id=%s map=%s x=%d y=%d z=%d result=%s errmsg=%s', $job->get_id(), $job->get_map(), $job->get_x(), $job->get_y(), $job->get_z(), $msg->{'result'}, $msg->{'errmsg'});

            # update statistics
            $self->{'stats'}->{'count_error' }++;

            $job->{'render_time'} = 0;
        }

        $self->{'rendering_jobs'}->remove($job);
        $job->get_bucket()->remove_job($job);
    }
    # if the job is not found, our records are confused and we log a warning but ignore the job
    # this can happen if there was a timeout waiting for the renderd, but later the renderd came
    # through and send the answer or if the master was restarted and gets a response for a tile from
    # the renderd that was requested by an earlier master process.
    else
    {
        ::syslog('warning', 'Job for id %s not found (timeout? restart of master?)', $msg->{'id'});
    }

    $self->schedule();
    return $job;
}

=head2 $rm->log_stats()

Write statistics to log file.

=cut

sub log_stats
{
    my $self = shift;

    my $stats = $self->{'stats'};
    foreach my $statkey (sort keys %$stats ) {
        my $statvalue = $stats->{$statkey};
        if (ref($statvalue) eq '')
        {
            ::syslog('info', 'stat %s=%s', $statkey, $statvalue);
        }
        elsif (ref($statvalue) eq 'HASH')
        {
            foreach my $map (sort keys %$statvalue)
            {
                my $text = join(', ', map { $_ || 0 } @{$statvalue->{$map}});
                ::syslog('info', 'stat %s[%s]=%s', $statkey, $map, $text);
            }
        }
    }
}

=head2 $rm->status()

Return status of the rendering manager.

=cut

sub status
{
    my $self = shift;

    my $current_load = $self->get_load();

    # 0 + in the following to force numbers for JSON
    my $status = {
        load            => 0 + $current_load,
        num_rendering   => 0 + $self->{'rendering_jobs'}->count(),
        stats           => $self->{'stats'},
        buckets         => [],
        rendering       => [],
    };

    foreach my $bucket (@{$self->{'buckets'}})
    {
        push(@{$status->{'buckets'}}, $bucket->status($self->{'rendering_jobs'}->count(), $current_load));
    }

    $status->{'rendering'} = $self->{'rendering_jobs'}->status();

    return $status;
}

=head2 $rm->get_load()

Get current load on the machine. If /proc/loadavg is not readable for some reason, it always returns 0.

=cut

sub get_load
{
    my $self = shift;

    return $self->{'load'} if ($self->{'last_load_check'} == time());

    open(my $loadavg, '<', '/proc/loadavg') or return 0;
    ($self->{'load'} = <$loadavg>) =~ s/ .*\n//;
    close($loadavg);

    $self->{'last_load_check'} = time();

    return $self->{'load'};
}

=head1 SEE ALSO

L<Tirex::Manager::Test>

=cut


1;

#-- THE END ------------------------------------------------------------------
