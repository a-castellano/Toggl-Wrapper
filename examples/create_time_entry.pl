#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib';
use DateTime;
use Toggl::Wrapper;
use Toggl::Wrapper::TimeEntry;
use Data::Dumper;

my $argsize;

$argsize = scalar @ARGV;
my %data;

if ( $argsize == 1 ) {
    $data{api_token} = $ARGV[0];
}
elsif ( $argsize == 2 ) {
    $data{email}    = $ARGV[0];
    $data{password} = $ARGV[1];
}
elsif ( $argsize == 3 ) {
    $data{api_token} = $ARGV[0];
    $data{email}     = $ARGV[1];
    $data{password}  = $ARGV[2];
}
else {
    die "Wrong number of parameters";
}

my $tggl = Toggl::Wrapper->new(%data);

my $returned_data = $tggl->create_time_entry(
    start_date => DateTime->new(
        year   => '2018',
        month  => '2',
        day    => '15',
        hour   => '6',
        minute => '0',
    ),
    duration => 1000,
);

