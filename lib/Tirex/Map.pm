#-----------------------------------------------------------------------------
#
#  Tirex/Map.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;

#-----------------------------------------------------------------------------

package Tirex::Map;

=head1 NAME

Tirex::Map - A Tirex map configuration

=head1 SYNOPSIS

my $map = Tirex::Map->new();

=head1 DESCRIPTION


=head1 METHODS

=head2 Tirex::Map->new( ... )

Create new map configuration.

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = bless \%args => $class;

    Carp::croak("missing name") unless (defined $self->{'name'});

    return $self;
}

=head2 $job->get_name()

Get name of this map.

=cut

sub get_name { return shift->{'name'}; }


1;

#-- THE END ------------------------------------------------------------------
