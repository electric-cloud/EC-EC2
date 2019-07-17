#
#  Copyright 2015 Electric Cloud, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

## Perl Code to implement EC2 API Calls
package main;

$::gDebug = 1;
$|        = 1;

use ElectricCommander;
use ElectricCommander::PropDB;
use ElectricCommander::PropMod qw(/myProject/lib);
use Data::Dumper;
use File::Spec;
use MIME::Base64 qw(encode_base64);
use XML::Simple;

use Amazon::EC2::Model::CreateTagsRequest;
use Amazon::EC2::Model::Tag;
use Amazon::EC2::Model::DescribeVolumesRequest;
use Amazon::EC2::Model::DescribeSubnetsRequest;
use Amazon::EC2::Model::AllocateAddressRequest;
use Amazon::EC2::Model::ReleaseAddressRequest;
use Amazon::EC2::Model::AttachVolumeRequest;
use Amazon::EC2::Model::CreateKeyPairRequest;
use Amazon::EC2::Model::DeleteKeyPairRequest;
use Amazon::EC2::Model::CreateVolumeRequest;
use Amazon::EC2::Model::CreateSnapshotRequest;
use Amazon::EC2::Model::DeleteVolumeRequest;
use Amazon::EC2::Model::DetachVolumeRequest;
use Amazon::EC2::Model::StartInstancesRequest;
use Amazon::EC2::Model::StartInstancesResponse;
use Amazon::EC2::Model::StartInstancesResult;
use Amazon::EC2::Model::StopInstancesRequest;
use Amazon::EC2::Model::StopInstancesResponse;
use Amazon::EC2::Model::StopInstancesResult;
use Amazon::EC2::Model::TerminateInstancesRequest;
use Amazon::EC2::Model::DescribeInstancesRequest;
use Amazon::EC2::Model::DeregisterImageRequest;
use Amazon::EC2::Model::CreateImageRequest;
use Amazon::EC2::Model::DescribeAccountAttributesRequest;
use Amazon::EC2::Model::RunInstancesRequest;
use Amazon::EC2::Model::CreateVpcRequest;
use Amazon::EC2::Model::CreateSubnetRequest;
use Amazon::EC2::Model::DeleteVpcRequest;
use Amazon::EC2::Model::DeleteSubnetRequest;
use Amazon::EC2::Model::Placement;
use Amazon::EC2::Model::Filter;

$::gMockData     = false;
$::gMockRegistry = q{};

main();
exit 0;

################################################################################

###########################
##
## Pull credential values from a credential
##
###########################
sub getCredential($) {
    my ($credname) = @_;

    my $jobStepId = $ENV{"COMMANDER_JOBSTEPID"};
    my $xPath =
      $::CmdrAPI->getFullCredential( "$credname", { jobStepId => $jobStepId } );
    if ( !defined $xPath ) {
        my $msg = $::CmdrAPI->getError();
        mesg( 0, "Error: retrieving credential $msg \n" );
        exit(1);
    }

    # Get user and password from Credential
    my $user = $xPath->findvalue('//credential/userName');
    my $pass = $xPath->findvalue('//credential/password');
    return ( $user, $pass );
}

#############################################################################
## extract_keyfile
##
## extract keyfile for commands that retun key contents to STDOUT
##
## args:
##      filename - the name of the file to put the key text in
##      pem      - contents of key file
#############################################################################
sub extract_keyfile($$) {
    my ( $filename, $pem ) = @_;

    open FILE, ">", $filename or die $!;
    print FILE $pem . "\n";
    close FILE;
    chmod( 0400, $filename );
}

####
# generate random digit
#   len - number of digits
####
sub getRandKey($) {
    my ($max) = @_;
    my $r = int( rand($max) );
    return $r;
}

###########################
##
## Print a message if it meets debugging level
##
###########################
sub mesg {
    my ( $level, $msg ) = @_;
    if ( $level <= $::gDebug ) {
        print $msg;
    }
}

###########################
##
## extract a required
## parameter from options
## die if not found
##
###########################
sub getRequiredParam {
    my ( $param, $opts, $expandValue ) = @_;
    if ( "$param" eq "" ) {
        mesg( 0, "Blank parameter name not allowed in getRequiredParam\n" );
        exit 1;
    }
    my $value = $opts->{$param};
    if ($expandValue && $value) {
        my $ec = $opts->{ec_instance};
        $value = $ec->expandString($value)->findvalue("//value")  . '';
    }
    if ( "$value" eq "" ) {
        mesg( 0, "Required parameter $param not found.\n" );
        exit 1;
    }
    return $value;
}

###########################
##
## extract an optional
## parameter from options
##
##
###########################
sub getOptionalParam {
    my ( $param, $opts ) = @_;
    my $value = "";
    eval { $value = $opts->{$param}; };
    return $value;
}

###########################
##
## Derive the location to store
## the output properties.
##
###########################
sub getPropResultLocationForPool {
    my ( $opts, $poolName ) = @_;
    my $propResult = getOptionalParam( "propResult", $opts );
    if ( !$propResult ) {
        $propResult = "/myParent/parent";
    }

    #Decided not to scope by resource pool name for now
    #to ensure backward compatibility.
    #if ($poolName) {
    #    $propResult .= "/" . $poolName;
    #}
    return $propResult;
}

###########################
##
## Throw EC2 error
##
##
###########################
sub throwEC2Error {
    my ($ex) = @_;

    if ( defined($ex) ) {
        require Amazon::EC2::Exception;
        if ( ref $ex eq "Amazon::EC2::Exception" ) {
            mesg( 1, "Caught Exception: " . $ex->getMessage() . "\n" );
            mesg( 1, "Response Status Code: " . $ex->getStatusCode() . "\n" );
            mesg( 1, "Error Code: " . $ex->getErrorCode() . "\n" );
            mesg( 1, "Error Type: " . $ex->getErrorType() . "\n" );
            mesg( 1, "Request ID: " . $ex->getRequestId() . "\n" );
            mesg( 1, "XML: " . $ex->getXML() . "\n" );
        }
        else {
            mesg( 0, "An error occurred:\n" );
            mesg( 0, "$ex\n" );
        }
        exit 1;
    }
}

###########################
##
## main program
##
###########################
sub main {
    my $opts = { method => teardownresource };

    $::CmdrAPI = new ElectricCommander();
    $::CmdrAPI->abortOnError(0);

    ## load option list from procedure parameters
    populateActualParameters( $::CmdrAPI, $opts );

    my $method = $opts->{method} . '';
    if ( $method =~ m/teardownresource/is ) {
        my $ok = tearDownResource($opts);

        # just a trap
        if ($ok) {
            exit 0;
        }
        exit 1;
    }

    # check for required params
    if ( !defined $opts->{config} || "$opts->{config}" eq "" ) {
        mesg( 0, "config parameter must exist and be non-blank\n" );
        exit 1;
    }

    # check to see if a config with this name exists
    my $proj = "@PLUGIN_NAME@";
    if ( substr( $proj, 0, 1 ) eq "@" ) {
        $proj = "EC-EC2-1.0.0.0";
    }

    # set property table to this cfg list
    my $CfgDB =
      ElectricCommander::PropDB->new( $::CmdrAPI, "/projects/$proj/ec2_cfgs" );

    # read values from this config

    $opts->{service_url} = $CfgDB->getCol( "$opts->{config}", "service_url" );
    $opts->{debug}       = $CfgDB->getCol( "$opts->{config}", "debug" );

    $opts->{resourceName} = $CfgDB->getCol( "$opts->{config}", 'resource_pool' );
    $opts->{workspaceName} = $CfgDB->getCol( "$opts->{config}", 'workspace' );
    eval {
        $opts->{http_proxy} = $CfgDB->getCol("$opts->{config}", 'http_proxy');
        if ($opts->{http_proxy}) {
            $ENV{HTTP_PROXY} = $opts->{http_proxy};
            $ENV{HTTPS_PROXY} = $opts->{http_proxy};
            $ENV{FTP_PROXY} = $opts->{http_proxy};
        }
    };

    # if mockdata is non blank, hard coded mock data will be
    # used and no actual calls to EC2 will be made
    if ( $CfgDB->getCol( "$opts->{config}", "mockdata" ) ne "" ) {
        print "MOCK DATA MODE=true\n";
        $::gMockData = true;

        # this property sheet will be used to keep track of
        # things created so getters can find them
        $::gMockRegistry = "/myProject/MOCK_REGISTRY/$opts->{config}";
    }

    if ( "$opts->{debug}" ne "" ) {
        $::gDebug = $opts->{debug};
    }

    # generic propdb for writting results
    $opts->{pdb} = ElectricCommander::PropDB->new( $::CmdrAPI, "" );
    $opts->{ec_instance} = $::CmdrAPI;
    if ( "$opts->{service_url}" eq "" ) {
        mesg(0, "Error: Configuration $opts->{config} does not specify a service_url\n");
        exit 1;
    }

    # credential uses the same name as the configuration
    ( $opts->{AWS_ACCESS_KEY_ID}, $opts->{AWS_SECRET_ACCESS_KEY} ) =
        getCredential("$opts->{config}");
    if ($opts->{http_proxy}) {
        eval {
            my ($proxy_username, $proxy_password) = getCredential($opts->{config} . '_proxy_credential');
            $ENV{HTTPS_PROXY_USERNAME} = $proxy_username if defined $proxy_username;
            $ENV{HTTPS_PROXY_PASSWORD} = $proxy_password if defined $proxy_password;
        };
    }
    # or do {
    #     print "Error occured during proxy config retrieval: $@\n";
    # };
    if ( "$opts->{AWS_ACCESS_KEY_ID}" eq "" ) {
        mesg( 0, "Access key not found in credential $opts->{config}\n" );
        exit 1;
    }
    mesg( 5, "Found credential $opts->{AWS_ACCESS_KEY_ID}\n" );

    my $config = {
        ServiceURL       => "$opts->{service_url}",
        UserAgent        => "Amazon EC2 Perl Library",
        SignatureVersion => 4,
        SignatureMethod  => "HmacSHA256",
        ProxyHost        => undef,
        ProxyPort        => -1,
        MaxErrorRetry    => 3
    };
    require Amazon::EC2::Client;
    my $service = Amazon::EC2::Client->new( $opts->{AWS_ACCESS_KEY_ID},
        $opts->{AWS_SECRET_ACCESS_KEY}, $config );

    foreach my $op ( keys %{$opts} ) {
        if ( $op eq 'AWS_SECRET_ACCESS_KEY' ) {
            next;
        }
        mesg( 5, "\$opts\-\>\{$op\}=$opts->{$op}\n" );
    }

    # ---------------------------------------------------------------
    # Dispatch operation
    # ---------------------------------------------------------------
    if ( $::gMockData ne false ) {
        $opts->{method} = "MOCK_" . $opts->{method};
    }
    $opts->{method}( $opts, $service );

    exit 0;
}

