package Toggl::Wrapper;

=pod

=encoding UTF-8

=head1 NAME

  Toggl::Wrapper - Wrapper for the toggl.com task logging API
=cut

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use MooseX::Types::Email qw/EmailAddress/;
use MooseX::SemiAffordanceAccessor;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use JSON::Parse ':all';
use JSON;
use Scalar::Util qw(looks_like_number);
use Carp qw(croak);
use Try::Tiny;

use Toggl::Wrapper::TimeEntry;
use Utils::Common qw(check_iso8601);
use Data::Dumper;

use namespace::autoclean;

use constant TOGGL_URL_V8 => "https://www.toggl.com/api/v8/";
use constant USER_AGENT   => "Toggl::Wrapper
https://github.com/a-castellano/Toggl-Wrapper";

=head1 VERSION

  Version 0.01

=cut

our $VERSION = '0.01';

has 'api_token' => (
    is        => 'ro',
    isa       => 'Str',
    writer    => '_set_api_token',
    predicate => 'has_api_token',
);
has 'email' => (
    is        => 'ro',
    isa       => EmailAddress,
    writer    => '_set_email',
    predicate => 'has_email',
);
has 'password' => (
    is        => 'ro',
    isa       => 'Str',
    writer    => '_set_password',
    predicate => 'has_password',
);
has '_user_data' => (
    is     => 'ro',
    isa    => 'HashRef',
    writer => '_set_user_data',
);

=head1 SYNOPSIS

This module aims to intereact with toggle.com API. For the time being,
this module allows users to authenticate using user/password pair or an
api token instead.


    use Toggl::Wrapper;

    my $foo = Toggl::Wrapper->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 BUILD

This class needs an api token or and user/password to be used. BUILD method
checks if these parameters exists and makes the first call abotaining
user's account data.
=cut

sub BUILD {
    my $self = shift;

    my $response;
    my $response_data;
    my %auth;

    if ( $self->has_api_token ) {
        if ( $self->has_email || $self->has_password ) {
            croak
"Trying to create a Toggl::Wrapper instance with and api_token and user/password. You can only create an instance with an api key or email/password, not both.\n";
        }
        else {
            $auth{api_token} = $self->api_token;
        }
    }
    else {
        #Thre is no api_token, check user and passwod
        if ( $self->has_email && $self->has_password ) {
            $auth{email}    = $self->email;
            $auth{password} = $self->password;
        }
        else {
            croak
"Trying to create a Toggl::Wrapper with no user or password neither api_token. You can only create an instance with an api key or email/passwrd, not both.";
        }
    }
    $response = _make_api_call(
        {
            type    => 'GET',
            url     => TOGGL_URL_V8 . 'me',
            auth    => \%auth,
            headers => [],
            data    => {},
        }
    );

    $response_data = $response->{data};

    $self->_set_api_token( $response_data->{api_token} );
    $self->_set_email( $response_data->{email} );
    $self->_set_user_data($response_data);

}

=head2 _make_api_call
Perform GET/POST/PUT calls to Toggl API.
=cut

sub _make_api_call {
    my $call      = shift;
    my $auth      = $call->{auth};
    my $headers   = $call->{headers};
    my $data      = $call->{data};
    my $json_data = "";
    my $wrapper   = LWP::UserAgent->new(
        agent      => USER_AGENT,
        cookie_jar => {}
    );
    my $request = HTTP::Request->new( $call->{type} => "$call->{url}" );

    # Auth
    if ( $auth->{api_token} ) {
        $request->authorization_basic( $auth->{api_token}, "api_token" );
    }
    else {
        $request->authorization_basic( "$auth->{email}", "$auth->{password}" );
    }

    # Headers
    if (@$headers) {
        foreach my $header (@$headers) {
            $request->header(%$header);
        }
    }

    # Data
    if (%$data) {
        foreach my $key ( keys %$data ) {
            $json_data = "$json_data \"$key\":$data->{$key},";
        }
        $json_data = substr( $json_data, 0, -1 );
        $json_data = "{$json_data}";
        $request->content($json_data);
    }
    else {
        $request->content("");
        $request->content_length('0');
    }
    my $response = $wrapper->request($request);
    if ( $response->is_success ) {
        $response = $response->decoded_content;
        my $json = parse_json($response);
        return $json;
    }
    else {
        my $r       = HTTP::Response->parse( $response->status_line );
        my $code    = $r->code;
        my $message = $r->message;
        if ( $code == 403 ) {
            croak "Check your credentaials: APP call returned $code: $message";
        }
        else {
            croak "An error ocurred: APP call returned $code: $message";
        }
    }
}

