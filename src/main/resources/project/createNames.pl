use ElectricCommander;

sub main()
{
    my $res = "$[propResult]/InstanceList";

    my $ec = new ElectricCommander();
    my $instProp = $ec->getProperty($res)->findvalue("//value")->value();

    my @instances = split(';', $instProp);

    for my $num (0..$#instances) {

         my $inum = $ec->incrementProperty("/myProject/instanceCounter")->findvalue("//value")->value();
         my $name = "EC-EC2Instance-" . $inum;
     
         my $xpath = $ec->runProcedure( '$[/myProject/projectName]',
                                {
                                procedureName => "API_CreateTags",
                                pollInterval    => '1',
                                timeout         => 600,
                                actualParameter => [ { actualParameterName => 'config', value => $[config] },
                                                     { actualParameterName => 'resourceId', value => $instances[$num] },
                                                     { actualParameterName => 'tagsMap', value => "Name => $name" },
                                                    ]
                            }
                          );

        my $out = $xpath->findvalue("//outcome");      

        if($out eq "success") { 
        
            print "Assign name $name to instance $instances[$num]\n";
        }
        else {

            print "Warning: can't assign name to instance $instance[$num]\n";

        }
    }
}

main();
