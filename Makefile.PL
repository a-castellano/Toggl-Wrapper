use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Toggl::Wrapper',
    AUTHOR           => q{Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>},
    VERSION_FROM     => 'lib/Toggl/Wrapper.pm',
    ABSTRACT_FROM    => 'lib/Toggl/Wrapper.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'DateTime::Format::ISO8601'              => 0.08,
        'Email::Abstract' => 3.008,
        'HTTP::Date' => 6.02,
        'HTTP::Headers' => 6.13,
        'HTTP::Message' => 6.13,
        'HTTP::Request' => 6.13,
        'HTTP::Response' => 6.13,
        'HTTP::Status' => 6.13,
        'JSON' => 2.97001,
        'JSON::Parse' => 0.55,
        'JSON::XS' => 3.03,
        'LWP' => 6.29,
        'LWP::Protocol' => 6.29,
        'LWP::UserAgent' => 6.29,
        'Mail::Address' => 2.18,
        'Mail::Header' => 2.18,
        'Mail::Internet' => 2.18,
        'Mail::Util' => 2.18,
        'Moose' => 2.2009,
        'Moose::Util::TypeConstraints' => 2.2009,
        'MooseX::SemiAffordanceAccessor' => 0.10,
        'MooseX::StrictConstructor' => 0.21,
        'MooseX::Types' => 0.50,
        'MooseX::Types::Email' => 0.007,
        'Devel::Cover::Report::Codecov' => 0.22,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Toggl-Wrapper-*' },
);
