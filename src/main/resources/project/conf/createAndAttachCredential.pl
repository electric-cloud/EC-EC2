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

##########################
# createAndAttachCredential.pl
##########################

use ElectricCommander;
use strict;
use warnings;

use constant {
	SUCCESS => 0,
	ERROR   => 1,
};

## get an EC object
my $ec = new ElectricCommander();
$ec->abortOnError(0);

# my $credName = "$[/myJob/config]";
my $ec2Config = '$[/myJob/config]';
my $ec2Credential = $ec2Config;
my $ec2ProxyCredential = $ec2Credential . '_proxy_credential';

my %credentials = (
    $ec2Credential => 'credential',
    $ec2ProxyCredential => 'proxy_credential'
);
for my $credName (keys %credentials) {
    $ec->abortOnError(1);
    print "CredName: $credName\n";
    my $xpath;
    eval {
        $xpath = $ec->getFullCredential($credentials{$credName});
        1;
    } or do {
        print "Failed to get credential $credentials{$credName}, next.\n";
        next;
    };
    $ec->abortOnError(0);
    my $userName = $xpath->findvalue("//userName");
    my $password = $xpath->findvalue("//password");

    # Create credential
    my $projName = '@PLUGIN_KEY@-@PLUGIN_VERSION@';

    $ec->deleteCredential($projName, $credName);
    $xpath = $ec->createCredential($projName, $credName, $userName, $password);
    my $errors = $ec->checkAllErrors($xpath);

    # Give config the credential's real name
    my $configPath = "/projects/$projName/ec2_cfgs/$ec2Config";
    print "Creating credential $credName in project $projName with user $userName\n";
    $errors .= $ec->checkAllErrors($xpath);

    # Give config the credential's real name
    # $xpath = $ec->setProperty($configPath . "/credential", $credName);
    $xpath = $ec->setProperty($configPath . '/' . $credentials{$credName}, $credName);
    $errors .= $ec->checkAllErrors($xpath);

    # Give job launcher full permissions on the credential
    my $user = '$[/myJob/launchedByUser]';
    $xpath = $ec->createAclEntry("user", $user, {
        projectName => $projName,
        credentialName => $credName,
        readPrivilege => 'allow',
        modifyPrivilege => 'allow',
        executePrivilege => 'allow',
        changePermissionsPrivilege => 'allow'
    });
    $errors .= $ec->checkAllErrors($xpath);

    # Attach credential to steps that will need it
    $xpath = $ec->attachCredential($projName, $credName,
                                   {procedureName => "API_Run",
                                    stepName => "run"});
    $errors .= $ec->checkAllErrors($xpath);

    # Attaching credential to API_RunInstances since it is required
    # for retrieving parameter options for dynamic environments UI.
    $xpath = $ec->attachCredential($projName, $credName,
                                   {procedureName => "API_RunInstances",
                                    stepName => "RunInstances"});
    $errors .= $ec->checkAllErrors($xpath);
    $xpath = $ec->attachCredential($projName, $credName,
                                   {procedureName => "API_RunInstances",
                                    stepName => "AssignNameTags"});
    $errors .= $ec->checkAllErrors($xpath);

    $xpath = $ec->attachCredential($projName, $credName,
                                   {procedureName => "EC2 Auto Resume",
                                    stepName => "Attach Volumes"});
    $errors .= $ec->checkAllErrors($xpath);

    $xpath = $ec->attachCredential($projName, $credName,
                                   {procedureName => "API_CreateVPC",
                                    stepName => "CreateVPC"});
    $errors .= $ec->checkAllErrors($xpath);


    $xpath = $ec->attachCredential($projName, $credName,
                                   {procedureName => "API_CreateSubnet",
                                    stepName => "CreateSubnet"});
    $errors .= $ec->checkAllErrors($xpath);

    $xpath = $ec->attachCredential($projName, $credName,
                                   {procedureName => "API_DeleteVPC",
                                    stepName => "DeleteVPC"});
    $errors .= $ec->checkAllErrors($xpath);

    $xpath = $ec->attachCredential($projName, $credName,
                                   {procedureName => "API_UpdateInstances",
                                    stepName => "UpdateInstances"});
    $errors .= $ec->checkAllErrors($xpath);

    if ("$errors" ne "") {
        # Cleanup the partially created configuration we just created
        $ec->deleteProperty($configPath);
        $ec->deleteCredential($projName, $credName);
        my $errMsg = "Error creating configuration credential: " . $errors;
        $ec->setProperty("/myJob/configError", $errMsg);
        print $errMsg;
        exit 1;
    }
}
