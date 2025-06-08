package Utils::Common;

use strict;
use warnings;

use DateTime::Format::ISO8601;
use Try::Tiny;
use namespace::autoclean;

use base 'Exporter';
our @EXPORT_OK = qw(check_iso8601 getdatestring);

=head2 check_iso8601
Returns True or False if given istring is a correct iso8601 formated date.

=cut

sub check_iso8601 {
    my $date = shift;
    try {
        DateTime::Format::ISO8601->parse_datetime($date);
        return 1;
    }
    catch {
        return 0;
    };
}

sub getdatestring {
    my $date = shift;

    my $date_str = $date->strftime('%Y-%m-%dT%H:%M:%SZ');
    #$date_str =~ s/(\d{2})(\d{2})$/$1:$2/;  # Add colon to timezone offset
    return $date_str;
}

1;
