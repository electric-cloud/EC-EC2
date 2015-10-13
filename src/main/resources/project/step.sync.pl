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

use ElectricCommander;
use ElectricCommander::PropDB;
use strict;

$::ec = new ElectricCommander();
$::ec->abortOnError(0);
$::pdb = new ElectricCommander::PropDB($::ec);

$|=1;

my $ec2_config          = "$[ec2_config]";
my $deployments         = '$[deployments]';

sub main {
    print "EC2 Sync:\n";

    # unpack request
    my $xPath = XML::XPath->new(xml => $deployments);
    my $nodeset = $xPath->find('//Deployment');

    my $instanceList = "";
    # put request in perl hash
    my $deplist;
    foreach my $node ($nodeset->get_nodelist) {
        # for each deployment
        my $i = $xPath->findvalue('handle',$node)->string_value;
        my $s = $xPath->findvalue('state',$node)->string_value; # alive
        print "Input: $i state=$s\n";
        $deplist->{$i}{state} = "alive"; # we only get alive items in list
        $deplist->{$i}{result} = "alive";
        $instanceList .= "$i\;";
    }

    checkIfAlive($instanceList,$deplist);

    my $xmlout = "";
    addXML(\$xmlout,"<SyncResponse>");
    foreach my $handle (keys %{$deplist}) {
        my $result = $deplist->{$handle}{result};
        my $state = $deplist->{$handle}{state};

        addXML(\$xmlout,"<Deployment>");
        addXML(\$xmlout,"  <handle>$handle</handle>");
        addXML(\$xmlout,"  <state>$state</state>");
        addXML(\$xmlout,"  <result>$result</result>");
        addXML(\$xmlout,"</Deployment>");
    }
    addXML(\$xmlout,"</SyncResponse>");
    $::ec->setProperty("/myJob/CloudManager/sync",$xmlout);
    print "\n$xmlout\n";
    exit 0;
}


# checks status of instances
# if found to be stopped, it marks the deplist to pending
# otherwise (including errors running api) it assumes it is still running
sub checkIfAlive {
    my ($instances, $deplist) = @_;

    ### describe instances ###
    print("Running EC2 Describe Instances\n");
    my $proj = "$[/myProject/projectName]";
    my $proc = "API_DescribeInstances";
    my $xPath = $::ec->runProcedure("$proj",
        { procedureName => "$proc", pollInterval => 1, timeout => 3600,
          actualParameter => [
            {actualParameterName => "config", value => "$ec2_config"},
            {actualParameterName => "instances", value => "$instances"},
            {actualParameterName => "propResult", value => "/myJob/CM"},
            ],
        });
    if ($xPath) {
        my $code = $xPath->findvalue('//code')->string_value;
        if ($code ne "") {
            my $mesg = $xPath->findvalue('//message')->string_value;
            print "Run procedure returned code is '$code'\n$mesg\n";
            return;
        }
    }
    my $outcome = $xPath->findvalue('//outcome')->string_value;
    my $jobid = $xPath->findvalue('//jobId')->string_value;
    if (!$jobid) {
        # at this point we have to assume it is still running becaue we could not prove otherwise
        print "could not find jobid of API_DescribeInstances job.\n";
        return;
    }
    my $response = $::pdb->getProp("/jobs/$jobid/CM/describe");
    if ("$response" eq "") {
        print "could not find resuls of describe in /jobs/$jobid/CM/describe";
        return;
    }

    my $respath = XML::XPath->new( xml => "$response");
    my $nodeset = $respath->find('//instance');

    # deployment specific response
    foreach my $node ($nodeset->get_nodelist) {
        my $id = $respath->findvalue('id',$node)->string_value;
        my $state = $respath->findvalue('state',$node)->string_value;
        my $err = "success";
        my $msg = "";
        if ("$state" eq "running" || "$state" eq "pending") {
            print("instance $id still running\n");
            $deplist->{$id}{state}  = "alive";
            $deplist->{$id}{result} = "success";
            $deplist->{$id}{mesg}   = "instance still running";
        } else {
            print("instance $id stopped\n");
            $deplist->{$id}{state}  = "pending";
            $deplist->{$id}{result} = "success";
            $deplist->{$id}{mesg}   = "instance was manually stopped or failed";
        }
    }
    return ;
}
    

sub addXML {
   my ($xml,$text) = @_;
   ## TODO encode
   ## TODO autoindent
   $$xml .= $text;
   $$xml .= "\n";
}

main();
