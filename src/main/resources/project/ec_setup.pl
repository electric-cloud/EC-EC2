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

use ElectricCommander::Util;

my $pluginName = q{@PLUGIN_NAME@};
my $pluginKey = q{@PLUGIN_KEY@};

my %allocateip = (
    label       => "EC2 - Allocate IP",
    procedure   => "API_AllocateIP",
    description => "Allocate an Elastic IP",
    category    => "Resource Management"
);


my %associateip = (
    label       => "EC2 - Associate IP",
    procedure   => "API_AssociateIP",
    description => "Associate an Elastic IP to an instance",
    category    => "Resource Management"
);

my %attachvolumes = (
    label       => "EC2 - Attach Volumes",
    procedure   => "API_AttachVolumes",
    description => "Attach a list of volumes to a list of instances",
    category    => "Resource Management"
);

my %createimage = (
    label       => "EC2 - Create Image",
    procedure   => "API_CreateImage",
    description => "Make a copy of an EBS instance",
    category    => "Resource Management"
);

my %createkey = (
    label       => "EC2 - Create Key",
    procedure   => "API_CreateKey",
    description => "Create a new key pair",
    category    => "Resource Management"
);

my %deletekey = (
    label       => "EC2 - Delete Key",
    procedure   => "API_DeleteKey",
    description => "Delete security Key pair",
    category    => "Resource Management"
);

my %deletevolume = (
    label       => "EC2 - Delete Volume",
    procedure   => "API_DeleteVolume",
    description => "Delete an EBS volume",
    category    => "Resource Management"
);

my %releaseip = (
    label       => "EC2 - Release IP",
    procedure   => "API_ReleaseIP",
    description => "Release an Elastic IP address",
    category    => "Resource Management"
);

my %runinstances = (
    label       => "EC2 - Run Instances",
    procedure   => "API_RunInstances",
    description => "Start one or more instances from a machine image",
    category    => "Resource Management"
);

my %startinstance = (
    label       => "EC2 - Start Instance",
    procedure   => "API_StartInstance",
    description => "Start an EBS backed instance that has been stopped",
    category    => "Resource Management"
);

my %stopinstance = (
    label       => "EC2 - Stop Instance",
    procedure   => "API_StopInstance",
    description => "Stop an EBS backed instance. Data will not be lost",
    category    => "Resource Management"
);

my %terminate = (
    label       => "EC2 - Terminate",
    procedure   => "API_Terminate",
    description => "Terminate an instance. Any data created or changes made to the disk will be lost",
    category    => "Resource Management"
);
my %teardownresource =  (
    label       => "EC2 - Tear Down Resource",
    procedure   => "API_TearDownResource",
    description => "Tear down resource with instance termination",
    category    => "Resource Management"
);

my %autocleanup = (
    label       => "EC2 - Auto Cleanup",
    procedure   => "EC2 Auto Cleanup",
    description => "Cleanup an auto deployed EC2 instance. The keypair, storage, elastic IP, and security settings will all be deleted",
    category    => "Resource Management"
);

my %autodeploy = (
    label       => "EC2 - Auto Deploy",
    procedure   => "EC2 Auto Deploy",
    description => "A procedure to deploy an EC2 instance. The keypair, storage, elastic IP, and security settings will all be automatically created and associated",
    category    => "Resource Management"
);

my %autopause = (
    label       => "EC2 - Auto Pause",
    procedure   => "EC2 Auto Pause",
    description => "Pause a deployed instance-store backed instance. This disconnects volumes and saves them, it then terminates the instance. Auto Resume will start a new instance and re-attach the volumes",
    category    => "Resource Management"
);

my %autoresume = (
    label       => "EC2 - Auto Resume",
    procedure   => "EC2 Auto Resume",
    description => "Resume a paused instance-store backed instance. A new instance is started and the saved volumes are re-attached",
    category    => "Resource Management"
);

my %snapattachedvolume = (
    label       => "EC2 - Snap Attached Volume",
    procedure   => "Snap Attached Volume",
    description => "Create a new snapshot from volume attached to instance. Note, only snaps first volume found",
    category    => "Resource Management"
);
my %createTags = (
    label       => "EC2 - Create Tags",
    procedure   => "API_CreateTags",
    description => "Adds or overwrites one or more tags for the specified Amazon EC2 resource or resources.",
    category    => "Resource Management"
);
my %test = (
    label       => "EC2 - Test",
    procedure   => "Test",
    description => "Deploy instances with volumes attached and clean up afterwards.",
    category    => "Resource Management"
);

my %createVPC = (
    label       => "EC2 - Create VPC",
    procedure   => "API_CreateVPC",
    description => "Create a new Virtual Private Network.",
    category    => "Resource Management"
);

my %createSubnet = (
    label       => "EC2 - Create Subnet",
    procedure   => "API_CreateSubnet",
    description => "Create a new subnet.",
    category    => "Resource Management"
);

