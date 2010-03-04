#-----------------------------------------------------------------------------
#
#  Tirex/Munin.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Tirex;

#-----------------------------------------------------------------------------

package Tirex::Munin;

=head1 NAME

Tirex::Munin - Parent class for Munin scripts

=head1 SYNOPSIS

 my $m = Tirex::Munin::SomeSubclass->new(...)

 if ($ARGV[0] eq 'config') {
     print $m->config();
 } else {
     $m->init(...) or die;
     print $m->fetch();
 }

=head1 DESCRIPTION

Parent class for Munin scripts. This class is never instantiated, create subclasses
instead.

=head1 METHODS

=head2 Tirex::Munin::SomeSubclass->new( map => [ 'map1', 'map2' ], z => [$zr1, $zr2] )

Create new munin object.

=cut

sub new
{
    my $class = shift;

    die("never instantiate Tirex::Munin, create a subclass instead") if ($class eq 'Tirex::Munin');

    my %args = @_;
    my $self = bless \%args => $class;

    $self->{'zoomranges'} = [];
    foreach my $zr (@{$self->{'z'}})
    {
        if (ref($zr) eq '' && $zr =~ /^[0-9]+$/)
        {
            push(@{$self->{'zoomranges'}}, Tirex::Zoomrange->new("z$zr", $zr, $zr));
        }
        elsif ($zr =~ /^([0-9]+)-([0-9]+)$/)
        {
            push(@{$self->{'zoomranges'}}, Tirex::Zoomrange->new("z$zr", $1, $2));
        }
        else
        {
            push(@{$self->{'zoomranges'}}, $zr);
        }
    }

    $self->init(%args);

    return $self;
}

=head2 $m->do(...)

Do the right Munin action depending on command line.

All command line args are passed to init_data().

=cut

sub do
{
    my $self = shift;

    if (defined($ARGV[0]) && $ARGV[0] eq 'config')
    {
        print $self->config();
    }
    else
    {
        $self->init_data(@_);
        print $self->fetch();
    }
    return;
}

=head2 $m->init()

Initialize config source.

This method is called from new(), in the Tirex::Munin class it does nothing,
but can be overwritten in subclasses.

=cut

sub init { }

=head2 $m->config()

Return config in Munin format.

This method must be overwritten in subclasses.

=cut

sub config { die("overwrite config() in subclass"); }

=head2 $m->init_data()

Initialize data source.

This method must be called before fetch(), in the Tirex::Munin class it does
nothing, but can be overwritten in subclasses.

=cut

sub init_data { }

=head2 $m->fetch()

Return data in Munin format.

This method must be overwritten in subclasses.

=cut

sub fetch { die("overwrite fetch() in subclass"); }

=head2 Tirex::Munin::make_id($name)

Create Id from name by changing all characters except A-Z, a-z, and 0-9 to a _
(underscore).

=cut

sub make_id
{
    my $name = shift;
    (my $id = $name) =~ tr/A-Za-z0-9/_/cs;
    return $id;
}


1;

#-- THE END ------------------------------------------------------------------
