package TestsFor::Toggl::Wrapper;

use Test::Most;
use base 'TestsFor';

use Test::MockModule;
use Email::Valid;
use HTTP::Response;
use JSON;
use Data::Dumper;

use Toggl::Wrapper;
use Toggl::Wrapper::TimeEntry;

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
      "Creating a $class without proper attributes should fail.";
}

sub wrong_or_right_data_constructor : Tests(15) {
    my $test  = shift;
    my $class = $test->class_to_test;

    my ( $mocked_lwp, $mocked_http_request, $mocked_http_response ) = mock();

    throws_ok { $class->new( api_token => "wr0ngtt0k3n" ) }
    qr/Check your credentaials: API call returned 403: Forbidden/,
      "Creating $class without proper attributes should fail.";

    ok $class->new( api_token => "u1tra53cr3tt0k3n" ),
      qr/With right token, constructor works/;

    throws_ok {
        $class->new(
            api_token => "u1tra53cr3tt0k3n",
            nonsense  => "ThisIsNonSense",
        );
    }
    qr/passed to the constructor: nonsense/,
"Creating $class with data containing anything different than api_token, password and email should fail.";

    throws_ok { $class->new( email => 'somemail@domain.com' ) }
qr/$class with no user or password neither api_token. You can only create an instance with an api key or email\/passwrd, not both. at constructor/,
      "Creating a $class with data containing email without password.";

    throws_ok { $class->new( email => 'somemail@domaincom' ) }
qr/does not pass the type constraint because: Must be a valid e-mail address at constructor/,
      "Creating $class with data containing email without password.";

    throws_ok {
        $class->new(
            email     => 'somemail@domaincom',
            api_token => "wr0ngtt0k3n",
        );
    }
qr/does not pass the type constraint because: Must be a valid e-mail address at constructor/,
"Creating $class with data containing email without password. It does not matter if there is other valid parameter";

    throws_ok {
        $class->new(
            email    => 'somemail@domain.com',
            nonsense => "ThisIsNonSense",
        );
    }
qr/with no user or password neither api_token. You can only create an instance with an api key/,
"Creating $class with data containing anything different than api_token, password and email should fail. It will fail even there are valid fields.";

    throws_ok {
        $class->new(
            api_token => 'u1tra53cr3tt0k3n',
            password  => 'somepassword',
        );
    }
qr/$class instance with and api_token and user\/password. You can only create an instance with an api key or email\/password, not both/,
"Creating $class with data containing api_token and password, but no email. That should fail.";

    throws_ok {
        $class->new(
            api_token => 'u1tra53cr3tt0k3n',
            email     => 'somemail@domain.com',
            password  => 'somepassword',
        );
    }
qr/$class instance with and api_token and user\/password. You can only create an instance with an api key or email\/password, not both/,
"Creating $class with data containing api_token email and password should fail.";

    throws_ok {
        $class->new(
            api_token  => 'u1tra53cr3tt0k3n',
            email      => 'somemail@domain.com',
            password   => 'somepassword',
            extrastuff => 'mayhem',
        );
    }
qr/$class instance with and api_token and user\/password. You can only create an instance with an api key or email\/password, not both/,
"Creating $class with data containing api_token email and password and anithing else should fail.";

    throws_ok {
        $class->new(
            email    => 'somemail@domain.com',
            password => "myU1tra53cr3tPa55wd",
        );
    }
    qr/Check your credentaials: API call returned 403: Forbidden/,
      "Creating $class with wrong email should fail.";

    throws_ok {
        $class->new(
            email    => 'myemail@domain.com',
            password => "somepassword",
        );
    }
    qr/Check your credentaials: API call returned 403: Forbidden/,
      "Creating $class with wrong password should fail.";

    ok $class->new(
        email    => 'myemail@domain.com',
        password => "myU1tra53cr3tPa55wd"
      ),
      qr/With right user and pasword, constructor works/;

    throws_ok {
        $class->new( email => 'myemail@domain.com', );
    }
qr/a $class with no user or password neither api_token. You can only create an instance with an api key or email\/passwrd, not both./,
      "Creating $class with email but without password should fail.";

    throws_ok {
        $class->new( password => 'somepassword', );
    }
qr/a $class with no user or password neither api_token. You can only create an instance with an api key or email\/passwrd, not both./,
      "Creating $class with password but without email should fail.";

}

