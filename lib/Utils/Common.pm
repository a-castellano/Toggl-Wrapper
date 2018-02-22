package Utils::Common;

use strict;
use warnings;

use DateTime::Format::ISO8601;
use Try::Tiny;
use namespace::autoclean;

use base 'Exporter';
our @EXPORT_OK = qw(check_iso8601);

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

1;
