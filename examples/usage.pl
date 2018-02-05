#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib';
use Toggl::Wrapper;

my $argsize;

$argsize = scalar @ARGV;

if ( $argsize != 1){
  print STDERR "This script only accepts one arg.\n";
  exit 1;
}

my $api_token = $ARGV[0];

my $tggl = Toggl::Wrapper->new(
    {
        api_token => $api_token,
    }
);