sub tearDownResource {
    my ($opts) = @_;
    my $ec = ElectricCommander->new();

    mesg( 0, "Starting tearDownResource\n" );

    $::gDebug = 0;

    my $resName = $opts->{resName} . '';
    if ( !$resName ) {
        mesg( 0, "Missing resource name parameter\n" );
    }
    my $instances = getInstancesForTermination( $ec, $resName );
    if ( !@$instances ) {
        mesg( 0, "No resource or resource pool with name '$resName' found for termination. Nothing to do in this case.\n" );

#ECPRESOURCEAMAZON-148:
#This is considered an acceptable condition when this procedure is called for a cleanup
#after an error is encountered during provisioning. We could have failed before the
#resouce itself was created in which case there would be no resource in EC to terminate.
        exit 0;
    }

    my $proj = '@PLUGIN_NAME@';

    if ( substr( $proj, 0, 1 ) eq '@' ) {
        $proj = "EC-EC2-1.0.0.0";
    }

    my $config = '';
    for my $inst (@$instances) {
        my $init = 0;

        # higher priority. If config provided into procedure - it will be used
        if ( $opts->{config} ) {
            $config = $opts->{config};
        }
        elsif ( $inst->{config} ) {
            $config = $inst->{config};
        }
        else {
            mesg( 0,
                "No config presented. Can't tear down $inst->{instance_id}" );
            next;
        }

        # let's try to get config data.

        # set property table to this cfg list
        my $CfgDB =
          ElectricCommander::PropDB->new( $ec, "/projects/$proj/ec2_cfgs" );
        eval {
            $opts->{service_url} = $CfgDB->getCol( "$config", "service_url" );
            $opts->{debug}       = $CfgDB->getCol( "$config", "debug" );
            ( $opts->{AWS_ACCESS_KEY_ID}, $opts->{AWS_SECRET_ACCESS_KEY} ) =
              getCredential("$config");
            $opts->{resourceName} =
              $CfgDB->getCol( "$config", 'resource_pool' );
            $opts->{workspaceName} = $CfgDB->getCol( "$config", 'workspace' );
            1;
        } or do {
            mesg(0, "Can't get information from config provided. Can't terminate $inst->{instance_id}\n");
            next;
        };

        eval {
            $opts->{http_proxy} = $CfgDB->getCol("$config", 'http_proxy');
            if ($opts->{http_proxy}) {
                $ENV{HTTP_PROXY} = $opts->{http_proxy};
                $ENV{HTTPS_PROXY} = $opts->{http_proxy};
                $ENV{FTP_PROXY} = $opts->{http_proxy};
            }
        };
        if ($opts->{http_proxy}) {
            eval {
                my ($proxy_username, $proxy_password) = getCredential($config . '_proxy_credential');
                $ENV{HTTPS_PROXY_USERNAME} = $proxy_username if defined $proxy_username;
                $ENV{HTTPS_PROXY_PASSWORD} = $proxy_password if defined $proxy_password;
            };
        }

        $::gDebug = $opts->{debug};
        $opts->{ec_instance} = $ec;
        $opts->{pdb} = ElectricCommander::PropDB->new( $ec, "" );
        my $config_hash = {
            ServiceURL       => "$opts->{service_url}",
            UserAgent        => "Amazon EC2 Perl Library",
            SignatureVersion => 4,
            SignatureMethod  => "HmacSHA256",
            ProxyHost        => undef,
            ProxyPort        => -1,
            MaxErrorRetry    => 3
        };
        require Amazon::EC2::Client;
        my $service = Amazon::EC2::Client->new( $opts->{AWS_ACCESS_KEY_ID},
            $opts->{AWS_SECRET_ACCESS_KEY}, $config_hash );
        $opts->{resName} = $inst->{resource_name};
        API_TearDownResource( $opts, $service );
    }
    exit 0;
}
########################################
## individual api methods
########################################
sub API_AllocateIP {
    my ( $opts, $service ) = @_;

    my $ip = "";
    my $propResult = getOptionalParam( "propResult", $opts );

    mesg( 1, "--Allocating Amazon EC2 Address -------\n" );

    my $request = new Amazon::EC2::Model::AllocateAddressRequest();
    eval {
        my $response = $service->allocateAddress($request);
        if ( $response->isSetAllocateAddressResult() ) {
            my $result = $response->getAllocateAddressResult();
            if ( $result->isSetPublicIp() ) {
                $ip = $result->getPublicIp();
            }
        }
    };
    if ($@) { throwEC2Error($@); }
    if ( "$ip" eq "" ) {
        mesg( 1, "Error allocating IP address.\n" );
        exit 1;
    }

    mesg( 1, "Address $ip allocated\n" );

    ## store new key in properties
    if ( "$propResult" ne "" ) {
        $opts->{pdb}->setProp( "$propResult/ip", $ip );
    }
    exit 0;
}

sub MOCK_API_AllocateIP {
    my ( $opts, $service ) = @_;

    my $ip = "";
    my $propResult = getOptionalParam( "propResult", $opts );

    mesg( 1, "--Allocating Amazon EC2 Address -------\n" );

    my $r1 = getRandKey(255);
    my $r2 = getRandKey(255);
    $ip = "192.168.$r1.$2";
    $opts->{pdb}->setProp( "$::gMockRegistry/ElasticIPS", $ip );

    mesg( 1, "Address $ip allocated\n" );

    ## store new key in properties
    if ( "$propResult" ne "" ) {
        $opts->{pdb}->setProp( "$propResult/ip", $ip );
    }

    exit 0;
}

sub API_AssociateIP {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Associate Amazon EC2 Address -------\n" );
    my $ip       = getRequiredParam( "ip",       $opts );
    my $instance = getRequiredParam( "instance", $opts );

    require Amazon::EC2::Model::AssociateAddressRequest;

    my $request = new Amazon::EC2::Model::AssociateAddressRequest(
        { "InstanceId" => "$instance", "PublicIp" => "$ip" } );

    # associate address
    eval {
        my $response = $service->associateAddress($request);
        mesg( 3, $response->toXML() . "\n" );
    };
    if ($@) { throwEC2Error($@); }
    mesg( 1, "Address $ip associated with instance $instance\n" );
}

sub MOCK_API_AssociateIP {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Associate Amazon EC2 Address -------\n" );
    my $ip       = getRequiredParam( "ip",       $opts );
    my $instance = getRequiredParam( "instance", $opts );

    $opts->{pdb}->setProp( "$::gMockRegistry/IPAssociations/$ip", $instance );

    mesg( 1, "Address $ip associated with instance $instance\n" );
}

sub API_ReleaseIP {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Releasing Amazon EC2 Address -------\n" );

    # see if an IP was passed in
    my $ip = getRequiredParam( "ip", $opts );

    my $request =
      new Amazon::EC2::Model::ReleaseAddressRequest( { "PublicIp" => "$ip" } );

    eval { my $response = $service->releaseAddress($request); };
    if ($@) { throwEC2Error($@); }

    mesg( 1, "Address $ip released\n" );

    exit 0;
}

sub MOCK_API_ReleaseIP {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Releasing Amazon EC2 Address -------\n" );

    # see if an IP was passed in
    my $ip = getRequiredParam( "ip", $opts );

    # if associated, throw error
    my $instance = $opts->{pdb}->setProp("$::gMockRegistry/IPAssociations/$ip");
    if ( $instance ne "" ) {
        mesg( 1, "Caught Exception: " . "IP address in use\n" );
    }
    else {

        # else remove
        $opts->{pdb}->deleteProp("$::gMockRegistry/ElasticIPS/$ip");
    }

    mesg( 1, "Address $ip released\n" );

    exit 0;
}

sub API_AttachVolume {
    my ( $opts, $service ) = @_;

    mesg( 1, "-- Attach Volumes -------\n" );

    my $instlist1 = getRequiredParam( "instances", $opts );
    my $vollist1  = getRequiredParam( "volumes",   $opts );
    my $device    = getRequiredParam( "device",    $opts );

    my $attachCount = 0;

    my @instlist = split( /;/, $instlist1 );
    my @vollist  = split( /;/, $vollist1 );

    if ( scalar(@vollist) == 0 ) {
        mesg( 1, "--No volumes to attach\n" );
        exit 0;
    }

    # pair instances with volumes in order
    my %vol_id_match;
    my $i = 0;
    foreach (@instlist) {
        my $instance_id = $_;
        $vol_id_match{$instance_id} = @vollist[$i];
        $i++;
    }

    my $done = 0;
    my %doneList;
    while ( !$done ) {
        $done = 1;
        foreach (@instlist) {
            my $instance_id = $_;
            my $vol_id      = $vol_id_match{$instance_id};
            my $status      = "";

            if ( "$vol_id" eq "" ) { next; }

            if ( !$doneList{$vol_id} ) {

                mesg( 1, "Attaching $vol_id to instance $instance_id\n" );

                # check to make sure volume is in available state
                eval {
                    my $request =
                      new Amazon::EC2::Model::DescribeVolumesRequest(
                        { "VolumeId" => "$vol_id" } );
                    my $response = $service->describeVolumes($request);
                    if ( $response->isSetDescribeVolumesResult() ) {
                        my $result  = $response->getDescribeVolumesResult();
                        my $volumes = $result->getVolume();

                        # should only be one row in result
                        foreach (@$volumes) {
                            my $vol = $_;
                            $status = $vol->getStatus();
                        }
                    }
                };
                if ($@) { throwEC2Error($@); }

                mesg( 1, "Volume $vol_id is in state $status\n" );
                if ( "$status" eq "available" ) {

                    ## associate volume to instance
                    mesg( 1, "Trying to attach $vol_id to $instance_id\n" );
                    eval {
                        my $request =
                          new Amazon::EC2::Model::AttachVolumeRequest(
                            {
                                "VolumeId"   => "$vol_id",
                                "InstanceId" => "$instance_id",
                                "Device"     => "$device"
                            }
                          );
                        my $response = $service->attachVolume($request);
                    };
                    if ($@) { throwEC2Error($@); }

                    mesg( 1,
                        "Volume $vol_id attached to instance $instance_id\n" );
                    $doneList{$vol_id} = 1;
                    $attachCount++;
                }
                else {

                    # at least one more to process
                    # If we reset $done outside of this block,
                    # the function will try to add the volume twice.
                    $done = 0;
                }
            }
            else {
                mesg( 1, "Volume $vol_id already attached to $instance_id.\n" );
            }
        }
        sleep(10);
    }

    mesg( 1, "$attachCount volumes were attached to instances.\n" );
    exit 0;
}

sub MOCK_API_AttachVolume {
    my ( $opts, $service ) = @_;

    mesg( 1, "-- Attach Volumes -------\n" );

    my $instlist1 = getRequiredParam( "instances", $opts );
    my $vollist1  = getRequiredParam( "volumes",   $opts );
    my $device    = getRequiredParam( "device",    $opts );

    my $attachCount = 0;

    my @instlist = split( /;/, $instlist1 );
    my @vollist  = split( /;/, $vollist1 );

    if ( scalar(@vollist) == 0 ) {
        mesg( 1, "--No volumes to attach\n" );
        exit 0;
    }

    # pair instances with volumes in order
    my %vol_id_match;
    my $i = 0;
    foreach (@instlist) {
        my $instance_id = $_;
        $vol_id_match{$instance_id} = @vollist[$i];
        $i++;
    }

    my $done = 0;
    my %doneList;
    while ( !$done ) {
        $done = 1;
        foreach (@instlist) {
            my $instance_id = $_;
            my $vol_id      = $vol_id_match{$instance_id};
            my $status      = "";

            if ( "$vol_id" eq "" ) { next; }

            if ( !$doneList{$vol_id} ) {

                # at least one more to process
                $done = 0;

                mesg( 1, "Attaching $vol_id to instance $instance_id\n" );

                $status = "available";

                mesg( 1, "Volume $vol_id is in state $status\n" );
                if ( "$status" eq "available" ) {
                    mesg( 1, "Attaching $vol_id to instance $instance_id\n" );
                    $opts->{pdb}->setProp(
                        "$::gMockRegistry/Instances/$instance_id/volume",
                        "$vol_id" );
                    $opts->{pdb}->setProp(
                        "$::gMockRegistry/Instances/$instance_id/device",
                        "$device" );
                    $opts->{pdb}
                      ->setProp( "$::gMockRegistry/Volumes/$vol_id/instance",
                        $instance_id );

                    mesg( 1,
                        "Volume $vol_id attached to instance $instance_id\n" );
                    $doneList{$vol_id} = 1;
                    $attachCount++;
                }
            }
            else {
                mesg( 1, "Volume $vol_id already attached to $instance_id.\n" );
            }
        }
        sleep(10);
    }

    mesg( 1, "$attachCount volumes were attached to instances.\n" );
    exit 0;
}

