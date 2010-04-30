#-----------------------------------------------------------------------------
#
#  Tirex.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Sys::Syslog;

use Tirex::Message;
use Tirex::Zoomrange;
use Tirex::Metatile;
use Tirex::Metatiles::Range;
use Tirex::Job;
use Tirex::Config;

#-----------------------------------------------------------------------------

package Tirex;

our $DEBUG = 0;
our $VERSION = "0.0";

=head1 NAME

Tirex - Tirex Tile Rendering System

=head1 SYNOPSIS

 use Tirex;

=head1 DESCRIPTION

There are only a few utility functions and config variables in the Tirex namespace.

=cut

# max size of UDP packets (this just defines the buffer size, no actual check is done)
our $MAX_PACKET_SIZE = 512;

# max zoom level we will ever allow
our $MAX_ZOOM = 30;

# defaults for config variables (these can also be set in the config file, see there for documentation)
our $METATILE_COLUMNS = 8;
our $METATILE_ROWS    = 8;
our $PIXEL_PER_TILE   = 256;
our $RENDERD_UDP_PORT = 9320;
our $SYNCD_UDP_PORT   = 9323;

our $MODTILE_SOCK = "/var/lib/tirex/modtile.sock";
our $MODTILE_PERM = 0666;

our $MASTER_UDP_PORT          = 9322;
our $MASTER_SYSLOG_FACILITY   = 'local0';
our $MASTER_PIDFILE           = '/var/run/tirex/tirex-master.pid';
our $SYNCD_PIDFILE            = '/var/run/tirex/tirex-syncd.pid';
our $RENDERD_PIDFILE          = '/var/run/tirex/tirex-renderd-starter.pid';
our $MASTER_LOGFILE           = '/var/log/tirex/jobs.log';
our $TIREX_CONFIGDIR          = '/etc/tirex';
our $TIREX_CONFIGFILENAME     = 'tirex.conf';
our $TIREX_CONFIGFILE         = $TIREX_CONFIGDIR . '/' . $TIREX_CONFIGFILENAME;
our $MASTER_RENDERING_TIMEOUT = 10; # minutes
our $RENDERD_ALIVE_TIMEOUT    = 8; # minutes - make this a tad smaller than the above

# set dummy to enable built-in dummy renderer
our $RENDERD_DUMMY            = 0;
our $RENDERD_DUMMY_SLEEPTIME  = 2;
our $RENDERD_PROCESSES        = 5;

our $METATILE_DIR             = '/var/lib/tirex/tiles';
our $STATS_DIR                = '/var/lib/tirex/stats';
our $MAPNIK_PLUGINDIR         = '/usr/lib/mapnik/input';
our $MAPNIK_FONTDIR           = '/usr/lib/mapnik/fonts';
our $MAPNIK_MAPDIR            = '/etc/mapnik-osm-data/';
our $MAPNIK_FONTDIR_RECURSE   = 0;

=head1 METHODS

=head2 Tirex::parse_msg($string)

Parse a message with linefeed separated var=value assignments into a hash ref. Carriage returns are removed.

=cut

sub parse_msg
{
    my $string = shift;
    my $msg;
    foreach (split(/\r?\n/m, $string))
    {
        my ($k, $v) = split(/=/);
        $msg->{$k} = $v;
    }
    return $msg;
}

=head2 tirex::create_msg($msg)

Create a message string with lines of the format key=value from a hash.

=cut

sub create_msg
{
    my $msg         = shift;
    my $prefixcount = shift || 0;

    my $string = '';
    foreach my $k (sort(keys %$msg))
    {
        $string .= (' ' x $prefixcount);
        $string .= "$k=$msg->{$k}\n";
    }
    return $string;
}

=head2 Tirex::print_msg($msg)

Create a message string with lines of the format key=value from a hash. Each line has two leading spaces. For debugging output.

=cut

sub print_msg
{
    my $msg = shift;
    create_msg($msg, 2);
}

=head1 SEE ALSO

L<Tirex::Config>,
L<Tirex::Job>,
L<Tirex::Manager::Bucket>,
L<Tirex::Manager::RenderingJobs>,
L<Tirex::Manager>,
L<Tirex::Metatile>,
L<Tirex::PrioQueue>,
L<Tirex::Queue>,
L<Tirex::Source>,
L<Tirex::Status>,
L<Tirex::Synclog>

=cut


1;

#-- THE END ------------------------------------------------------------------
