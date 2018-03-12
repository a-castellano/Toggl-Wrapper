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
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Toggl-Wrapper-*' },
);
