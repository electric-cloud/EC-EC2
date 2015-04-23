use ElectricCommander;
use ElectricCommander::PropDB;

my $ec = new ElectricCommander({server=> "174.129.239.19"});
$ec->abortOnError(0);
my $pd = new ElectricCommander::PropDB($ec,"");

# for each procedure
my @procs = ();
my $xPath = $ec->getProcedures("EC-EC2");
my $nodeset = $xPath->find('//procedure');
foreach my $node ($nodeset->get_nodelist) {
    my $proc = $xPath->findvalue('procedureName', $node);
    push @procs, $proc;
}
    
foreach my $proc (@procs) {
    if (! -d "procedures/$proc") {
        mkdir "procedures/$proc";
    }
    $xPath = $ec->getSteps("EC-EC2",$proc);
    my $nodeset = $xPath->find('//step');
    foreach my $node ($nodeset->get_nodelist) {
        my $step = $xPath->findvalue('stepName', $node);
        my $fname = "procedures/$proc/$step";
        my $cmd = $xPath->findvalue('command', $node);
        if ("$cmd" ne "") {
            print "    ['//procedure[procedureName=\"$proc\"]/step[stepName=\"$step\"]/command' , '$fname'],\n";
            open FH, "> $fname";
            print FH $cmd;
            close FH;
        }
    }
}
