#-----------------------------------------------------------------------------
#
#  Tirex/Config.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;

#-----------------------------------------------------------------------------

package Tirex::Config;

=head1 NAME

Tirex::Config - Configuration 

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 METHODS

=cut

our $confhash = {};

=head2 init($configfilename [,$prefix])

Loads the given config file. Dies on failure.
If $prefix is given, all keys are prepended with $prefix and a dot.
Does not overwrite already loaded data.

=cut

sub init {
    my $configname = shift;
    my $prefix     = shift;

    $prefix = defined($prefix) ? "$prefix." : "";

    open(my $configfh, '<', $configname) or die("cannot open configuration file '$configname'");
    while (<$configfh>)
    {
        chomp;
        parse_line($configname, $prefix, $_);
    }
    close($configfh);
}

sub parse_line
{
    my $configname = shift;
    my $prefix     = shift;
    my $line       = shift;

    $line =~ s/#.*$//;
    if ($line =~ /^([a-z0-9_]+)\s*=\s*(\S*)\s*$/)
    {
        $confhash->{$prefix.$1} = $2;
    }
    elsif ($line =~ /^([a-z0-9_]+)\s+(.*?)\s*$/)
    {
        my $obj = $1;
        my @attrs = split(/\s+/, $2);
        my %attrs = ();
        foreach my $attr (@attrs)
        {
            if ($attr =~ /^([a-z0-9_]+)=(.*)$/)
            {
                $attrs{$1} = $2;
            }
        }
        push(@{$confhash->{$prefix.$obj}}, \%attrs);
    }
    elsif ($line =~ /^\s*$/)
    {
        # ignore empty lines
    }
    else
    {
        Carp::croak("error reading config file '$configname' in line $.");
    }
}


=head2 dump_to_syslog()

Dump config to syslog.

=cut

sub dump_to_syslog {
    foreach my $key (sort(keys %$confhash))
    {
        my $value = $confhash->{$key};

        if (ref($value) eq 'ARRAY')
        {
            my @values = ();
            foreach my $item (@$value)
            {
                push(@values, '{' . join(' ', map { "$_=$item->{$_}"; } sort keys %$item) . '}');
            }
            $value = '[' . join(',', @values) . ']';
        }

        ::syslog('info', 'Config %s=%s', $key, $value);
    }
}
        
=head2 get($key [,$default [, $pattern]])

Returns the value of config key $key, or $default if the value is unset.

If $pattern is available the value is checked against it. Will croak if
it doesn't match.

=cut

sub get {
    my $key     = shift;
    my $default = shift;
    my $pattern = shift;

    my $value = defined($confhash->{$key}) ? $confhash->{$key} : $default;

    if (defined $pattern)
    {
        Carp::croak("config value for '$key' doesn't match pattern '$pattern'") unless ($value =~ $pattern);
    }

    return $value;
}

=head2 get_int($key [,$default])

Returns the value of config key $key as integer, or $default if the value is unset.

=cut

sub get_int {
    my $key = shift;
    return sprintf "%d", defined($confhash->{$key}) ? $confhash->{$key} : shift;
}

1;

