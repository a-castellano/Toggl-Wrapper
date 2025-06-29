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
use DateTime::Format::ISO8601;
use Try::Tiny;
use Carp qw(croak);

use Utils::Common qw(check_iso8601 getdatestring);
with "Utils::Role::Serializable::JSON";
use namespace::autoclean;

=head1 VERSION

  Version 0.2

=cut

our $VERSION = '0.2';

=head1 SYNOPSIS

This module manages Toggl time entries.

    use Toggl::Wrapper::TimeEntry;

    my $time_entry = Toggl::Wrapper::TimeEntry->new();
    ...

=head1 Properties

description: (string, strongly suggested to be used)
workspace_id: workspace ID (integer, required if pid or tid not supplied)
wid: alias for workspace_id
pid: project ID (integer, not required)
tid: task ID (integer, not required)
billable: (boolean, not required, default false, available for pro workspaces)
start: time entry start time (string, required, ISO 8601 date and time)
stop: time entry stop time (string, not required, ISO 8601 date and time)
duration: time entry duration in seconds. If the time entry is currently running, the duration attribute contains a negative value, denoting the start of the time entry in seconds since epoch (Jan 1 1970). The correct duration can be calculated as current_time + duration, where current_time is the current time in seconds since epoch. (integer, required)
created_with: the name of your client app (string, required)
tags: a list of tag names (array of strings, not required)
duronly: should Toggl show the start and stop time of this time entry? (boolean, not required)
at: timestamp that is sent in the response, indicates the time item was last updated
id: unique time entry ID (integer, not required)
guid: globally unique identifier for the time entry (string, not required)
start_date: time entry start time as DateTime object (DateTime, not required)
stop_date: time entry stop time as DateTime object (DateTime, not required)
project_id: project ID (integer or undef, not required)
server_deleted_at: deletion timestamp from server (string or undef, not required)
tag_ids: list of tag IDs (arrayref or undef, not required)
task_id: task ID (integer or undef, not required)
user_id: user ID (integer or undef, not required)
uid: user ID (integer, not required)

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
    default  => "",
    required => 0,
);

has 'workspace_id' => (
    is        => 'ro',
    isa       => 'Int',
    required  => 0,
    predicate => 'has_workspace_id',
    writer    => 'set_workspace_id',
);

has 'wid' => (
    is       => 'ro',
    isa      => 'Int',
    required => 0,
    writer   => 'set_wid',
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
    is        => 'ro',
    isa       => 'DateTime',
    required  => 0,
    predicate => 'has_start_date',
);

has 'start' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 0,
    writer    => 'set_start',
    predicate => 'has_start',
);

has 'stop_date' => (
    is        => 'ro',
    isa       => 'DateTime|Undef',
    required  => 0,
    predicate => 'has_stop_date',
);

has 'stop' => (
    is        => 'ro',
    isa       => 'Str|Undef',
    required  => 0,
    predicate => 'has_stop',
    writer    => 'set_stop',
);

has 'duration' => (
    is        => 'ro',
    isa       => 'Int',
    required  => 1,
    writer    => 'set_duration',
    predicate => 'has_duration',

);

has 'project_id' => (
    is       => 'ro',
    isa      => 'Int|Undef',
    required => 0,
);

has 'server_deleted_at' => (
    is       => 'ro',
    isa      => 'Str|Undef',
    required => 0,
);

has 'tag_ids' => (
    is       => 'ro',
    isa      => 'ArrayRef|Undef',
    required => 0,
);

has 'task_id' => (
    is       => 'ro',
    isa      => 'Int|Undef',
    required => 0,
);

has 'user_id' => (
    is       => 'ro',
    isa      => 'Int|Undef',
    required => 0,
);

has 'created_with' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has 'tags' => (
    is       => 'ro',
    isa      => 'ArrayRef|Undef',
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
    isa      => 'Str',
    required => 0,
);

has 'uid' => (
    is       => 'ro',
    isa      => 'Int',
    required => 0,
);

=head1 SUBROUTINES/METHODS

=head2 BUILD

If stop date is set this method chacks if stop date is older than start
data. It also converts data to ISO 8601 format.

=cut

sub BUILD {
    my $self = shift;

    if ( $self->has_workspace_id ) {
        $self->set_workspace_id( int( $self->workspace_id ) );
        $self->set_wid( $self->workspace_id );
    }

    if ( $self->has_start_date && $self->has_start ) {
        croak
"TimeEntry does not allow to be instanced with 'start_date' and 'start' at the same time. Only one of them is allowed.";
    }

    if ( !$self->has_start_date && !$self->has_start ) {
        croak
"TimeEntry does not allow to be instanced without 'start_date' or 'start'.";
    }

    if ( $self->has_stop_date && $self->has_stop ) {
        croak
"TimeEntry does not allow to be instanced with 'stop_date' and 'stop' at the same time. Only one of them is allowed.";
    }

    if ( $self->has_start_date ) {

        $self->set_start( getdatestring( $self->start_date ) );
    }
    else {
        if ( !check_iso8601( $self->start ) ) {
            croak "Attibute 'start' format is not valid.";
        }
        $self->set_start( $self->start );
    }

    if ( $self->has_stop_date ) {
        $self->set_stop( $self->stop_date->strftime('%Y-%m-%dT%H:%M:%S%z') );
    }
    elsif ( $self->has_stop ) {
        if ( $self->stop ) {
            if ( !check_iso8601( $self->stop ) ) {
                croak "Attibute 'stop' format is not valid.";
            }
        }
    }

    if ( $self->has_stop ) {
        if ( $self->stop ) {
            if (
                DateTime->compare(
                    DateTime::Format::ISO8601->parse_datetime( $self->start ),
                    DateTime::Format::ISO8601->parse_datetime( $self->stop )
                ) > 0
              )
            {
                croak "End date has to be greater than start date.";
            }

        }
    }

}

=head2 serializable_attributes

Returns json serialiable atributes.

=cut

sub serializable_attributes {
    return

#qw(id guid description workspace_id pid tid billable start stop duration created_with tags duronly at );
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

This license includes the non-exclusive, worldworkspace_ide, free-of-charge
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
