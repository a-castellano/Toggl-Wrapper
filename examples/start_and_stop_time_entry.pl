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

my $started_entry = $tggl->start_time_entry();

my $id = $started_entry->id;

print "Entry id -> $id\n";
print "Waiting 3 seconds...\n";

sleep 3;

$tggl->stop_time_entry($started_entry);
