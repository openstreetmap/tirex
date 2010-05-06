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

Tirex can work with several rendering backends such as Mapnik or WMS.  A
backend can be started with different configurations, for the Mapnik backend
you need to configure the font directory for instance. This class defines
methods for reading the config files (/etc/tirex/renderer/*.conf) describing
the backend configurations and managing those renderers.

See the class L<Tirex::Backend> and its subclasses for the actual code of
some backends.

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

    my $self = bless {} => $class;

    Carp::croak("missing name")  unless (defined $args{'name'} );
    Carp::croak("missing type")  unless (defined $args{'type'} );
    Carp::croak("missing path")  unless (defined $args{'path'} );
    Carp::croak("missing port")  unless (defined $args{'port'} );
    Carp::croak("missing procs") unless (defined $args{'procs'} );

    Carp::croak("renderer with name $args{'name'} already exists") if ($Renderers{$args{'name'}});

    foreach my $cfg ( qw( name type path port procs syslog_facility debug filename ) )
    {
        $self->{$cfg} = $args{$cfg};
        delete $args{$cfg};
    }

    # set default values
    $self->{'syslog_facility'} = $Tirex::BACKEND_MANAGER_SYSLOG_FACILITY unless ($self->{'syslog_facility'});
    $self->{'debug'}           = 0                                       unless ($self->{'debug'});
    $self->{'maps'}            = [];

    $self->{'config'} = \%args;

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

    my %config = ( filename => $filename );
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

    my $renderer = $class->new(%config);
    $renderer->read_map_config();

    return $renderer;
}

=head2 $rend->read_map_config()

Read all map configs for this renderer.

=cut

sub read_map_config
{
    my $self = shift;

    (my $dirname = $self->{'filename'}) =~ s/\.conf$//;

    return unless (-d $dirname);

    my @maps;
    foreach my $file (glob("$dirname/*.conf"))
    {
        push(@maps, Tirex::Map->new_from_configfile($file, $self));
    }

    $self->{'maps'} = \@maps;
}

=head2 $rend->get_maps()

Get array ref of map configs for this renderer.

=cut

sub get_maps { return shift->{'maps'}; }

=head2 $rend->get_config()

Return hash with renderer-specific configuration.

=cut

sub get_config
{
    my $self = shift;

    return $self->{'config'};
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

    my $s = sprintf("Renderer %s:", $self->get_name());

    foreach my $key ( qw( type port procs path syslog_facility debug ) ) {
        $s .= " $key=$self->{$key}";
    }
    foreach my $key ( sort keys %{$self->{'config'}}) {
        $s .= " $key=$self->{'config'}->{$key}";
    }

    return $s;
}

=head2 $rend->to_hash();

Return parameters of this renderer as hash.

=cut

sub to_hash
{
    my $self = shift;

    my %hash = %{$self->{'config'}};
    $hash{'name'}            =     $self->get_name();
    $hash{'type'}            =     $self->get_type();
    $hash{'path'}            =     $self->get_path();
    $hash{'syslog_facility'} =     $self->get_syslog_facility();
    $hash{'debug'}           = 0 + $self->get_debug(); # force integer (so that it works in JSON)
    $hash{'port'}            = 0 + $self->get_port();
    $hash{'procs'}           = 0 + $self->get_procs();

    $hash{'maps'} = [map { $_->get_name(); } @{$self->get_maps()}];

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
