#-----------------------------------------------------------------------------
#
#  Tirex/Metatile.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;
use Math::Trig;
use File::stat;

#-----------------------------------------------------------------------------

package Tirex::Metatile;

=head1 NAME

Tirex::Metatile - A Metatile

=head1 SYNOPSIS

my $mt = Tirex::Metatile->new( map => 'osm', x => 16, y => 12, z=> 12 );

=head1 DESCRIPTION

A metatile.

=head1 METHODS

=head2 Tirex::Metatile->new( ... )

Create new metatile object.

A metatile always needs the following parameters:

 map  the map config to use for rendering
 x    metatile x coordinate
 y    metatile y coordinate
 z    zoom level

You can give any x and y coordinate in the range 0 .. 2^z-1. It will be
rounded down to the next tile coordinate.

Croaks if there is a problem with the parameters.

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = bless \%args => $class;

    Carp::croak("need map for new metatile") unless (defined $self->{'map'});
    Carp::croak("need x for new metatile")   unless (defined $self->{'x'}  );
    Carp::croak("need y for new metatile")   unless (defined $self->{'y'}  );
    Carp::croak("need z for new metatile")   unless (defined $self->{'z'}  );
    Carp::croak("z must be between 0 and $Tirex::MAX_ZOOM (but is $self->{'z'})") unless ( 0 <= $self->{'z'} && $self->{'z'} <= $Tirex::MAX_ZOOM );

    my $limit = 2 ** $self->{'z'} - 1;
    Carp::croak("x must be between 0 and 2^z-1 (but is $self->{'x'})") unless ( 0 <= $self->{'x'} && $self->{'x'} <= $limit );
    Carp::croak("y must be between 0 and 2^z-1 (but is $self->{'y'})") unless ( 0 <= $self->{'y'} && $self->{'y'} <= $limit );

    $self->{'x'} -= $self->{'x'} % Tirex::Config::get('metatile_columns', $Tirex::METATILE_COLUMNS);
    $self->{'y'} -= $self->{'y'} % Tirex::Config::get('metatile_rows',    $Tirex::METATILE_ROWS   );

    return $self;
}

=head2 Tirex::Metatile->new_from_filename($filename)

Create metatile from filename. The first directory element must be the
map name.

Optionally, the filename can start with '/' or './'.

=cut

sub new_from_filename
{
    my $class    = shift;
    my $filename = shift;

    # remove leading / or ./
    $filename =~ s{^\.?/}{};

    # remove trailing .meta
    $filename =~ s{\.meta$}{};

    my @path_components = split('/', $filename);
    my $map = shift @path_components;
    my $z   = shift @path_components;

    my $x = 0;
    my $y = 0;

    Carp::croak("not a valid metatile filename: too many or too few components") unless (scalar(@path_components) == 5);

    while (defined (my $c = shift @path_components))
    {
        Carp::croak("failed to parse tile path (invalid component '$c')") if ($c < 0 || $c > 255);
        $x <<= 4;
        $y <<= 4;
        $x |= ($c & 0xf0) >> 4;
        $y |= ($c & 0x0f);
    }

    return $class->new( map => $map, z => $z, x => $x, y => $y );
}

=head2 Tirex::Metatile->new_from_lon_lat(map => $map, lon => $lon, lat => $lat, z => $z)

Create metatile from zoom, longitude, and latitude.

=cut

sub new_from_lon_lat
{
    my $class = shift;
    my %args  = @_;

    my $map = $args{'map'};
    my $z   = $args{'z'};
    my $lon = $args{'lon'};
    my $lat = $args{'lat'};

    Carp::croak('need map for new metatile') unless (defined $map);
    Carp::croak('need z for new metatile')   unless (defined $z  );
    Carp::croak('need lon for new metatile') unless (defined $lon);
    Carp::croak('need lat for new metatile') unless (defined $lat);

    Carp::croak('lon must be between -180 and 180')                     unless (-180       <= $lon && $lon <= 180);
    Carp::croak('lat must be between -85.05112 and 85.05113')           unless ( -85.05112 <= $lat && $lat <= 85.05113);
    Carp::croak("z must be between 0 and $Tirex::MAX_ZOOM (but is $z)") unless (   0       <= $z   && $z   <= $Tirex::MAX_ZOOM );

    my $x = lon2x(1, $z, $lon);
    my $y = lat2y(1, $z, $lat);

    return $class->new( map => $map, z => $z, x => $x, y => $y );
}

