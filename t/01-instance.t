#!perl -T
use 5.006;
use Test::Most tests => 1;
use Toggl::Wrapper;

ok 1, 'this is a test!';

my %data = ( api_token => "test" );
my $tggl = Toggl::Wrapper->new(%data);

diag( "Testing Toggl::Wrapper $Toggl::Wrapper::VERSION, Perl $], $^X" );