=head1 Time Entries
Manage Toggl time entries.
=cut

=head2 _set_required_default_time_entry_values
Sets TimeEntry 'wid' if there is no one defined.
It also sets created_with attribute.
=cut

sub _set_required_default_time_entry_values() {
    my ( $self, $time_entry_data ) = @_;

    my $response;

    # If there is no wid defined, Wrapper will use default one
    if ( !$time_entry_data->{wid} ) {
        $time_entry_data->{wid} = $self->_user_data->{default_wid};
    }

    # Set created_with
    $time_entry_data->{created_with} = USER_AGENT;

}

=head2 create_time_entry
Creates and publishes a new time entry.
=cut

sub create_time_entry() {
    my ( $self, %time_entry_data ) = @_;

    $self->_set_required_default_time_entry_values( \%time_entry_data );

    my $response;
    my $time_entry = Toggl::Wrapper::TimeEntry->new( \%time_entry_data );

    $response = _make_api_call(
        {
            type => 'POST',
            url  => TOGGL_URL_V8 . 'time_entries',
            auth => {
                api_token => $self->api_token,
            },
            headers => [            { 'Content-Type' => 'application/json' } ],
            data    => { time_entry => $time_entry },
        }
    );
    return $response;
}

=head2 start_time_entry
Starts new time entry.
=cut

sub start_time_entry() {
    my ( $self, %time_entry_data ) = @_;
    my $response;
    my %response_data;

    $self->_set_required_default_time_entry_values( \%time_entry_data );

    # Start time does not need duration, set negative one.
    $time_entry_data{duration}   = 0;
    $time_entry_data{start_date} = DateTime->now();

    my $time_entry = Toggl::Wrapper::TimeEntry->new(%time_entry_data);

    $response = _make_api_call(
        {
            type => 'POST',
            url  => join( '', ( TOGGL_URL_V8, 'time_entries/start' ) ),
            auth => {
                api_token => $self->api_token,
            },
            headers => [ { 'Content-Type' => 'application/json' } ],
            data => { time_entry => $time_entry->as_json() },
        }
    );
    return Toggl::Wrapper::TimeEntry->new( $response->{data} );
}

=head2 stop_time_entry
Stop given time entry.
=cut

sub stop_time_entry() {
    my ( $self, $time_entry ) = @_;
    my $response;

    if ( !$time_entry->has_id ) {
        croak "Error:
passed entry does not contain 'id' field.";
    }

    return $self->stop_time_entry_by_id( $time_entry->id() );
}

=head2 get_time_entry_details
Get time entry details from a given entry id.
=cut

sub get_time_entry_details() {
    my ( $self, $time_entry_id ) = @_;
    my $response;

    $response = _make_api_call(
        {
            type => 'GET',
            url =>
              join( '', ( TOGGL_URL_V8, "time_entries/", $time_entry_id ) ),
            auth => {
                api_token => $self->api_token,
            },
            headers => [],
            data    => {},
        }
    );
    return Toggl::Wrapper::TimeEntry->new( $response->{data} );
}

=head2 _check_timeentry_id_is_numeric
Check if giiven TimeEntry id is numeric.
=cut

sub _check_id_is_numeric() {
    my ( $self, $id_candidate ) = @_;

    if ( !( $id_candidate =~ /^[+-]?\d+$/ ) ) {
        croak "TimeEntry id must be a number.";
    }
}

=head2 stop_time_entry_by_id
Stop time entries from a given entry id.
=cut

sub stop_time_entry_by_id() {
    my ( $self, $time_entry_id ) = @_;
    my $response;

    $self->_check_id_is_numeric($time_entry_id);

    $response = _make_api_call(
        {
            type => 'PUT',
            url  => join( '',
                ( TOGGL_URL_V8, "time_entries/", $time_entry_id, "/stop" ) ),
            auth => {
                api_token => $self->api_token,
            },
            headers => [ { 'Content-Type' => 'application/json' } ],
            data    => {},
        }
    );
    return Toggl::Wrapper::TimeEntry->new( $response->{data} );
}

=head2 get_running_time_entry
Get currently running time entry.
=cut

sub get_running_time_entry() {
    my $self = shift;
    my $response;

    $response = _make_api_call(
        {
            type => 'GET',
            url  => join( '', ( TOGGL_URL_V8, "time_entries/current" ) ),
            auth => {
                api_token => $self->api_token,
            },
            headers => [],
            data    => {},
        }
    );
    return Toggl::Wrapper::TimeEntry->new( $response->{data} );
}