sub API_CreateKeyPair {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Creating Amazon EC2 KeyPair -------\n" );
    my $newkeyname = getRequiredParam( "keyname", $opts, 1);
    my $propResult = getOptionalParam( "propResult", $opts );
    my $pem;

    mesg( 1, "Create request...\n" );
    my $request = new Amazon::EC2::Model::CreateKeyPairRequest(
        { "KeyName" => "$newkeyname" } );

    eval {

        #mesg(5, Data::Dumper->Dumper([$request]));
        my $response = $service->createKeyPair($request);
        if ( $response->isSetCreateKeyPairResult() ) {
            my $result = $response->getCreateKeyPairResult();
            if ( $result->isSetKeyPair() ) {
                my $pair = $result->getKeyPair();
                $pem = $pair->getKeyMaterial();
            }
        }
    };
    if ($@) { throwEC2Error($@); }

    ## store new key in properties
    if ( "$propResult" ne "" ) {
        $opts->{pdb}->setProp( $propResult . "/KeyPairId", $newkeyname );
    }

    ## extract private key from results
    my $currentDir = File::Spec->rel2abs(File::Spec->curdir());
    my $keyFileLoc = File::Spec->catfile($currentDir, $newkeyname . ".pem");
    extract_keyfile($keyFileLoc, $pem );
    mesg( 1, "KeyPair $newkeyname created at $keyFileLoc\n" );
    mesg( 1, "You should retrieve the private key file from the job workspace and save it in a secure place.\n" );
    exit 0;
}

sub API_CreateVPC {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Creating Amazon VPC -------\n" );

    my $vpcName = getOptionalParam( "vpcName", $opts );
    my $cidrBlock = getRequiredParam( "cidrBlock", $opts );
    my $propResult = getOptionalParam( "propResult", $opts );
    my $VpcId;
    my $VpcState;

    mesg( 1, "Create request...\n" );
    my $request = new Amazon::EC2::Model::CreateVpcRequest(
        { "CidrBlock" => "$cidrBlock" } );

    eval {

        my $response = $service->createVpc($request);
        if ( $response->isSetCreateVpcResult() ) {
            mesg( 10, "CreateVpcResult\n" );
            my $createVpcResult = $response->getCreateVpcResult();
            if ( $createVpcResult->isSetVpc() ) {

                my $vpc = $createVpcResult->getVpc();
                if ( $vpc->isSetVpcId() ) {
                    mesg( 10, "VpcId\n" );
                    mesg( 10, "    " . $vpc->getVpcId() . "\n" );
                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}
                          ->setProp( $propResult . "/VpcId", $vpc->getVpcId() );
                    }
                    $VpcId = $vpc->getVpcId();
                }
                if ( $vpc->isSetVpcState() ) {
                    mesg( 10, "VpcState\n" );
                    mesg( 10, "    " . $vpc->getVpcState() . "\n" );
                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}->setProp( $propResult . "/VpcState",
                            $vpc->getVpcState() );
                    }
                    $VpcState = $vpc->getVpcState();
                }
                if ( $vpc->isSetCidrBlock() ) {
                    mesg( 10, "CidrBlock\n" );
                    mesg( 10, "    " . $vpc->getCidrBlock() . "\n" );
                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}->setProp( $propResult . "/CidrBlock",
                            $vpc->getCidrBlock() );
                    }
                }
                if ( $vpc->isSetDhcpOptionsId() ) {
                    mesg( 10, "DhcpOptionsId\n" );
                    mesg( 10, "    " . $vpc->getDhcpOptionsId() . "\n" );
                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}->setProp(
                            $propResult . "/DhcpOptionsId",
                            $vpc->getDhcpOptionsId()
                        );
                    }

                }
            }
        }
    };
    if ($@) { throwEC2Error($@); }

    require Amazon::EC2::Model::DescribeVpcsRequest;
    require Amazon::EC2::Model::DescribeVpcsResponse;
    require Amazon::EC2::Model::DescribeVpcsResult;

    if ( $VpcState eq "pending" ) {
        mesg( 1, "Waiting for VPC $VpcId to become available.\n" );
    }

    ## Wait till VPC becomes available
    while ( $VpcState ne "available" || $VpcState eq "" ) {
        if ( $VpcState ne "" ) {
            mesg( 10, "Waiting for 30 sec.\n" );
            sleep(30);
            mesg( 10, "Done waiting\n" );
        }
        eval {

            my $describeRequest = new Amazon::EC2::Model::DescribeVpcsRequest(
                { "VpcId" => "$VpcId" } );
            my $describeVpcResponse = $service->describeVpcs($describeRequest);
            if ( $describeVpcResponse->isSetDescribeVpcsResult() ) {
                my $describeVpcResult =
                  $describeVpcResponse->getDescribeVpcsResult();
                my $vpcList = $describeVpcResult->getVpc();
                my $vpc     = @$vpcList[0];
                if ( $vpc->isSetVpcId() ) {
                    if ( $vpc->getVpcId() eq "$VpcId" ) {

                        if ( $vpc->isSetVpcState() ) {
                            $VpcState = $vpc->getVpcState();
                            mesg( 10,
                                    "Vpc Status for "
                                  . $VpcId . " = "
                                  . $VpcState
                                  . "\n" );
                        }
                    }
                }
            }
        };
        if ($@) { throwEC2Error($@); }

    }
    ## Set the final subnet status in properties
    if ( "$propResult" ne "" ) {
        $opts->{pdb}->setProp( $propResult . "/VpcState", $VpcState );
    }

    mesg( 1, "VPC $VpcId created\n" );
    if ($vpcName) {

        # Assign name to VPC if provided by user
        createTag( $VpcId, "Name", $vpcName, $service );
    }
    exit 0;
}

sub API_CreateSubnet {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Creating subnet -------\n" );

    my $subnetName = getOptionalParam( "subnetName", $opts );
    my $cidrBlock        = getRequiredParam( "cidrBlock",        $opts );
    my $vpcId            = getRequiredParam( "vpcId",            $opts );
    my $availabilityZone = getRequiredParam( "availabilityZone", $opts );
    my $propResult = getOptionalParam( "propResult", $opts );
    my $subnetId = "";
    my $subnetStatus;
    my $createSubnetResult;

    mesg( 1, "Create request...\n" );
    my $request = new Amazon::EC2::Model::CreateSubnetRequest(
        {
            "VpcId"            => "$vpcId",
            "CidrBlock"        => "$cidrBlock",
            "AvailabilityZone" => "$availabilityZone"
        }
    );

    eval {

        my $response = $service->createSubnet($request);

        if ( $response->isSetCreateSubnetResult() ) {

            mesg( 10, "CreateSubnetResult\n" );
            $createSubnetResult = $response->getCreateSubnetResult();
            if ( $createSubnetResult->isSetSubnet() ) {

                my $subnet = $createSubnetResult->getSubnet();

                print("Subnet\n");
                if ( $subnet->isSetSubnetState() ) {
                    $subnetStatus = $subnet->getSubnetState();
                    mesg( 10, "SubnetState\n" );
                    mesg( 10, "    " . $subnet->getSubnetState() . "\n" );
                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}->setProp(
                            $propResult . "/SubnetState",
                            $subnet->getSubnetState()
                        );
                    }

                }

                if ( $subnet->isSetSubnetId() ) {
                    $subnetId = $subnet->getSubnetId();
                    mesg( 10, "SubnetId\n" );
                    mesg( 10, "    " . $subnet->getSubnetId() . "\n" );
                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}->setProp( $propResult . "/SubnetId",
                            $subnet->getSubnetId() );
                    }
                }

                if ( $subnet->isSetVpcId() ) {
                    mesg( 10, "VpcId\n" );
                    mesg( 10, "    " . $subnet->getVpcId() . "\n" );
                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}->setProp( $propResult . "/VpcId",
                            $subnet->getVpcId() );
                    }
                }
                if ( $subnet->isSetCidrBlock() ) {
                    mesg( 10, "CidrBlock\n" );
                    mesg( 10, "    " . $subnet->getCidrBlock() . "\n" );
                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}->setProp(
                            $propResult . "/CidrBlock",
                            $subnet->getCidrBlock()
                        );
                    }
                }
                if ( $subnet->isSetAvailableIpAddressCount() ) {
                    mesg( 10, "AvailableIpAddressCount\n" );
                    mesg( 10,
                        "    " . $subnet->getAvailableIpAddressCount() . "\n" );
                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}->setProp(
                            $propResult . "/AvailableIpAddressCount",
                            $subnet->getAvailableIpAddressCount()
                        );
                    }
                }
                if ( $subnet->isSetAvailabilityZone() ) {
                    mesg( 10, "AvailabilityZone\n" );
                    mesg( 10, "    " . $subnet->getAvailabilityZone() . "\n" );
                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}->setProp(
                            $propResult . "/AvailabilityZone",
                            $subnet->getAvailabilityZone()
                        );
                    }
                }
            }
        }
    };
    if ($@) { throwEC2Error($@); }

    require Amazon::EC2::Model::DescribeSubnetsRequest;
    require Amazon::EC2::Model::DescribeSubnetsResponse;
    require Amazon::EC2::Model::DescribeSubnetsResult;

    if ( $subnetStatus ne "available" || $subnetStatus eq "" ) {
        mesg( 10, "Waiting for subnet to become available\n" );
    }

    ## Wait till subnet becomes available
    while ( $subnetStatus ne "available" || $subnetStatus eq "" ) {
        if ( $subnetStatus ne "" ) {
            mesg( 10, "Waiting for 30 sec.\n" );
            sleep(30);
            mesg( 10, "Done waiting\n" );
        }
        eval {

            my $describeRequest =
              new Amazon::EC2::Model::DescribeSubnetsRequest(
                { "SubnetId" => "$subnetId" } );
            my $describeSubnetResponse =
              $service->describeSubnets($describeRequest);
            if ( $describeSubnetResponse->isSetDescribeSubnetsResult() ) {
                my $describeSubnetsResult =
                  $describeSubnetResponse->getDescribeSubnetsResult();
                my $subnetList = $describeSubnetsResult->getSubnet();
                my $subnet     = @$subnetList[0];
                if ( $subnet->isSetSubnetId() ) {
                    if ( $subnet->getSubnetId() eq "$subnetId" ) {

                        if ( $subnet->isSetSubnetState() ) {
                            $subnetStatus = $subnet->getSubnetState();
                            mesg( 10,
                                    "Subnet Status = "
                                  . $subnetStatus
                                  . " for subnet "
                                  . $subnet->getSubnetId()
                                  . "\n" );
                        }
                    }
                }
            }
        };
        if ($@) { throwEC2Error($@); }
    }

    ## Set the final subnet status in properties
    if ( "$propResult" ne "" ) {
        $opts->{pdb}->setProp( $propResult . "/SubnetState", $subnetStatus );
    }

    mesg( 1, "Subnet with ID $subnetId created\n" );
    if ($subnetName) {
        ## Assign name to subnet if provided by user.
        createTag( $subnetId, "Name", $subnetName, $service );
    }
    exit 0;
}

sub API_DeleteVPC {
    my ( $opts, $service ) = @_;
    my $request;
    my $response;
    my $vpcId = getRequiredParam( "vpcId", $opts );
    my $subnetList;
    my @listOfSubnets;

    ## Get the list of all subnets within VPC.
    my $subnetFilter = new Amazon::EC2::Model::Filter(
        { "Name" => "vpc-id", "Value" => "$vpcId" } );

    require Amazon::EC2::Model::DescribeSubnetsRequest;
    require Amazon::EC2::Model::DescribeSubnetsResponse;
    require Amazon::EC2::Model::DescribeSubnetsResult;

    eval {
        my $describeRequest = new Amazon::EC2::Model::DescribeSubnetsRequest();
        $describeRequest->setFilter($subnetFilter);
        my $describeSubnetResponse =
          $service->describeSubnets($describeRequest);
        if ( $describeSubnetResponse->isSetDescribeSubnetsResult() ) {
            my $describeSubnetsResult =
              $describeSubnetResponse->getDescribeSubnetsResult();
            $subnetList = $describeSubnetsResult->getSubnet();
            foreach $subnet (@$subnetList) {
                if ( $subnet->isSetSubnetId() ) {
                    push @listOfSubnets, $subnet->getSubnetId();
                }
            }
        }
    };
    if ($@) { throwEC2Error($@); }

    foreach $subnet (@listOfSubnets) {

        mesg( 1, "--Deleting subnet $subnet -------\n" );
        $request = new Amazon::EC2::Model::DeleteSubnetRequest(
            { "SubnetId" => "$subnet" } );

        eval {

            $response = $service->deleteSubnet($request);
            if ( $response->isSetResponseMetadata() ) {
                mesg( 1, "ResponseMetadata\n" );
                my $responseMetadata = $response->getResponseMetadata();
                if ( $responseMetadata->isSetRequestId() ) {
                    mesg( 1, "RequestId\n" );
                    mesg( 1,
                            "          "
                          . $responseMetadata->getRequestId()
                          . "\n" );
                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}->setProp(
                            $propResult . "/$subnet/SubnetDeleteRequestId",
                            $responseMetadata->getRequestId() );
                    }
                }
            }
            mesg( 1, "--Deleted subnet $subnet -------\n" );
        };
        if ($@) { throwEC2Error($@); }

    }

    my $propResult = getOptionalParam( "propResult", $opts );

    mesg( 1, "--Deleting VPC $vpcId -------\n" );
    $request =
      new Amazon::EC2::Model::DeleteVpcRequest( { "VpcId" => "$vpcId" } );

    eval {

        $response = $service->deleteVpc($request);
        if ( $response->isSetResponseMetadata() ) {
            mesg( 1, "ResponseMetadata\n" );
            my $responseMetadata = $response->getResponseMetadata();
            if ( $responseMetadata->isSetRequestId() ) {
                mesg( 1, "RequestId\n" );
                mesg( 1,
                    "          " . $responseMetadata->getRequestId() . "\n" );

                if ( "$propResult" ne "" ) {
                    $opts->{pdb}->setProp(
                        $propResult . "/VPCDeleteRequestId",
                        $responseMetadata->getRequestId()
                    );
                }
            }

        }
    };
    if ($@) { throwEC2Error($@); }

    mesg( 1, "VPC $vpcId deleted.\n" );
    exit 0;
}

