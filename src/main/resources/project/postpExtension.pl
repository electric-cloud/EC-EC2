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

use strict;

$::gDontCheck = "cppunitExtraOutput";
$::gBuildDirectory = "";

#### Address matchers
push (@::gMatchers, 
    {
        id =>              "Amazon Elastic IP Allocate",
        pattern =>          q{Address\s(.*)\sallocated},
        action =>           q{addToSummary("Address $1 allocated");},
    },
);

push (@::gMatchers, 
    {
        id =>              "address associated",
        pattern =>          q{Address\s(.*)\sassociated\swith\sinstance\s(.*)},
        action =>           q{addToSummary("Address $1 associated with instance $2");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Elastic IP Release",
        pattern =>          q{Address\s(.*)\sreleased},
        action =>           q{addToSummary("Address $1 released");},
    },
);

#### KeyPair matchers
push (@::gMatchers, 
    {
        id =>              "Amazon Key Pair Create",
        pattern =>          q{KeyPair\s(.*)\screated\sat\s(.*)},
        action =>           q{addToSummary("KeyPair $1 created at $2");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Key Pair Delete",
        pattern =>          q{KeyPair\s(.*)\sdeleted},
        action =>           q{addToSummary("KeyPair $1 deleted");},
    },
);

#### Snapshot and Volume matchers
push (@::gMatchers, 
    {
        id =>              "snapshot created 2",
        pattern =>          q{Created\snew\ssnapshot\s(.*)},
        action =>           q{replaceSummary("Created snapshot $1");},
    },
);

push (@::gMatchers, 
    {
        id =>              "snapshot created",
        pattern =>          q{Snapshot\s(.*)\sused\sto\screate\svolume\s(.*)},
        action =>           q{replaceSummary("Snapshot $1 used to create volume $2");},
    },
);

push (@::gMatchers, 
    {
        id =>              "volumes created",
        pattern =>          q{Snapshot\s(.*)\sused\sto\screate\s(.*)\svolumes},
        action =>           q{replaceSummary("$2 volumes created from $1");},
    },
);

#### Run matchers
push (@::gMatchers, 
    {
        id =>              "run instances",
        pattern =>          q{(.*)\sof\s(.*)\sinstances\sready},
        action =>           q{replaceSummary("$1 of $2 instances ready");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Waiting for start",
        pattern =>          q{Waiting\sfor\sinstance\s(.*)\sto\sstart},
        action =>           q{replaceSummary("Instance $1 starting");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Run",
        pattern =>          q{AMI\s(.*)\slaunched\sas\s(.*)},
        action =>           q{addToSummary("AMI instance=$2");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Terminate",
        pattern =>          q{Instance\s(.*)\sterminated},
        action =>           q{addToSummary("AMI intance $1 terminated");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Wait OK",
        pattern =>          q{Instance\sstarted\safter\s(.*)\sseconds},
        action =>           q{addToSummary("Waited $1 seconds");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Wait Error",
        pattern =>          q{Instance\sdid\snot\sstart\safter\s(.*)\sseconds},
        action =>           q{addToSummary("Quit waiting after $1 seconds");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Register Bundle",
        pattern =>          q{Image\s(.*)\screated},
        action =>           q{replaceSummary("AMI $1 created");},
    },
);


push (@::gMatchers, 
    {
        id =>              "Waiting for start pending",
        pattern =>          q{Instance\s(.*)\sstate:\s(.*)},
        action =>           q{replaceSummary("Instance $1 in state $2");},
    },
);

push (@::gMatchers, 
    {
        id =>              "instance started",
        pattern =>          q{Instance\s(.*)\srunning},
        action =>           q{replaceSummary("Instance $1 is running");},
    },
);

push (@::gMatchers, 
    {
        id =>              "volumes attached",
        pattern =>          q{(.*)\svolumes\swere\sattached\sto\sinstances.},
        action =>           q{replaceSummary("$1 volumes attached");},
    },
);

push (@::gMatchers, 
    {
        id =>              "volumes deleted",
        pattern =>          q{(.*)\svolumes\sdeleted.},
        action =>           q{replaceSummary("$1 volumes deleted");},
    },
);

push (@::gMatchers, 
    {
        id =>              "volumes detached",
        pattern =>          q{(.*)\svolumes\sdetached.},
        action =>           q{replaceSummary("$1 volumes detached");},
    },
);

push (@::gMatchers, 
    {
        id =>              "instances terminated",
        pattern =>          q{(.*)\sinstances\sterminated.},
        action =>           q{replaceSummary("$1 instances terminated");},
    },
);

push (@::gMatchers,
    {
        id =>              "VPC created",
        pattern =>          q{VPC\s(.+)\screated},
        action =>           q{replaceSummary("VPC $1 created");},
    },
);

push (@::gMatchers,
    {
        id =>              "Subnet created",
        pattern =>          q{Subnet\swith\sID\s(.+)\screated},
        action =>           q{replaceSummary("Subnet with ID $1 created");},
    },
);

push (@::gMatchers,
    {
        id =>              "vpc deleted",
        pattern =>          q{VPC\s(.+)\sdeleted.},
        action =>           q{addToSummary("VPC $1 deleted.");},
    },
);

push (@::gMatchers, 
    {
        id =>              "amazon error",
        pattern =>          q{Caught\sException:\s(.*)},
        action =>           q{addToSummary("AWS Error: $1");},
    },
);

push (@::gMatchers, 
    {
        id =>              "error",
        pattern =>          q{ERROR:|[Ee]rror:},
        action =>           q{addToSummary("Error: $1");},
    },
);

sub addToSummary($)
{
    my ($str) = @_;
    my $original = (defined $::gProperties{"summary"}) ? $::gProperties{"summary"} . "\n" : "";
    setProperty("summary", $original . $str);
    setProperty("/myParent/parent/summary", $original . $str);
}

sub replaceSummary($)
{
    my ($str) = @_;
    setProperty("summary", $str);
    setProperty("/myParent/parent/summary", $str);
}
