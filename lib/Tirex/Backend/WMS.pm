#-----------------------------------------------------------------------------
#
#  Tirex/Backend/WMS.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use LWP;

use Tirex::Backend;

#-----------------------------------------------------------------------------

package Tirex::Backend::WMS;
use base qw( Tirex::Backend );

=head1 NAME

Tirex::Backend::WMS - WMS backend for Tirex

=head1 DESCRIPTION

Simple "renderer" that gets the map image from a WMS server. The WMS server
must support the right SRS (EPSG:3857 or the informal EPSG:900913).

Only WMS 1.1.1 is currently supported.

Config parameters for the map file:

=over 8

=item url url prefix

=item layers list of comma-separated layers

=item srs spatial reference system, 'EPSG:3857' etc.

=item transparent TRUE or FALSE

=back

=head1 METHODS

=head2 $backend->type()

Return type of this backend: 'wms'.

=cut

sub type
{
    return 'wms';
}

=head2 $backend->init()

This method initializes things specific to this backend.

=cut

sub init
{
    my $self = shift;

    $self->{'ua'} = LWP::UserAgent->new();
    $self->{'ua'}->agent('tirex-backend-wms/' . $Tirex::VERSION);
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
        $top    = ( $yy                           * $factor) - 20037508.3392;
        $bottom = (($yy+$Tirex::METATILE_ROWS)    * $factor) - 20037508.3392;

        $size   = $Tirex::PIXEL_PER_TILE * $Tirex::METATILE_COLUMNS;
    }

    my %wms_request = (
        SERVICE     => 'WMS',
        VERSION     => '1.1.1',
        REQUEST     => 'GetMap',
        LAYERS      => $map->{'layers'},
        STYLES      => '',
        SRS         => $map->{'srs'} || 'EPSG:3857',
        BBOX        => join(',', $left, $bottom, $right, $top),
        WIDTH       => $size,
        HEIGHT      => $size,
        FORMAT      => 'image/png',
        TRANSPARENT => $map->{'transparent'} || 'FALSE',
        EXCEPTIONS  => 'application/vnd.ogc.se_xml',
    );

    my $request = $map->{'url'} . join('&', map { $_ . '=' . $wms_request{$_} } sort keys %wms_request);
    ::syslog('debug', 'WMS request: %s', $request) if ($Tirex::DEBUG);

    $self->set_status("wms request");

    my $response = $self->{'ua'}->request(HTTP::Request->new(GET => $request));

    if ($response->is_success() && $response->header('Content-type') eq 'image/png')
    {
        if (my $image = GD::Image->newFromPngData($response->content()))
        {
            ::syslog('debug', 'WMS request was successful') if ($Tirex::DEBUG);
            return $image;
        }
    }
    ::syslog('err', 'Error on WMS request: status=%d (%s) content-type=%s', $response->code(), $response->message(), $response->header('Content-type'));
    if ($response->header('Content-type') eq 'application/vnd.ogc.se_xml' && $Tirex::DEBUG)
    {
        ::syslog('debug', 'WMS request returned: %s', $response->content());
    }
    return $self->create_error_image($map, $metatile);
}


1;

#-- THE END ------------------------------------------------------------------
