#-----------------------------------------------------------------------------
#
#  t/tirex_basic.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;

#-----------------------------------------------------------------------------
# test message handling
#-----------------------------------------------------------------------------

my $msg = { foo => 'bar', 1 => 2, blob => 'blib' };

my $str = Tirex::create_msg($msg);
is($str, "1=2\nblob=blib\nfoo=bar\n", 'create_msg');

is_deeply(Tirex::parse_msg($str), $msg , 'parse msg');

my $print = Tirex::print_msg($msg);
is($print, "  1=2\n  blob=blib\n  foo=bar\n", 'print_msg');

my $crlf = Tirex::parse_msg("a=b\r\nc=d\ne=f\r\n");
is_deeply($crlf, { a => 'b', c => 'd', e => 'f' }, 'parse msg with crlf');


#-- THE END ------------------------------------------------------------------
