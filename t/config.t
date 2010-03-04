#-----------------------------------------------------------------------------
#
#  t/config.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;

#-----------------------------------------------------------------------------

Tirex::Config::parse_line('t', '', '');
is_deeply($Tirex::Config::confhash, {}, 'empty 1');

Tirex::Config::parse_line('t', '', '  ');
is_deeply($Tirex::Config::confhash, {}, 'empty 2');

Tirex::Config::parse_line('t', '', '# foo');
is_deeply($Tirex::Config::confhash, {}, 'empty 3');

Tirex::Config::parse_line('t', '', 'a=b');
is_deeply($Tirex::Config::confhash, { a => 'b'}, 'a 1');
$Tirex::Config::confhash = {};

Tirex::Config::parse_line('t', '', 'a=b ');
is_deeply($Tirex::Config::confhash, { a => 'b'}, 'a 2');
$Tirex::Config::confhash = {};

Tirex::Config::parse_line('t', '', 'a =b');
is_deeply($Tirex::Config::confhash, { a => 'b'}, 'a 3');
$Tirex::Config::confhash = {};

Tirex::Config::parse_line('t', '', 'a = b');
is_deeply($Tirex::Config::confhash, { a => 'b'}, 'a 4');
$Tirex::Config::confhash = {};

Tirex::Config::parse_line('t', '', 'foo a=b ');
is_deeply($Tirex::Config::confhash, { foo => [ { a => 'b' } ] }, 'list 1');
$Tirex::Config::confhash = {};

Tirex::Config::parse_line('t', '', 'bucket name=live  minprio=1  maxproc=3 maxload=20');
is_deeply($Tirex::Config::confhash, { bucket => [ { name => 'live', minprio => 1, maxproc => 3, maxload => 20 } ] }, 'list 1');
$Tirex::Config::confhash = {};


#-- THE END ------------------------------------------------------------------
