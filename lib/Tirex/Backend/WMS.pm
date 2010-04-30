#-----------------------------------------------------------------------------
#
#  Tirex/Backend/WMS.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use LWP;

#-----------------------------------------------------------------------------

package Tirex::Backend::WMS;
use base qw( Tirex::Backend );

=head1 NAME

Tirex::Backend::WMS - WMS backend for Tirex

=head1 DESCRIPTION

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
    $self->{'ua'}->agent('tirex-renderd-wms/0.1');
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
        BBOX        => join(',', $left, $bottom, $right, $top),
        SRS         => $map->{'srs'},
        WIDTH       => $size,
        HEIGHT      => $size,
        LAYERS      => $map->{'layers'},
        STYLES      => '',
        FORMAT      => 'image/png',
        TRANSPARENT => 'TRUE',
    );

    my $request = $map->{'url'} . join('&', map { $_ . '=' . $wms_request{$_} } sort keys %wms_request);
    ::syslog('debug', 'WMS request: %s', $request);

    my $response = $self->{'ua'}->request(HTTP::Request->new(GET => $request));

    my $image;
    if ($response->is_success() && $response->header('Content-type') eq 'image/png')
    {
        ::syslog('debug', 'WMS request was successful');
        $image = GD::Image->new($response->content());
    }
    else
    {
        ::syslog('err', 'Error on WMS request: status=%d (%s) content-type=%s', $response->code(), $response->message(), $response->header('Content-type'));
        $image = $self->create_error_image($map, $metatile);
    }

    return $image;
}


1;

#-- THE END ------------------------------------------------------------------
