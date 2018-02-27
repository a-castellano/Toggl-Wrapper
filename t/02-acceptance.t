#!perl -T
use strict;
use warnings;
use Test::More tests => 7;
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

diag("Testing Toggl::Wrapper $Toggl::Wrapper::VERSION, Perl $], $^X");