# Tirex::Metatile::lon2x
sub lon2x
{
    my $mtx  = shift;
    my $zoom = shift;
    my $lon  = shift;

    my $limit = 2 ** $zoom;
    my $x = int( ($lon+180) / 360 * $limit );

    $x = $limit-1 if ($x >= $limit); # need this so that +180 comes out to max x

    return int($x / $mtx) * $mtx;
}

# Tirex::Metatile::lat2y
sub lat2y
{
    my $mty  = shift;
    my $zoom = shift;
    my $lat  = shift;

    $lat = -85.05113 if ($lat < -85.05113);
    $lat =  85.05113 if ($lat >  85.05113);

    my $limit = 2 ** $zoom;
    $lat = $lat * Math::Trig::pi / 180; # degree -> radians
    my $y = int( ( 1 - log(Math::Trig::tan($lat) + Math::Trig::sec($lat)) / Math::Trig::pi ) / 2 * $limit );

    $y = $limit-1 if ($y >= $limit); # need this so that -85.05113 comes out to max y

    return int($y / $mty) * $mty;
}

=head2 $mt->get_x()

Get x coordinate.

=head2 $mt->get_y()

Get y coordinate.

=head2 $mt->get_x()

Get zoom.

=head2 $mt->get_map()

Get map.

=cut

sub get_x   { my $self = shift; return $self->{'x'};   }
sub get_y   { my $self = shift; return $self->{'y'};   }
sub get_z   { my $self = shift; return $self->{'z'};   }
sub get_map { my $self = shift; return $self->{'map'}; }

=head2 $mt->to_s()

Return string describing this metatile in the format
'map=MAP z=Z x=X y=Y'

=cut

sub to_s
{
    my $self = shift;

    return join(' ', map { "$_=$self->{$_}"; } qw( map z x y ));
}

=head2 $mt->equals($other_metatile)

Returns true if both metatiles are the same, false otherwise.

The same tile means: same map, same x and y coordinates and same zoom level.

=cut

sub equals
{
    my $self  = shift;
    my $other = shift;

    return (($self->{'map'} eq $other->{'map'}) &&
            ($self->{'x'}   == $other->{'x'}  ) &&
            ($self->{'y'}   == $other->{'y'}  ) &&
            ($self->{'z'}   == $other->{'z'}  ));
}

=head2 $mt->up()

Return the metatile one zoom level above this metatile that contains this metatile.

=cut

sub up
{
    my $self = shift;

    return if ($self->{'z'} == 0);

    my $x = int($self->{'x'} / 2);
    my $y = int($self->{'y'} / 2);

    $x -= $x % Tirex::Config::get('metatile_columns', $Tirex::METATILE_COLUMNS);
    $y -= $y % Tirex::Config::get('metatile_rows',    $Tirex::METATILE_ROWS   );

    return Tirex::Metatile->new( map => $self->{'map'}, z => $self->{'z'} - 1, x => $x, y => $y );
}

=head2 $mt->filename()

Return filename for this metatile.

Format is something like:
  /[metatile_dir]/[map]/[zoom]/[path].meta

  metatile_dir  from the config file
  map           map
  zoom          zoom level
  path          path with 4 directory elements and a filename
                based on x and y coordinates

=cut

sub filename
{
    my $self = shift;

    my @path_components;
    my $x = $self->{'x'};
    my $y = $self->{'y'};

    foreach (0..4)
    {
       my $v = $x & 0x0f;
       $v <<= 4;
       $v |=  ($y & 0x0f);
       $x >>= 4;
       $y >>= 4;
       unshift(@path_components, $v);
    }

    unshift(@path_components, $self->{'z'});
    unshift(@path_components, $self->{'map'});
    unshift(@path_components, Tirex::Config::get('metatile_dir') || '');

    return join('/', @path_components) . '.meta';
}


=head2 $mt->exists()

Does the metatile file for this metatile exist?

=cut

sub exists
{
    my $self = shift;

    my $s = $self->_stat() or return 0;

    return 1;
}


=head2 $mt->older($time)

Is the metatile file older than the given time?

Returns 2 if the file doesn't exist.

=cut

sub older
{
    my $self = shift;
    my $time = shift;

    my $s = $self->_stat() or return 2;

    return $s->mtime() < $time;
}

=head2 $mt->size()

Return size of the metatile file.

=cut

sub size
{
    my $self = shift;

    my $s = $self->_stat() or return 0;

    return $s->size();
}

# call stat on the metatile file and memoize the result
sub _stat
{
    my $self = shift;

    $self->{'stat'} = stat($self->filename()) unless (defined $self->{'stat'});

    return $self->{'stat'};
}


1;

#-- THE END ------------------------------------------------------------------
