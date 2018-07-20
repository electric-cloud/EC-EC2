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
                                actualParameter => [ { actualParameterName => 'config', value => "$[config]" },
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