my %deleteVPC = (
    label       => "EC2 - Delete VPC",
    procedure   => "API_DeleteVPC",
    description => "Delete existing Virtual Private Cloud.",
    category    => "Resource Management"
);
my %updateInstance = (
    label       => "EC2 - Update Instances",
    procedure   => "API_UpdateInstances",
    description => "Updates existing EC2 instances.",
    category    => "Resource Management"
);

$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - CloudManagerShrink");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - CloudManagerGrow");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_AllocateIP");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_DescribeInstances");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_AssociateIP");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_AttachVolumes");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - Attacholumes");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_CreateImage");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_CreateKey");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_DeleteKey");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_DeleteVolume");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_ReleaseIP");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_RunInstances");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_StartInstance");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_StopInstance");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_Terminate");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_TearDownResource");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - EC2_Auto_Cleanup");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - EC2_Auto_Deploy");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - EC2_Auto_Pause");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - EC2_Auto_Resume");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - Snap_Attached_Volume");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - Tear Down Resource");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - Test");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - Create VPC");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_CreateSubnet");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-EC2 - API_DeleteVPC");

$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - CloudManagerShrink");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - CloudManagerGrow");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_AllocateIP");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_DescribeInstances");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_AssociateIP");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_AttachVolumes");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Attacholumes");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_CreateImage");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_CreateKey");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_DeleteKey");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_DeleteVolume");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_ReleaseIP");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_RunInstances");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_StartInstance");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_StopInstance");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_Terminate");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_TearDownResource");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - EC2_Auto_Cleanup");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - EC2_Auto_Deploy");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - EC2_Auto_Pause");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - EC2_Auto_Resume");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Snap_Attached_Volume");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Tear Down Resource");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Test");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_CreateVPC");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_CreateSubnet");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - API_DeleteVPC");

$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Allocate IP");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Associate IP");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Attach Volumes");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Create Image");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Create Key");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Delete Key");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Delete Volume");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Release IP");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Run Instances");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Start Instance");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Stop Instance");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Terminate");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Auto Cleanup");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Auto Deploy");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Auto Pause");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Auto Resume");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Snap Attached Volume");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Test");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Tear Down Resource");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Create VPC");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Create Subnet");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC2 - Update Instances");

@::createStepPickerSteps = (\%allocateip, \%associateip, \%attachvolumes, \%createimage, \%createkey, \%deletekey, \%deletevolume, \%releaseip, \%runinstances, \%startinstance, \%stopinstance, \%terminate, \%autocleanup, \%autodeploy, \%autopause, \%autoresume, \%snapattachedvolume, \%test, \%teardownresource, \%createTags, \%createVPC, \%createSubnet, \%deleteVPC, \%updateInstance);

if ($promoteAction ne '') {
    my @objTypes = ('projects', 'resources', 'workspaces');
    my $query    = $commander->newBatch();
    my @reqs     = map { $query->getAclEntry('user', "project: $pluginName", { systemObjectName => $_ }) } @objTypes;
    push @reqs, $query->getProperty('/server/ec_hooks/promote');
    $query->submit();

    foreach my $type (@objTypes) {
        if ($query->findvalue(shift @reqs, 'code') ne 'NoSuchAclEntry') {
            $batch->deleteAclEntry('user', "project: $pluginName", { systemObjectName => $type });
        }
    }

    if ($promoteAction eq 'promote') {
        foreach my $type (@objTypes) {
            $batch->createAclEntry(
                                   'user',
                                   "project: $pluginName",
                                   {
                                      systemObjectName           => $type,
                                      readPrivilege              => 'allow',
                                      modifyPrivilege            => 'allow',
                                      executePrivilege           => 'allow',
                                      changePermissionsPrivilege => 'allow'
                                   }
                                  );
        }
    }
}
if ($upgradeAction eq 'upgrade') {
    my $query = $commander->newBatch();
    my $cfgs  = $query->getProperty("/plugins/$otherPluginName/project/ec2_cfgs");
    my $creds = $query->getCredentials("\$[/plugins/$otherPluginName]");

    local $self->{abortOnError} = 0;
    $query->submit();

    # Copy configurations from $otherPluginName
    if ($query->findvalue($cfgs, 'code') ne 'NoSuchProperty') {
        $batch->clone(
                      {
                        path      => "/plugins/$otherPluginName/project/ec2_cfgs",
                        cloneName => "/plugins/$pluginName/project/ec2_cfgs"
                      }
                     );
    }

    # Copy configuration credentials and attach them to the appropriate steps
    my $nodes = $query->find($creds);
    if ($nodes) {
        my @nodes = $nodes->findnodes('credential/credentialName');
        for (@nodes) {
            my $cred = $_->string_value;

            # Clone the credential
            $batch->clone(
                          {
                            path      => "/plugins/$otherPluginName/project/credentials/$cred",
                            cloneName => "/plugins/$pluginName/project/credentials/$cred"
                          }
                         );

            # Make sure the credential has an ACL entry for the new project principal
            my $xpath = $commander->getAclEntry(
                                                "user",
                                                "project: $pluginName",
                                                {
                                                   projectName    => $otherPluginName,
                                                   credentialName => $cred
                                                }
                                               );
            if ($xpath->findvalue('//code') eq 'NoSuchAclEntry') {
                $batch->deleteAclEntry(
                                       "user",
                                       "project: $otherPluginName",
                                       {
                                          projectName    => $pluginName,
                                          credentialName => $cred
                                       }
                                      );
                $batch->createAclEntry(
                                       "user",
                                       "project: $pluginName",
                                       {
                                          projectName                => $pluginName,
                                          credentialName             => $cred,
                                          readPrivilege              => "allow",
                                          modifyPrivilege            => "allow",
                                          executePrivilege           => "allow",
                                          changePermissionsPrivilege => "allow"
                                       }
                                      );
            }

            # Attach the credential to the appropriate steps
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'API_Run',
                                        stepName      => 'run'
                                     }
                                    );

            # Attach the credential to the API_RunInstances since it is required
            #for retrieving parameter options for dynamic environments UI.
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'API_RunInstances',
                                        stepName      => 'RunInstances'
                                     }
                                    );

            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'EC2 Auto Resume',
                                        stepName      => 'Attach Volumes'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'API_UpdateInstances',
                                        stepName      => 'UpdateInstances'
                                     }
                                    );
        }
    }
}

