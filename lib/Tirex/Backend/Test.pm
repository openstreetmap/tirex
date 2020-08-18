#-----------------------------------------------------------------------------
#
#  Tirex/Backend/Test.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use List::Util qw();
use Carp;

use Tirex::Backend;

#-----------------------------------------------------------------------------

package Tirex::Backend::Test;
use base qw( Tirex::Backend );

=head1 NAME

Tirex::Backend::Test - Test backend for Tirex

=head1 DESCRIPTION

This backend creates a checkerboard test pattern for testing the Tirex
tile rendering system. It will be called from tirex-backend-manager if you
configure it in /etc/tirex/renderer/test.conf.

It has no renderer specific configuration option. There is one renderer
specific configuration option for maps called "sleep".  It gives the time in
seconds the renderer should sleep before notifying the tirex-master to simulate
a longer rendering time.

=head1 METHODS

=head2 $backend->init()

This method initializes things specific to this backend.

=cut

sub init
{
    my $self = shift;

    $self->{'border_width'} = 6;
}

=head2 $backend->check_map_config($map)

=cut

sub check_map_config
{
    my $self = shift;
    my $map  = shift;

    if (defined $map->{'sleep'})
    {
        Carp::croak("parameter 'sleep' needs integer argument between 0 and 999 (is '" . $map->{'sleep'} . "')") unless ($map->{'sleep'} =~ /^[0-9]{1,3}$/);
        $map->{'sleep'} = 0 + $map->{'sleep'}; # force to integer
    }
    else
    {
        $map->{'sleep'} = 0; # default: no sleep
    }
}

=head2 $backend->create_metatile()

Create a metatile.

The metatile will have a checkerboard pattern with the tile numbers and
zoom level in each tile and an additional red border around the whole metatile.

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

    my $image = GD::Image->new($pixel * $Tirex::METATILE_COLUMNS, $pixel * $Tirex::METATILE_ROWS);

    my $white = $image->colorAllocate(255, 255, 255);
    my $black = $image->colorAllocate(  0,   0,   0);
    my $red   = $image->colorAllocate(200,   0,   0); # for border around metatile
    my @color = ($white, $black);

    my $font = GD::Font->Large;
    my $text_y_offset1 = $pixel/2 - (1.5 * $font->height());
    my $text_y_offset2 = $pixel/2 + (0.5 * $font->height());

    # create checkerboard pattern and write tile numbers and zoom into it
    foreach my $x (0..$Tirex::METATILE_COLUMNS-1)
    {
        foreach my $y (0..$Tirex::METATILE_ROWS-1)
        {
            my $xpixel = $x * $pixel;
            my $ypixel = $y * $pixel;

            my $color_offset = ($x+$y) % 2;

            $image->filledRectangle($xpixel, $ypixel, $xpixel + $pixel - 1, $ypixel + $pixel - 1, $color[$color_offset]);

            my $text1 = sprintf("x=%d y=%d", $xc + $x, $yc + $y);
            my $text2 = sprintf("zoom=%d", $zoom);

            my $text_x_offset1 = $pixel/2 - (length($text1)/2) * $font->width();
            my $text_x_offset2 = $pixel/2 - (length($text2)/2) * $font->width();

            $image->string($font, $xpixel + $text_x_offset1, $ypixel + $text_y_offset1, $text1, $color[1 - $color_offset]);
            $image->string($font, $xpixel + $text_x_offset2, $ypixel + $text_y_offset2, $text2, $color[1 - $color_offset]);
        }
    }

    # draw border around metatile
    my $xmax = $pixel * List::Util::min(2**$zoom, $Tirex::METATILE_COLUMNS) - 1;
    my $ymax = $pixel * List::Util::min(2**$zoom, $Tirex::METATILE_ROWS)    - 1;
    $image->filledRectangle(                              0,                               0,                   $xmax, $self->{'border_width'}, $red);
    $image->filledRectangle(                              0,                               0, $self->{'border_width'},                   $ymax, $red);
    $image->filledRectangle($xmax - $self->{'border_width'},                               0,                   $xmax,                   $ymax, $red);
    $image->filledRectangle(                              0, $ymax - $self->{'border_width'},                   $xmax,                   $ymax, $red);

    # sleep to simulate longer rendering time if so configured
    sleep($map->{'sleep'});

    return $image;
}


1;

#-- THE END ------------------------------------------------------------------
