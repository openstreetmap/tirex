#-----------------------------------------------------------------------------
#
#  Tirex/Status.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;

use IPC::SysV;
use IPC::ShareLite;
use JSON;

#-----------------------------------------------------------------------------

package Tirex::Status;

our $SHMKEY = 0x00002468;

# use pretty printing of JSON in shared memory
# it might make sense to set this to 1 for debugging
our $pretty = 1;

# permissions for shared memory
# you need write permissions even for read-only access!
# (probably because of locking)
our $mode = 0666;

=head1 NAME

Tirex::Status - Status of running master daemon in shared memory

=head1 SYNOPSIS

my $status = Tirex::Status->new();

=head1 DESCRIPTION

This package manages the status of the master daemon in shared memory.

=head1 METHODS

=head2 Tirex::Status->new( master => 1 );

If 'master' is true the shared memory is created (and destroyed afterwards).
Only the master server should do this.

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = bless \%args => $class;

    # if we are the master, remove pre-existing shared memory segments and
    # semaphore
    if ($self->{'master'})
    {
        my $id = shmget($SHMKEY, 0, 0);
        shmctl($id, IPC::SysV::IPC_RMID, 0) if (defined($id));
        $id = semget($SHMKEY, 0, 0);
        semctl($id, IPC::SysV::IPC_RMID, 0, 0) if (defined($id));
    }

    $self->{'share'} = IPC::ShareLite->new(
        -key       => $SHMKEY,
        -mode      => $mode,
        -create    => $self->{'master'} ? 1 : 0,
        -destroy   => $self->{'master'} ? 1 : 0,
        -exclusive => $self->{'master'} ? 1 : 0,
    ) or Carp::croak("cannot connect to shared memory: $!");

    return $self;
}

=head2 $status->destroy()

Destroy shared memory segment.

=cut

sub destroy
{
    my $self = shift;
    delete $self->{'share'};
}

=head2 $status->update(key1 => val1, key2 => val2, ...)

Update shared memory with current status. Call with
key-value pairs that should be added to status.

=cut

sub update
{
    my $self    = shift;

    my %status = (
        'pid'     => 0 + $$, # force integer for JSON
        'updated' => time(),
        @_
    );

    $self->write(JSON::to_json(\%status, { pretty => $pretty }) . "\n");
}

=head2 $status->write($string)

Write a string into shared memory.

=cut

sub write
{
    my $self = shift;
    my $str  = shift;

    $self->{'share'}->store($str);
}

=head2 $status->read()

Read a string from shared memory.

Returns the string read, or undef if the shared memory was not accessible.

=cut

sub read
{
    my $self = shift;

    my $str = eval { $self->{'share'}->fetch(); };

    return $str;
}


1;

#-- THE END ------------------------------------------------------------------
