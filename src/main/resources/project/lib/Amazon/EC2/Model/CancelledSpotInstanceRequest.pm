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


package Amazon::EC2::Model::CancelledSpotInstanceRequest;

use base qw (Amazon::EC2::Model);

    

    #
    # Amazon::EC2::Model::CancelledSpotInstanceRequest
    # 
    # Properties:
    #
    # 
    # SpotInstanceRequestId: string
    # State: string
    #
    # 
    # 
    sub new {
        my ($class, $data) = @_;
        my $self = {};
        $self->{_fields} = {
            
            SpotInstanceRequestId => { FieldValue => undef, FieldType => "string"},
            State => { FieldValue => undef, FieldType => "string"},
        };

        bless ($self, $class);
        if (defined $data) {
           $self->_fromHashRef($data); 
        }
        
        return $self;
    }

    
    sub getSpotInstanceRequestId {
        return shift->{_fields}->{SpotInstanceRequestId}->{FieldValue};
    }


    sub setSpotInstanceRequestId {
        my ($self, $value) = @_;

        $self->{_fields}->{SpotInstanceRequestId}->{FieldValue} = $value;
        return $self;
    }


    sub withSpotInstanceRequestId {
        my ($self, $value) = @_;
        $self->setSpotInstanceRequestId($value);
        return $self;
    }


    sub isSetSpotInstanceRequestId {
        return defined (shift->{_fields}->{SpotInstanceRequestId}->{FieldValue});
    }


    sub getState {
        return shift->{_fields}->{State}->{FieldValue};
    }


    sub setState {
        my ($self, $value) = @_;

        $self->{_fields}->{State}->{FieldValue} = $value;
        return $self;
    }


    sub withState {
        my ($self, $value) = @_;
        $self->setState($value);
        return $self;
    }


    sub isSetState {
        return defined (shift->{_fields}->{State}->{FieldValue});
    }





1;
