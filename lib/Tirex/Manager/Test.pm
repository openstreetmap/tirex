#-----------------------------------------------------------------------------
#
#  Tirex/Manager/Test.pm
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Tirex;
use Tirex::Manager;

#-----------------------------------------------------------------------------

package Tirex::Manager::Test;
use base qw( Tirex::Manager );

=head1 NAME

Tirex::Manager::Test - Dummy rendering manager for testing

=head1 SYNOPSIS

 use Tirex::Manager::Test;

 my $queue = Tirex::Queue->new();
 my $rm = Tirex::Manager::Test->new( queue => $queue );

 $rm->set_load(1.5);
 print $rm->get_load();

 $rm->schedule();

=head1 DESCRIPTION

This is a dummy version of the L<Tirex::Manager> rendering manager class for testing. It is a child class of the normal L<Tirex::Manager> class and behaves just like it except that
you can set the "system load" with set_load() and this load is returned by the get_load() method. This way the system load can be simulated in tests.

This class also has a dummy version of the send() method that doesn't actually send the message.

=head1 METHODS

=head2 $rm->get_load()

Get the load that was set with set_load().

=cut

sub get_load
{
    my $self = shift;

    return $self->{'load'} || 0;
}

=head2 $rm->set_load($load)

Set the load.

=cut

sub set_load
{
    my $self = shift;
    my $load = shift;

    $self->{'load'} = $load;

    return;
}

=head2 $rm->send($job)

Simulate sending a job to the rendering daemon.

=cut

sub send
{
    # do nothing
    return;
}

=head1 SEE ALSO

L<Tirex::Manager>

=cut

1;

#-- THE END ------------------------------------------------------------------
