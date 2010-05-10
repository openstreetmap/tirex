#-----------------------------------------------------------------------------
#
#  Tirex/Metatiles/Range.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Carp;
use List::Util qw();
use Math::Trig;

#-----------------------------------------------------------------------------

package Tirex::Metatiles::Range;

=head1 NAME

Tirex::Metatiles::Range - range of metatiles

=head1 SYNOPSIS

 use Tirex::Metatiles::Range;

 $range = Tirex::Metatiles::Range->new( z => '3-4', lon => '8-9', lat => '48-49' );

=head1 DESCRIPTION

A range of metatiles for one or more maps, one or more zoom levels and an x/y range for a lon/lat bounding box.

Is used to easily iterate over all those metatiles.

=head1 METHODS

=head2 Tirex::Metatiles::Range->new(...)

Create new range.

=cut

sub new
{
    my $class = shift;
    my %args = ();
    my $self = bless \%args => $class;

    my %options = @_;

    $self->{'mtx'} = Tirex::Config::get_int('metatile_columns', $Tirex::METATILE_COLUMNS);
    $self->{'mty'} = Tirex::Config::get_int('metatile_rows',    $Tirex::METATILE_ROWS   );
    $self->{'mtz'} = 1; # XXX argh

    Carp::croak("you cannot have parameters 'z' and 'zmin'/'zmax'") if ( exists($options{'z'}) && ( exists($options{'zmin'}) || exists($options{'zmax'}) ) );
    Carp::croak("you cannot have parameters 'y' and 'ymin'/'ymax'") if ( exists($options{'y'}) && ( exists($options{'ymin'}) || exists($options{'ymax'}) ) );
    Carp::croak("you cannot have parameters 'x' and 'xmin'/'xmax'") if ( exists($options{'x'}) && ( exists($options{'xmin'}) || exists($options{'xmax'}) ) );

    foreach my $var ('xmin', 'xmax', 'ymin', 'ymax', 'zmin', 'zmax')
    {
        Carp::croak("$var must be zero or positive integer") if ( exists($options{$var}) && ($options{$var} !~ /^[0-9]+$/) );
    }

    foreach my $var ('lonmin', 'lonmax', 'latmin', 'latmax')
    {
        Carp::croak("$var must be legal degree value")    if ( exists($options{$var}) && ($options{$var} !~ /^-?[0-9]+(.[0-9]+)?$/) );
        Carp::croak("$var must be legal longitude value") if ( $var =~ /^lon/ && exists($options{$var}) && ($options{$var} < -180 || $options{$var} > 180) );
        Carp::croak("$var must be legal latitude value" ) if ( $var =~ /^lat/ && exists($options{$var}) && ($options{$var} <  -90 || $options{$var} >  90) );
    }

    foreach my $var ('x', 'y', 'z', 'lon', 'lat')
    {
        Carp::croak("'${var}min' but missing '${var}max'") if ( exists($options{$var . 'min'}) && ! exists($options{$var . 'max'}) );
        Carp::croak("'${var}max' but missing '${var}min'") if ( exists($options{$var . 'max'}) && ! exists($options{$var . 'min'}) );
    }

    foreach my $key (keys %options)
    {
        my $value = $options{$key};

        if ($key eq 'init')
        {
            $self->_parse_init($value);
        }
        else
        {
            $self->_parse_key_value($key, $options{$key});
        }
    }

    # make sure we have all needed parameters
    Carp::croak("missing 'map' parameter") if ( ! exists($self->{'maps'}));
    Carp::croak("missing 'z' or 'zmin'/'zmax' parameter") if ( ! exists($self->{'z'}) && ! exists($self->{'zmin'}) && ! exists($self->{'zmax'}) );
    Carp::croak("missing 'x' or 'xmin'/'xmax' or 'lon' or 'lonmin/lonmax' or 'bbox' parameter")
        if ( ! exists($self->{'x'}) && ! exists($self->{'xmin'}) && ! exists($self->{'xmax'}) &&
             ! exists($self->{'lon'}) && ! exists($self->{'lonmin'}) && ! exists($self->{'lonmax'}) );
    Carp::croak("missing 'y' or 'ymin'/'ymax' or 'lat' or 'latmin/latmax' or 'bbox' parameter")
        if ( ! exists($self->{'y'}) && ! exists($self->{'ymin'}) && ! exists($self->{'ymax'}) &&
             ! exists($self->{'lat'}) && ! exists($self->{'latmin'}) && ! exists($self->{'latmax'}) );

    # make sure min is always smaller than max
    ($self->{'zmin'  }, $self->{'zmax'  }) = (List::Util::min($self->{'zmin'  }, $self->{'zmax'  }), List::Util::max($self->{'zmin'  }, $self->{'zmax'  })) if (defined $self->{'zmin'  });
    ($self->{'ymin'  }, $self->{'ymax'  }) = (List::Util::min($self->{'ymin'  }, $self->{'ymax'  }), List::Util::max($self->{'ymin'  }, $self->{'ymax'  })) if (defined $self->{'ymin'  });
    ($self->{'xmin'  }, $self->{'xmax'  }) = (List::Util::min($self->{'xmin'  }, $self->{'xmax'  }), List::Util::max($self->{'xmin'  }, $self->{'xmax'  })) if (defined $self->{'xmin'  });
    ($self->{'lonmin'}, $self->{'lonmax'}) = (List::Util::min($self->{'lonmin'}, $self->{'lonmax'}), List::Util::max($self->{'lonmin'}, $self->{'lonmax'})) if (defined $self->{'lonmin'});
    ($self->{'latmin'}, $self->{'latmax'}) = (List::Util::min($self->{'latmin'}, $self->{'latmax'}), List::Util::max($self->{'latmin'}, $self->{'latmax'})) if (defined $self->{'latmin'});

    # if there is only one zoom level, calculate x/y range now
    if ($self->{'zmin'} == $self->{'zmax'})
    {
        ($self->{'xmin'}, $self->{'xmax'}) = $self->_get_range_x($self->{'zmin'});
        ($self->{'ymin'}, $self->{'ymax'}) = $self->_get_range_y($self->{'zmin'});
    }

    $self->reset();

    return $self;
}

