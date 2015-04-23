
package Amazon::EC2::Model::Tag;

use base qw (Amazon::EC2::Model);

    sub new {
        my ($class, $data) = @_;
        my $self = {};
        $self->{_fields} = {

            Key => {FieldValue => undef, FieldType => "string"},
            Value => {FieldValue => undef, FieldType => "string"},
        };

        bless ($self, $class);
        if (defined $data) {
           $self->_fromHashRef($data);
        }

        return $self;
    }

    sub setKey {
        my ($self, $value) = @_;
        $self->{_fields}->{Key}->{FieldValue} = $value;
    }

    sub setValue {
        my ($self, $value) = @_;
        $self->{_fields}->{Value}->{FieldValue} = $value;
    }

    sub getKey {
        return shift->{_fields}->{Key}->{FieldValue};
    }

    sub getValue {
        return shift->{_fields}->{Value}->{FieldValue};
    }

1;