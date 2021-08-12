#-----------------------------------------------------------------------------
#
#  Tirex/Backend/TMS.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use HTTP::Async;
use HTTP::Request;
use IPC::SysV qw(IPC_PRIVATE IPC_CREAT S_IWUSR S_IRUSR);
use IPC::SharedMem;
use List::Util qw(min max);

use Tirex::Backend;

#-----------------------------------------------------------------------------

package Tirex::Backend::TMS;
use base qw( Tirex::Backend );

=head1 NAME

Tirex::Backend::TMS - TMS backend for Tirex

=head1 DESCRIPTION

Simple "renderer" that gets the map image from a TMS server. The TMS server
is assumed to be a standard EPSG:3857 service with standard tiling scheme.

Config parameters for the map file:

=over 8

=item url url template (should contain {x}, {y}, {z} which are replaced)
=item slots maximum number of parallel connections per backend process

=back

=head1 METHODS

=head2 $backend->init()

This method initializes things specific to this backend.

=cut

sub init
{
    my $self = shift;
    $self->{'max_tile_size'} = 4 * 256 * 256 + 256;
}

=head2 $backend->create_metatile()

Create a metatile.

=cut

sub create_metatile
{
    my $self     = shift;
    my $map      = shift;
    my $metatile = shift;

    my $async = HTTP::Async->new;
    $async->slots(defined($map->{'slots)'} ? $map->{'slots)'} : 4));
    my $async_index = {};
    my $async_error = 0;
    my $async_array = [];

    my $limit = 2 ** $metatile->get_z();
    
    my $url = $map->{'url'};
    my $z = $metatile->get_z();
    $url =~ s/{z}/$z/g;

    for (my $x = 0; $x < $Tirex::METATILE_COLUMNS; $x++)
    {
        my $xx = $metatile->get_x() + $x;
        next if ($xx >= $limit);
        my $url1 = $url;
        $url1 =~ s/{x}/$xx/g;
        for (my $y = 0; $y < $Tirex::METATILE_ROWS; $y++)
        {
            my $yy = $metatile->get_y() + $y;
            next if ($yy >= $limit);
            my $url2 = $url1;
            $url2 =~ s/{y}/$yy/g;
            ::syslog('debug', 'TMS request: %s', $url2) if ($Tirex::DEBUG);
            my $request = HTTP::Request->new('GET', $url2, [ 'User-Agent' => 'tirex-backend-tms/' . $Tirex::VERSION ]);
            my $async_id = $async->add($request);
            $async_index->{$async_id} = $x*$Tirex::METATILE_ROWS+$y;
        }
    }
    while (my ($response, $async_id) = $async->wait_for_next_response) 
    {
        if ($response->is_success() && $response->header('Content-type') eq 'image/png')
        {
            my $size = length($response->content());
            if ($size > $self->{'max_tile_size'})
            {
                ::syslog('err', 'Error on TMS request: %d bytes returned but limit is %d', $size, $self->{'max_tile_size'} );
                $async_error = 1;
                last;
            }
            else
            {
                my $index = $async_index->{$async_id};
                ::syslog('debug', 'TMS request was successful (got %d bytes), saving at index %d', $size, $index) if ($Tirex::DEBUG);
                $async_array->[$index] = $response->content();
            }
        }
        else
        {
            ::syslog('err', 'Error on TMS request: status=%d (%s) content-type=%s', $response->code(), $response->message(), $response->header('Content-type'));
            $async_error = 1;
            last;
        }
    }
    $async->remove_all();

    return undef if ($async_error);
    return $async_array;
}

# write_metatile is not normally overloaded by backends; the standard implementation
# cuts a large image returned by create_metatile into smaller PNGs. However the TMS 
# service does not bother to create a large metatile, it simply keeps the 64 tiles
# in an array and saves them into the meta tile.

sub write_metatile
{
    my $self     = shift;
    my $image    = shift;
    my $filename = shift;
    my $metatile = shift;

    # metatile header
    my $limit = 2 ** $metatile->get_z();
    my $meta = 'META' . pack('llll', $Tirex::METATILE_ROWS * $Tirex::METATILE_COLUMNS,
                                     $metatile->get_x(),
                                     $metatile->get_y(),
                                     $metatile->get_z());

    my @pngs = ();    
    my $offset = length($meta) + ($Tirex::METATILE_COLUMNS * $Tirex::METATILE_ROWS * 2 * 4); # header + (number of tiles * (start offset and length) * 4 bytes for int32)
    # this builds the offset table in the meta tile's header
    foreach my $x (0..$Tirex::METATILE_COLUMNS-1)
    {
        my $xx = $metatile->get_x() + $x;
        foreach my $y (0..$Tirex::METATILE_ROWS-1)
        {
            my $yy = $metatile->get_y() + $y;
            my $size = ($x >= $limit || $y >= $limit) ? 0 : length($image->[$x*$Tirex::METATILE_ROWS+$y]);
            $meta .= pack('ll', $offset, $size);
            $offset += $size;
        }
    }

    # add pngs to metatile
    $meta .= join('', grep { defined($_) } @$image);

    # check for directory and create if missing
    (my $dirname = $filename) =~ s{/[^/]*$}{};
    if (! -d $dirname)
    {
        File::Path::mkpath($dirname) or $self->error_disable("Can't create path $dirname: $!");
    }

    open(METATILE, '>', $filename) or $self->error_disable("Can't open $filename: $!");
    binmode(METATILE);
    print METATILE $meta;
    close(METATILE);
}

1;

#-- THE END ------------------------------------------------------------------
