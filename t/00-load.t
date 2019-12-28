#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Carpecrustum::TerminalUtils' ) || print "Bail out!\n";
}

diag( "Testing Carpecrustum::TerminalUtils $Carpecrustum::TerminalUtils::VERSION, Perl $], $^X" );