sub _parse_key_value
{
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    if ($key eq 'map')       { $self->{'maps'} = ref($value) eq '' ? [split(',', $value)] : $value; }

    elsif ($key eq 'z')      { $self->_parse_int_range('z', $value); }
    elsif ($key eq 'x')      { $self->_parse_int_range('x', $value); }
    elsif ($key eq 'y')      { $self->_parse_int_range('y', $value); }

    elsif ($key eq 'zmin')   { $self->{'zmin'} = $value; }
    elsif ($key eq 'zmax')   { $self->{'zmax'} = $value; }

    elsif ($key eq 'xmin')   { $self->{'xmin'} = int($value / $self->{'mtx'}) * $self->{'mtx'}; }
    elsif ($key eq 'xmax')   { $self->{'xmax'} = int($value / $self->{'mtx'}) * $self->{'mtx'}; }
    elsif ($key eq 'ymin')   { $self->{'ymin'} = int($value / $self->{'mty'}) * $self->{'mty'}; }
    elsif ($key eq 'ymax')   { $self->{'ymax'} = int($value / $self->{'mty'}) * $self->{'mty'}; }

    elsif ($key eq 'lon')    { $self->_parse_degree_range('lon', $value); }
    elsif ($key eq 'lat')    { $self->_parse_degree_range('lat', $value); }

    elsif ($key eq 'lonmin') { $self->{'lonmin'} = $value; }
    elsif ($key eq 'lonmax') { $self->{'lonmax'} = $value; }
    elsif ($key eq 'latmin') { $self->{'latmin'} = $value; }
    elsif ($key eq 'latmax') { $self->{'latmax'} = $value; }

    elsif ($key eq 'bbox')   { $self->_parse_bbox($value); }

    elsif ($key eq 'init')   { $self->_parse_init($value); }

    else { Carp::croak("unknown parameter: '$key'"); }
}