sub MOCK_API_CreateKeyPair {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Creating Amazon EC2 KeyPair -------\n" );

    my $newkeyname = getRequiredParam( "keyname", $opts );
    my $propResult = getOptionalParam( "propResult", $opts );
    my $pem;

    $pem = "lalalala";
    $opts->{pdb}
      ->setProp( $::gMockRegistry . "/Keypairs/$newkeyname", "created" );

    ## store new key in properties
    if ( "$propResult" ne "" ) {
        $opts->{pdb}->setProp( "$propResult/KeyPairId", $newkeyname );
    }

    ## extract private key from results
    extract_keyfile( $newkeyname . ".pem", $pem );
    mesg( 1, "KeyPair $newkeyname created\n" );
    exit 0;
}

sub API_DeleteKeyPair {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Deleting Amazon EC2 KeyPair -------\n" );

    # see if a key was created for this tag
    my $keynames = getRequiredParam( "keyname", $opts );
    my @keylist = split( /;/, "$keynames" );
    foreach my $keyname (@keylist) {
        my $request = new Amazon::EC2::Model::DeleteKeyPairRequest(
            { "KeyName" => "$keyname" } );

        eval { my $response = $service->deleteKeyPair($request); };
        if ($@) { throwEC2Error($@); }
        mesg( 1, "KeyPair $keyname deleted\n" );
    }
    exit 0;
}

sub MOCK_API_DeleteKeyPair {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Deleting Amazon EC2 KeyPair -------\n" );

    # see if a key was created for this tag
    my $keynames = getRequiredParam( "keyname", $opts );
    my @keylist = split( /;/, "$keynames" );
    foreach my $keyname (@keylist) {
        $opts->{pdb}->deleteProp("$::gMockData/Keypairs/$keyname");
        mesg( 1, "KeyPair $keyname deleted\n" );
    }
    exit 0;
}

sub CreateVolume {
    my ( $opts, $service ) = @_;

    mesg( 1, "-- Create Volume  -------\n" );
    my $snap_id = $opts->{snapshot};
    my $propResult = getRequiredParam( "propResult", $opts );
    if ( "$snap_id" eq "" ) {
        mesg( 0, "No snapshots to process.\n" );
        $opts->{pdb}->setProp( "$propResult/VolumeList", "" );
        exit 0;
    }

    my $propResult = getRequiredParam( "propResult", $opts );
    $opts->{pdb}->setProp( "$propResult/Snapshot", "$snap_id" );

    ## now make a new volume out of the snapshot

    # get list of instances
    my $instListProp = $opts->{pdb}->getProp("$propResult/InstanceList");
    my @instList = split( /;/, $instListProp );

    my %volsCreated;
    my $vollist = "";
    foreach (@instList) {
        my $id     = $_;
        my $newvol = "";
        eval {
            my $actualZone =
              $opts->{pdb}->getProp("$propResult/Instance-$id/Zone");
            mesg( 1, "Creating volume from snapshot in zone $actualZone\n" );

            my $request = new Amazon::EC2::Model::CreateVolumeRequest(
                {
                    "SnapshotId"       => "$snap_id",
                    "AvailabilityZone" => "$actualZone"
                }
            );
            my $response = $service->createVolume($request);

            # get volume id
            if ( $response->isSetCreateVolumeResult() ) {
                $result = $response->getCreateVolumeResult();
                my $vol = $result->getVolume();
                $newvol = $vol->getVolumeId();

                mesg( 1,
"New volume $newvol created from snapshot $snap_id for instance $id\n"
                );
                $opts->{pdb}
                  ->setProp( "$propResult/Instance-$id/NewVolume", $newvol );
                if ( "$vollist" ne "" ) { $vollist .= ";"; }
                $vollist .= $newvol;
                $volsCreated{$newvol} = 1;
            }
        };
        if ($@) { throwEC2Error($@); }
    }

    ## wait for snapshots to be ready
    my $done   = 0;
    my $status = "pending";
    while ( !$done ) {
        $done = 1;
        sleep 10;
        eval {
            mesg( 1, "Waiting for volume $newvol\n" );
            my $request  = new Amazon::EC2::Model::DescribeVolumesRequest();
            my $response = $service->describeVolumes($request);
            if ( $response->isSetDescribeVolumesResult() ) {
                my $result  = $response->getDescribeVolumesResult();
                my $volumes = $result->getVolume();
                foreach (@$volumes) {
                    my $vol = $_;
                    $status = $vol->getStatus();
                    $id     = $vol->getVolumeId;
                    if ( $volsCreated{$id} and $status ne "available" ) {
                        $done = 0;
                    }
                }
            }
        };
        if ($@) { throwEC2Error($@); }
    }
    $opts->{pdb}->setProp( "$propResult/VolumeList", $vollist );
    mesg( 1, "Snapshot $snap_id used to create volumes\n" );
    exit 0;
}

sub MOCK_CreateVolume {
    my ( $opts, $service ) = @_;

    mesg( 1, "-- Create Volume  -------\n" );
    my $snap_id = $opts->{snapshot};
    my $propResult = getRequiredParam( "propResult", $opts );
    if ( "$snap_id" eq "" ) {
        mesg( 0, "No snapshots to process.\n" );
        $opts->{pdb}->setProp( "$propResult/VolumeList", "" );
        exit 0;
    }

    my $propResult = getRequiredParam( "propResult", $opts );
    $opts->{pdb}->setProp( "$propResult/Snapshot", "$snap_id" );

    # get list of instances
    my $instListProp = $opts->{pdb}->getProp("$propResult/InstanceList");
    my @instList = split( /;/, $instListProp );

    my %volsCreated;
    my $vollist = "";
    foreach (@instList) {
        my $id     = $_;
        my $v      = getRandKey(9999999);
        my $newvol = "vol-$v";
        mesg( 1,
"New volume $newvol created from snapshot $snap_id for instance $id\n"
        );
        $opts->{pdb}->setProp( "$propResult/Instance-$id/NewVolume", $newvol );

        $opts->{pdb}
          ->setProp( "$::gMockRegistry/Volumes/$newvol/state", "created" );
        if ( "$vollist" ne "" ) { $vollist .= ";"; }
        $vollist .= $newvol;
    }
    $opts->{pdb}->setProp( "$propResult/VolumeList", $vollist );
    mesg( 1, "Snapshot $snap_id used to create volumes\n" );
    exit 0;
}

sub SnapVolume {
    my ( $opts, $service ) = @_;

    mesg( 1, "-- Snapping Volume -------\n" );

    my $vol        = getRequiredParam( "volume",     $opts );
    my $instance   = getRequiredParam( "instance",   $opts );
    my $propResult = getRequiredParam( "propResult", $opts );
    my $snap_id    = "";

    if ( "$vol" eq "" ) {
        mesg( 0, "Volume parameter is blank.\n" );
        exit 0;
    }
    if ( "$instance" eq "" ) {
        mesg( 0, "Instance parameter is blank.\n" );
        exit 0;
    }

    ## double check that the volume is attached to the instance
    eval {
        my $request = new Amazon::EC2::Model::DescribeVolumesRequest(
            { "VolumeId" => "$vol" } );
        my $response = $service->describeVolumes($request);
        if ( $response->isSetDescribeVolumesResult() ) {
            my $result  = $response->getDescribeVolumesResult();
            my $volumes = $result->getVolume();

            # should only be one row in result
            foreach (@$volumes) {
                my $volume      = $_;
                my $attachments = $volume->getAttachment();
                foreach (@$attachments) {
                    my $attach = $_;
                    my $id     = $attach->getInstanceId();
                    if ( "$id" ne "$instance" ) {
                        mesg( 0,
"Volume $vol was not attached to instance $instance ($id).\n"
                        );
                        exit 1;
                    }
                }
            }
        }
    };
    if ($@) { throwEC2Error($@); }

    ## create a snapshot from volume
    eval {
        my $request = new Amazon::EC2::Model::CreateSnapshotRequest(
            { "VolumeId" => "$vol" } );
        my $response = $service->createSnapshot($request);
        if ( $response->isSetCreateSnapshotResult() ) {
            my $result   = $response->getCreateSnapshotResult();
            my $snapshot = $result->getSnapshot();
            $snap_id = $snapshot->getSnapshotId();
        }
    };
    if ($@) { throwEC2Error($@); }
    mesg( 1, "Created new snapshot $snap_id\n" );

    # return new snapid
    $opts->{pdb}->setProp( "$propResult/NewSnapshot", $snap_id );
    exit 0;
}

sub MOCK_SnapVolume {
    my ( $opts, $service ) = @_;

    mesg( 1, "-- Snapping Volume -------\n" );

    my $vol        = getRequiredParam( "volume",     $opts );
    my $instance   = getRequiredParam( "instance",   $opts );
    my $propResult = getRequiredParam( "propResult", $opts );
    my $snap_id    = "";

    if ( "$vol" eq "" ) {
        mesg( 0, "Volume parameter is blank.\n" );
        exit 0;
    }
    if ( "$instance" eq "" ) {
        mesg( 0, "Instance parameter is blank.\n" );
        exit 0;
    }

    my $r = getRandKey(9999999);
    $snap_id = "snap-$r";
    $opts->{pdb}->setProp( "$::gMockRegistry/Snapshots/$snap_id", "created" );
    mesg( 1, "Created new snapshot $snap_id\n" );

    # return new snapid
    $opts->{pdb}->setProp( "$propResult/NewSnapshot", $snap_id );
    exit 0;
}

