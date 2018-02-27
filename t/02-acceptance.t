#!perl -T
use strict;
use warnings;
use DateTime;

use Test::More tests => 15;
use Test::Most;

our $class = 'Toggl::Wrapper';

our $toggl_api_token = $ENV{'TOGGL_API_KEY'};
our $toggl_email     = $ENV{'TOGGL_EMAIL'};
our $toggl_password  = $ENV{'TOGGL_PASSWORD'};

BEGIN {
    use_ok('Toggl::Wrapper')            || print "Bail out!\n";
    use_ok('Toggl::Wrapper::TimeEntry') || print "Bail out!\n";
}

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

throws_ok { $class->new( api_token => "wr0ngtt0k3n" ) }
qr/Check your credentaials: API call returned 403/,
  "Creating $class without proper attributes should fail.";

ok $class->new( email => $toggl_email, password => $toggl_password ),
  qr/With right token, constructor works/;

ok $class->new( api_token => $toggl_api_token ),
  qr/With right token, constructor works/;

my $wrapper = Toggl::Wrapper->new( api_token => $toggl_api_token );

my $time_entry = $wrapper->create_time_entry(
    duration    => 900,
    description => "Test entry",
    start_date  => DateTime->new(
        year      => '2018',
        month     => '2',
        day       => '13',
        hour      => '18',
        minute    => '0',
        time_zone => 'local',
    ),
);

is( $time_entry->duration, 900, "Time entry is created, duration" );
is( $time_entry->description, "Test entry",
    "Time entry is created, description" );

my $updated_time_entry = $wrapper->update_time_entry( $time_entry,
    { description => "Change description" } );

is(
    $updated_time_entry->description,
    "Change description",
    "Time entry description is updated"
);

ok $wrapper->delete_time_entry($time_entry), qr/Delete created time entry./;

$time_entry = $wrapper->start_time_entry( description => "Started test entry" );

is(
    $time_entry->description,
    "Started test entry",
    "Started time entry description is set"
);

sleep 10;

my $details = $wrapper->get_time_entry_details( $time_entry->id );
is(
    $details->description,
    "Started test entry",
    "Get time entry description as detail"
);

ok $wrapper->stop_time_entry($time_entry),   qr/Stop started time entry./;
ok $wrapper->delete_time_entry($time_entry), qr/Delete stopped time entry./;

diag("Testing Toggl::Wrapper $Toggl::Wrapper::VERSION, Perl $], $^X");