sub _parse_init
{
    my $self = shift;
    my $init = shift;

    foreach my $parameter (split(/\s+/, $init))
    {
        if ($parameter =~ /^([^=]+)=(.+)$/)
        {
            $self->_parse_key_value($1, $2);
        }
        else
        {
            Carp::croak("can't parse init string: '$init'");
        }
    }

    return;
}

=head2 $range->reset()

Reset range, so that the next call to next() will return the first metatile in the range.

Returns range itself.

=cut

sub reset
{
    my $self = shift;

    $self->{'finished'} = 0;

    $self->{'current_map_pos'} = 0;
    $self->{'current_z'} = $self->{'zmin'};

    ($self->{'ymin_for_current_z'}, $self->{'ymax_for_current_z'}) = $self->_get_range_y($self->{'current_z'});
    ($self->{'xmin_for_current_z'}, $self->{'xmax_for_current_z'}) = $self->_get_range_x($self->{'current_z'});

    $self->{'current_y'} = $self->{'ymin_for_current_z'};
    $self->{'current_x'} = $self->{'xmin_for_current_z'};

    $self->{'metatiles'} = 0;

    return $self;
}

sub _get_range_x
{
    my $self = shift;
    my $zoom = shift;

    return ($self->{'xmin'}, $self->{'xmax'}) if (defined $self->{'xmin'});

    if (defined $self->{'lonmin'})
    {
        return (
            Tirex::Metatile::lon2x($self->{'mtx'}, $zoom, $self->{'lonmin'}),
            Tirex::Metatile::lon2x($self->{'mtx'}, $zoom, $self->{'lonmax'})
        );
    }

    Carp::croak("should not be here");
}

sub _get_range_y
{
    my $self = shift;
    my $zoom = shift;

    return ($self->{'ymin'}, $self->{'ymax'}) if (defined $self->{'ymin'});

    if (defined $self->{'latmin'})
    {
        return (
            Tirex::Metatile::lat2y($self->{'mty'}, $zoom, $self->{'latmax'}), # latitude increases from south to north, but tile numbers from north to south!
            Tirex::Metatile::lat2y($self->{'mty'}, $zoom, $self->{'latmin'})
        );
    }

    Carp::croak("should not be here");
}

=head2 $range->count()

Calculates how many metatiles there are in this range.

=cut

sub count
{
    my $self = shift;

    my $maps = scalar(@{$self->{'maps'}});

    my $tiles = 0;
    foreach my $zoom ($self->{'zmin'} .. $self->{'zmax'})
    {
        my ($ymin, $ymax) = $self->_get_range_y($zoom);
        my ($xmin, $xmax) = $self->_get_range_x($zoom);
        $tiles += (int(($ymax - $ymin)/$self->{'mtx'}) + 1) * (int(($xmax - $xmin)/$self->{'mty'}) + 1);
    }

    return $maps * $tiles;
}

=head2 $range->get_metatiles()

Return the number of metatiles you already got out of this range with next().

=cut

sub get_metatiles
{
    my $self = shift;
    return $self->{'metatiles'};
}

=head2 $range->to_s()

Return string describing the range.

=cut

sub to_s
{
    my $self = shift;

    if ($self->{'lonmin'})
    {
        return sprintf('maps=%s z=%s lon=%s lat=%s',
            join(',', @{$self->{'maps'}}),
            _range_to_s($self->{'zmin'}, $self->{'zmax'}),
            _range_to_s($self->{'lonmin'}, $self->{'lonmax'}),
            _range_to_s($self->{'latmin'}, $self->{'latmax'})
        );
    }
    else
    {
        return sprintf('maps=%s z=%s x=%s y=%s',
            join(',', @{$self->{'maps'}}),
            _range_to_s($self->{'zmin'}, $self->{'zmax'}),
            _range_to_s($self->{'xmin'}, $self->{'xmax'}),
            _range_to_s($self->{'ymin'}, $self->{'ymax'})
        );
    }
}

