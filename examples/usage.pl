#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib';
use Toggl::Wrapper;

my $argsize;

$argsize = scalar @ARGV;
my %data;

if ( $argsize == 1 ) {
    $data{api_token} = $ARGV[0];
}
elsif($argsize == 2){
  $data{email} = $ARGV[0];
  $data{password} = $ARGV[1];
}
elsif ($argsize == 3){
  $data{api_token} = $ARGV[0];
  $data{email} = $ARGV[1];
  $data{password} = $ARGV[2];
}
else{
  die "Bad number of parameters"
}
my $tggl = Toggl::Wrapper->new(%data);
