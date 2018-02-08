#!perl -T
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Toggl::Wrapper' ) || print "Bail out!\n";
}

diag( "Testing Toggl::Wrapper $Toggl::Wrapper::VERSION, Perl $], $^X" );
