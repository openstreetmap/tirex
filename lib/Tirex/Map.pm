#-----------------------------------------------------------------------------
#
#  Tirex/Map.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;

use Tirex::Renderer;

#-----------------------------------------------------------------------------

package Tirex::Map;

# a hash with all configured maps
our %Maps;

=head1 NAME

Tirex::Map - A Tirex map configuration

=head1 SYNOPSIS

my $map = Tirex::Map->new();

=head1 DESCRIPTION

A Tirex map configuration. It always contains the name, tile directory and zoom
range for this map. Depending on the backend there can be more options.

=head1 METHODS

=head2 Tirex::Map->get('foo')

Get map by name.

=cut

sub get
{
    my $class = shift;
    my $name  = shift;

    return $Maps{$name};
}

=head2 Tirex::Map->clear();

Clear list of maps.

=cut

sub clear
{
    %Maps = ();
}

=head2 Tirex::Map->get_map_for_metatile($metatile)

Get map for a metatile.

Will croak if the map named in the metatile does not exist. Will also croak if
the zoom given in the metatile is out of range.

=cut

sub get_map_for_metatile
{
    my $class    = shift;
    my $metatile = shift;

    my $map = $Maps{$metatile->get_map()};
    Carp::croak("map with name '" . $metatile->get_map() . "' not found") unless (defined $map);
    Carp::croak('zoom out of range') if ($metatile->get_z() < $map->get_minz());
    Carp::croak('zoom out of range') if ($metatile->get_z() > $map->get_maxz());

    return $map;
}

=head2 Tirex::Map->new( ... )

Create new map configuration.

Default values for minimum zoom (minz) is 0, for maximum zoom (maxz) it's 17.

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = bless \%args => $class;

    Carp::croak('missing name'    ) unless (defined $self->{'name'    });
    Carp::croak('missing renderer') unless (defined $self->{'renderer'});
    Carp::croak('missing tiledir' ) unless (defined $self->{'tiledir' });
    Carp::croak("map with name $self->{'name'} exists") if ($Maps{$self->{'name'}});

    $self->{'minz'} =  0 unless (defined $self->{'minz'});
    $self->{'maxz'} = 17 unless (defined $self->{'maxz'});

    $Maps{$self->{'name'}} = $self;

    return $self;
}

=head2 Tirex::Map->new_from_configfile($filename, $renderer)

Create new map config from a file for a given renderer.

Croaks if the file does not exist.

=cut

sub new_from_configfile
{
    my $class    = shift;
    my $filename = shift;
    my $renderer = shift;

    my %config;
    open(my $cfgfh, '<', $filename) or Carp::croak("Can't open map config file '$filename': $!");
    while (<$cfgfh>)
    {
        s/#.*$//;
        next if (/^\s*$/);
        if (/^([a-z0-9_]+)\s*=\s*(\S*)\s*$/) {
            $config{$1} = $2;
        }
    }
    close($cfgfh);

    $config{'filename'} = $filename;
    $config{'renderer'} = $renderer;

    return $class->new(%config);
}

=head2 $map->get_name()

Get name of this map.

=cut

sub get_name { return shift->{'name'}; }

=head2 $map->get_renderer()

Get renderer of this map.

=cut

sub get_renderer { return shift->{'renderer'}; }

=head2 $map->get_filename()

Get filename of config file for this map. This only works if the map was
created from a config file. Otherwise it will return undef.

=cut

sub get_filename { return shift->{'filename'}; }

=head2 $map->get_tiledir()

Get tile directory of this map.

=cut

sub get_tiledir { return shift->{'tiledir'}; }

=head2 $map->get_minz()

Get minimum zoom value of this map.

=cut

sub get_minz { return shift->{'minz'}; }

=head2 $map->get_maxz()

Get maximum zoom of this map.

=cut

sub get_maxz { return shift->{'maxz'}; }

=head2 $map->to_s();

Return human readable description of this map.

=cut

sub to_s
{
    my $self = shift;

    my $s = sprintf("Map %s: renderer=%s tiledir=%s zoom=%d-%d", $self->get_name(), $self->get_renderer()->get_name(), $self->get_tiledir(), $self->get_minz(), $self->get_maxz());

    foreach my $key (sort keys %$self) {
        $s .= " $key=$self->{$key}" unless ($key =~ /^(name|renderer|tiledir|minz|maxz|filename)$/);
    }

    return $s;
}

=head2 $map->to_hash();

Return parameters of this map as hash.

=cut

sub to_hash
{
    my $self = shift;

    my %hash = %$self;
    $hash{'minz'}     = 0 + $self->get_minz(); # force integer (so that it works in JSON)
    $hash{'maxz'}     = 0 + $self->get_maxz();
    $hash{'renderer'} = $self->get_renderer()->get_name();

    return \%hash;
}

=head2 Tirex::Map->status();

Return status of all configured maps.

=cut

sub status
{
    my $self = shift;

    my @status = ();
    foreach my $map (sort { $a->get_name() cmp $b->get_name() } values %Maps)
    {
        push(@status, $map->to_hash());
    }

    return \@status;
}


1;

#-- THE END ------------------------------------------------------------------
