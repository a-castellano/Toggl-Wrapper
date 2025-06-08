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

my $returned_data = $tggl->start_time_entry();

my $first_id = $returned_data->id;

print(  "First ID: "
      . $first_id . "\n"
      . "Waiting 10 seconds before stopping the first entry...\n" );

sleep 10;

$tggl->stop_time_entry_by_id( $first_id, $tggl->default_workspace_id() );

print("Updating first entry description .\n");

$tggl->update_time_entry_by_id(
    $first_id,
    $tggl->default_workspace_id(),
    { description => "Change description" }
);

$returned_data = $tggl->start_time_entry();

my $second_id = $returned_data->id;
print(  "Second ID: "
      . $second_id . "\n"
      . "Waiting 10 seconds before stopping the seconds entry...\n" );
sleep 10;

$tggl->stop_time_entry_by_id( $second_id, $tggl->default_workspace_id() );

print("Updating second entry description .\n");

$tggl->update_time_entry_by_id(
    $second_id,
    $tggl->default_workspace_id(),
    { description => "Second change description" }
);

$tggl->bulk_update_time_entries_tags(
    {
        time_entry_ids => [ $first_id, $second_id ],
        tags           => [ "some",    "tags" ],
        tag_action     => "add",
    }
);

sleep 10;

$tggl->bulk_update_time_entries_tags(
    {
        time_entry_ids => [ $first_id, $second_id ],
        tags           => ["tags"],
        tag_action     => "remove",
    }
);
