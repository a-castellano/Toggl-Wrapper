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

Toggl::Wrapper::TimeEntry->new(

    start_date => DateTime->new(
        year      => '2018',
        month     => '3',
        day       => '7',
        hour      => '13',
        minute    => '0',
        time_zone => 'local'
    ),

    stop_date => DateTime->new(
        year      => '2018',
        month     => '3',
        day       => '7',
        hour      => '12',
        minute    => '0',
        time_zone => 'local'
    ),

    #stop => '2017-02-15T11:15:00Z',
    #          start         => '2017-02-16T11:15:00Z',
    duration     => 900,
    created_with => "TestEntry.pm"
);

my $tggl = Toggl::Wrapper->new(%data);

my $returned_data = $tggl->start_time_entry();

#my $started_entry = Toggl::Wrapper::TimeEntry->new($returned_data);

print $returned_data->id;