sub _DescribeInstance {
    my ($service, $resultHash, $instanceName, $filter) = @_;

    my $instance = {};

    if(defined $instanceName) {
        mesg( 2, " describing $instanceName\n" );
        $instance = { "InstanceId" => $instanceName };
    }

    eval {
        my $request = new Amazon::EC2::Model::DescribeInstancesRequest($instance);
        if(defined $filter) {
            my $describeInstancesFilter = new Amazon::EC2::Model::Filter($filter);
            $request->setFilter($describeInstancesFilter);
        }

        my $response = $service->describeInstances($request);

        if ( $response->isSetDescribeInstancesResult() ) {
            my $result  = $response->getDescribeInstancesResult();
            my $resList = $result->getReservation();

            foreach my $res (@$resList) {
                my $instanceList = $res->getRunningInstance();
                foreach my $instance (@$instanceList) {
                            my $stateObj = $instance->getInstanceState();
                            $resultHash->{$instance->getInstanceId()} = {};
                            my $instanceHash = $resultHash->{$instance->getInstanceId()};
                             $instanceHash->{state} = $stateObj->getName();
                               $instanceHash->{image} = $instance->getImageId();
                            $instanceHash->{prvdns} = ref $instance->getPrivateDnsName() eq ref {} ? "" : $instance->getPrivateDnsName();
                            $instanceHash->{pubdns} = ref $instance->getPublicDnsName() eq ref {} ? "" : $instance->getPublicDnsName();
                            $instanceHash->{key} = $instance->getKeyName();
                            $instanceHash->{type} = $instance->getInstanceType();
                            $instanceHash->{launch} = $instance->getLaunchTime();
                            my $placement = $instance->getPlacement();
                            $instanceHash->{zone} = $placement->getAvailabilityZone();
                        }
            }
        }
    };

    # dont die on error...
    if ($@) {
        require Amazon::EC2::Exception;
        if ( ref $@ eq "Amazon::EC2::Exception" ) {
            mesg( 1, "Caught Exception: " . $@->getMessage() . "\n" );
            mesg( 1, "Response Status Code: " . $@->getStatusCode() . "\n" );
            mesg( 1, "Error Code: " . $@->getErrorCode() . "\n" );
            mesg( 1, "Error Type: " . $@->getErrorType() . "\n" );
            mesg( 1, "Request ID: " . $@->getRequestId() . "\n" );
            mesg( 1, "XML: " . $@->getXML() . "\n" );
        }
        else {
            mesg( 0, "An error occurred:\n" );
            mesg( 0, "$@\n" );
        }

        if(defined $instanceName) {
            # send back results that it is stopped
            $resultHash->{$instanceName}{state} = "stopped";
        }
    }
}

sub API_DescribeInstances {
    my ( $opts, $service ) = @_;

    mesg( 1, "-- Describe Instances -------\n" );

    # possible states
    #   pending
    #   running
    #   shutting-down
    #   terminated
    #   stopping
    #   stopped
    #
    # answer will be in form $resultHash->{instance} = state;
    my $resultHash = {};

    # instances can be of 2 forms
    # 1-  a single instance i-1232
    # 2 - a list of instances i-1232;i-4566
    my $reservation = getOptionalParam( "instances", $opts );
    my $propResult = getOptionalParam( "propResult", $opts );

    @instances = split( /;/, $reservation );
    mesg( 1, " found " . scalar(@instances) . " in instance list $reservation\n" );

    if(scalar(@instances) > 0) {
        foreach my $instanceName (@instances) {
            _DescribeInstance($service, $resultHash, $instanceName);
        }
    } else {
        _DescribeInstance($service, $resultHash);
    }

    my $xml = "<DescribeResponse>\n";
    foreach my $i ( keys %{$resultHash} ) {
        $xml .= "  <instance>\n";
        $xml .= "    <id>$i</id>\n";
        foreach my $p ( keys %{ $resultHash->{$i} } ) {
            $xml .= "    <$p>" . $resultHash->{$i}{$p} . "</$p>\n";
        }
        $xml .= "  </instance>\n";
    }
    $xml .= "</DescribeResponse>\n";
    if ( !$propResult ) {
        mesg( 0, "$xml" );
    }
    else {
        $opts->{pdb}->setProp( "$propResult/describe", $xml );
    }

}

sub MOCK_API_DescribeInstances {
    my ( $opts, $service ) = @_;

    mesg( 1, "-- Describe Instances -------\n" );

    # possible states
    #   pending
    #   running
    #   shutting-down
    #   terminated
    #   stopping
    #   stopped
    #
    # answer will be in form $resultHash->{instance} = state;
    my $resultHash;

    # instances can be of 2 forms
    # 1-  a single instance i-1232
    # 2 - a list of instances i-1232;i-4566
    my $reservation = getRequiredParam( "instances", $opts );
    my $propResult = getOptionalParam( "propResult", $opts );

    @instances = split( /;/, $reservation );
    mesg( 1,
        " found " . scalar(@instances) . " in instance list $reservation\n" );

    foreach my $instanceName (@instances) {
        mesg( 2, " describing $instanceName\n" );
        $resultHash->{$instanceName}{state} =
          $opts->{pdb}
          ->getProp("$::gMockRegistry/Instances/$instanceName/state");
        if ( $resultHash->{$instanceName}{state} eq "" ) {
            $resultHash->{$instanceName}{state} = "terminated";
        }
        $resultHash->{$instanceName}{image} =
          $opts->{pdb}
          ->getProp("$::gMockRegistry/Instances/$instanceName/image");
        $resultHash->{$instanceName}{pvrdns} =
          $opts->{pdb}
          ->getProp("$::gMockRegistry/Instances/$instanceName/pvrdns");
        $resultHash->{$instanceName}{pubdns} =
          $opts->{pdb}
          ->getProp("$::gMockRegistry/Instances/$instanceName/pubdns");
        $resultHash->{$instanceName}{key} =
          $opts->{pdb}->getProp("$::gMockRegistry/Instances/$instanceName/key");
        $resultHash->{$instanceName}{type} =
          $opts->{pdb}
          ->getProp("$::gMockRegistry/Instances/$instanceName/type");
        $resultHash->{$instanceName}{launch} =
          $opts->{pdb}
          ->getProp("$::gMockRegistry/Instances/$instanceName/launch");
        $resultHash->{$instanceName}{zone} =
          $opts->{pdb}
          ->getProp("$::gMockRegistry/Instances/$instanceName/zone");
        $resultHash->{$instanceName}{volue} =
          $opts->{pdb}
          ->getProp("$::gMockRegistry/Instances/$instanceName/volume");
    }
    my $xml = "<DescribeResponse>";
    foreach my $i ( keys %{$resultHash} ) {
        $xml .= "  <instance>\n";
        $xml .= "    <id>$i</id>\n";
        foreach my $p ( keys %{ $resultHash->{$i} } ) {
            $xml .= "    <$p>" . $resultHash->{$i}{$p} . "</$p>\n";
        }
        $xml .= "  </instance>\n";
    }
    $xml .= "</DescribeResponse>\n";
    if ( !$propResult ) {
        mesg( 0, "$xml" );
    }
    else {
        $opts->{pdb}->setProp( "$propResult/describe", $xml );
    }
}

sub API_DeleteVol {
    my ( $opts, $service ) = @_;

    mesg( 1, "-- Delete Dynamic Volume -------\n" );

    my $volumes = $opts->{volumes};
    my @volumeList = split( /;/, "$volumes" );
    if ( @volumeList == 0 ) {
        mesg( 1, "No volumes to delete.\n" );
        exit 0;
    }

    my $detachOnly = getRequiredParam( "detachOnly", $opts );

    my $delCount = 0;
    my $detCount = 0;

    foreach (@volumeList) {
        my $vol_id = $_;

        mesg( 1, "Deleting Volume $vol_id\n" );

        # loop until volume available
        # either it completes or the step times out...
        my $status = "";
        while (1) {
            eval {
                my $request = new Amazon::EC2::Model::DescribeVolumesRequest(
                    { "VolumeId" => "$vol_id" } );
                my $response = $service->describeVolumes($request);
                if ( $response->isSetDescribeVolumesResult() ) {
                    my $result  = $response->getDescribeVolumesResult();
                    my $volumes = $result->getVolume();

                    # should only be one row in result
                    foreach (@$volumes) {
                        my $vol = $_;
                        $status = $vol->getStatus();
                    }
                }
            };
            if ($@) { throwEC2Error($@); }
            mesg( 1, "Found status=[$status]\n" );
            if ( $status eq "available" ) {
                last;
            }
            if ( $status eq "terminated" or $status eq "deleting" ) {
                mesg( 1, "Error detaching volume $vol_id\n" );
                exit 1;
            }
            if ( $status eq "in-use" ) {
                mesg( 1, "Trying to detach $vol_id\n" );
                eval {
                    my $request = new Amazon::EC2::Model::DetachVolumeRequest(
                        { "VolumeId" => "$vol_id" } );
                    my $response = $service->detachVolume($request);
                };
                if ($@) {
                    throwEC2Error($@);
                    $status = "busy";
                }
                $detCount++;
                mesg( 1, "Volume $vol_id detached\n" );
            }
            mesg( 1, "Waiting for volume $vol_id to be in available state\n" );
            sleep 10;
        }
        if ( !$detachOnly ) {
            ## delete volume
            eval {
                mesg( 1, "Deleting volume $vol_id\n" );
                my $request = new Amazon::EC2::Model::DeleteVolumeRequest(
                    { "VolumeId" => "$vol_id" } );
                my $response = $service->deleteVolume($request);
            };
            if ($@) { throwEC2Error($@); }
            mesg( 1, "Volume $vol_id deleted\n" );
            $delCount++;
        }

    }

    if ( !$detachOnly ) {
        mesg( 1, "$delCount volumes deleted.\n" );
    }
    else {
        mesg( 1, "$detCount volumes detached.\n" );
    }
    exit 0;
}

sub MOCK_API_DeleteVol {
    my ( $opts, $service ) = @_;

    mesg( 1, "-- Delete Dynamic Volume -------\n" );

    my $volumes = $opts->{volumes};
    my @volumeList = split( /;/, "$volumes" );
    if ( @volumeList == 0 ) {
        mesg( 1, "No volumes to delete.\n" );
        exit 0;
    }

    my $detachOnly = getRequiredParam( "detachOnly", $opts );

    my $delCount = 0;
    my $detCount = 0;

    foreach (@volumeList) {
        my $vol_id = $_;

        mesg( 1, "Deleting Volume $vol_id\n" );

        # if volume attached
        my $instance =
          $opts->{pdb}->getProp("$::gMockRegistry/Volumes/$vol_id/instance");

        if ( $instance ne "" ) {
            mesg( 1, "Trying to detach $vol_id\n" );
            $opts->{pdb}
              ->setProp( "$::gMockRegistry/Volumes/$vol_id/instance", "" );
            $opts->{pdb}
              ->setProp( "$::gMockRegistry/Instances/$instance/volume", "" );
            $detCount++;
            mesg( 1, "Volume $vol_id detached\n" );
        }

        if ( !$detachOnly ) {
            ## delete volume
            $opts->{pdb}->delRow("$::gMockRegistry/Volumes/$vol_id");
            mesg( 1, "Volume $vol_id deleted\n" );
            $delCount++;
        }

    }

    if ( !$detachOnly ) {
        mesg( 1, "$delCount volumes deleted.\n" );
    }
    else {
        mesg( 1, "$detCount volumes detached.\n" );
    }
    exit 0;
}

sub API_Start {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Start Amazon EC2 Instance -------\n" );

    my $instance = getRequiredParam( "instance", $opts );

    ## start EBS instance

    mesg( 1, "Starting instance\n" );

    eval {

        my $request = new Amazon::EC2::Model::StartInstancesRequest(
            { "InstanceId" => "$instance", } );
        my $response = $service->startInstances($request);
    };
    if ($@) { throwEC2Error($@); }
    exit 0;
}

sub MOCK_API_Start {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Start Amazon EC2 Instance -------\n" );

    my $instance = getRequiredParam( "instance", $opts );

    ## start EBS instance

    mesg( 1, "Starting instance\n" );

    $opts->{pdb}
      ->setProp( "$::gMockRegistry/Instances/$instance/state", "running" );
    exit 0;
}

sub API_Stop {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Stop Amazon EC2 Instance -------\n" );

    my $instance = getRequiredParam( "instance", $opts );

    ## stop EBS instance

    mesg( 1, "Stopping instance\n" );

    eval {

        my $request = new Amazon::EC2::Model::StopInstancesRequest(
            { "InstanceId" => "$instance", } );
        my $response = $service->stopInstances($request);
    };
    if ($@) { throwEC2Error($@); }
    exit 0;

}

sub MOCK_API_Stop {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Stop Amazon EC2 Instance -------\n" );

    my $instance = getRequiredParam( "instance", $opts );

    ## stop EBS instance
    mesg( 1, "Stopping instance\n" );

    $opts->{pdb}
      ->setProp( "$::gMockRegistry/Instances/$instance/state", "stopped" );
    exit 0;
}

