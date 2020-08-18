#-----------------------------------------------------------------------------
#
#  t/message_basic.t
#
#-----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More qw( no_plan );
 
use lib 'lib';

use Tirex;

#-----------------------------------------------------------------------------

eval{ Tirex::Message->new( foo => 'bar' ); };
if ($@ =~ /need type for new message/) { pass(); } else { fail(); }

my $msg = Tirex::Message->new( type => 'test', foo => 1, bar => '' );
isa_ok($msg, 'Tirex::Message', 'create');
is($msg->{'type'}, 'test', 'type');
is($msg->{'foo'},  1,      'attribute foo');
is($msg->{'bar'},  '',     'attribute bar');
is($msg->to_s(),   'bar= foo=1 type=test', 'to_s');

my $s = $msg->serialize();
is($s, "bar=\nfoo=1\ntype=test\n", 'serialize');

my $smsg = Tirex::Message->new_from_string($s);
is_deeply($smsg, $msg, 're-created');

#-----------------------------------------------------------------------------

my $crlfmsg = Tirex::Message->new_from_string("type=foo\r\nbar=baz\r\n");
is($crlfmsg->{'type'}, 'foo', 'CRLF parse type');
is($crlfmsg->{'bar'},  'baz', 'CRLF parse bar');

#-----------------------------------------------------------------------------

$msg = Tirex::Message->new( type => 'test', foo => 'x=y', bar => undef );
isa_ok($msg, 'Tirex::Message', 'create');
is($msg->{'type'}, 'test', 'type');
is($msg->{'foo'},  'x=y',  'attribute foo');
is($msg->{'bar'},  undef,  'attribute bar');

is($msg->serialize(), "foo=x=y\ntype=test\n", 'serialize');

my $pmsg = $msg->new_from_string($msg->serialize());
is($pmsg->{'type'}, 'test', 'pmsg type');
is($pmsg->{'foo'},  'x=y',  'pmsg attribute foo');

#-----------------------------------------------------------------------------

$msg = Tirex::Message->new( type => 'test', foo => 1, bar => '', result => 'ok' );

eval{ $msg->reply('error_foo'); };
if ($@ =~ /can't reply to reply/) { pass(); } else { fail(); }

ok($msg->ok(), 'ok');

#-----------------------------------------------------------------------------

$msg = Tirex::Message->new( type => 'test', foo => 1, bar => '' );

ok(!$msg->ok(), 'not ok');

my $r1 = $msg->reply('ok');
my $r2 = $msg->reply('error');
my $r3 = $msg->reply('error_foo');
my $r4 = $msg->reply('error_foo', 'broken');

isa_ok($r1, 'Tirex::Message', 'reply r1');
isa_ok($r2, 'Tirex::Message', 'reply r2');
isa_ok($r3, 'Tirex::Message', 'reply r3');
isa_ok($r4, 'Tirex::Message', 'reply r4');

is($r1->{'type'},   'test',      'r1 type');
is($r1->{'foo'},    '1',         'r1 foo');
is($r1->{'bar'},    '',          'r1 bar');
is($r1->{'result'}, 'ok',        'r1 result');
is($r2->{'result'}, 'error',     'r2 result');
is($r3->{'result'}, 'error_foo', 'r3 result');
is($r3->{'errmsg'}, undef,       'r3 errmsg');
is($r4->{'result'}, 'error_foo', 'r4 result');
is($r4->{'errmsg'}, 'broken',    'r4 errmsg');

#-----------------------------------------------------------------------------

$msg = Tirex::Message->new( type => 'foo', map => 'test', x => 1, y => 2, z => 3 );
my $metatile = $msg->to_metatile();
is($metatile->to_s(), 'map=test z=3 x=0 y=0', 'metatile');


#-- THE END ------------------------------------------------------------------
