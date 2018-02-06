#!perl -T
use 5.006;
use Test::Most tests => 1;
use Toggl::Wrapper;
use Test::MockModule;

use Data::Dumper;

my $mocked_lwp = Test::MockModule->new('LWP::UserAgent');
$mocked_lwp->mock('request', sub { my $data = shift;
        die Dumper(\$data);
    });

my $mocked_http_request = Test::MockModule->new('HTTP::Request');
$mocked_http_request->mock("authorization_basic", sub {
my ( $self, @data ) = @_;
$self->{'requested_data'}=[@data];
die Dumper(\$self);
    
});
ok 1, 'this is a test!';



my %data = ( api_token => "test" );
my $tggl = Toggl::Wrapper->new(%data);

diag( "Testing Toggl::Wrapper $Toggl::Wrapper::VERSION, Perl $], $^X" );
