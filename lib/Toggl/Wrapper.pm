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
use Carp qw(croak);

use Toggl::Wrapper::TimeEntry;
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
    $response_data = _make_api_call(
        {
            type    => 'GET',
            url     => TOGGL_URL_V8 . 'me',
            auth    => \%auth,
            headers => [],
            data    => {},
        }
    );

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
        $json_data =~ s/,$//;
        $json_data = "{$json_data}";
        $request->content($json_data);
    }

    my $response = $wrapper->request($request);
    if ( $response->is_success ) {
        $response = $response->decoded_content;
        my $json = parse_json($response);
        return $json->{data};
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

=head1 create_time_entry
Creates and publishes a new time entry..
=cut

sub create_time_entry() {
    my ( $self, %time_entry_data ) = @_;

    # If there is no wid defined, Wrapper will use default one
    if ( $time_entry_data{wid} ) {
        $time_entry_data{wid} = $self->_user_data->{default_wid};
    }

    my $time_entry = Toggl::Wrapper::TimeEntry->new( \%time_entry_data );

    my $response_data = _make_api_call(
        {
            type => 'POST',
            url  => TOGGL_URL_V8 . 'time_entries',
            auth => {
                api_token => $self->api_token,
            },
            headers => [ { 'content-type' => 'application/json' } ],
            data => { time_entry => $time_entry->as_json() },
        }
    );
    return 1;
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