sub _wait_for_instance_termination {

    my ($list, $service)  = @_;
    my $terminated = 0;         # instances terminated till now
    my $total   = @list;        # total number of instance to terminate
    my $instanceState = "";     # initial state of an instance

     foreach (@$list) {
         my $instanceId = $_;
            while($instanceState ne "terminated"){
                eval {
                    my $request = new Amazon::EC2::Model::DescribeInstancesRequest(
                        { "InstanceId" => "$instanceId" } );
                    my $response = $service->describeInstances($request);

                    if ( $response->isSetDescribeInstancesResult() ) {
                        my $result  = $response->getDescribeInstancesResult();
                        my $resList = $result->getReservation();
                        foreach (@$resList) {
                            my $res   = $_;
                            $instanceList = $res->getRunningInstance();
                            foreach (@$instanceList) {
                                my $instance = $_;
                                my $id       = $instance->getInstanceId();
                                if ( "$id" ne "$instanceId" ) { next; }
                                my $stateObj = $instance->getInstanceState();
                                $instanceState   = $stateObj->getName();
                                mesg( 1, "Evaluating instance $id in state $instanceState\n" );
                                $total += 1;
                                if ( "$instanceState" eq "terminated" )
                                {
                                    $terminated += 1;
                                } else {
                                    # Wait for some time and check the state again
                                    sleep(30);
                                }
                            }
                        }
                    }
                };if ($@) { throwEC2Error($@); }

            } # end of while
            # Instance terminated successfully, reset the flag for next instance in the list.
            $instanceState = "";
    } # end of instance list

    return $terminated;
}

sub _terminate_instance {
    my ( $instanceId, $service ) = @_;

    my ( $request, $response );
    eval {
        $request = new Amazon::EC2::Model::TerminateInstancesRequest(
            { "InstanceId" => "$instanceId" } );
        $response = $service->terminateInstances($request);
        my @list = ( $instanceId );
        _wait_for_instance_termination(\@list, $service);
        1;
    } or do {
        mesg( 1, "Can't terminate instance $instance_id :" . Dumper $@ . "\n" );
        return 0;
    };
    return 1;
}

sub API_TerminateInstances {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Terminate Amazon EC2 Instance -------\n" );
    my $id = getRequiredParam( "id", $opts );
    my $resources = getOptionalParam( "resources", $opts );

    ## terminate instance
    my $termCount = 0;
    my $terminated;
    my @list = getInstanceList( $id, $service );
    foreach (@list) {
        my $id = $_;

        mesg( 1, "Terminating instance $id\n" );
        eval {
            my $request = new Amazon::EC2::Model::TerminateInstancesRequest(
                { "InstanceId" => "$id" } );
            my $response = $service->terminateInstances($request);
        };
        if ($@) { throwEC2Error($@); }
        $termCount++;
    }

    $terminated = _wait_for_instance_termination(\@list, $service);
    mesg( 1, "$terminated instances terminated.\n" );

    mesg( 1, "Deleting resources.\n" );
    my @rlist = split( /;/, $resources );
    foreach my $r (@rlist) {
        deleteResource( $opts, $r );
    }
    exit 0;
}

sub MOCK_API_TerminateInstances {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Terminate Amazon EC2 Instance -------\n" );
    my $id = getRequiredParam( "id", $opts );
    my $resources = getOptionalParam( "resources", $opts );

    ## terminate instance
    my $termCount = 0;
    my @list = getInstanceList( $id, $service );
    foreach (@list) {
        my $id = $_;
        mesg( 1, "Terminating instance $id\n" );
        $opts->{pdb}
          ->setProp( "$::gMockRegistry/Instances/$id/state", "terminated" );
        $termCount++;
    }
    mesg( 1, "$termCount instances terminated.\n" );

    mesg( 1, "Deleting resources.\n" );
    my @rlist = split( /;/, $resources );
    foreach my $r (@rlist) {
        deleteResource( $opts, $r );
    }
    exit 0;
}

sub API_TearDownResource {
    my ( $opts, $service ) = @_;

    my $ec = $opts->{ec_instance};
    my $resource_name = getRequiredParam( 'resName', $opts );
    my $resource_value;

    eval {
        $resource_value = $ec->getResource($resource_name);
        1;
    } or do {
        mesg( 1, "Error occured: $@\n" );
        mesg( 1, "Can't find resource $resource_name\n" );
        return 0;
    };

    if ( !$resource_value ) {
        mesg( 1, "No such resource: $resource_name\n" );
        return 0;
    }

    my ( $createdBy, $instance_id, $config_name );
    $p_path = "/resources/$resource_name/ec_cloud_instance_details";
    eval {
        $createdBy =
          $ec->getProperty("$p_path/createdBy")->findvalue('//value')
          ->string_value;
        $instance_id =
          $ec->getProperty("$p_path/instance_id")->findvalue('//value')
          ->string_value;
        $config_name =
          $ec->getProperty("$p_path/config")->findvalue('//value')
          ->string_value;
        1;
    } or do {
        mesg( 1,
            "Can't destroy instance, which was created by another plugin.\n" );
        return 0;
    };

    if ( !$instance_id || !$createdBy || $createdBy ne 'EC-EC2' ) {
        mesg( 1, "Can't terminate resource $resource_name\n" );
        return 0;
    }
    if ( !_terminate_instance( $instance_id, $service ) ) {
        mesg( 1, "Can't terminate instance\n" );
        return 0;
    }
    mesg( 1,
"Terminating resource: $resource_name, created by $createdBy with id: $instance_id\n"
    );

    $ec->deleteResource($resource_name);
    return 1;
}

#
# Instance list can be in one of three forms:
#    reservation of the form r-xxxxxx
#    instance of the form i-xxxxx
#    instance list of the form i-xxxx;i-xxxxx;i-xxxxxx
#
sub getInstanceList($$) {
    my ( $resIn, $service ) = @_;

    my @list;

# if first letter of id is "r" then we want to terminate all instances of reservation.
# If the first letter is "i" then we only want to terminate a specific instance or list of instances
    if ( $resIn =~ m/i-/ ) {
        @list = split( /;/, $resIn );
        return @list;
    }

    # otherwise make a list of each instance in the reservation
    eval {
        my $reservationFilter = new Amazon::EC2::Model::Filter({ "Name" => "reservation-id", "Value" => $resIn } );
        my $request = new Amazon::EC2::Model::DescribeInstancesRequest();
        $request->setFilter($reservationFilter);
        my $response = $service->describeInstances($request);

        if ( $response->isSetDescribeInstancesResult() ) {
            my $result  = $response->getDescribeInstancesResult();
            my $resList = $result->getReservation();
            foreach (@$resList) {
                my $res   = $_;
                my $resId = $res->getReservationId();

                # if instance not in reservation
                if ( "$resId" ne "$resIn" ) { next; }
                $instanceList = $res->getRunningInstance();
                foreach (@$instanceList) {
                    my $instance = $_;
                    my $id       = $instance->getInstanceId();
                    push( @list, $id );
                }
            }
        }
    };
    if ($@) { throwEC2Error($@); }
    return @list;
}

#
# Instance list can be in one of three forms:
#    reservation of the form r-xxxxxx
#    instance of the form i-xxxxx
#    instance list of the form i-xxxx;i-xxxxx;i-xxxxxx
#
sub MOCK_getInstanceList($$) {
    my ( $resIn, $service ) = @_;

    my @list;

# if first letter of id is "r" then we want to terminate all instances of reservation.
# If the first letter is "i" then we only want to terminate a specific instance or list of instances
    if ( $resIn =~ m/i-/ ) {
        @list = split( /;/, $resIn );
        return @list;
    }

    print "Mock Data mode does not support reservations...\n";
    exit 1;
}

sub DeregisterInstance {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Deregister Amazon EC2 Windows Instance -------\n" );

    my $ami = getRequiredParam( "ami", $opts );

    my $request =
      new Amazon::EC2::Model::DeregisterImageRequest( { "ImageId" => "$ami" } );

    eval { my $response = $service->deregisterImage($request); };
    if ($@) { throwEC2Error($@); }
    mesg( 1, "AMI $ami deregistered.\n" );
    exit 0;
}

sub MOCK_DeregisterInstance {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Deregister Amazon EC2 Windows Instance -------\n" );

    my $ami = getRequiredParam( "ami", $opts );
    $opts->{pdb}->delRow("$::gMockRegistry/Images/$ami");

    mesg( 1, "AMI $ami deregistered.\n" );
    exit 0;
}

sub CreateImage {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Create EBS Image from existing EBS image -------\n" );

    my $instance   = getRequiredParam( "instance",   $opts );
    my $name       = getRequiredParam( "name",       $opts );
    my $desc       = getRequiredParam( "desc",       $opts );
    my $noreboot   = getRequiredParam( "noreboot",   $opts );
    my $propResult = getRequiredParam( "propResult", $opts );
    my $newami     = "";

    my $request = new Amazon::EC2::Model::CreateImageRequest(
        {
            "InstanceId"  => "$instance",
            "Name"        => "$name",
            "Description" => "$desc",
            "NoReboot"    => "$noreboot"
        }
    );

    eval {
        my $response = $service->createImage($request);
        if ( $response->isSetCreateImageResult() ) {
            my $result = $response->getCreateImageResult();
            $newami = $result->getImageId();
        }
    };
    if ($@) { throwEC2Error($@); }
    mesg( 1, "CreateImage returned new AMI=$newami\n" );

    # loop until new instance has been created
    require Amazon::EC2::Model::DescribeImagesRequest;
    require Amazon::EC2::Model::DescribeImagesResponse;
    require Amazon::EC2::Model::DescribeImagesResult;

    my $state = "";
    while ( "$state" eq "pending" || "$state" eq "" ) {
        if ( "$state" ne "" ) {
            sleep(30);
        }
        eval {
            my $request = new Amazon::EC2::Model::DescribeImagesRequest(
                { "ImageId" => "$newami" } );
            my $response = $service->describeImages($request);

            if ( $response->isSetResponseMetadata() ) {
                my $responseMetadata = $response->getResponseMetadata();
            }
            if ( $response->isSetDescribeImagesResult() ) {
                my $describeImagesResult = $response->getDescribeImagesResult();
                my $imageList            = $describeImagesResult->getImage();
                foreach (@$imageList) {
                    my $image = $_;
                    $state = $image->getImageState();
                }
            }
        };
        if ($@) { throwEC2Error($@); }
        mesg( 1, "AMI $newami state is $state\n" );
    }
    mesg( 1, "Image $newami created.\n" );
    $opts->{pdb}->setProp( "$propResult/NewAMI",  $newami );
    $opts->{pdb}->setProp( "$propResult/NewName", $name );
    exit 0;
}

sub MOCK_CreateImage {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Create EBS Image from existing EBS image -------\n" );

    my $instance   = getRequiredParam( "instance",   $opts );
    my $name       = getRequiredParam( "name",       $opts );
    my $desc       = getRequiredParam( "desc",       $opts );
    my $noreboot   = getRequiredParam( "noreboot",   $opts );
    my $propResult = getRequiredParam( "propResult", $opts );
    my $newami     = "";

    my $r = getRandKey(999999);
    $newami = "ami-$r";
    $opts->{pdb}->setProp( "$::gMockRegistry/Images/$newami", "created" );
    mesg( 1, "Image $newami created.\n" );
    $opts->{pdb}->setProp( "$propResult/NewAMI",  $newami );
    $opts->{pdb}->setProp( "$propResult/NewName", $name );
    exit 0;
}

sub _getInstancesLimit {
    my ($service) = @_;
    my $maxInstances = 50; # Setup reasonable default in case of error

    eval {
        $request = new Amazon::EC2::Model::DescribeAccountAttributesRequest({ "AttributeName" => "max-instances" });
        my $response = $service->describeAccountAttributes($request);

        # get instances limit
        if ( $response->isSetDescribeAccountAttributesResult() ) {
            my $result = $response->getDescribeAccountAttributesResult();
            my $attribute = $result->getAccountAttribute()->[0];
            $maxInstances = $attribute->getAttributeValue()->[0];
        }
    };

    # dont die on error, use predefined limit
    if ($@) {
        require Amazon::EC2::Exception;
        if ( ref $@ eq "Amazon::EC2::Exception" ) {
            mesg( 1, "Caught Exception: " . $@->getMessage() . "\n" );
            mesg( 1, "Response Status Code: " . $@->getStatusCode() . "\n" );
            mesg( 1, "Error Code: " . $@->getErrorCode() . "\n" );
            mesg( 1, "Error Type: " . $@->getErrorType() . "\n" );
            mesg( 1, "Request ID: " . $@->getRequestId() . "\n" );
            mesg( 1, "XML: " . $@->getXML() . "\n" );
        }
        else {
            mesg( 0, "An error occurred:\n" );
            mesg( 0, "$@\n" );
        }
    }

	return scalar($maxInstances);
}

