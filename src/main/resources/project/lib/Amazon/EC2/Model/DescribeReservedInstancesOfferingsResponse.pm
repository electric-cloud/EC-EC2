###########################################$
#  Copyright 2008-2010 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#  Licensed under the Apache License, Version 2.0 (the "License"). You may not
#  use this file except in compliance with the License.
#  A copy of the License is located at
#
#      http://aws.amazon.com/apache2.0
#
#  or in the "license" file accompanying this file. This file is distributed on
#  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
#  or implied. See the License for the specific language governing permissions
#  and limitations under the License.
###########################################$
#    __  _    _  ___
#   (  )( \/\/ )/ __)
#   /__\ \    / \__ \
#  (_)(_) \/\/  (___/
#
#  Amazon EC2 Perl Library
#  API Version: 2010-06-15
#  Generated: Wed Jul 21 13:37:54 PDT 2010
#


package Amazon::EC2::Model::DescribeReservedInstancesOfferingsResponse;

use base qw (Amazon::EC2::Model);

    

    #
    # Amazon::EC2::Model::DescribeReservedInstancesOfferingsResponse
    # 
    # Properties:
    #
    # 
    # ResponseMetadata: Amazon::EC2::Model::ResponseMetadata
    # DescribeReservedInstancesOfferingsResult: Amazon::EC2::Model::DescribeReservedInstancesOfferingsResult
    #
    # 
    # 
    sub new {
        my ($class, $data) = @_;
        my $self = {};
        $self->{_fields} = {
            
            ResponseMetadata => {FieldValue => undef, FieldType => "Amazon::EC2::Model::ResponseMetadata"},
            DescribeReservedInstancesOfferingsResult => {FieldValue => undef, FieldType => "Amazon::EC2::Model::DescribeReservedInstancesOfferingsResult"},
        };

        bless ($self, $class);
        if (defined $data) {
           $self->_fromHashRef($data); 
        }
        
        return $self;
    }

       
     #
     # Construct Amazon::EC2::Model::DescribeReservedInstancesOfferingsResponse from XML string
     # 
    sub fromXML {
        my ($self, $xml) = @_;
        eval "use XML::Simple";
        my $tree = XML::Simple::XMLin ($xml);
         
        # TODO: check valid XML (is this a response XML?)
        
        return new Amazon::EC2::Model::DescribeReservedInstancesOfferingsResponse($tree);
          
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

    sub getDescribeReservedInstancesOfferingsResult {
        return shift->{_fields}->{DescribeReservedInstancesOfferingsResult}->{FieldValue};
    }


    sub setDescribeReservedInstancesOfferingsResult {
        my ($self, $value) = @_;
        $self->{_fields}->{DescribeReservedInstancesOfferingsResult}->{FieldValue} = $value;
    }


    sub withDescribeReservedInstancesOfferingsResult {
        my ($self, $value) = @_;
        $self->setDescribeReservedInstancesOfferingsResult($value);
        return $self;
    }


    sub isSetDescribeReservedInstancesOfferingsResult {
        return defined (shift->{_fields}->{DescribeReservedInstancesOfferingsResult}->{FieldValue});

    }



    #
    # XML Representation for this object
    # 
    # Returns string XML for this object
    #
    sub toXML {
        my $self = shift;
        my $xml = "";
        $xml .= "<DescribeReservedInstancesOfferingsResponse xmlns=\"http://ec2.amazonaws.com/doc/2010-06-15/\">";
        $xml .= $self->_toXMLFragment();
        $xml .= "</DescribeReservedInstancesOfferingsResponse>";
        return $xml;
    }


1;