# Set the credentialProtected flag on the validation and parameterOptions
# property sheets if installing the plugin on EF server 6.1+. Doing this
# programatically allows the plugin to continue to be supported on
# older versions of EF server.
my $xpath = $commander->getVersions();
my $serverVersion = $xpath->findvalue('//version')->string_value();

if (compareMinor($serverVersion, '8.4') < 0) {
    $commander->setProperty("/projects/$pluginName/ec_cloudprovisioning_plugin/operations/createConfiguration/ui_formRefs/parameterForm", 'ui_forms/EC2CreateConfigFallbackForm');
}

if (compareMinor($serverVersion, '6.1') >= 0) {
  # Flag the property sheet as being protected by credentials
  # attached to the enclosing procedure's steps.

  $commander->modifyProperty("/projects/$pluginName/procedures/CreateConfiguration/ec_form/validation", {credentialProtected => "1"});
  $commander->modifyProperty("/projects/$pluginName/procedures/CreateConfiguration/ec_form/parameterOptions", {credentialProtected => "1"});
  $commander->modifyProperty("/projects/$pluginName/procedures/API_RunInstances/ec_form/validation", {credentialProtected => "1"});
  $commander->modifyProperty("/projects/$pluginName/procedures/API_RunInstances/ec_form/parameterOptions", {credentialProtected => "1"});

  if ($upgradeAction eq 'upgrade') {
    # If the disable flags were set on the earlier version of the plugin,
    # then set them when upgrading.
    my $batch = $commander->newBatch();
    my @reqIds = (
        $batch->getProperty("/plugins/$otherPluginName/project/ec_disable_dynamic_operations"),
        $batch->getProperty("/plugins/$otherPluginName/project/procedures/CreateConfiguration/ec_form/disable"),
        $batch->getProperty("/plugins/$otherPluginName/project/procedures/API_RunInstances/ec_form/disable"),
    );
    $batch->submit();

    my $disabledOps = $batch->findvalue($reqIds[0], 'property/value')->string_value();
    my $disabledCreateConfigurationOp = $batch->findvalue($reqIds[1], 'property/value')->string_value();
    my $disabledRunInstancesOp = $batch->findvalue($reqIds[2], 'property/value')->string_value();

    if ($disabledOps == '1') {
        my $desc = $batch->findvalue($reqIds[0], 'property/description');
        $commander->setProperty( "/plugins/$pluginName/project/ec_disable_dynamic_operations", { value => '1', description => $desc});
    }

    if ($disabledCreateConfigurationOp == '1') {
        my $desc = $batch->findvalue($reqIds[1], 'property/description');
        $commander->setProperty( "/plugins/$pluginName/project/procedures/CreateConfiguration/ec_form/disable", { value => '1', description => $desc});
    }

    if ($disabledRunInstancesOp == '1') {
        my $desc = $batch->findvalue($reqIds[2], 'property/description');
        $commander->setProperty( "/plugins/$pluginName/project/procedures/API_RunInstances/ec_form/disable", { value => '1', description => $desc});
    }

  }
}

$commander->deleteArtifact("com.electriccloud:@PLUGIN_KEY@-Grapes");


