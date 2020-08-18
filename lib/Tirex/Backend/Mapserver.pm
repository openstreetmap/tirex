#-----------------------------------------------------------------------------
#
#  Tirex/Backend/Mapserver.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use mapscript;

use Tirex::Backend;

#-----------------------------------------------------------------------------

package Tirex::Backend::Mapserver;
use base qw( Tirex::Backend );

=head1 NAME

Tirex::Backend::Mapserver - Mapserver backend for Tirex

=head1 DESCRIPTION

Simple "renderer" that gets the map image from a Mapserver via Mapscript.

Config parameters for the map file:

=over 8

=item mapfile mapfile to use for Mapserver configuration

=item layers list of comma-separated layers

=item srs spatial reference system, 'EPSG:3857' etc.

=item transparent TRUE or FALSE

=back

=head1 METHODS

=head2 $backend->init()

This method initializes things specific to this backend.

=cut

sub init
{
    my $self = shift;
    mapscript::msIO_installStdoutToBuffer();
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

    my ($left, $right, $top, $bottom, $size);

    my $pow = 2 ** $zoom;

    if ($pow <= $Tirex::METATILE_COLUMNS)
    {
        $left   = -20037508.3392;
        $right  =  20037508.3392;
        $top    =  20037508.3392;
        $bottom = -20037508.3392;
        $size   = $Tirex::PIXEL_PER_TILE * $pow;
    }
    else
    {
        my $factor = 40075016.6784 / $pow;
        my $yy = $pow - $yc - $Tirex::METATILE_ROWS;

        $left   = ( $xc                           * $factor) - 20037508.3392;
        $right  = (($xc+$Tirex::METATILE_COLUMNS) * $factor) - 20037508.3392;
        $bottom = ( $yy                           * $factor) - 20037508.3392;
        $top    = (($yy+$Tirex::METATILE_ROWS)    * $factor) - 20037508.3392;

        $size   = $Tirex::PIXEL_PER_TILE * $Tirex::METATILE_COLUMNS;
    }

    ::syslog('debug', 'Mapserver request for layer(s) >>%s<< started with mapfile %s', $map->{'layers'}, $map->{'mapfile'}) if ($Tirex::DEBUG);

    my $req = new mapscript::OWSRequest();
    $req->setParameter( 'SERVICE', 'WMS' );
    $req->setParameter( 'VERSION', '1.1.1' );
    $req->setParameter( 'REQUEST', 'GetMap' );
    $req->setParameter( 'LAYERS', $map->{'layers'});
    $req->setParameter( 'STYLES', '' );
    $req->setParameter( 'SRS', $map->{'srs'} || 'EPSG:3857' );
    $req->setParameter( 'BBOX', join(',', $left, $bottom, $right, $top));
    $req->setParameter( 'WIDTH', "$size");
    $req->setParameter( 'HEIGHT', "$size");
    $req->setParameter( 'FORMAT', 'image/png');
    $req->setParameter( 'TRANSPARENT', $map->{'transparent'} || 'FALSE' );
    $req->setParameter( 'EXCEPTIONS', 'application/vnd.ogc.se_xml');

    $self->set_status("mapserver request");

    my $msmap = new mapscript::mapObj( $map->{'mapfile'} );
    $msmap->OWSDispatch( $req );
    
    my $content_type = mapscript::msIO_stripStdoutBufferContentType();
    my $content  = mapscript::msIO_getStdoutBufferBytes();

    if ($content_type eq 'image/png')
    {
        # Bit 0 af Byte 25 in the png header is 1 for palette image, 0 for truecolor image:
        # http://en.wikipedia.org/wiki/Portable_Network_Graphics#File_header
        my $palette_bit = unpack("x25 c1", $$content) & 1;
        my $palette_name;
        my $image;
        # Despite the description at http://search.cpan.org/~lds/GD-2.46/GD.pm
        # "Images created by reading PNG images will be truecolor if the image file itself is truecolor."
        #
        # auto-detection of input png does not seem to work so (at least for now) we need to do this manually by looking at the png header        
        if ($palette_bit)
        {
            $image = GD::Image->newFromPngData($$content,0);
            $palette_name = "palette";
        }
        else
        {
            $image = GD::Image->newFromPngData($$content,1);
            $palette_name = "truecolor";
        }
        if ($image)
        {
            ::syslog('debug', 'Mapserver request was successful (got %s image)',$palette_name) if ($Tirex::DEBUG);
            return $image;
        }
    }
    ::syslog('err', 'Error on Mapserver request: content-type=%s', $content_type);
    if ($content_type eq 'application/vnd.ogc.se_xml' && $Tirex::DEBUG)
    {
        ::syslog('debug', 'Mapserver request returned: %s', $$content);
    }
    return $self->create_error_image($map, $metatile);
}


1;

#-- THE END ------------------------------------------------------------------