sub _getAvailableIpAddressCount {
    my ($service, $subnet_id) = @_;
    my $ipCount = 0;

    eval {
        $request = new Amazon::EC2::Model::DescribeSubnetsRequest({ "SubnetId" => $subnet_id });
        my $response = $service->describeSubnets($request);

        # get available IP count
        if ( $response->isSetDescribeSubnetsResult() ) {
            my $result = $response->getDescribeSubnetsResult();
            my $subnet = $result->getSubnet()->[0];
            $ipCount = $subnet->getAvailableIpAddressCount();
        }
    };
    if ($@) { throwEC2Error($@); }

    return $ipCount;
}

sub API_RunInstance {
    my ( $opts, $service ) = @_;
    my $request;


    mesg( 1, "--Run Amazon EC2 Instances -------\n" );

    my $ami          = getRequiredParam( "image",        $opts );
    my $key          = getRequiredParam( "keyname",      $opts );
    my $instanceType = getRequiredParam( "instanceType", $opts );
    my $zone         = getRequiredParam( "zone",         $opts );
    my $count        = getRequiredParam( "count",        $opts );

    my $group     = getOptionalParam( "group",        $opts );
    my $poolName  = getOptionalParam( "res_poolName", $opts );
    my $privateIp = getOptionalParam( "privateIp",    $opts );
    my $resource_zone = getOptionalParam( "resource_zone", $opts );
    my $instanceInitiatedShutdownBehavior = getOptionalParam( "instanceInitiatedShutdownBehavior", $opts );
    my $iamProfile   = getOptionalParam( "iamProfileName",        $opts );

    my $propResult = getPropResultLocationForPool( $opts, $poolName );

    my $workspace = getOptionalParam( "res_workspace", $opts );
    my $port      = getOptionalParam( "res_port",      $opts );
    my $subnet_id = getOptionalParam( "subnet_id", $opts );
    my $use_private_ip = '';

    # now use_private_ip depends on subnet_id
    if ($subnet_id) {
        $use_private_ip = getOptionalParam( 'use_private_ip', $opts );
    }

    my $ec = $opts->{ec_instance};
    my $userData = getOptionalParam( "userData", $opts );
    if ( "$userData" eq "" ) {
        $userData = MIME::Base64::encode_base64("none");
    }
    else {
        $userData = MIME::Base64::encode_base64("$userData");
    }

    my $tenancy = getOptionalParam("tenancy", $opts);

    # Get instances limit count for EC2 account
    my $limit = _getInstancesLimit($service);

    # Get running instances count
    my $instances = {};
    _DescribeInstance($service, $instances, undef, {'Name' => 'instance-state-name', 'Value' => 'running'});
    my $instancesCount = scalar values %$instances;

    mesg(1, "Running instances count: $instancesCount, max instances: $limit\n");

    $limit -= $instancesCount;
    if($limit < $count) {
        mesg(1, "Error: Requested instances count is more than available ($limit), bailing out\n");
        exit 1;
    }

    my $ipCount = 0;

    if(length($subnet_id)) {
        $ipCount = _getAvailableIpAddressCount($service, $subnet_id);
        mesg(1, "Subnet $subnet_id available IP count: $ipCount\n");
    }

    if($ipCount != 0 && $ipCount < $count && length($poolName)) {
        mesg(1, "Error: Requested instances count for pool $poolName is more than available IP count for subnet $subnet_id , bailing out\n");
        exit 1;
    }

    mesg(1, "Running $count instance(s) of $ami in zone $zone as type $instanceType with group $group\n");

    ## run new instance
    my $reservation = "";
    my $placement   = new Amazon::EC2::Model::Placement();
    $placement->setAvailabilityZone($zone);
    if ($tenancy) {
        $placement->setTenancy($tenancy);
    }

    my %requestParameters = (
        "ImageId"      => "$ami",
        "Placement"    => $placement,
        "MinCount"     => "$count",
        "MaxCount"     => "$count",
        "KeyName"      => "$key",
        "InstanceType" => "$instanceType",
        "UserData"     => "$userData"
    );

    ## Add optional agruments
    if ($group) {
        $requestParameters{"SecurityGroup"} = "$group";
    }
    if ($subnet_id) {
        $requestParameters{"SubnetId"} = "$subnet_id";
    }
    if ($instanceInitiatedShutdownBehavior) {
        $requestParameters{"InstanceInitiatedShutdownBehavior"} =
          "$instanceInitiatedShutdownBehavior";
    }
    if ($privateIp) {
        $requestParameters{"PrivateIpAddress"} = "$privateIp";
    }

    eval {
        $request = Amazon::EC2::Model::RunInstancesRequest->new(\%requestParameters);
        $request->setPlacement($placement);
        if (defined $iamProfile && $iamProfile ne ''){
           $request->withIamInstanceProfile($iamProfile);
        }

        my $response = $service->runInstances($request);

        # get reservation
        if ( $response->isSetRunInstancesResult() ) {
            $result = $response->getRunInstancesResult();
            my $res = $result->getReservation();
            $reservation = $res->getReservationId();
            mesg(1, "Run instance returned reservation id $reservation\n");
        }
    };
    if ($@) { throwEC2Error($@); }

    # loop until all instances in reservation are running
    # either it completes or the step times out...
    while ( "$reservation" ne "" ) {
        my $running = 0;         # number ready
        my $total   = $count;    # number in reservation
        eval {
            my $reservationFilter = new Amazon::EC2::Model::Filter({ "Name" => "reservation-id", "Value" => $reservation } );
            my $request = new Amazon::EC2::Model::DescribeInstancesRequest();
            $request->setFilter($reservationFilter);
            my $response = $service->describeInstances($request);

            # examine all instances in reservation and
            # exit if ALL instances are running
            # (this ignores the original count, only
            #  looks at instances that Amazon thinks are
            #  part of the reservation)
            if ( $response->isSetDescribeInstancesResult() ) {
                my $result  = $response->getDescribeInstancesResult();
                my $resList = $result->getReservation();
                foreach (@$resList) {
                    my $res   = $_;
                    my $resId = $res->getReservationId();

                    # if instance not in reservation
                    if ( "$resId" ne "$reservation" ) { next; }
                    $total        = 0;
                    $instanceList = $res->getRunningInstance();
                    foreach (@$instanceList) {
                        my $instance = $_;
                        my $id       = $instance->getInstanceId();
                        my $stateObj = $instance->getInstanceState();
                        my $state    = $stateObj->getName();
                        mesg( 1, "Evaluating instance $id in state $state\n" );
                        $total += 1;

            # if it is running or something went wrong, either way consider this
            # task complete
                        if (   "$state" eq "running"
                            || "$state" eq "shutting-down"
                            || "$state" eq "terminated" )
                        {
                            $running += 1;
                        }
                    }
                }
            }
        };
        if ($@) { throwEC2Error($@); }
        mesg( 1, "$running of $total instances ready\n" );
        if ( "$running" eq "$total" ) { last; }
        sleep 10;
    }

    if ( "$reservation" eq "" ) {
        mesg( 1, "Error running instances. No reservation created.\n" );
        exit 1;
    }

    my $instlist = "";

    # Now describe them one more time to capture the attributes
    eval {
        my $reservationFilter = new Amazon::EC2::Model::Filter({ "Name" => "reservation-id", "Value" => $reservation } );
        my $request = new Amazon::EC2::Model::DescribeInstancesRequest();
        $request->setFilter($reservationFilter);
        my $response = $service->describeInstances($request);

        if ( $response->isSetDescribeInstancesResult() ) {
            my $result  = $response->getDescribeInstancesResult();
            my $resList = $result->getReservation();
            foreach (@$resList) {
                my $res   = $_;
                my $resId = $res->getReservationId();

                # if instance not in reservation
                if ( "$resId" ne "$reservation" ) { next; }
                $instanceList = $res->getRunningInstance();
                foreach (@$instanceList) {
                    my $instance = $_;
                    my $id       = $instance->getInstanceId();
                    my $image    = $instance->getImageId();
                    my $rtype    = $instance->getRootDeviceType();

                    # if we get back something other than a string, default
                    if ( ref($rtype) ne "" ) { $rtype = "instance-store"; }

                    my $publicIP  = $instance->getPublicDnsName();
                    my $privateIP = $instance->getPrivateIpAddress();

                    my $ip_for_resource_creation = '';
                    if ( ref $publicIP eq 'HASH' && !%$publicIP ) {
                        $publicIP = '';
                    }
                    if ( ref $privateIP eq 'HASH' && !%$privateIP ) {
                        $privateIP = '';
                    }

                    $ip_for_resource_creation = $publicIP;
                    if ($use_private_ip) {
                        $ip_for_resource_creation = $privateIP;
                    }

                    my $placement  = $instance->getPlacement();
                    my $actualZone = $placement->getAvailabilityZone();
                    mesg(1, "Instance $id: IP=$publicIP  AMI=$image ZONE=$actualZone\n");

                    my $resource = "";
                    if ( !$ip_for_resource_creation ) {
                        mesg(1, "WARNING: Can't create resource because of no public IP was assigned to the created instance\n");
                    } elsif ($poolName) {
                        mesg( 1, "Poolname is not empty, adding resources.\n" );
                        $resource =
                          makeNewResource( $opts, $ip_for_resource_creation,
                            $poolName, $workspace, $port, $resource_zone );
                        my $p_path =
                          "/resources/$resource/ec_cloud_instance_details";
                        $ec->createProperty( $p_path,
                            { propertyType => 'sheet' } );
                        $ec->createProperty( "$p_path/etc/",
                            { propertyType => 'sheet' } );
                        $opts->{pdb}->setProp( "$p_path/createdBy", "EC-EC2" );
                        $opts->{pdb}->setProp( "$p_path/instance_id", $id );
                        $opts->{pdb}
                          ->setProp( "$p_path/config", $opts->{config} );

                        # let's set other properties for ETC folder
                        $p_path .= '/etc/';
                        if ( !$use_private_ip ) {
                            $opts->{pdb}
                              ->setProp( "$p_path/public_ip", $publicIP );
                        }
                        $opts->{pdb}
                          ->setProp( "$p_path/private_ip", $privateIP );
                        $opts->{pdb}->setProp( "$p_path/ami", $image );
                    }

                    if ( "$propResult" ne "" ) {
                        $opts->{pdb}
                          ->setProp( "$propResult/Instance-$id/AMI", "$image" );
                        $opts->{pdb}
                          ->setProp( "$propResult/Instance-$id/RootType",
                            "$rtype" );
                        $opts->{pdb}
                          ->setProp( "$propResult/Instance-$id/Address",
                            "$publicIP" );
                        $opts->{pdb}
                          ->setProp( "$propResult/Instance-$id/Private",
                            "$privateIP" );
                        $opts->{pdb}->setProp( "$propResult/Instance-$id/Zone",
                            "$actualZone" );
                        $opts->{pdb}
                          ->setProp( "$propResult/Instance-$id/Resource",
                            "$resource" );
                    }
                    if ( "$instlist" ne "" ) { $instlist .= ";"; }
                    $instlist .= "$id";
                    mesg( 1, "Adding $id to instance list\n" );
                }
            }
        }
    };
    if ($@) { throwEC2Error($@); }

    if ( "$propResult" ne "" ) {
        mesg( 1, "Saving instance list $instlist\n" );
        $opts->{pdb}->setProp( "$propResult/InstanceList", $instlist );
        $opts->{pdb}->setProp( "$propResult/Reservation",  $reservation );
        $opts->{pdb}->setProp( "$propResult/Count",        $count );
    }

    exit 0;
}

