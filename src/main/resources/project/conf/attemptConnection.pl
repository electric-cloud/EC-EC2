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

#########################
## createcfg.pl
#########################

use ElectricCommander;
use ElectricCommander::PropDB;
use ElectricCommander::PropMod qw(/myProject/lib);
use Carp qw( carp croak );

use constant {
               SUCCESS => 0,
               ERROR   => 1,
             };

## get an EC object
my $ec = new ElectricCommander();
$ec->abortOnError(0);

my $credName = "$[/myJob/config]";

my $xpath    = $ec->getFullCredential("credential");
my $errors   = $ec->checkAllErrors($xpath);
my $AWS_ACCESS_KEY_ID = $xpath->findvalue("//userName");
my $AWS_SECRET_ACCESS_KEY = $xpath->findvalue("//password");


my ($proxy_user, $proxy_pass, $http_proxy);
eval {
    my $http_proxy = '$[http_proxy]';
    if ($http_proxy) {
        $ENV{HTTP_PROXY} = $http_proxy;
        $ENV{HTTPS_PROXY} = $http_proxy;
        $ENV{FTP_PROXY} = $http_proxy;
    }
    my $proxy_xpath = $ec->getFullCredential("proxy_credential");
    my $proxy_user = $proxy_xpath->findvalue("//userName");
    my $proxy_pass = $proxy_xpath->findvalue("//userName");
    if ($proxy_user) {
        $ENV{HTTPS_PROXY_USERNAME} = $proxy_user;
    }
    if ($proxy_pass) {
        $ENV{HTTPS_PROXY_PASSWORD} = $proxy_pass;
    }

};


my $projName = "$[/myProject/projectName]";
print "Attempting connection with user server\n";

require Amazon::EC2::Client;
my $config = {
               ServiceURL       => "$[service_url]",
               UserAgent        => "Amazon EC2 Perl Library",
               SignatureVersion => 4,
               SignatureMethod  => "HmacSHA256",
               ProxyHost        => undef,
               ProxyPort        => -1,
               MaxErrorRetry    => 3
             };
my $service = Amazon::EC2::Client->new($AWS_ACCESS_KEY_ID, $AWS_SECRET_ACCESS_KEY, $config);

require Amazon::EC2::Model::DescribeAvailabilityZonesRequest;

my $request = new Amazon::EC2::Model::DescribeAvailabilityZonesRequest();

eval {
    my $response = $service->describeAvailabilityZones($request);

    print("Service Response\n");
    print("=============================================================================\n");

    print(" DescribeAvailabilityZonesResponse\n");
    if ($response->isSetResponseMetadata()) {
        my $responseMetadata = $response->getResponseMetadata();
        if ($responseMetadata->isSetRequestId()) {
            print("  RequestId:");
            print(" " . $responseMetadata->getRequestId() . "\n");
        }
    }
};
my $ex = $@;
if ($ex) {
    my $errMsg = "Test connection failed.\n";
    $ec->setProperty("/myJob/configError", $errMsg);
    print $errMsg;

    $ec->deleteProperty("/projects/$projName/ec2_cfgs/$credName");
    $ec->deleteCredential($projName, $credName);
    require Amazon::EC2::Exception;
    if (ref $ex eq "Amazon::EC2::Exception") {
        print("Caught Exception: " . $ex->getMessage() . "\n");
        print("Response Status Code: " . $ex->getStatusCode() . "\n");
        print("Error Code: " . $ex->getErrorCode() . "\n");

    }
    else {
       croak $@;
    }

    exit ERROR;
}

exit SUCCESS;
