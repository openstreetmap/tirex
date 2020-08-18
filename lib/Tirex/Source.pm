#-----------------------------------------------------------------------------
#
#  Tirex/Source.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;

use IO::Socket;

use Tirex::Source::Command;
use Tirex::Source::ModTile;

#-----------------------------------------------------------------------------

package Tirex::Source;

=head1 NAME

Tirex::Source - A source of a job request

=head1 SYNOPSIS

 my $source = Tirex::Source::...->new();
 $source->readable($socket);
 $source->writable($socket);
 $source->notify();

=head1 DESCRIPTION

This is a virtual parent class. Only instantiate subclasses: L<Tirex::Source::Command>, L<Tirex::Source::ModTile>, L<Tirex::Source::Test>

=head1 METHODS

Each subclass must define the following methods:

=head2 Tirex::Source::...->new()

Create new object of this source class.

=head2 $source->readable($socket)
=head2 $source->writable($socket)

These methods are called if the socket that was associated to this source object becomes
readable or writable.

The source will return true from any of these if reading/writing has been completed,
and false if waits for another chance to read/write.

=head2 $source->notify()

This method is called once a tile has been rendered to notify the source.

=cut

#use constant {
#    STATUS_CONTINUE => 0, 
#    STATUS_SOCKET_CLOSED => 1,
#    STATUS_MESSAGE_COMPLETE => 2
#}

sub STATUS_CONTINUE { return 0; }
sub STATUS_SOCKET_CLOSED { return 1; }
sub STATUS_MESSAGE_COMPLETE { return 2; }

sub set_timeout
{
    my $self = shift;
    my $to = shift;
    $self->{'timeout'} = $to;
}

sub get_timeout
{
    my $self = shift;
    return $self->{'timeout'};
}

# XXX overwrite this in subclass
sub name
{
    return '?';
}


1;


#-- THE END ------------------------------------------------------------------
