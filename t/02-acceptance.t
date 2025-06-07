#!perl -T
use strict;
use warnings;
use DateTime;

#use Test::More tests => 28;
use Test::More tests => 4;
use Test::Most;

our $class = 'Toggl::Wrapper';

our $toggl_api_token = $ENV{'TOGGL_API_KEY'};
our $toggl_email     = $ENV{'TOGGL_EMAIL'};
our $toggl_password  = $ENV{'TOGGL_PASSWORD'};

BEGIN {
    use_ok('Toggl::Wrapper')            || print "Bail out!\n";
    use_ok('Toggl::Wrapper::TimeEntry') || print "Bail out!\n";
}

# Try to create a Toggl::Wrapper instance with wrong parameters

throws_ok { $class->new() }
qr/Trying to create a $class with no user or password neither api_token/,
  "Creating $class without proper attributes should fail.";

throws_ok {
    $class->new(
        email    => 'somemail@domain.com',
        password => "somewrongpassword",
    );
}
qr/Check your credentaials: API call returned 403/,
  "Creating $class without proper attributes should fail.";

  ###throws_ok { $class->new( api_token => "wr0ngtt0k3n" ) }
  ###qr/Check your credentaials: API call returned 403/,
  ###  "Creating $class without proper attributes should fail.";
  ###
  #### Create Toggl::Wrapper instance with right parameters
  ###
  ###ok $class->new( email => $toggl_email, password => $toggl_password ),
  ###  qr/With right token, constructor works/;
  ###
  ###ok $class->new( api_token => $toggl_api_token ),
  ###  qr/With right token, constructor works/;
  ###
  ###my $wrapper = Toggl::Wrapper->new( api_token => $toggl_api_token );
  ###
  ####Clean
  ###my @entries = @{
  ###    $wrapper->get_time_entries(
  ###        {
  ###            start => DateTime->today(),
  ###            stop  => DateTime->today()->add( days => 1 )
  ###        }
  ###    )
  ###};
  ###
  ###for my $entry (@entries) {
  ###    $wrapper->delete_time_entry($entry), qr/Delete stopped time entry./;
  ###}
  ###
  #### Create time entries
  ###
  ###my $time_entry = $wrapper->create_time_entry(
  ###    duration    => 900,
  ###    description => "Test entry",
  ###    start_date  => DateTime->new(
  ###        year      => '2018',
  ###        month     => '2',
  ###        day       => '13',
  ###        hour      => '18',
  ###        minute    => '0',
  ###        time_zone => 'local',
  ###    ),
  ###);
  ###
  ###is( $time_entry->duration, 900, "Time entry is created, duration" );
  ###is( $time_entry->description, "Test entry",
  ###    "Time entry is created, description" );
  ###
  #### Update time entries
  ###
  ###my $updated_time_entry = $wrapper->update_time_entry( $time_entry,
  ###    { description => "Change description" } );
  ###
  ###is(
  ###    $updated_time_entry->description,
  ###    "Change description",
  ###    "Time entry description is updated"
  ###);
  ###
  #### Delete time entry
  ###
  ###ok $wrapper->delete_time_entry($time_entry), qr/Delete created time entry./;
  ###
  #### Start time entry
  ####
  ###$time_entry = $wrapper->start_time_entry( description => "Started test entry" );
  ###
  ###is(
  ###    $time_entry->description,
  ###    "Started test entry",
  ###    "Started time entry description is set"
  ###);
  ###
  ###sleep 10;
  ###
  ###my $details = $wrapper->get_time_entry_details( $time_entry->id );
  ###is(
  ###    $details->description,
  ###    "Started test entry",
  ###    "Get time entry description as detail"
  ###);
  ###
  #### Stop and Delete time entry
  ###
  ###ok $wrapper->stop_time_entry($time_entry),   qr/Stop started time entry./;
  ###ok $wrapper->delete_time_entry($time_entry), qr/Delete stopped time entry./;
  ###
  ####Start 3 time entries time entries
  ###
  ###my $first = $wrapper->start_time_entry( description => "First test entry" );
  ###sleep 5;
  ###my $second = $wrapper->start_time_entry( description => "Second test entry" );
  ###sleep 5;
  ###my $third = $wrapper->start_time_entry( description => "Third test entry" );
  ###sleep 5;
  ###
  ###my $started_time_entry = $wrapper->get_running_time_entry();
  ###is(
  ###    $started_time_entry->description,
  ###    "Third test entry",
  ###    "Running time entry is third one."
  ###);
  ###
  ###ok $wrapper->stop_time_entry($started_time_entry), qr/Stop third time entry./;
  ###
  ###ok @entries = @{
  ###    $wrapper->get_time_entries(
  ###        {
  ###            start => DateTime->today(),
  ###            stop  => DateTime->today()->add( days => 1 )
  ###        }
  ###    )
  ###  },
  ###  qr/get time entries./;
  ###
  ###is( @entries, 3, "There are 3 entries created" );
  ###
  ###ok $wrapper->bulk_update_time_entries_tags(
  ###    {
  ###        time_entry_ids => [ $first->id, $second->id, $third->id ],
  ###        tags           => [ "some",     "tags" ],
  ###        tag_action     => "add",
  ###    }
  ###  ),
  ###  qr/Bulk update add/;
  ###
  ###$first  = $wrapper->get_time_entry_details( $first->id );
  ###$second = $wrapper->get_time_entry_details( $second->id );
  ###$third  = $wrapper->get_time_entry_details( $third->id );
  ###
  ###is_deeply( $first->tags, [ "some", "tags" ], "First has some tags" );
  ###
  ###is_deeply( $second->tags, [ "some", "tags" ], "Sirst has some tags" );
  ###
  ###is_deeply( $third->tags, [ "some", "tags" ], "Third has some tags" );
  ###
  ###ok $wrapper->bulk_update_time_entries_tags(
  ###    {
  ###        time_entry_ids => [ $first->id, $second->id ],
  ###        tags           => ["tags"],
  ###        tag_action     => "remove",
  ###    }
  ###  ),
  ###  qr/Bulk update remove/;
  ###
  ###$first  = $wrapper->get_time_entry_details( $first->id );
  ###$second = $wrapper->get_time_entry_details( $second->id );
  ###$third  = $wrapper->get_time_entry_details( $third->id );
  ###
  ###is_deeply( $first->tags, ["tags"], "First has only tags" );
  ###
  ###is_deeply( $second->tags, ["tags"], "Second has only tags" );
  ###
  ###is_deeply( $third->tags, [ "some", "tags" ], "Third still has some tags" );
  ###
  ###for my $entry (@entries) {
  ###    $wrapper->delete_time_entry($entry), qr/Delete stopped time entry./;
  ###}
  ###
  ###my $untagged_entry = $wrapper->start_time_entry( description => "Untagged" );
  ###sleep 10;
  ###$wrapper->stop_time_entry($untagged_entry);
  ###
  ###ok $wrapper->bulk_update_time_entries_tags(
  ###    {
  ###        time_entry_ids => [ $untagged_entry->id ],
  ###        tags           => ["test_tag"],
  ###        tag_action     => "add",
  ###    }
  ###  ),
  ###  qr/Bulk update only one time entry/;
  ###
  ###$wrapper->delete_time_entry($untagged_entry);

diag("Testing Toggl::Wrapper $Toggl::Wrapper::VERSION, Perl $], $^X");