=head2 update_time_entry_by_id
Update time entry using a given entry id.
=cut

sub update_time_entry_by_id() {
    my ( $self, $time_entry_id, $update_data ) = @_;
    my $response;

    $self->_check_id_is_numeric($time_entry_id);

    $response = _make_api_call(
        {
            type => 'PUT',
            url =>
              join( '', ( TOGGL_URL_V8, "time_entries/", $time_entry_id ) ),
            auth => {
                api_token => $self->api_token,
            },
            headers => [ { 'Content-Type' => 'application/json' } ],
            data => { time_entry => encode_json $update_data },
        }
    );
    return Toggl::Wrapper::TimeEntry->new( $response->{data} );
}

=head2 update_time_entry
Update given time entry.
=cut

sub update_time_entry() {
    my ( $self, $time_entry, $update_data ) = @_;
    my $response;

    if ( !$time_entry->has_id ) {
        croak "Error:
passed entry does not contain 'id' field.";
    }

    return $self->stop_time_entry_by_id( $time_entry->id(), $update_data );
}

=head2 delete_time_entry_by_id
Delete time entry using a given entry id.
=cut

sub delete_time_entry_by_id() {
    my ( $self, $time_entry_id ) = @_;
    my $response;

    $self->_check_id_is_numeric($time_entry_id);

    $response = _make_api_call(
        {
            type => 'DELETE',
            url =>
              join( '', ( TOGGL_URL_V8, "time_entries/", $time_entry_id ) ),
            auth    => { api_token => $self->api_token },
            headers => [],
            data    => {},
        }
    );
    return 1;
}

=head2 delete_time_entry
Delete given time entry.
=cut

sub delete_time_entry() {
    my ( $self, $time_entry ) = @_;
    my $response;

    if ( !$time_entry->has_id ) {
        croak "Error:
passed entry does not contain 'id' field.";
    }

    return $self->stop_time_entry_by_id( $time_entry->id() );
}

=head2 get_time_entries
Return a list of time entries occurred between two dates. If no dates
are supplied, API returns time entries started during the last 9 days.

'start' and 'stop' parameters can be supplied as datetime objects or
iso8091 strings.
=cut

sub get_time_entries() {
    my ( $self, $date_range ) = @_;

    my $start = '';
    my $stop  = '';

    my $data = '';
    my $response;

    my $entries;
    my @time_entries;

    if ($date_range) {
        if ( ref $date_range ne 'HASH' ) {
            croak
"Error: Invalid parameters supplied, specify start and stop dates or don't specify anithing.";
        }

        if ( !exists $date_range->{start} ) {
            croak
              "Error: Invalid parameters supplied, start date is not supplied.";
        }
        if ( !exists $date_range->{stop} ) {
            croak
              "Error: Invalid parameters supplied, stop date is not supplied.";
        }

        if ( ref $date_range->{start} eq "DateTime" ) {
            $start = $date_range->{start}->iso8601() . 'Z';
        }
        else {
            $start = $date_range->{start};
            if ( !check_iso8601($start) ) {
                croak "Attibute 'start' format is not valid.";
            }
        }

        if ( ref $date_range->{stop} eq "DateTime" ) {
            $stop = $date_range->{stop}->iso8601() . 'Z';
        }
        else {
            $stop = $date_range->{stop};
            if ( !check_iso8601($stop) ) {
                croak "Attibute 'stop' format is not valid.";
            }
        }

        if (
            DateTime->compare(
                DateTime::Format::ISO8601->parse_datetime($start),
                DateTime::Format::ISO8601->parse_datetime($stop)
            ) > 0
          )
        {
            croak
"Error: Invalid parameters supplied, stop date cannot be eairlier than start date.";
        }

        $data = "?start_date=$start&stop_date=$stop";
    }

    $response = _make_api_call(
        {
            type => 'GET',
            url  => join( '', ( TOGGL_URL_V8, "time_entries", $data ) ),
            auth => {
                api_token => $self->api_token,
            },
            headers => [],
            data    => {},
        }
    );

    map { push( @time_entries, Toggl::Wrapper::TimeEntry->new($_) ) }
      @{ $response->{data} };
    return \@time_entries;
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

    perldoc Toggl::Wrapper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Toggl-Wrapper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Toggl-Wrapper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Toggl-Wrapper>

=item * Search CPAN

L<http://search.cpan.org/dist/Toggl-Wrapper/>

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

1;    # End of Toggl::Wrapper
