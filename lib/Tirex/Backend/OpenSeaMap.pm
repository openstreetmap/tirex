#-----------------------------------------------------------------------------
#
#  Tirex/Backend/OpenSeaMap.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use List::Util qw();
use Carp;

use Tirex::Backend;

#-----------------------------------------------------------------------------

package Tirex::Backend::OpenSeaMap;
use base qw( Tirex::Backend );

=head1 NAME

Tirex::Backend::OpenSeaMap - OpenSeaMap backend for Tirex

=head1 DESCRIPTION

This backend calls an external Java program to generate an OpenSeaMap 
meta tile. The Java program is here: https://svn.openstreetmap.org/applications/editors/josm/plugins/seachart/jrenderpgsql/

Config parameters for the map file:

=over 8

=item dburl the JDBC database connection URL, with username and password if needed

=item jar the JAR file containing the JRenderPsql class to use

=item scalefactor the scale factor (defaults to 1.0)

=item tilesize the tile size (should be 256 * scalefactor to avoid issues)

=head1 METHODS

=head2 $backend->init()

This method initializes things specific to this backend.

=cut

sub init
{
    my $self = shift;

    $self->{'border_width'} = 6;
    GD::Image->trueColor(1);

}

=head2 $backend->check_map_config($map)

=cut

sub check_map_config
{
    my $self = shift;
    my $map  = shift;

    if ($Tirex::METATILE_COLUMNS != $Tirex::METATILE_ROWS)
    {
        Carp::croak("this plugin cannot work with non-square meta tiles");
    }

    if (!defined($map->{'jar'}))
    {
        Carp::croak("must configure renderer in map file");
    }

    if (!-f $map->{'jar'})
    {
        Carp::croak("configured renderer " . $map->{'jar'} . " does not exist");
    }

    if (!defined($map->{'dburl'}))
    {
        Carp::croak("must configure dburl in map file");
    }
}

=head2 $backend->create_metatile()

Create a metatile.

=cut

sub create_metatile
{
    my $self     = shift;
    my $map      = shift;
    my $metatile = shift;

    my $xc   = $metatile->get_x();
    my $yc   = $metatile->get_y();
    my $zoom = $metatile->get_z();

    my $pixel = $Tirex::PIXEL_PER_TILE;
    my $tmpfile = "/tmp/tirex-$$-openseamap.png";
    my $cmdline = sprintf("java -jar %s --scale %f --tilesize %d '%s' %d %d %d %s",
        $map->{'jar'}, $map->{'scalefactor'}, $map->{'tilesize'} * $Tirex::METATILE_COLUMNS, $map->{'dburl'}, $zoom , $xc, $yc, $tmpfile);

    ::syslog('debug', 'OpenSeaMap request: %s', $cmdline) if ($Tirex::DEBUG);
    system($cmdline);

    my $image = GD::Image->new($tmpfile);
    $image->alphaBlending(0);
    $image->saveAlpha(1);

    unlink ($tmpfile);
    return $image;
}


1;

#-- THE END ------------------------------------------------------------------
