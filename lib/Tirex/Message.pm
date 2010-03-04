#-----------------------------------------------------------------------------
#
#  Tirex/Message.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;

#-----------------------------------------------------------------------------

package Tirex::Message;

=head1 NAME

Tirex::Message - A message 

=head1 SYNOPSIS

my $msg = Tirex::Message->new( ... );

=head1 DESCRIPTION

Messages are used to exchange requests and replies between different components
of the Tirex system.

"On the wire" they consist of several lines (separated by an optional carriage
return and a newline). Each line has the form "key=value". No spaces are
allowed before or after the key or equals sign.

=head1 METHODS

=head2 Tirex::Message->new( type => '...', field1key => "field2value", ... )

Create new message. You always need a type for the message, all other
fields are optional.

Will croak if there is no type given.

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
    my $self = bless \%args => $class;

    Carp::croak("need type for new message") unless (defined $self->{'type'});

    return $self;
}


=head2 Tirex::Message->new_from_string("type=foo\nbar=baz\n");

Create message object from string.

=cut

sub new_from_string
{
    my $class  = shift;
    my $string = shift;

    my %hash;
    foreach my $line (split(/\r?\n/, $string))
    {
        my ($k, $v) = split(/=/, $line, 2);
        $hash{$k} = $v;
    }

    return $class->new(%hash);
}

=head2 Tirex::Message->new_from_socket($socket)

Read a datagram from given socket and create new message from it.

=cut

# XXX error handling?

sub new_from_socket
{
    my $class  = shift;
    my $socket = shift;

    my $buf;
    if ($socket->recv($buf, $Tirex::MAX_PACKET_SIZE))
    {
        return $class->new_from_string($buf);
    }
    else
    {
        return;
    }
}

=head2 $msg->reply([RESULT[, ERRMSG]])

Create new message with reply to old one. If RESULT is not given
it defaults to 'ok'. If ERRMSG is givenm, it is attached to the
message.

You can't send a reply to a reply, so if the original message
contains a 'result' field, this method croaks.

=cut

sub reply
{
    my $self   = shift;
    my $result = shift;
    my $errmsg = shift;

    Carp::croak("can't reply to reply") if ($self->{'result'});

    $result = 'ok' unless ($result);

    my %fields = (%$self, result => $result);
    $fields{'errmsg'} = $errmsg if ($errmsg);
    
    return $self->new(%fields);
}


=head2 $msg->serialize()

Serialize this message into a string with lines of the format
key=value.

If a value is undefined the field is not added.

=cut

sub serialize
{
    my $self = shift;

    return $self->_to_s('', "\n");
}

=head2 $msg->to_s()

Return string version of this message, for instance for debugging.
Format is key=value separated by spaces.

If a value is undefined the field is not added.

=cut

sub to_s
{
    my $self = shift;

    return $self->_to_s(' ', '');
}

sub _to_s
{
    my $self       = shift;
    my $joinstring = shift;
    my $endstring  = shift;

    return join($joinstring, map { defined($self->{$_}) ? "$_=$self->{$_}$endstring" : '' } sort(keys %$self) );
}

=head2 $msg->send($socket, $dest)

Send message through $socket to $dest.

=cut

sub send
{
    my $self   = shift;
    my $socket = shift;
    my $dest   = shift;

    return $socket->send($self->serialize(), undef, $dest);
}

=head2 $msg->to_metatile()

Create metatile from message.

Croaks when the message can't be made into a valid metatile.

=cut

sub to_metatile
{
    my $self = shift;

    return Tirex::Metatile->new(
        map => $self->{'map'},
        x   => $self->{'x'},
        y   => $self->{'y'},
        z   => $self->{'z'}
    );
}

=head2 $msg->ok()

Is this message a positive reply (contains 'result=ok')?

=cut

sub ok
{
    my $self = shift;

    return unless (defined $self->{'result'});
    return $self->{'result'} eq 'ok';
}

=head2 $msg->unknown_message_type()

Is this an error message for an unknown message type (contains
'result=error_unknown_command')?

=cut

sub unknown_message_type
{
    my $self = shift;

    return unless (defined $self->{'result'});
    return $self->{'result'} eq 'error_unknown_command';
}


1;

#-- THE END ------------------------------------------------------------------
