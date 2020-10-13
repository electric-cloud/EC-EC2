use strict;
# use warnings;
use ElectricCommander::Util qw(compareVersion);
use Data::Dumper;

# Resource management plugin
my @objTypes = ('projects', 'resources', 'workspaces');
my $query = $commander->newBatch();
my @reqs = map {$query->getAclEntry('user', "project: $pluginName", { systemObjectName => $_ })} @objTypes;
push @reqs, $query->getProperty('/server/ec_hooks/promote');
$query->submit();

foreach my $type (@objTypes) {
    if ($query->findvalue(shift @reqs, 'code') ne 'NoSuchAclEntry') {
        $batch->deleteAclEntry('user', "project: $pluginName", { systemObjectName => $type });
        # print "Deleted ACL for $pluginName for $type\n";
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
        # print "Created ACL for $pluginName for $type\n";
    }

    # Version 3.0 config change
    if (compareVersion($thisVersion, "3.0.0") >= 0 && compareVersion($otherVersion, "3.0.0") < 0) {
        migrateConfigs();
    }
}

sub migrateConfigs {
    my $configurations = $commander->getProperties({ path => "/projects/$otherPluginName/ec2_cfgs" });
    for my $config ($configurations->findnodes("//propertyName")) {
        my $configName = $config->string_value;
        print "Config name $configName\n";

        my $configProperties = $commander->getProperties({ path => "/projects/$otherPluginName/ec2_cfgs/$configName" });
        my $oldConfig = {};
        for my $prop ($configProperties->findnodes("//property")) {
            my $name = $prop->findvalue('propertyName')->string_value;
            my $value = $prop->findvalue('value')->string_value;
            $oldConfig->{$name} = $value;
        }
        eval {
            migrateConfig($configName, $oldConfig);
            1
        } or do {
            warn "Failed to migrate $configName: $@";
        };
    }
}

sub migrateConfig {
    my ($configName, $oldConfig) = @_;

    my $newConfig = convertConfig($oldConfig);
    print Dumper $newConfig;
    unless ($newConfig) {
        return;
    }

    print Dumper [ $otherPluginName, $pluginName ];
    for my $prop (keys %$newConfig) {
        $commander->setProperty("/projects/$pluginName/ec_plugin_cfgs/$configName/$prop", $newConfig->{$prop});
    }

    # todo attach
    $commander->clone({
        path      => "/projects/$otherPluginName/credentials/$newConfig->{credential}",
        cloneName => "/projects/$pluginName/credentials/$newConfig->{credential}"
    });
    print "Cloned credential $newConfig->{credential}\n";
    print "Moved configuration $configName\n";

}


sub convertConfig {
    my ($oldConfig) = @_;

    my $serviceUrl = $oldConfig->{service_url};
    my ($region) = $serviceUrl =~ m{https?://ec2\.([\w\w-]+)\.amazonaws.com};

    unless ($region) {
        $region  = 'us-east-1';
        warn "Cannot retrieve region from $serviceUrl, default region $region will be used\n";
    }
    my $newConfig = {
        debugLevel   => $oldConfig->{debug},
        httpProxyUrl => $oldConfig->{http_proxy},
        region       => $region,
        credential   => $oldConfig->{credential},
        authType     => "basic",
        roleArn      => "",
        proxy_credential => $oldConfig->{proxy_credential},
    };
    return $newConfig;
}
