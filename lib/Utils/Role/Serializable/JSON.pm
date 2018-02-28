package Utils::Role::Serializable::JSON;

use Moose::Role;
use JSON;
use boolean;

requires qw( serializable_attributes boolean_atributes  );

sub as_json {
    my $self = shift;
    my %object = map { $_ => $self->$_ } $self->serializable_attributes;
    foreach my $bool_attribute ( $self->boolean_atributes ) {
        if ( $object{$bool_attribute} ) {
            $object{$bool_attribute} = JSON::true();
        }
        else {
            $object{$bool_attribute} = JSON::false();
        }
    }
    return encode_json( \%object );
}

1;
