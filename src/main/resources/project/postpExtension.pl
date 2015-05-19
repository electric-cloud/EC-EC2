use strict;

$::gDontCheck = "cppunitExtraOutput";
$::gBuildDirectory = "";

#### Address matchers
push (@::gMatchers, 
    {
        id =>              "Amazon Elastic IP Allocate",
        pattern =>          q{Address (.*) allocated},
        action =>           q{addToSummary("Address $1 allocated");},
    },
);

push (@::gMatchers, 
    {
        id =>              "address associated",
        pattern =>          q{Address (.*) associated with instance (.*)},
        action =>           q{addToSummary("Address $1 associated with instance $2");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Elastic IP Release",
        pattern =>          q{Address (.*) released},
        action =>           q{addToSummary("Address $1 released");},
    },
);

#### KeyPair matchers
push (@::gMatchers, 
    {
        id =>              "Amazon Key Pair Create",
        pattern =>          q{KeyPair (.*) created},
        action =>           q{addToSummary("KeyPair $1 created");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Key Pair Delete",
        pattern =>          q{KeyPair (.*) deleted},
        action =>           q{addToSummary("KeyPair $1 deleted");},
    },
);

#### Snapshot and Volume matchers
push (@::gMatchers, 
    {
        id =>              "snapshot created 2",
        pattern =>          q{Created new snapshot (.*)},
        action =>           q{replaceSummary("Created snapshot $1");},
    },
);

push (@::gMatchers, 
    {
        id =>              "snapshot created",
        pattern =>          q{Snapshot (.*) used to create volume (.*)},
        action =>           q{replaceSummary("Snapshot $1 used to create volume $2");},
    },
);

push (@::gMatchers, 
    {
        id =>              "volumes created",
        pattern =>          q{Snapshot (.*) used to create (.*) volumes},
        action =>           q{replaceSummary("$2 volumes created from $1");},
    },
);

#### Run matchers
push (@::gMatchers, 
    {
        id =>              "run instances",
        pattern =>          q{(.*) of (.*) instances ready},
        action =>           q{replaceSummary("$1 of $2 instances ready");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Waiting for start",
        pattern =>          q{Waiting for instance (.*) to start},
        action =>           q{replaceSummary("Instance $1 starting");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Run",
        pattern =>          q{AMI (.*) launched as (.*)},
        action =>           q{addToSummary("AMI instance=$2");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Terminate",
        pattern =>          q{Instance (.*) terminated},
        action =>           q{addToSummary("AMI intance $1 terminated");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Wait OK",
        pattern =>          q{Instance started after (.*) seconds},
        action =>           q{addToSummary("Waited $1 seconds");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Amazon Wait Error",
        pattern =>          q{Instance did not start after (.*) seconds},
        action =>           q{addToSummary("Quit waiting after $1 seconds");},
    },
);

push (@::gMatchers, 
    {
        id =>              "Register Bundle",
        pattern =>          q{Image (.*) created},
        action =>           q{replaceSummary("AMI $1 created");},
    },
);


push (@::gMatchers, 
    {
        id =>              "Waiting for start pending",
        pattern =>          q{Instance (.*) state: (.*)},
        action =>           q{replaceSummary("Instance $1 in state $2");},
    },
);

push (@::gMatchers, 
    {
        id =>              "instance started",
        pattern =>          q{Instance (.*) running},
        action =>           q{replaceSummary("Instance $1 is running");},
    },
);

push (@::gMatchers, 
    {
        id =>              "volumes attached",
        pattern =>          q{(.*) volumes were attached to instances.},
        action =>           q{replaceSummary("$1 volumes attached");},
    },
);

push (@::gMatchers, 
    {
        id =>              "volumes deleted",
        pattern =>          q{(.*) volumes deleted.},
        action =>           q{replaceSummary("$1 volumes deleted");},
    },
);

push (@::gMatchers, 
    {
        id =>              "volumes detached",
        pattern =>          q{(.*) volumes detached.},
        action =>           q{replaceSummary("$1 volumes detached");},
    },
);

push (@::gMatchers, 
    {
        id =>              "instances terminated",
        pattern =>          q{(.*) instances terminated.},
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
        pattern =>          q{Subnet with ID\s(.+)\screated},
        action =>           q{replaceSummary("Subnet with ID $1 created");},
    },
);

push (@::gMatchers, 
    {
        id =>              "amazon error",
        pattern =>          q{Caught Exception: (.*)},
        action =>           q{addToSummary("AWS Error: $1");},
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
