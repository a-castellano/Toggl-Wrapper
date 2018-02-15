package Toggl::Wrapper::TimeEntry;

=pod

=encoding UTF-8

=head1 NAME

  Toggl::Wrapper::TimeEntry - Toggl time entries manager
=cut

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;
use DateTime;
use Carp qw(croak);
with "Utils::Role::Serializable::JSON";
use namespace::autoclean;

=head1 VERSION

  Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module manages Toggl time entries.

    use Toggl::Wrapper::TimeEntry;

    my $time_entry = Toggl::Wrapper::TimeEntry->new();
    ...

=head1 Properties

description: (string, strongly suggested to be used)
wid: workspace ID (integer, required if pid or tid not supplied)
pid: project ID (integer, not required)
tid: task ID (integer, not required)
billable: (boolean, not required, default false, available for pro workspaces)
start: time entry start time (string, required, ISO 8601 date and time)
stop: time entry stop time (string, not required, ISO 8601 date and time)
duration: time entry duration in seconds. If the time entry is currently running, the duration attribute contains a negative value, denoting the start of the time entry in seconds since epoch (Jan 1 1970). The correct duration can be calculated as current_time + duration, where current_time is the current time in seconds since epoch. (integer, required)
created_with: the name of your client app (string, required)
tags: a list of tag names (array of strings, not required)
duronly: should Toggl show the start and stop time of this time entry? (boolean, not required)
at: timestamp that is sent in the response, indicates the time item was last updatedead1 SUBROUTINES/METHODS
=cut

has 'id' => (
    is        => 'ro',
    isa       => 'Int',      #
    writer    => 'set_id',
    predicate => 'has_id',
    required  => 0,
);

has 'guid' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has 'description' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has 'wid' => (
    is       => 'ro',
    isa      => 'Int',
    required => 0,
);

has 'pid' => (
    is       => 'ro',
    isa      => 'Int',
    required => 0,
);

has 'tid' => (
    is       => 'ro',
    isa      => 'Int',
    required => 0,
);

has 'billable' => (
    is       => 'ro',
    isa      => 'Bool',
    traits   => ['Bool'],
    default  => 0,
    required => 0,
);

has 'start_date' => (
    is       => 'ro',
    isa      => 'DateTime',
    required => 1,
);

has 'start' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    writer   => 'set_start_date_iso8601',
    init_arg => undef,
);

has 'stop_date' => (
    is        => 'ro',
    isa       => 'DateTime',
    required  => 0,
    predicate => 'has_stop_date',
);

has 'stop' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    writer   => 'set_stop_date_iso8601',
    init_arg => undef,
);

has 'duration' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

# Toggl API requires this attribute. It is up to wrappers to set it.

has 'created_with' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has 'tags' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 0,
);

has 'duronly' => (
    is       => 'ro',
    isa      => 'Bool',
    traits   => ['Bool'],
    default  => 0,
    required => 0,
);

has 'at' => (
    is       => 'ro',
    isa      => 'DateTime',
    required => 0,
);

=head1 SUBROUTINES/METHODS
=head2 BUILD

If stop date is set this method chacks if stop date is older than start
data. It also converts data to ISO 8601 format.

=cut

sub BUILD {
    my $self = shift;
    my $timestamp;

    $self->set_start_date_iso8601( $self->start_date->iso8601() . 'Z' );

    if ( $self->has_stop_date ) {
        if ( DateTime->compare( $self->start_date, $self->stop_date ) > 0 ) {
            croak "End date has to be greater than start date.";
        }
        $self->set_stop_date_iso8601( $self->stop_date->iso8601() . 'Z' );
    }
}

=head2 serializable_attributes

Returns json serialiable atributes.

=cut

sub serializable_attributes {
    return
      qw(id guid description wid pid tid billable start stop duration created_with tags duronly at );
}

=head2 boolean_atributes

From serializable_attributes, return which are boolean.

=cut

sub boolean_atributes {
    return qw( billable duronly );
}

=head1 AUTHOR

Álvaro Castellano Vela, C<< <alvaro.castellano.vela at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-toggl-wrapper at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Toggl-Wrapper>.  I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Toggl::Wrapper::TimeEntry


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Toggl-Wrapper-TimeEntry>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Toggl-Wrapper-TimeEntry>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Toggl-Wrapper-TimeEntry>

=item * Search CPAN

L<http://search.cpan.org/dist/Toggl-Wrapper-TimeEntry/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Álvaro Castellano Vela.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by
the Package. If you institute patent litigation (including a
cross-claim or counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement, then
this Artistic License to you shall terminate on the date that such
litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable;

1;    # End of Toggl::Wrapper::TimeEntry
