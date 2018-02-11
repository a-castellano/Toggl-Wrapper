package TestsFor::Toggl::Wrapper::TimeEntry;

use Test::Most;
use base 'TestsFor';

use Test::MockModule;
use Email::Valid;
use HTTP::Response;

use Toggl::Wrapper::TimeEntry;

sub class_to_test { 'Toggl::Wrapper::TimeEntry' }

sub startup : Tests(startup) {
    my $test  = shift;
    my $class = $test->class_to_test;
}

sub constructor : Tests(5) {
    my $test  = shift;
    my $class = $test->class_to_test;

    my $start_date = my $dt1 = DateTime->new(
        year      => '2018',
        month     => '3',
        day       => '8',
        hour      => '12',
        minute    => '0',
        time_zone => 'local'
    );

    my $end_date = DateTime->new(
        year      => '2018',
        month     => '3',
        day       => '8',
        hour      => '11',
        minute    => '0',
        time_zone => 'local'
    );

    can_ok $class, 'new';

    throws_ok { $class->new }
    qr/Attribute \(created_with\) is required at constructor/,
      "Creating a $class without required attributes should fail.";

    throws_ok {
        $class->new( created_with => "TestEntry.pm" );
    }
    qr/Attribute \(duration\) is required at constructor/,
      "Creating a $class without 'duration' should fail.";

    ok $class->new(
        start        => $start_date,
        duration     => 900,
        created_with => "TestEntry.pm"
      ),
      "Creating a $class without required attributes should fail.";

    throws_ok {
        $class->new(
            start => DateTime->new(
                year      => '2018',
                month     => '3',
                day       => '8',
                hour      => '12',
                minute    => '0',
                time_zone => 'local'
            ),
            stop => DateTime->new(
                year      => '2018',
                month     => '3',
                day       => '8',
                hour      => '11',
                minute    => '0',
                time_zone => 'local'
            ),
            duration     => 900,
            created_with => "TestEntry.pm"
        );
    }
    qr/End date has to be greater than start date. at constructor/,
      "Creating a $class without 'duration' should fail.";

}

1;
