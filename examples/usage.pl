#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib';
use Toggl::Wrapper;

my $tggl = Toggl::Wrapper->new(
    {
        api_token => '99ad3f3398351d13f6d1c9657e8413a9',
    }
);
