#-----------------------------------------------------------------------------
#
#  Tirex/Munin/Status.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use JSON;

use Tirex::Status;
use Tirex::Munin;

#-----------------------------------------------------------------------------

package Tirex::Munin::Status;
use base qw( Tirex::Munin );

=head1 NAME

Tirex::Munin::Status - Parent class for Tirex munin classes using status

=head1 SYNOPSIS

my $m = Tirex::Munin::Status::SomeSubclass->new(...)
$m->init();

=head1 DESCRIPTION

Parent class for Tirex munin classes using status.

=head1 METHODS

=head2 $m->init_config()

Initialize data source from status in shared memory.

=cut

sub init
{
    my $self = shift;

    eval {
        my $status = Tirex::Status->new()->read();
        $self->{'status'} = JSON::from_json($status);
        return 1;
    };

    return 0;
}


1;

#-- THE END ------------------------------------------------------------------
