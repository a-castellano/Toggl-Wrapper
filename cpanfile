requires 'CPAN::Meta', 2.12091;
requires 'CPAN::Meta::Prereqs', 2.12091;
requires 'Email::Abstract', 3.008;
requires 'parent';

recommends 'Pod::Usage';

on test => sub {
    requires 'Test::More', 0.88;
};
