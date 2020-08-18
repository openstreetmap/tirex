#-----------------------------------------------------------------------------
#
#  Tirex/Source/Test.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;

use IO::Socket;

#-----------------------------------------------------------------------------
package Tirex::Source::Test;
use base qw( Tirex::Source );

=head1 NAME

Tirex::Source::Test -- Dummy source for testing

=head1 SYNOPSIS

 my $source = Tirex::Source::Test->new('x');
 $source->notify();

=head1 DESCRIPTION

Dummy source for testing notifies.

=head1 METHODS

=head2 Tirex::Source::Test->new($x)

Create new object. The parameter will be returned on notify calls.

=cut

sub new
{
    my $class = shift;
    my %args = ();
    my $self = bless \%args => $class;
    $self->{'para'} = shift;

    return $self;
}

=head2 $source->notify()

Returns the parameter that was given when the class was created.

=cut

sub notify
{
    my $self = shift;
    return $self->{'para'};
}


1;


#-- THE END ------------------------------------------------------------------
