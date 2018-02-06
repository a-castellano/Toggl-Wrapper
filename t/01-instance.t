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

        unless ( !Email::Valid->address($email_or_api_token)
            && $password_or_api_token_text eq 'api_token' )
        {
            $using_token_auth = 1;
        }

        if ($using_token_auth) {
            if ( $email_or_api_token ne "u1tra53cr3tt0k3n" ){
            $successful_request = 0;
            }
        }
        else{
            if ($email_or_api_token ne 'myemail@domain.com' || $password_or_api_token_text ne 'myU1tra53cr3tPa55wd'){
               $successful_request = 0;
            }
        }
        if ($successful_request){
            return HTTP::Response->new( 200 );
        }
        else {
            return HTTP::Response->new( 403, 'Forbidden' );
        }
    }
);

$mocked_lwp->mock(
    'is_success',
    sub {return 1;}
);


my $mocked_http_request = Test::MockModule->new('HTTP::Request');
$mocked_http_request->mock(
    "authorization_basic",
    sub {
        my ( $self, @data ) = @_;
        $self->{'requested_data'} = [@data];

        #die Dumper(\$self);
    }
);

ok 1, 'this is a test!';

my %data = ( api_token => "test" );
my $tggl = Toggl::Wrapper->new(%data);

diag("Testing Toggl::Wrapper $Toggl::Wrapper::VERSION, Perl $], $^X");
