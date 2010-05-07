#-----------------------------------------------------------------------------
#
#  Tirex/Source/ModTile.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;

use IO::Socket::UNIX;
use Socket;

#-----------------------------------------------------------------------------
package Tirex::Source::ModTile;
use base qw( Tirex::Source );

=head1 NAME

Tirex::Source::ModTile -- mod_tile a a source of job requests

=head1 SYNOPSIS

 my $source = &Tirex::Source::ModTile->new();
 $source->notify();

=head1 DESCRIPTION

Source using Tirex messages sent through mod_tile (Unix domain socket)

=head1 METHODS

=head2 Tirex::Source::ModTile->new()

Create source object for Unix domain socket connection.

=cut

sub new
{
    my $class = shift;
    my $socket = shift;
    my $self = bless { 'read_buffer' => "", 'socket' => $socket } => $class;
    return $self;
}

=head2 $source->readable($sock)

Indicates to this source that the given socket is readable, and has data for
this source. 

The source will return STATUS_CONTINUE if it expects to continue reading, 
or STATUS_MESSAGE_COMPLETE if reading is complete. STATUS_SOCKET_CLOSED 
indicates that the peer has closed the connection.

=cut

sub readable
{
    my $self = shift;
    my $sock = shift;

    # we want 64 bytes. nothing else will do. recv is not guaranteed to 
    # return that.
    my $tmp;
    return &Tirex::Source::STATUS_SOCKET_CLOSED unless defined($sock->recv($tmp, 64 - length($self->{read_buffer}))); 
    return &Tirex::Source::STATUS_SOCKET_CLOSED unless length($tmp);
    $self->{read_buffer} .= $tmp;
    return &Tirex::Source::STATUS_CONTINUE if (length($self->{read_buffer}) < 64);

    # request fully read.
    ($self->{ver}, $self->{cmd}, $self->{x}, $self->{y}, $self->{z}, $self->{map}) = 
        unpack("lllllZ*", $self->{read_buffer});
    $self->{read_buffer} = "";

    ::syslog('debug', 'read request from mod_tile: ver=%d cmd=%d x=%d y=%d z=%d map=%s', $self->{ver}, $self->{cmd}, $self->{x}, $self->{y}, $self->{z}, $self->{map}) if ($Tirex::DEBUG);

    return &Tirex::Source::STATUS_MESSAGE_COMPLETE;
}

=head2 $source->make_job($sock)

Returns a new Tirex::Job object created from the data read by this source. 
Also decides whether or not this source would like to be notified of 
job completion, and if yes, flags the job accordingly.

ModTile priorities are converted as follows:

Render -> 2
RenderPrio -> 1
RenderBulk -> 10

=cut

sub make_job
{
    my $self = shift;
    my $sock = shift;

    my $metatile = eval {
        my $mt = Tirex::Metatile->new(
            map => $self->{'map'}, 
            x   => $self->{'x'}, 
            y   => $self->{'y'}, 
            z   => $self->{'z'}
        );
        Tirex::Map->get_map_for_metatile($mt);
        return $mt;
    };

    # return error if we cannot create the metatile
    if ($@) {
        ::syslog('warning', $@) if ($Tirex::DEBUG);
        return;
    }

    my $job = eval {
        Tirex::Job->new(
            metatile => $metatile,
            # enum protoCmd { cmdIgnore, cmdRender, cmdDirty, cmdDone, cmdNotDone, cmdRenderPrio, cmdRenderBulk };
            'prio' => [99, 2, 10, 99, 99, 1, 20]->[$self->{'cmd'}] 
        );
    };

    # return error if we can't create the job
    return if ($@);

    $job->add_notify($self);

    return $job;
}

=head2 $source->set_request_write_callback(\&wcb}

Specifies a function to be called if this source ever wants to 
receive writable events.

=cut

sub set_request_write_callback
{
    my $self = shift;
    my $callback = shift;
    $self->{request_write_callback} = $callback;
}

=head2 $source->notify($job)

Prepares a notification message about succesful tile rendering
and informs the main select loop to give us a chance to write.

=cut

sub notify
{
    my $self = shift;
    my $job  = shift;

    # enum protoCmd { cmdIgnore, cmdRender, cmdDirty, cmdDone, cmdNotDone, cmdRenderPrio, cmdRenderBulk };
    $self->{write_buffer} = pack("lllllZ*", 
        2, # protocol version
        $job->get_success() ? 3 : 4, # cmdDone or cmdNotDone
        $self->{'x'}, $self->{'y'}, $self->{'z'}, # x, y, z
        $self->{"map"} # map
    );
    $self->{write_buffer} .= chr(0) x 64;
    $self->{write_buffer} = substr($self->{write_buffer}, 0, 64);
    &{$self->{request_write_callback}}();
    return 1;
}

=head2 $source->writable($sock)

Indicates to this source that the given socket is writable.

The source will attempt to send the prepared notification message, and
return STATUS_MESSAGE_COMPLETE if the message has been fully sent. It
will return STATUS_CONTINUE if sending needs to continue later. A return
value of STATUS_SOCKET_CLOSED indicates that the peer has closed the 
connection.

=cut

sub writable
{
    my $self = shift;
    my $sock = shift;
    my $bytes_sent = eval { $sock->send($self->{write_buffer}, Socket::MSG_NOSIGNAL) };
    if (!defined($bytes_sent))
    {
        # other side is gone. no use trying to continue.
        return &Tirex::Source::STATUS_SOCKET_CLOSED;
    }
    if ($bytes_sent < length($self->{write_buffer}))
    {
        $self->{write_buffer} = substr($self->{write_buffer}, $bytes_sent);
        return &Tirex::Source::STATUS_CONTINUE;
    }
    delete $self->{write_buffer};
    return &Tirex::Source::STATUS_MESSAGE_COMPLETE;
}

sub name
{
    return 'M';
}

#-----------------------------------------------------------------------------

1;


#-- THE END ------------------------------------------------------------------
