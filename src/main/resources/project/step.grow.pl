use ElectricCommander;
use ElectricCommander::PropDB;

$::ec = new ElectricCommander();
$::ec->abortOnError(0);

$|=1;

my $ec2_config          = "$[ec2_config]";
my $ec2_device          = "$[ec2_device]";
my $ec2_image           = "$[ec2_image]";
my $ec2_security_group  = "$[ec2_security_group]";
my $ec2_snapshot        = "$[ec2_snapshot]";
my $ec2_zone            = "$[ec2_zone]";
my $ec2_instance_type   = "$[ec2_instance_type]";
my $ec2_userData        = "$[ec2_userData]";
my $number              = "$[number]";
my $poolName            = "$[poolName]";
my @deparray            = split(/\|/,$deplist);

sub main {
    print "Amazon Grow:\n";
    
    # TODO 
    # Validate inputs
    #
    
    ### CREATE INSTANCES ###
    print("Running EC2 Auto Deploy\n");
    my $proj = "$[/myProject/projectName]";
    my $proc = "EC2 Auto Deploy";
    my $xPath = $::ec->runProcedure("$proj",
        { procedureName => "$proc", pollInterval => 1, timeout => 3600,
          actualParameter => [
            {actualParameterName => "config", value => "$ec2_config"},
            {actualParameterName => "cleanup_tag", value => "tag"},
            {actualParameterName => "count", value => "$number"},
            {actualParameterName => "EC2 AMI", value => "$ec2_image" },
            {actualParameterName => "group", value => "$ec2_security_group" },
            {actualParameterName => "zone", value => "$ec2_zone" },
            {actualParameterName => "instanceType", value => "$ec2_instance_type" },
            {actualParameterName => "propResult", value => "/myJob/EC2/tag" },
            {actualParameterName => "userData", value => "$ec2_userData" },
            {actualParameterName => "snapshot", value => "$ec2_snapshot" },
            {actualParameterName => "res_poolName", value => "$poolName" },
            ],
        });
    if ($xPath) {
        my $code = $xPath->findvalue('//code');
        if ($code ne "") {
            my $mesg = $xPath->findvalue('//message');
            print "Run procedure returned code is '$code'\n$mesg\n";
        }
    }
    my $outcome = $xPath->findvalue('//outcome')->string_value;
    if ("$outcome" ne "success") {
        print "EC2 deploy job failed.\n";
        exit 1;
    }
    my $jobId = $xPath->findvalue('//jobId')->string_value;
    if (!$jobId) {
        exit 1;
    }
    my $depobj = new ElectricCommander::PropDB($::ec,"");
    my $instanceList = $depobj->getProp("/jobs/$jobId/EC2/tag/InstanceList");
    print "Instance list=$instanceList\n";
    my @instances = split(/;/,$instanceList);
    my $createdList = ();
    my $xmlout = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>";
    addXML(\$xmlout,"<GrowResponse>");
    foreach my $instance (@instances) {
        addXML(\$xmlout,"<Deployment>");
        addXML(\$xmlout,"<handle>$instance</handle>");
        addXML(\$xmlout,"<hostname>" 
          . $depobj->getProp("/jobs/$jobId/EC2/tag/Instance-$instance/Address")
          . "</hostname>");
        addXML(\$xmlout,"<key>" 
          . $depobj->getProp("/jobs/$jobId/EC2/tag/KeyPairId")
          . "</key>");
        addXML(\$xmlout,"<NewVolume>" 
          . $depobj->getProp("/jobs/$jobId/EC2/tag/Instance-$instance/NewVolume")
          . "</NewVolume>");
        addXML(\$xmlout,"<Resource>" 
          . $depobj->getProp("/jobs/$jobId/EC2/tag/Instance-$instance/Resource")
          . "</Resource>");
        addXML(\$xmlout,"</Deployment>");
    }
    addXML(\$xmlout,"</GrowResponse>");
    my $prop = "/myJob/CLoudManager/grow";
    print "Registering results for $instance in $prop\n";
    $::ec->setProperty("$prop",$xmlout);
}

sub addXML {
   my ($xml,$text) = @_;
   ## TODO encode
   ## TODO autoindent
   $$xml .= $text;
   $$xml .= "\n";
}

main();
