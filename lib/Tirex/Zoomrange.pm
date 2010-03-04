#-----------------------------------------------------------------------------
#
#  Tirex/Zoomrange.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

#-----------------------------------------------------------------------------

package Tirex::Zoomrange;

=head1 NAME

Tirex::Zoomrange - Range of zoom levels

=head1 SYNOPSIS

my $zr = Tirex::Job->new($name, $min[, $max])

=head1 DESCRIPTION


=head1 METHODS

=head2 Tirex::Zoomrange->new('foo', 4, 5)

Create new range. First argument is the name. Second and third argument the min
and max zoom levels. If no max level is given, it is the same as min.

If the name is undef, it is set to 'zMIN-MAX' or 'zMIN' if MIN==MAX.

=cut

sub new
{
    my $class = shift;
    my ($name, $min, $max) = @_;

    my $self = bless {} => $class;

    $self->{'min'}  = $min;
    $self->{'max'}  = $max // $min;
    $self->{'name'} = $name // ('z' . $self->to_s());

    return $self;
}

=head2 $zr->get_name()

Get name.

=cut

sub get_name
{
    my $self = shift;
    return $self->{'name'};
}

=head2 $zr->get_min()

Get minimum zoom level in this range.

=cut

sub get_min
{
    my $self = shift;
    return $self->{'min'};
}

=head2 $zr->get_max()

Get maximum zoom level in this range.

=cut

sub get_max
{
    my $self = shift;
    return $self->{'max'};
}

=head2 $zr->to_s()

Get range as string. Format "MIN-MAX" or "MIN" if MIN==MAX was empty.

=cut

sub to_s
{
    my $self = shift;
    return $self->{'min'} == $self->{'max'} ? $self->{'min'} : $self->{'min'} . '-' . $self->{'max'};
}

=head2 $zr->get_id()

Get id. The id is a simplified version of the name that only contains the characters a-z, 0-9, and _.

=cut

sub get_id
{
    my $self = shift;
    (my $id = $self->{'name'}) =~ s/[^a-z0-9]+/_/g;
    return $id;
}


1;

#-- THE END ------------------------------------------------------------------
