package Amazon::EC2::Model::CreateTagsResponse;

use base qw (Amazon::EC2::Model);

    sub new {
        my ($class, $data) = @_;
        my $self = {};
        $self->{_fields} = {

            ResponseMetadata => {FieldValue => undef, FieldType => "Amazon::EC2::Model::ResponseMetadata"},
        };

        bless ($self, $class);
        if (defined $data) {
           $self->_fromHashRef($data);
        }

        return $self;
    }

     #
     # Construct Amazon::EC2::Model::CreateTagsResponse from XML string
     #
    sub fromXML {
        my ($self, $xml) = @_;
        eval "use XML::Simple";
        my $tree = XML::Simple::XMLin($xml);

        return new Amazon::EC2::Model::CreateTagsResponse($tree);

    }

    sub getResponseMetadata {
        return shift->{_fields}->{ResponseMetadata}->{FieldValue};
    }

    sub setResponseMetadata {
        my ($self, $value) = @_;
        $self->{_fields}->{ResponseMetadata}->{FieldValue} = $value;
    }

    sub withResponseMetadata {
        my ($self, $value) = @_;
        $self->setResponseMetadata($value);
        return $self;
    }

    sub isSetResponseMetadata {
        return defined (shift->{_fields}->{ResponseMetadata}->{FieldValue});

    }

    #
    # XML Representation for this object
    #
    # Returns string XML for this object
    #
    sub toXML {
        my $self = shift;
        my $xml = "";
        $xml .= "<CreateTagsResponse xmlns=\"http://ec2.amazonaws.com/doc/2010-06-15/\">";
        $xml .= $self->_toXMLFragment();
        $xml .= "</CreateTagsResponse>";
        return $xml;
    }


1;