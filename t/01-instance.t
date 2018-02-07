#!perl -T
use Test::Most tests => 1;
use Toggl::Wrapper;
use Test::MockModule;
use Email::Valid;
use HTTP::Response;
use Data::Dumper;

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

my $mocked_http_request = Test::MockModule->new('HTTP::Request');
$mocked_http_request->mock(
    "authorization_basic",
    sub {
        my ( $self, @data ) = @_;
        $self->{'requested_data'} = [@data];
    }
);

my $mocked_http_response = Test::MockModule->new('HTTP::Response');
$mocked_http_response->mock(
    "decoded_content",
    sub {
        return '{"since":1517980319,"data":{"id":921391,"api_token":"u1tra53cr3tt0k3n","default_wid":1864303,"email":"myemail@domain.com","fullname":"Wrapper Test User","jquery_timeofday_format":"h:i A","jquery_date_format":"m/d/Y","timeofday_format":"h:mm A","date_format":"MM/DD/YYYY","store_start_and_stop_time":true,"beginning_of_week":1,"language":"en_US","image_url":"https://assets.toggl.com/images/profile.png","sidebar_piechart":true,"at":"2018-02-06T05:14:02+00:00","created_at":"2013-03-06T18:14:24+00:00","retention":9,"record_timeline":false,"render_timeline":false,"timeline_enabled":false,"timeline_experiment":false,"new_blog_post":{"title":"Notes on Yesterday’s Server Problems","url":"http://blog.toggl.com/notes-on-yesterdays-server-problems/","category":"Announcement","pub_date":"2018-01-17T13:44:50Z"},"should_upgrade":true,"achievements_enabled":true,"timezone":"Europe/Madrid","openid_enabled":true,"openid_email":"myemail@domain.com","send_product_emails":true,"send_weekly_report":true,"send_timer_notifications":true,"last_blog_entry":"","invitation":{},"workspaces":[{"id":1364303,"name":"User\'s workspace","profile":0,"premium":false,"admin":true,"default_hourly_rate":0,"default_currency":"USD","only_admins_may_create_projects":false,"only_admins_see_billable_rates":false,"only_admins_see_team_dashboard":false,"projects_billable_by_default":true,"rounding":1,"rounding_minutes":0,"api_token":"u1tra53cr3tt0k3n","at":"2013-03-06T18:14:25+00:00","ical_enabled":true}],"duration_format":"improved","obm":{"included":false,"nr":0,"actions":"tree"}}}';
    }
);

ok 1, 'this is a test!';

my %data = ( api_token => "u1tra53cr3tt0k3n" );
my $tggl = Toggl::Wrapper->new(%data);

diag("Testing Toggl::Wrapper $Toggl::Wrapper::VERSION, Perl $], $^X");
