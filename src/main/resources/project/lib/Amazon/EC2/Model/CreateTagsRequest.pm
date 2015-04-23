
package Amazon::EC2::Model::CreateTagsRequest;

use base qw (Amazon::EC2::Model);

sub new {

    my ($class, $data) = @_;
    my $self = {};
    $self->{_fields} = {

        ResourceId => {FieldValue => undef, FieldType => ["string"]},
        Tag => {FieldValue => undef, FieldType => ["Amazon::EC2::Model::Tag"]},
    };

    bless ($self, $class);
    if (defined $data) {
        $self->_fromHashRef($data);
    }

    return $self;
}

sub setIdList    {
    my ($self, $value) = @_;
    $self->{_fields}->{ResourceId}->{FieldValue} = $value;
}

sub setTagList {
    my ($self, $value) = @_;
    $self->{_fields}->{Tag}->{FieldValue} = $value;
}

sub getIdList() {
    return shift->{_fields}->{ResourceId}->{FieldValue};
}

sub getTagList() {
    return shift->{_fields}->{Tag}->{FieldValue};
}

1;