sub _range_to_s
{
    my $min = shift;
    my $max = shift;

    return $min == $max ? $min : "$min,$max";
}

=head2 $range->next()

Get next metatile from the range.

Returns undef if there are no more metatiles.

=cut

sub next
{
    my $self = shift;

    return undef if ($self->{'finished'});

    my $metatile = Tirex::Metatile->new(
        map => $self->{'maps'}->[$self->{'current_map_pos'}],
        x   => $self->{'current_x'},
        y   => $self->{'current_y'},
        z   => $self->{'current_z'}
    );

    $self->{'current_x'} += $self->{'mtx'};

    if ($self->{'current_x'} > $self->{'xmax_for_current_z'})
    {
        $self->{'current_y'} += $self->{'mty'};

        if ($self->{'current_y'} > $self->{'ymax_for_current_z'})
        {
            $self->{'current_z'}++;

            if ($self->{'current_z'} > $self->{'zmax'})
            {
                $self->{'current_map_pos'}++;

                if ($self->{'current_map_pos'} >= scalar(@{$self->{'maps'}}))
                {
                    $self->{'finished'} = 1;
                    return $metatile;
                }

                $self->{'current_z'} = $self->{'zmin'};
            }

            ($self->{'ymin_for_current_z'}, $self->{'ymax_for_current_z'}) = $self->_get_range_y($self->{'current_z'});
            ($self->{'xmin_for_current_z'}, $self->{'xmax_for_current_z'}) = $self->_get_range_x($self->{'current_z'});

            $self->{'current_y'} = $self->{'ymin_for_current_z'};
        }

        $self->{'current_x'} = $self->{'xmin_for_current_z'};
    }

    $self->{'metatiles'}++;

    return $metatile;
}

sub _parse_int_range
{
    my $self = shift;
    my $var  = shift;
    my $val  = shift;

    if ($val =~ /^[0-9]+$/)
    {
        $self->{$var . 'min'} = int($val / $self->{"mt$var"}) * $self->{"mt$var"};
        $self->{$var . 'max'} = int($val / $self->{"mt$var"}) * $self->{"mt$var"};
    }
    elsif ($val =~ /^([0-9]+)\s*[:,-]\s*([0-9]+)$/)
    {
        $self->{$var . 'min'} = int($1 / $self->{"mt$var"}) * $self->{"mt$var"};
        $self->{$var . 'max'} = int($2 / $self->{"mt$var"}) * $self->{"mt$var"};
    }
    else
    {
        Carp::croak("wrong format for '$var'");
    }
    return;
}

sub _parse_degree_range
{
    my $self = shift;
    my $var  = shift;
    my $val  = shift;

    if ($val =~ /^-?[0-9]+(\.[0-9]+)?$/)
    {
        $self->{$var . 'min'} = $val;
        $self->{$var . 'max'} = $val;
    }
    elsif ($val =~ /^(-?[0-9]+(?:\.[0-9]+)?)\s*[:,]\s*(-?[0-9]+(?:\.[0-9]+)?)$/)
    {
        $self->{$var . 'min'} = $1;
        $self->{$var . 'max'} = $2;
    }
    else
    {
        Carp::croak("wrong format for '$var'");
    }
    return;
}

sub _parse_bbox
{
    my $self = shift;
    my $val  = shift;

    if ($val =~ /^(-?[0-9]+(?:\.[0-9]+)?)\s*[:,]\s*(-?[0-9]+(?:\.[0-9]+)?)\s*[:,]\s*(-?[0-9]+(?:\.[0-9]+)?)\s*[:,]\s*(-?[0-9]+(?:\.[0-9]+)?)$/)
    {
        $self->{'lonmin'} = $1;
        $self->{'lonmax'} = $3;
        $self->{'latmin'} = $2;
        $self->{'latmax'} = $4;
    }
    else
    {
        Carp::croak("wrong format for 'bbox'");
    }
    return
}    


1;

#-- THE END ------------------------------------------------------------------
