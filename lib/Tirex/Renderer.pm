#-----------------------------------------------------------------------------
#
#  Tirex/Renderer.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;

#-----------------------------------------------------------------------------

package Tirex::Renderer;

# a hash with all configured renderers
our %Renderers;

=head1 NAME

Tirex::Renderer - A Tirex renderer config

=head1 SYNOPSIS

my $r = Tirex::Renderer->new( ... );

=head1 DESCRIPTION

Tirex can work with several rendering backends. For each one several processes
are started by tirex-renderd-manager and they are sent requests my tirex-master.
This class defines methods to configure renderers.

=head1 METHODS

=head2 Tirex::Renderer->read_config_dir($dir)

Read all renderer configs in given config directory.

=cut

sub read_config_dir
{
    my $class = shift;
    my $dir   = shift;

    foreach my $file (glob("$dir/renderer/*.conf"))
    {
        $class->new_from_configfile($file);
    }
}

=head2 Tirex::Renderer->get('foo')

Get renderer by name.

=cut

sub get
{
    my $class = shift;
    my $name  = shift;

    return $Renderers{$name};
}

=head2 Tirex::Renderer->all();

Return sorted (by name) list of all configured renderers.

=cut

sub all
{
    return sort { $a->get_name() cmp $b->get_name() } values %Renderers;
}

=head2 Tirex::Renderer->new( name => 'foo', type => 'type', path => '/path/to/exec', port => 1234, procs => 3, ... )

Create new renderer config.

Every renderer has at least these general options: name, type, path, port, and
procs. Will croak if they are not all present.

In addition it can have zero or more options specific to this renderer.

Will croak if a renderer configuration already exists under the same name.

=cut

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = bless \%args => $class;

    Carp::croak("missing name")  unless (defined $self->{'name'} );
    Carp::croak("missing type")  unless (defined $self->{'type'} );
    Carp::croak("missing path")  unless (defined $self->{'path'} );
    Carp::croak("missing port")  unless (defined $self->{'port'} );
    Carp::croak("missing procs") unless (defined $self->{'procs'});
    Carp::croak("renderer with name $self->{'name'} exists") if ($Renderers{$self->{'name'}});

    $Renderers{$self->{'name'}} = $self;

    return $self;
}

=head2 Tirex::Renderer->new_from_configfile($filename)

Create new renderer config from a file.

Croaks if the file does not exist.

=cut

sub new_from_configfile
{
    my $class    = shift;
    my $filename = shift;

    my %config;
    open(my $cfgfh, '<', $filename) or Carp::croak("Can't open renderer config file '$filename': $!");
    while (<$cfgfh>)
    {
        s/#.*$//;
        next if (/^\s*$/);
        if (/^([a-z0-9_]+)\s*=\s*(\S*)\s*$/) {
            $config{$1} = $2;
        }
    }
    close($cfgfh);

    return $class->new(%config);
}

=head2 $rend->get_config()

Return hash with renderer-specific configuration.

=cut

sub get_config
{
    my $self = shift;

    my $cfg = {};

    foreach my $key (keys %$self)
    {
        next if ($key =~ /^(name|type|path|port|procs|syslog_facility)$/);
        $cfg->{$key} = $self->{$key};
    }
    
    return $cfg;
}

=head2 $rend->get_name();

Get name of this renderer.

=cut

sub get_name { return shift->{'name' }; }

=head2 $rend->get_debug();

Get debug flag of this renderer.

=cut

sub get_debug { return shift->{'debug' }; }

=head2 $rend->get_type();

Get type of this renderer.

=cut

sub get_type { return shift->{'type' }; }

=head2 $rend->get_path();

Get path of this renderer.

=cut

sub get_path { return shift->{'path' }; }

=head2 $rend->get_port();

Get port of this renderer.

=cut

sub get_port { return shift->{'port' }; }

=head2 $rend->get_procs();

Get procs of this renderer.

=cut

sub get_procs { return shift->{'procs'}; }

=head2 $rend->get_syslog_facility();

Get syslog facility of this renderer.

=cut

sub get_syslog_facility { return shift->{'syslog_facility'}; }

=head2 $rend->to_s();

Return human readable description of this renderer.

=cut

sub to_s
{
    my $self = shift;

    my $s = sprintf("Renderer %s: type=%s port=%d procs=%d path=%s", $self->get_name(), $self->get_type(), $self->get_port(), $self->get_procs(), $self->get_path());

    foreach my $key (sort keys %$self) {
        $s .= " $key=$self->{$key}" unless ($key =~ /^(name|type|port|path|procs)$/);
    }

    return $s;
}

=head2 $rend->to_hash();

Return parameters of this renderer as hash.

=cut

sub to_hash
{
    my $self = shift;

    my %hash = %$self;
    $hash{'port'}  = 0 + $self->get_port(); # force integer (so that it works in JSON)
    $hash{'procs'} = 0 + $self->get_procs();

    return \%hash;
}

=head2 Tirex::Renderer->status();

Return status of all configured renderers.

=cut

sub status
{
    my $self = shift;

    my @status = ();
    foreach my $renderer (sort { $a->get_name() cmp $b->get_name() } values %Renderers)
    {
        push(@status, $renderer->to_hash());
    }

    return \@status;
}

=head2 $rend->add_worker($pid);

Add process id to list of currently running workers.

=cut

sub add_worker
{
    my $self = shift;
    my $pid  = shift;

    $self->{'workers'}->{$pid} = 1;
}

=head2 $rend->remove_worker($pid);

Remove process id from list of currently running workers.

=cut

sub remove_worker
{
    my $self = shift;
    my $pid  = shift;

    delete $self->{'workers'}->{$pid};
}

=head2 $rend->num_workers();

Return number of currently running workers.

=cut

sub num_workers
{
    my $self = shift;

    return scalar(keys %{$self->{'workers'}});
}


1;

#-- THE END ------------------------------------------------------------------
