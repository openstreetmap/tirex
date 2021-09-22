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

our $VERSION = '0.6.2';

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

our $EXIT_CODE_RESTART = 9;
our $EXIT_CODE_DISABLE = 10;

our $STATS_DIR = '/var/cache/tirex/stats';

our $PIXEL_PER_TILE   = 256;

#-----------------------------------------------------------------------------
# defaults for config variables (these can also be set in the config file, see there for documentation)
our $METATILE_COLUMNS = 8;
our $METATILE_ROWS    = 8;

our $TIREX_CONFIGDIR                 = '/etc/tirex';
our $TIREX_CONFIGFILENAME            = 'tirex.conf';
our $TIREX_CONFIGFILE                = $TIREX_CONFIGDIR . '/' . $TIREX_CONFIGFILENAME;

our $SOCKET_DIR                      = '/run/tirex';

our $MASTER_SYSLOG_FACILITY          = 'daemon';
our $MASTER_PIDFILE                  = '/run/tirex/tirex-master.pid';
our $MASTER_LOGFILE                  = '/var/log/tirex/jobs.log';
our $MASTER_RENDERING_TIMEOUT        = 10; # minutes

our $BACKEND_MANAGER_SYSLOG_FACILITY = 'daemon';
our $BACKEND_MANAGER_PIDFILE         = '/run/tirex/tirex-backend-manager.pid';
our $BACKEND_MANAGER_ALIVE_TIMEOUT   = 8; # minutes - make this a tad smaller than the above

our $SYNCD_PIDFILE                   = '/run/tirex/tirex-syncd.pid';
our $SYNCD_UDP_PORT                  = 9323;
our $SYNCD_AGGREGATE_DELAY           = 5;
our $SYNCD_COMMAND                   = qq(tar -C/ -cf - %FILES% | ssh %HOST% -oControlMaster=auto -oControlPersist=1h -oControlPath=$SOCKET_DIR/ssh-control-%h-%r-%p -Tq "tar -C/ -xf -");

our $MODTILE_SOCK                    = "/run/tirex/modtile.sock";
our $MODTILE_PERM                    = 0666;

#-----------------------------------------------------------------------------

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

L<Tirex::Backend>,
L<Tirex::Backend::Test>,
L<Tirex::Backend::WMS>,
L<Tirex::Config>,
L<Tirex::Job>,
L<Tirex::Manager::Bucket>,
L<Tirex::Manager::RenderingJobs>,
L<Tirex::Manager>,
L<Tirex::Map>,
L<Tirex::Message>,
L<Tirex::Metatile>,
L<Tirex::Metatiles::Range>,
L<Tirex::PrioQueue>,
L<Tirex::Queue>,
L<Tirex::Renderer>,
L<Tirex::Source>,
L<Tirex::Status>,
L<Tirex::Zoomrange>,
L<http://wiki.openstreetmap.org/wiki/Tirex>

=cut


1;

#-- THE END ------------------------------------------------------------------
