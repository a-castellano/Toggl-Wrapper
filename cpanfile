requires 'CPAN::Meta', 2.12091;
requires 'CPAN::Meta::Prereqs', 2.12091;
requires 'DateTime::Format::ISO8601', 0.08;
requires 'Email::Abstract', 3.008;
requires 'HTTP::Date', 6.02;
requires 'HTTP::Headers', 6.13;
requires 'HTTP::Message', 6.13;
requires 'HTTP::Request', 6.13;
requires 'HTTP::Response', 6.13;
requires 'HTTP::Status', 6.13;
requires 'JSON', 2.97001;
requires 'JSON::Parse', 0.55;
requires 'JSON::XS', 3.03;
requires 'LWP', 6.29;
requires 'LWP::MemberMixin', 6.29;
requires 'LWP::Protocol', 6.29;
requires 'LWP::UserAgent', 6.29;
requires 'Mail::Address', 2.18;
requires 'Mail::Header', 2.18;
requires 'Mail::Internet', 2.18;
requires 'Mail::Util', 2.18;
requires 'Moose', 2.2009;
requires 'Moose::Util::TypeConstraints', 2.2009;
requires 'MooseX::SemiAffordanceAccessor', 0.10;
requires 'MooseX::StrictConstructor', 0.21;
requires 'MooseX::Types', 0.50;
requires 'MooseX::Types::Email', 0.007;
requires 'Devel::Cover::Report::Codecov', 0.22;

recommends 'Pod::Usage';

on test => sub {
    requires 'Test::More', 1.302120;
    requires 'Test::Class', 0.50;
    requires 'Test::MockModule', 0.13;
    requires 'Devel::Mutator', 0.03;
};