sub failed_request : Tests(1) {
    my $test  = shift;
    my $class = $test->class_to_test;

    my ( $mocked_lwp, $mocked_http_request, $mocked_http_response ) = mock();

    $mocked_lwp->mock( 'is_success', sub { return 0; } );

    $mocked_lwp->mock(
        'request',
        sub {
            return HTTP::Response->new( 400, 'Bad Request' );
        }
    );

    throws_ok {
        $class->new( api_token => 'u1tra53cr3tt0k3n', );
    }
    qr/An error ocurred: API call returned 400: Bad Request/,
      "Creating $class with unespected return code should fail.";

}

sub create_entry : Tests(3) {
    my $test  = shift;
    my $class = $test->class_to_test;

    my ( $mocked_lwp, $mocked_http_request, $mocked_http_response ) = mock();

    my $wrapper = $class->new( api_token => 'u1tra53cr3tt0k3n' );

    throws_ok { $wrapper->create_time_entry() }
    qr/Attribute \(duration\) is required at constructor/,
      "Calling create_time_entry with no duration attribute should fail.";

    throws_ok { $wrapper->create_time_entry( duration => 900 ) }
qr/TimeEntry does not allow to be instanced without 'start_date' or 'start'/,
      "Calling create_time_entry with no start_date attribute should fail.";

    my $return_json_example =
'{"id":"798455036","wid":"1364303","billable":0,"start":"2018-02-13T12:00:00Z","duration":900,"uid":2143391, "tags":[], "duronly":0, "description": "Test entry"}';

    $mocked_http_response->mock(
        "decoded_content",
        sub {
            return $return_json_example;
        }
    );

    my $returned_data = $wrapper->create_time_entry(
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

    my $json =
'{"guid":null,"tid":null,"id":"798455036","duronly":false,"pid":null,"tags":[],"duration":"900","start":"2018-02-13T12:00:00Z","at":null,"created_with":null,"stop":null,"billable":false,"description":"Test entry","wid":"1364303"}';

    is_deeply(
        decode_json $returned_data->as_json(),
        decode_json $json,
        "Wrapper is able to create time entries."
    );

}

###sub start_entry : Tests(1) {
###    my $test  = shift;
###    my $class = $test->class_to_test;
###
###    my ( $mocked_lwp, $mocked_http_request, $mocked_http_response ) = mock();
###
###    my $wrapper = $class->new( api_token => 'u1tra53cr3tt0k3n' );
###
###    my $return_json_example =
###'{"data":{"id":"798455036","wid":"1364303","billable":0,"start":"2018-02-14T12:00:00Z","duration":"-900"}}';
###
###    $mocked_http_response->mock(
###        "decoded_content",
###        sub {
###            return $return_json_example;
###        }
###    );
###
###    ok $wrapper->start_time_entry(), "Start time_entry";
###}
###
###sub stop_entry : Tests(4) {
###    my $test  = shift;
###    my $class = $test->class_to_test;
###
###    my ( $mocked_lwp, $mocked_http_request, $mocked_http_response ) = mock();
###
###    my $wrapper = $class->new( api_token => 'u1tra53cr3tt0k3n' );
###
###    my $return_json_example =
###'{"data":{"id":"798455036","wid":"1364303","billable":0,"start":"2018-02-14T12:00:00Z","duration":"-900"}}';
###
###    $mocked_http_response->mock(
###        "decoded_content",
###        sub {
###            return $return_json_example;
###        }
###    );
###
###    my $time_entry = $wrapper->start_time_entry();
###    ok $wrapper->stop_time_entry($time_entry), "Stop time entry.";
###
###    $time_entry = $wrapper->start_time_entry();
###    ok $wrapper->stop_time_entry_by_id(34567890), "Stop time entry.";
###
###    throws_ok { $wrapper->stop_time_entry_by_id("imnotanumber") }
###    qr/TimeEntry id must be a number/,
###      "Cannont stop a TimeEntry without a numeric id";
###
###    throws_ok {
###        $wrapper->stop_time_entry(
###            Toggl::Wrapper::TimeEntry->new(
###                start_date => DateTime->new(
###                    year      => '2018',
###                    month     => '3',
###                    day       => '8',
###                    hour      => '12',
###                    minute    => '0',
###                    time_zone => 'local'
###                ),
###                stop_date => DateTime->new(
###                    year      => '2018',
###                    month     => '3',
###                    day       => '8',
###                    hour      => '12',
###                    minute    => '15',
###                    time_zone => 'local'
###                ),
###
###                duration     => 900,
###                created_with => "TestEntry.pm"
###            )
###        );
###    }
###    qr/entry does not contain 'id' field/,
###      "Cannont stop a TimeEntry without id";
###
###}
###
###sub get_entry_details : Tests(1) {
###    my $test  = shift;
###    my $class = $test->class_to_test;
###
###    my ( $mocked_lwp, $mocked_http_request, $mocked_http_response ) = mock();
###
###    my $wrapper = $class->new( api_token => 'u1tra53cr3tt0k3n' );
###
###    my $return_json_example =
###'{"data":{"id":"798455036","wid":"1364303","billable":0,"start":"2018-02-14T12:00:00Z","duration":"-900"}}';
###
###    $mocked_http_response->mock(
###        "decoded_content",
###        sub {
###            return $return_json_example;
###        }
###    );
###
###    my $json =
###'{"guid":null,"tid":null,"id":"798455036","duronly":false,"pid":null,"tags":null,"duration":"-900","start":"2018-02-14T12:00:00Z","at":null,"created_with":null,"stop":null,"billable":false,"description":null,"wid":"1364303"}';
###
###    my $time_entry = $wrapper->get_time_entry_details(798455036);
###    is_deeply(
###        decode_json $time_entry->as_json(),
###        decode_json $json,
###        "Wrapper is able to get time entries details."
###    );
###}
###
###sub get_running_time_entry : Tests(1) {
###    my $test  = shift;
###    my $class = $test->class_to_test;
###
###    my ( $mocked_lwp, $mocked_http_request, $mocked_http_response ) = mock();
###
###    my $wrapper = $class->new( api_token => 'u1tra53cr3tt0k3n' );
###
###    my $return_json_example =
###'{"data":{"id":"798455036","wid":"1364303","billable":0,"start":"2018-02-14T12:00:00Z","duration":"-900"}}';
###
###    $mocked_http_response->mock(
###        "decoded_content",
###        sub {
###            return $return_json_example;
###        }
###    );
###
###    my $json =
###'{"guid":null,"tid":null,"id":"798455036","duronly":false,"pid":null,"tags":null,"duration":"-900","start":"2018-02-14T12:00:00Z","at":null,"created_with":null,"stop":null,"billable":false,"description":null,"wid":"1364303"}';
###
###    my $time_entry = $wrapper->get_running_time_entry();
###    is_deeply(
###        decode_json $time_entry->as_json(),
###        decode_json $json,
###        "Wrapper is able to get time entries details."
###    );
###}
###
###sub update_time_entry : Tests(3) {
###    my $test  = shift;
###    my $class = $test->class_to_test;
###
###    my ( $mocked_lwp, $mocked_http_request, $mocked_http_response ) = mock();
###
###    my $wrapper = $class->new( api_token => 'u1tra53cr3tt0k3n' );
###
###    my $return_json_example =
###'{"data":{"id":"798455036","wid":"1364303","billable":0,"start":"2018-02-14T12:00:00Z","duration":"-900","description":"Change description"}}';
###
###    $mocked_http_response->mock(
###        "decoded_content",
###        sub {
###            return $return_json_example;
###        }
###    );
###
###    my $json =
###'{"guid":null,"tid":null,"id":"798455036","duronly":false,"pid":null,"tags":null,"duration":"-900","start":"2018-02-14T12:00:00Z","at":null,"created_with":null,"stop":null,"billable":false,"description":"Change description","wid":"1364303"}';
###
###    my $time_entry         = $wrapper->get_running_time_entry();
###    my $updated_time_entry = $wrapper->update_time_entry( $time_entry,
###        { description => "Change description" } );
###    is_deeply(
###        decode_json $updated_time_entry->as_json(),
###        decode_json $json,
###        "Wrapper is able to get time entries details."
###    );
###
###    $updated_time_entry = $wrapper->update_time_entry_by_id( 798455036,
###        { description => "Change description" } );
###    is_deeply(
###        decode_json $updated_time_entry->as_json(),
###        decode_json $json,
###        "Wrapper is able to get time entries details."
###    );
###
###    throws_ok {
###        $wrapper->update_time_entry(
###            Toggl::Wrapper::TimeEntry->new(
###                start_date => DateTime->new(
###                    year      => '2018',
###                    month     => '3',
###                    day       => '8',
###                    hour      => '12',
###                    minute    => '0',
###                    time_zone => 'local'
###                ),
###                stop_date => DateTime->new(
###                    year      => '2018',
###                    month     => '3',
###                    day       => '8',
###                    hour      => '12',
###                    minute    => '15',
###                    time_zone => 'local'
###                ),
###
###                duration     => 900,
###                created_with => "TestEntry.pm"
###            ),
###            { description => "Change Description" },
###        );
###    }
###    qr/entry does not contain 'id' field/,
###      "Cannont update a TimeEntry without id";
###}
###
###sub delete_time_entry : Tests(3) {
###    my $test  = shift;
###    my $class = $test->class_to_test;
###
###    my ( $mocked_lwp, $mocked_http_request, $mocked_http_response ) = mock();
###
###    my $wrapper = $class->new( api_token => 'u1tra53cr3tt0k3n' );
###
###    my $return_json_example =
###'{"data":{"id":"798455036","wid":"1364303","billable":0,"start":"2018-02-14T12:00:00Z","duration":"-900","description":"Change description"}}';
###
###    $mocked_http_response->mock(
###        "decoded_content",
###        sub {
###            return $return_json_example;
###        }
###    );
###
###    my $time_entry = Toggl::Wrapper::TimeEntry->new(
###        start_date => DateTime->new(
###            year      => '2018',
###            month     => '3',
###            day       => '8',
###            hour      => '12',
###            minute    => '0',
###            time_zone => 'local'
###        ),
###        id           => 34567890,
###        duration     => 900,
###        created_with => "TestEntry.pm"
###    );
###
###    ok $wrapper->delete_time_entry($time_entry), "Delete time entry.";
###    ok $wrapper->delete_time_entry_by_id( $time_entry->id() ),
###      "Delete time entry by id.";
###
###    throws_ok {
###        $wrapper->delete_time_entry(
###            Toggl::Wrapper::TimeEntry->new(
###                start_date => DateTime->new(
###                    year      => '2018',
###                    month     => '3',
###                    day       => '8',
###                    hour      => '12',
###                    minute    => '0',
###                    time_zone => 'local'
###                ),
###                stop_date => DateTime->new(
###                    year      => '2018',
###                    month     => '3',
###                    day       => '8',
###                    hour      => '12',
###                    minute    => '15',
###                    time_zone => 'local'
###                ),
###
###                duration     => 900,
###                created_with => "TestEntry.pm"
###            )
###        );
###    }
###    qr/entry does not contain 'id' field/,
###      "Cannont delete a TimeEntry without id";
###}
###
###sub get_time_entries : Tests(13) {
###    my $test  = shift;
###    my $class = $test->class_to_test;
###
###    my @expected_array;
###
###    my ( $mocked_lwp, $mocked_http_request, $mocked_http_response ) = mock();
###
###    my $wrapper = $class->new( api_token => 'u1tra53cr3tt0k3n' );
###
###    my $return_json_example =
###'[{"id":"798455036","wid":"1364303","billable":0,"start":"2018-03-08T12:00:00Z","duration":"900","description":"Doing something","created_with":"TestEntry.pm"},{"id":"798455037","wid":"1364303","billable":0,"start":"2018-03-08T14:00:00Z","duration":"900","description":"Doing something more","created_with":"TestEntry.pm"}]';
###
###    $mocked_http_response->mock(
###        "decoded_content",
###        sub {
###            return $return_json_example;
###        }
###    );
###
###    my $json =
###'{"guid":null,"tid":null,"id":"798455036","duronly":false,"pid":null,"tags":null,"duration":"-900","start":"2018-02-14T12:00:00Z","at":null,"created_with":null,"stop":null,"billable":false,"description":"Change description","wid":"1364303"}';
###
###    throws_ok {
###        $wrapper->get_time_entries('purenoise');
###    }
###qr/Invalid parameters supplied, specify start and stop dates or don't specify anithing/,
###      "Cannont get entries without start and stop dates";
###
###    throws_ok {
###        $wrapper->get_time_entries( { start => '2018-02-14T12:00:00Z' } );
###    }
###    qr/Invalid parameters supplied, stop date is not supplied/,
###      "Cannont get entries without stop date";
###
###    throws_ok {
###        $wrapper->get_time_entries(
###            {
###                start => DateTime->new(
###                    year      => '2018',
###                    month     => '3',
###                    day       => '8',
###                    hour      => '12',
###                    minute    => '0',
###                    time_zone => 'local'
###                )
###            }
###        );
###    }
###    qr/Invalid parameters supplied, stop date is not supplied/,
###      "Cannont get entries without stop date, datetime";
###
###    throws_ok {
###        $wrapper->get_time_entries( { stop => '2018-02-14T12:00:00Z' } );
###    }
###    qr/Invalid parameters supplied, start date is not supplied/,
###      "Cannont get entries without start date";
###
###    throws_ok {
###        $wrapper->get_time_entries(
###            {
###                stop => DateTime->new(
###                    year      => '2018',
###                    month     => '3',
###                    day       => '8',
###                    hour      => '12',
###                    minute    => '0',
###                    time_zone => 'local'
###                )
###            }
###        );
###    }
###    qr/Invalid parameters supplied, start date is not supplied/,
###      "Cannont get entries without start date, datatime";
###
###    throws_ok {
###        $wrapper->get_time_entries(
###            {
###                start => '2018-02-14T12:00:00Z',
###                stop  => '2018-01-14T12:00:00Z'
###            }
###        );
###    }
###qr/Invalid parameters supplied, stop date cannot be eairlier than start date/,
###      "Cannont get entries with stop date newer than start one";
###
###    throws_ok {
###        $wrapper->get_time_entries(
###            {
###                start => '2018-07892-14T12:00:00Z',
###                stop  => '2018-01-14T12:00:00Z'
###            }
###        );
###    }
###    qr/Attibute 'start' format is not valid/,
###      "Cannont get entries with invalid start date";
###
###    throws_ok {
###        $wrapper->get_time_entries(
###            {
###                start => '2018-02-14T12:00:00Z',
###                stop  => '2018-056789-14T12:00:00Z'
###            }
###        );
###    }
###    qr/Attibute 'stop' format is not valid/,
###      "Cannont get entries with invalid stop date";
###
###    throws_ok {
###        $wrapper->get_time_entries(
###            {
###                stop => DateTime->new(
###                    year      => '2018',
###                    month     => '2',
###                    day       => '8',
###                    hour      => '12',
###                    minute    => '0',
###                    time_zone => 'local'
###                ),
###                start => DateTime->new(
###                    year      => '2018',
###                    month     => '3',
###                    day       => '8',
###                    hour      => '12',
###                    minute    => '0',
###                    time_zone => 'local'
###                )
###            }
###        );
###    }
###qr/Invalid parameters supplied, stop date cannot be eairlier than start date./,
###      "Cannont get entries with stop date newer than start one, datetime";
###
###    throws_ok {
###        $wrapper->get_time_entries(
###            {
###                stop  => '2018-02-14T12:00:00Z',
###                start => DateTime->new(
###                    year      => '2018',
###                    month     => '3',
###                    day       => '8',
###                    hour      => '12',
###                    minute    => '0',
###                    time_zone => 'local'
###                )
###            }
###        );
###    }
###qr/Invalid parameters supplied, stop date cannot be eairlier than start date/,
###      "Cannont get entries with stop date newer than start one, mixed";
###
###    @expected_array = (
###        Toggl::Wrapper::TimeEntry->new(
###            start        => '2018-03-08T12:00:00Z',
###            id           => 798455036,
###            wid          => 1364303,
###            duration     => 900,
###            description  => "Doing something",
###            created_with => "TestEntry.pm",
###        ),
###        Toggl::Wrapper::TimeEntry->new(
###            start        => '2018-03-08T14:00:00Z',
###            id           => 798455037,
###            wid          => 1364303,
###            duration     => 900,
###            description  => "Doing something more",
###            created_with => "TestEntry.pm",
###        )
###    );
###
###    is_deeply( $wrapper->get_time_entries(),
###        \@expected_array, "Wrapper is able to get time entries details." );
###
###    is_deeply(
###        $wrapper->get_time_entries(
###            {
###                start => '2018-02-14T12:00:00Z',
###                stop  => '2018-04-14T12:00:00Z'
###            }
###        ),
###        \@expected_array,
###"Wrapper is able to get time entries details sepecifying start and stop date."
###    );
###
###    is_deeply(
###        $wrapper->get_time_entries(
###            {
###                start => DateTime->new(
###                    year      => '2018',
###                    month     => '2',
###                    day       => '8',
###                    hour      => '14',
###                    minute    => '0',
###                    time_zone => 'local'
###                ),
###                stop => DateTime->new(
###                    year      => '2018',
###                    month     => '3',
###                    day       => '8',
###                    hour      => '14',
###                    minute    => '0',
###                    time_zone => 'local'
###                )
###            }
###        ),
###        \@expected_array,
###"Wrapper is able to get time entries details sepecifying start and stop date. Datatime"
###    );
###
###}

###sub bulk_update_time_entries_tags : Tests(14) {
###    my $test  = shift;
###    my $class = $test->class_to_test;
###
###    my @expected_array;
###
###    my ( $mocked_lwp, $mocked_http_request, $mocked_http_response ) = mock();
###
###    my $wrapper = $class->new( api_token => 'u1tra53cr3tt0k3n' );
###
###    my $return_json_example =
###'{"data":[{"id":"798455036","wid":"1364303","billable":0,"start":"2018-03-08T12:00:00Z","duration":"900","description":"Doing something","created_with":"TestEntry.pm","tags":["tagtest1", "some", "tags"]},{"id":"798455037","wid":"1364303","billable":0,"start":"2018-03-08T14:00:00Z","duration":"900","description":"Doing something more","created_with":"TestEntry.pm","tags":["tagtest2", "some", "tags"]}]}';
###
###    $mocked_http_response->mock(
###        "decoded_content",
###        sub {
###            return $return_json_example;
###        }
###    );
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags();
###    }
###qr/Invalid parameters supplied, specify an array of time entry ID's, an array of tags, and the action/,
###      "Cannont uptate entries without parametters";
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags('noise');
###    }
###qr/Invalid parameters supplied, specify an array of time entry ID's, an array of tags, and the action/,
###      "Cannont uptate entries without right parametters";
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags( {} );
###    }
###    qr/Invalid parameters supplied, 'time_entry_ids' array is not defined/,
###      "Cannont uptate entries without time_entry_ids";
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags(
###            { time_entry_ids => 'noise', } );
###    }
###    qr/Invalid parameters supplied, 'time_entry_ids' must be an array of ID's/,
###      "Cannont uptate entries with time_entry_ids not being an array";
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags(
###            { time_entry_ids => 'noise', } );
###    }
###    qr/Invalid parameters supplied, 'time_entry_ids' must be an array of ID's/,
###      "Cannont uptate entries with time_entry_ids not being an array";
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags( { time_entry_ids => [], } );
###    }
###    qr/Invalid parameters supplied, 'time_entry_ids' is empty/,
###      "Cannont uptate entries with empty time_entry_ids array";
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags(
###            { time_entry_ids => [ 43324, 78974 ], } );
###    }
###    qr/Invalid parameters supplied, 'tags' array is not defined/,
###      "Cannont uptate entries with no tags defined";
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags(
###            {
###                time_entry_ids => [ 43324, 78974 ],
###                tags           => 'noise'
###            }
###        );
###    }
###    qr/Invalid parameters supplied, 'tags' must be an array/,
###      "Cannont uptate entries with tags not being an array";
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags(
###            {
###                time_entry_ids => [ 43324, 78974 ],
###                tags           => []
###            }
###        );
###    }
###    qr/Invalid parameters supplied, 'tags' is empty/,
###      "Cannont uptate entries with empty array of tags";
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags(
###            {
###                time_entry_ids => [ 43324,  78974 ],
###                tags           => [ "some", "tags" ]
###            }
###        );
###    }
###    qr/Invalid parameters supplied, 'tag_action' is not defined/,
###      "Cannont uptate entries with no tag_action defined";
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags(
###            {
###                time_entry_ids => [ 43324,  78974 ],
###                tags           => [ "some", "tags" ],
###                tag_action     => [123],
###            }
###        );
###    }
###    qr/Invalid parameters supplied, 'tag_action' must be a string/,
###      "Cannont uptate entries with tag_action not being an string";
###
###    throws_ok {
###        $wrapper->bulk_update_time_entries_tags(
###            {
###                time_entry_ids => [ 43324,  78974 ],
###                tags           => [ "some", "tags" ],
###                tag_action     => "noise",
###            }
###        );
###    }
###qr/Invalid parameters supplied, 'tag_action' must be a string containing 'add' or 'remove' values/,
###      "Cannont uptate entries with tag_action not being an string";
###
###    @expected_array = (
###        Toggl::Wrapper::TimeEntry->new(
###            start        => '2018-03-08T12:00:00Z',
###            id           => 798455036,
###            wid          => 1364303,
###            duration     => 900,
###            description  => "Doing something",
###            created_with => "TestEntry.pm",
###            tags         => [ "tagtest1", "some", "tags" ],
###        ),
###        Toggl::Wrapper::TimeEntry->new(
###            start        => '2018-03-08T14:00:00Z',
###            id           => 798455037,
###            wid          => 1364303,
###            duration     => 900,
###            description  => "Doing something more",
###            created_with => "TestEntry.pm",
###            tags         => [ "tagtest2", "some", "tags" ],
###        )
###    );
###
###    is_deeply(
###        $wrapper->bulk_update_time_entries_tags(
###            {
###                time_entry_ids => [ 43324,  78974 ],
###                tags           => [ "some", "tags" ],
###                tag_action     => "add",
###            }
###        ),
###        \@expected_array,
###        "Wrapper is able to add tags."
###    );
###
###    @expected_array = (
###        Toggl::Wrapper::TimeEntry->new(
###            start        => '2018-03-08T12:00:00Z',
###            id           => 798455036,
###            wid          => 1364303,
###            duration     => 900,
###            description  => "Doing something",
###            created_with => "TestEntry.pm",
###            tags         => ["tagtest1"],
###        ),
###        Toggl::Wrapper::TimeEntry->new(
###            start        => '2018-03-08T14:00:00Z',
###            id           => 798455037,
###            wid          => 1364303,
###            duration     => 900,
###            description  => "Doing something more",
###            created_with => "TestEntry.pm",
###            tags         => ["tagtest2"],
###        )
###    );
###
###    $return_json_example =
###'{"data":[{"id":"798455036","wid":"1364303","billable":0,"start":"2018-03-08T12:00:00Z","duration":"900","description":"Doing something","created_with":"TestEntry.pm","tags":["tagtest1"]},{"id":"798455037","wid":"1364303","billable":0,"start":"2018-03-08T14:00:00Z","duration":"900","description":"Doing something more","created_with":"TestEntry.pm","tags":["tagtest2"]}]}';
###
###    $mocked_http_response->mock(
###        "decoded_content",
###        sub {
###            return $return_json_example;
###        }
###    );
###
###    is_deeply(
###        $wrapper->bulk_update_time_entries_tags(
###            {
###                time_entry_ids => [ 43324,  78974 ],
###                tags           => [ "some", "tags" ],
###                tag_action     => "remove",
###            }
###        ),
###        \@expected_array,
###        "Wrapper is able to remove tags."
###    );
###
###}

sub mock {

    # mock LWP::UserAgent

    my $mocked_lwp = Test::MockModule->new('LWP::UserAgent');
    $mocked_lwp->mock(
        'request',
        sub {
            my ( $self, $request ) = @_;
            my $using_token_auth   = 0;
            my $successful_request = 1;
            my %response;

            my $email_or_api_token         = $request->{requested_data}[0];
            my $password_or_api_token_text = $request->{requested_data}[1];

            if ( !Email::Valid->address($email_or_api_token)
                && $password_or_api_token_text eq 'api_token' )
            {
                $using_token_auth = 1;
            }

            if ($using_token_auth) {
                if ( $email_or_api_token ne "u1tra53cr3tt0k3n" ) {
                    $successful_request = 0;
                }
            }
            else {
                if (   $email_or_api_token ne 'myemail@domain.com'
                    || $password_or_api_token_text ne 'myU1tra53cr3tPa55wd' )
                {
                    $successful_request = 0;
                }
            }
            if ($successful_request) {
                return HTTP::Response->new(200);
            }
            else {
                return HTTP::Response->new( 403, 'Forbidden' );
            }
        }
    );

    $mocked_lwp->mock( 'is_success', sub { return 1; } );

    # mock HTTP::Request
    my $mocked_http_request = Test::MockModule->new('HTTP::Request');
    $mocked_http_request->mock(
        "authorization_basic",
        sub {
            my ( $self, @data ) = @_;
            $self->{'requested_data'} = [@data];
        }
    );

    # mock HTTP::Response
    my $mocked_http_response = Test::MockModule->new('HTTP::Response');
    $mocked_http_response->mock(
        "decoded_content",
        sub {
            return
'{"id":921391,"api_token":"u1tra53cr3tt0k3n","default_wid":1864303,"email":"myemail@domain.com","fullname":"Wrapper Test User","jquery_timeofday_format":"h:i A","jquery_date_format":"m/d/Y","timeofday_format":"h:mm A","date_format":"MM/DD/YYYY","store_start_and_stop_time":true,"beginning_of_week":1,"language":"en_US","image_url":"https://assets.toggl.com/images/profile.png","sidebar_piechart":true,"at":"2018-02-06T05:14:02+00:00","created_at":"2013-03-06T18:14:24+00:00","retention":9,"record_timeline":false,"render_timeline":false,"timeline_enabled":false,"timeline_experiment":false,"new_blog_post":{"title":"Notes on Yesterday’s Server Problems","url":"http://blog.toggl.com/notes-on-yesterdays-server-problems/","category":"Announcement","pub_date":"2018-01-17T13:44:50Z"},"should_upgrade":true,"achievements_enabled":true,"timezone":"Europe/Madrid","openid_enabled":true,"openid_email":"myemail@domain.com","send_product_emails":true,"send_weekly_report":true,"send_timer_notifications":true,"last_blog_entry":"","invitation":{},"workspaces":[{"id":1364303,"name":"User\'s workspace","profile":0,"premium":false,"admin":true,"default_hourly_rate":0,"default_currency":"USD","only_admins_may_create_projects":false,"only_admins_see_billable_rates":false,"only_admins_see_team_dashboard":false,"projects_billable_by_default":true,"rounding":1,"rounding_minutes":0,"api_token":"u1tra53cr3tt0k3n","at":"2013-03-06T18:14:25+00:00","ical_enabled":true}],"duration_format":"improved","obm":{"included":false,"nr":0,"actions":"tree"}}';
        }
    );

    # end mocking

    return ( $mocked_lwp, $mocked_http_request, $mocked_http_response );

}

1;
