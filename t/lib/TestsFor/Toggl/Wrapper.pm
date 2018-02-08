package TestsFor::Toggl::Wrapper;

use Test::Most;
use base 'TestsFor';

use lib '.';
use Toggl::Wrapper;

sub class_to_test { 'Toggl::Wrapper' }

sub startup : Tests(startup) {
    my $test  = shift;
    my $class = $test->class_to_test;
}

sub constructor : Tests(2) {
    my $test  = shift;
    my $class = $test->class_to_test;

    can_ok $class, 'new';
    throws_ok { $class->new }
qr/Trying to create a Toggl::Wrapper with no user or password neither api_token. You can only create an instance with an api key or email\/passwrd, not both./,
      "Creating a $class without proper attributes should fail";
}

1;
