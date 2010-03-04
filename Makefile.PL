use ExtUtils::MakeMaker;

unless (eval { require Test::More; 1 }) {
	print STDERR "*** Test::More is not installed, you will not be able to run the tests\n";
}
unless ($] >= 5.006001) {
	print STDERR "*** This Perl version ($]) is not supported\n";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	       => 'Tirex',
    'AUTHOR'       => 'Jochen Topf',
    'LICENSE'      => 'GPL',
    'INSTALLDIRS'  => 'vendor',
    'VERSION_FROM' => 'lib/Tirex.pm', # finds $VERSION
    'ABSTRACT'     => "Modules for the Tirex tile server",
    'PREREQ_PM'    => { 'IPC::ShareLite' => 0, 'JSON' => 0 },
    test           => { TESTS => join(' ', glob('t/*/*.t')) },
);
