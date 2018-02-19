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

sub constructor : Tests(14) {
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

    ok $class->new(
        start_date   => $start_date,
        duration     => 900,
        created_with => "TestEntry.pm"
      ),
      "Creating a $class without required attributes should fail.";

    throws_ok {
        $class->new(
            start_date => DateTime->new(
                year      => '2018',
                month     => '3',
                day       => '8',
                hour      => '12',
                minute    => '0',
                time_zone => 'local',
            ),
            stop_date => DateTime->new(
                year      => '2018',
                month     => '3',
                day       => '8',
                hour      => '10',
                minute    => '0',
                time_zone => 'local',
            ),
            duration     => 900,
            created_with => "TestEntry.pm",
        );
    }
    qr/End date has to be greater than start date. at constructor/,
      "Creating a $class with start date older than stop date should fail.";

    ok $class->new(
        start_date => DateTime->new(
            year      => '2018',
            month     => '3',
            day       => '8',
            hour      => '12',
            minute    => '0',
            time_zone => 'local'
        ),
        stop_date => DateTime->new(
            year      => '2018',
            month     => '3',
            day       => '8',
            hour      => '12',
            minute    => '15',
            time_zone => 'local'
        ),

        duration     => 900,
        created_with => "TestEntry.pm"
      ),
      "Create a $class object with correct start and stop dates works.";

    throws_ok {
        $class->new(
            start_date => DateTime->new(
                year      => '2018',
                month     => '3',
                day       => '8',
                hour      => '12',
                minute    => '0',
                time_zone => 'local'
            ),
            stop         => '2018-03-08T11:15:00Z',
            duration     => 900,
            created_with => "TestEntry.pm"
        );
    }
    qr/End date has to be greater than start date/,
"Create a $class using stop newer than start fails even if stop date is given as a timestamp.";

    throws_ok {
        $class->new(
            start        => '2018-03-09T11:15:00Z',
            stop         => '2018-03-08T11:15:00Z',
            duration     => 900,
            created_with => "TestEntry.pm"
        );
    }
    qr/End date has to be greater than start date/,
"Create a $class using stop newer than start fails even if stop and start dates are given as a timestamp.";

    throws_ok {
        $class->new(
            stop_date => DateTime->new(
                year      => '2018',
                month     => '3',
                day       => '7',
                hour      => '12',
                minute    => '0',
                time_zone => 'local'
            ),
            start        => '2018-03-08T11:15:00Z',
            duration     => 900,
            created_with => "TestEntry.pm"
        );
    }
    qr/End date has to be greater than start date/,
"Create a $class using stop newer than start fails even if start date is given as a timestamp.";

    throws_ok {
        $class->new(
            start_date => DateTime->new(
                year      => '2018',
                month     => '3',
                day       => '8',
                hour      => '12',
                minute    => '0',
                time_zone => 'local'
            ),
            start        => '2018-02-10T18:18:58Z',
            duration     => 900,
            created_with => "TestEntry.pm"
        );
    }
qr/does not allow to be instanced with 'start_date' and 'start' at the same time. Only one of them is allowed/,
"There is not posibe instance Timeentry with start and start_date attributes.";

    throws_ok {
        $class->new(
            start_date => DateTime->new(
                year      => '2018',
                month     => '3',
                day       => '8',
                hour      => '12',
                minute    => '0',
                time_zone => 'local'
            ),
            stop_date => DateTime->new(
                year      => '2018',
                month     => '3',
                day       => '8',
                hour      => '13',
                minute    => '0',
                time_zone => 'local'
            ),
            stop         => '2018-02-10T18:18:58Z',
            duration     => 900,
            created_with => "TestEntry.pm"
        );
    }
qr/does not allow to be instanced with 'stop_date' and 'stop' at the same time. Only one of them is allowed/,
"There is not posibe to instance TimeEntry with start and start_date attributes.";

    throws_ok {
        $class->new(
            start        => '2018-029-10T18:18:58Z',
            duration     => 900,
            created_with => "TestEntry.pm"
        );
    }
    qr/Attibute 'start' format is not valid/,
      "There is not posibe instance to TimeEntry with invalid start date.";

    throws_ok {
        $class->new(
            start        => '2018-02-10T18:18:58Z',
            stop         => '2018-029-10T18:18:58Z',
            duration     => 900,
            created_with => "TestEntry.pm"
        );
    }
    qr/Attibute 'stop' format is not valid/,
      "There is not posibe instance to TimeEntry with invalid stop date.";

    my $entry = $class->new(
        start_date => DateTime->new(
            year      => '2018',
            month     => '3',
            day       => '8',
            hour      => '12',
            minute    => '0',
            time_zone => 'local'
        ),
        stop_date => DateTime->new(
            year      => '2018',
            month     => '3',
            day       => '8',
            hour      => '12',
            minute    => '15',
            time_zone => 'local'
        ),

        duration     => 900,
        created_with => "TestEntry.pm"
    );

    ok $entry->as_json();

    $entry = $class->new(
        start_date => DateTime->new(
            year      => '2018',
            month     => '3',
            day       => '8',
            hour      => '12',
            minute    => '0',
            time_zone => 'local'
        ),
        stop_date => DateTime->new(
            year      => '2018',
            month     => '3',
            day       => '8',
            hour      => '12',
            minute    => '15',
            time_zone => 'local'
        ),
        duronly      => 1,
        duration     => 900,
        created_with => "TestEntry.pm"
    );

    ok $entry->as_json();

}

1;