sub MOCK_API_RunInstance {
    my ( $opts, $service ) = @_;

    mesg( 1, "--Run Amazon EC2 Instances -------\n" );

    my $ami          = getRequiredParam( "image",        $opts );
    my $key          = getRequiredParam( "keyname",      $opts );
    my $instanceType = getRequiredParam( "instanceType", $opts );
    my $group        = getRequiredParam( "group",        $opts );
    my $zone         = getRequiredParam( "zone",         $opts );
    my $count        = getRequiredParam( "count",        $opts );
    my $resource_zone = getOptionalParam( "resource_zone", $opts );
    my $poolName = getOptionalParam( "res_poolName", $opts );
    my $propResult = getPropResultLocationForPool( $opts, $poolName );

    my $workspace = getOptionalParam( "res_workspace", $opts );
    my $port      = getOptionalParam( "res_port",      $opts );

    my $userData = getOptionalParam( "userData", $opts );
    if ( "$userData" eq "" ) {
        $userData = MIME::Base64::encode_base64("none");
    }
    else {
        $userData = MIME::Base64::encode_base64("$userData");
    }

    mesg( 1,
"Running $count instance(s) of $ami in zone $zone as type $instanceType with group $group\n"
    );

    ## run new instance

    my $reservation = "";

    for ( my $num = 0 ; $num < $count ; $num++ ) {
        my $r  = getRandKey(9999999);
        my $id = "i-$r";
        $opts->{pdb}
          ->setProp( "$::gMockRegistry/Instances/$id/state", "running" );
        $opts->{pdb}->setProp( "$::gMockRegistry/Instances/$id/key", "$key" );
        $opts->{pdb}
          ->setProp( "$::gMockRegistry/Instances/$id/group", "$group" );
        $opts->{pdb}->setProp( "$::gMockRegistry/Instances/$id/zone", "$zone" );
        $opts->{pdb}
          ->setProp( "$::gMockRegistry/Instances/$id/userData", "$userData" );
        $opts->{pdb}->setProp( "$::gMockRegistry/Instances/$id/ami",  "$ami" );
        $opts->{pdb}->setProp( "$::gMockRegistry/Instances/$id/root", "ebs" );

        my $publicIP = $opts->{pdb}->getProp("/myProject/publicIP");
        if ( $publicIP eq "" ) {
            $publicIP = "192.168." . getRandKey(255) . "." . getRandKey(255);
        }
        my $privateIP = "192.168." . getRandKey(255) . "." . getRandKey(255);
        $opts->{pdb}
          ->setProp( "$::gMockRegistry/Instances/$id/prvdns", "$privateIP" );
        $opts->{pdb}
          ->setProp( "$::gMockRegistry/Instances/$id/pubdns", "$publicIP" );

        my $resource = "";
        if ( "$poolName" ne "" ) {
            $resource =
              makeNewResource( $opts, $publicIP, $poolName, $workspace, $port, $resource_zone );
        }

        if ( "$propResult" ne "" ) {
            $opts->{pdb}->setProp( "$propResult/Instance-$id/AMI", "$ami" );
            $opts->{pdb}->setProp( "$propResult/Instance-$id/RootType", "ebs" );
            $opts->{pdb}
              ->setProp( "$propResult/Instance-$id/Address", "$publicIP" );
            $opts->{pdb}
              ->setProp( "$propResult/Instance-$id/Private", "$privateIP" );
            $opts->{pdb}->setProp( "$propResult/Instance-$id/Zone", "$zone" );
            $opts->{pdb}
              ->setProp( "$propResult/Instance-$id/Resource", "$resource" );
        }
        if ( "$instlist" ne "" ) { $instlist .= ";"; }
        $instlist .= "$id";
        mesg( 1, "Adding $id to instance list\n" );
    }

    if ( "$propResult" ne "" ) {
        mesg( 1, "Saving instance list $instlist\n" );
        $opts->{pdb}->setProp( "$propResult/InstanceList", $instlist );
        $opts->{pdb}->setProp( "$propResult/Reservation",  $reservation );
        $opts->{pdb}->setProp( "$propResult/Count",        $count );
    }

    exit 0;
}

sub makeNewResource {
    my ( $opts, $host, $pool, $workspace, $port, $zone ) = @_;
    my $ec = $opts->{pdb}->getCmdr();

    # host must be present
    if ( "$host" eq "" ) {
        mesg( 1, "No host provided to makeNewResource.\n" );
        return "";
    }

   # workspace and port can be blank
   # default the port to 7800, the default agent port, if port was not specified
    if ( !$port ) {
        $port = 7800;
    }

    mesg( 1, "Creating resource for machine $host in pool $pool and zone $zone\n" );

    my $resName = "$pool-$now_$seq";

    #-------------------------------------
    # Create the resource
    #-------------------------------------
    for ( my $seq = 1 ; $seq < 9999 ; $seq++ ) {
        my $now = time();
        $resName = "$pool" . "-" . $now . "_" . $seq;

        my $params = {
                description => "EC2 provisioned resource (dynamic)",
                workspaceName => $workspace,
                port => $port,
                hostName => $host
        };

        if($zone) {
            $params->{zoneName} = $zone;
        }

        my $cmdrresult = $ec->createResource($resName, $params);

        # resource created.

        # Check for error return
        my $errMsg = $ec->checkAllErrors($cmdrresult);
        if ( $errMsg ne "" ) {
            if ( $errMsg =~ /DuplicateResourceName/ ) {
                mesg( 4, "resource $resName exists\n" );
                next;
            }
            else {
                mesg( 1, "Error: $errMsg\n" );
                return "";
            }
        }

        mesg( 1, "Resource Name: $resName\n" );
        $ec->addResourcesToPool( $pool, { resourceName => [$resName] } );

        return $resName;
    }

    return "";
}

sub deleteResource() {
    my ( $opts, $resource ) = @_;

    # host must be present
    if ( "$resource" eq "" ) {
        mesg( 1, "No resource provded to deleteResource.\n" );
        return;
    }

    mesg( 1, "Deleting resource $resource\n" );

    #-------------------------------------
    # Delete the resource
    #-------------------------------------
    my $cmdrresult = $opts->{pdb}->getCmdr()->deleteResource($resource);

    # Check for error return
    my $errMsg = $opts->{pdb}->getCmdr()->checkAllErrors($cmdrresult);
    if ( $errMsg ne "" ) {
        mesg( 1, "Error: $errMsg\n" );
    }
    return;
}

sub API_CreateTags {
    my ( $opts, $service ) = @_;

    my $resourceId = getRequiredParam( "resourceId", $opts );
    my $tagsMap    = getRequiredParam( 'tagsMap',    $opts );
    my @resources = split( ' ', $resourceId );

    my $request = new Amazon::EC2::Model::CreateTagsRequest();

    $request->setIdList( \@resources );

    my $map  = parseTagsMap($tagsMap);
    my @tags = ();

    for ( keys %$map ) {
        my $tag = new Amazon::EC2::Model::Tag();
        mesg( 1,
"Adding $_ tag(s) to Amazon EC2 resource(s): $resourceId with value: $map->{$_}\n"
        );
        $tag->setKey($_);
        $tag->setValue( $map->{$_} );

        push( @tags, $tag );
    }
    $request->setTagList( \@tags );

    eval { my $response = $service->createTags($request); };
    if ($@) { throwEC2Error($@); }

    mesg( 1, "Tag(s) successfully created\n" );

}

sub AssignNameTags {
    my ( $opts, $service ) = @_;

    my $poolName = getOptionalParam( "res_poolName", $opts );

    #Location where the provisioned instances' properties are stored
    my $propLocation = getPropResultLocationForPool( $opts, $poolName );

    my $ec           = $opts->{ec_instance};
    my $instanceProp = "$propLocation/InstanceList";
    my $instanceList =
      $ec->getProperty($instanceProp)->findvalue("//value")->value();
    my @instances = split( ';', $instanceList );

    for my $resourceId (@instances) {

        my $resourceName =
          $ec->getProperty("$propLocation/Instance-$resourceId/Resource")
          ->findvalue("//value")->value();

        #Default the resourceName to the AWS Instance id,
        #if no commander resource associated with the instance
        if ( !$resourceName ) {
            $resourceName = $resourceId;
        }
        createTag( $resourceId, "Name", $resourceName, $service );
    }
}

sub createTag {
    my ( $resourceId, $tagName, $tagValue, $service ) = @_;

    mesg( 1, "Adding Tag '$tagName'='$tagValue' to Amazon EC2 resource '$resourceId'\n");

    my $request = new Amazon::EC2::Model::CreateTagsRequest();

    my @resources = ();
    push( @resources, $resourceId );
    $request->setIdList( \@resources );

    my @tags = ();
    my $tag  = new Amazon::EC2::Model::Tag();
    $tag->setKey($tagName);
    $tag->setValue($tagValue);
    push( @tags, $tag );
    $request->setTagList( \@tags );

    eval {
        $service->createTags($request);
        1;
    };

    if ($@) {
        mesg(0, "Failed to add Tag '$tagName'='$tagValue' to Amazon EC2 resource '$resourceId'\n");
        throwEC2Error($@);
    }

    mesg( 1, "Tag(s) successfully created\n" );
}

sub getInstancesForTermination {
    my ( $ec, $prop ) = @_;

    my $retval = [];

    my $instance_data = getResourceDetails( $ec, $prop );

    if (%$instance_data) {
        push @$retval, $instance_data;
        return $retval;
    }
    my $data = undef;
    eval {
        my $res = $ec->getResourcePool($prop);
        if ($res) {
            my $xml = XMLin( $res->{_xml} );
            $data =
              $xml->{response}->{resourcePool}->{resourceNames}->{resourceName};
        }
    };
    if ( !$data ) {
        return $retval;
    }

    if ( ref $data eq 'ARRAY' ) {
        for my $instance (@$data) {
            push @$retval, getResourceDetails( $ec, $instance );
        }
    }
    else {
        push @$retval, getResourceDetails( $ec, $data );
    }
    @$retval = grep { $_ } @$retval;
    return $retval;
}

sub getResourceDetails {
    my ( $ec, $prop ) = @_;
    my $instance_data = undef;
    eval {
        my $res    = $ec->getResource($prop);
        my $p_path = "/resources/$prop/ec_cloud_instance_details";
        $instance_data = {
            instance_id =>
              $ec->getProperty("$p_path/instance_id")->findvalue('//value')
              ->string_value(),
            resource_name => $prop,
        };
        eval {
            $instance_data->{config} =
              $ec->getProperty("$p_path/config")->findvalue('//value')
              ->string_value();
        };
    };
    return $instance_data;
}

sub populateActualParameters {
    my ( $ec, $opts ) = @_;

    populateActualParametersForJobStepId( $ec, $opts,
        '/myParent/parent/jobStepId' );
    populateActualParametersForJobStepId( $ec, $opts, '/myParent/jobStepId' );
}

sub populateActualParametersForJobStepId {
    my ( $ec, $opts, $jobStepIdPropName ) = @_;

    my $xpath     = $ec->getProperty($jobStepIdPropName);
    my $jobStepId = $xpath->findvalue('//value')->value;
    $xpath = $ec->getActualParameters( { jobStepId => $jobStepId } );
    my $nodeset = $xpath->find('//actualParameter');

    foreach my $node ( $nodeset->get_nodelist ) {
        my $parm = $node->findvalue('actualParameterName');
        my $val  = $node->findvalue('value');
        $opts->{$parm} = "$val";
    }
}

# parses tagsmap(key1 => value1, key2 => value2) into a perl hashref.
sub parseTagsMap {
    my ($map) = @_;
    $map =~ s/\n//gis;
    my $result = {};
    my @t = split /,/, $map;

    for my $row (@t) {

        # negative lookbehind
        my @arr = split( /(?<!\\)=>/, $row );
        if ( scalar @arr > 2 ) {
            die "Error occured";
        }
        trim( $arr[0] );
        trim( $arr[1] );
        $result->{ $arr[0] } = $arr[1];
    }
    return $result;
}

# removes leading and trailing whitespaces
sub trim {
    $_[0] or return;
    $_[0] =~ s/^\s+//s;
    $_[0] =~ s/\s+$//s;
}
