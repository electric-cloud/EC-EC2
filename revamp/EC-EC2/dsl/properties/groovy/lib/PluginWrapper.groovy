import com.cloudbees.flowpdf.Log
import groovy.xml.XmlSlurper
import org.apache.http.HttpResponse
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.auth.credentials.AwsCredentials
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider
import software.amazon.awssdk.auth.credentials.AwsSessionCredentials
import software.amazon.awssdk.auth.credentials.EnvironmentVariableCredentialsProvider
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.http.SdkHttpClient
import software.amazon.awssdk.http.TlsTrustManagersProvider
import software.amazon.awssdk.http.apache.ApacheHttpClient
import software.amazon.awssdk.http.apache.ProxyConfiguration
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.ec2.Ec2Client
import software.amazon.awssdk.services.ec2.model.AvailabilityZone
import software.amazon.awssdk.services.ec2.model.CreateTagsRequest
import software.amazon.awssdk.services.ec2.model.DescribeImagesRequest
import software.amazon.awssdk.services.ec2.model.DescribeImagesResponse
import software.amazon.awssdk.services.ec2.model.DescribeInstancesRequest
import software.amazon.awssdk.services.ec2.model.Ec2Exception
import software.amazon.awssdk.services.ec2.model.Filter
import software.amazon.awssdk.services.ec2.model.IamInstanceProfileSpecification
import software.amazon.awssdk.services.ec2.model.Image
import software.amazon.awssdk.services.ec2.model.Instance
import software.amazon.awssdk.services.ec2.model.InstanceType
import software.amazon.awssdk.services.ec2.model.Placement
import software.amazon.awssdk.services.ec2.model.RunInstancesRequest
import software.amazon.awssdk.services.ec2.model.RunInstancesResponse
import software.amazon.awssdk.services.ec2.model.Tag
import software.amazon.awssdk.services.ec2.model.Tenancy
import software.amazon.awssdk.services.ec2.model.TerminateInstancesRequest
import software.amazon.awssdk.services.sts.StsClient
import software.amazon.awssdk.services.sts.model.AssumeRoleRequest
import software.amazon.awssdk.services.sts.model.AssumeRoleResponse

import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager
import java.security.cert.X509Certificate

class PluginWrapper {
    private String accessKeyId
    private String accessKeySecret
    private String sessionToken
    private String region
    private String roleArn
    private String proxyUrl
    private String proxyUser
    private String proxyPassword
    private boolean environmentAuth
    Log log = new Log()
    private boolean ignoreSslIssues


    @Lazy
    private AwsCredentialsProvider credentialsProvider = {
        //todo untested!!!
        if (environmentAuth) {
            return EnvironmentVariableCredentialsProvider.create()
        }
        assert accessKeyId: "accessKeyId must be provided"
        assert accessKeySecret: "accessKeySecret must be provided"
        if (sessionToken) {
            AwsSessionCredentials credentials = AwsSessionCredentials.create(
                accessKeyId,
                accessKeySecret,
                sessionToken
            )
            return StaticCredentialsProvider.create(credentials)
        } else if (roleArn) {
            log.info "Assuming role $roleArn"
            AwsCredentials credentials = AwsBasicCredentials.create(
                accessKeyId,
                accessKeySecret
            )
            assert region: "No region is provided"
            StsClient stsClient = StsClient
                .builder()
                .region(Region.of(region))
                .credentialsProvider(StaticCredentialsProvider.create(credentials))
                .build()
            String sessionName = '@PLUGIN_KEY@_' + new Random().nextInt()
            AssumeRoleRequest request = AssumeRoleRequest.builder()
                .roleArn(roleArn)
                .roleSessionName(sessionName)
                .build()
            AssumeRoleResponse response = stsClient.assumeRole(request)
            log.info "Assumed role user: ${response.assumedRoleUser().arn()}"
            AwsSessionCredentials sessionCredentials = AwsSessionCredentials.create(
                response.credentials().accessKeyId(),
                response.credentials().secretAccessKey(),
                response.credentials().sessionToken()
            )
            return StaticCredentialsProvider.create(sessionCredentials)
        } else {
            AwsCredentials credentials = AwsBasicCredentials.create(
                accessKeyId,
                accessKeySecret
            )
            return StaticCredentialsProvider.create(credentials)
        }
    }()


    @Lazy
    private SdkHttpClient httpClient = {
        def builder = ApacheHttpClient.builder().proxyConfiguration(proxyConfiguration)
        if (ignoreSslIssues) {
            log.warning("Ignoring SSL issues")
            TlsTrustManagersProvider allTrustingProvider = new TlsTrustManagersProvider() {
                @Override
                TrustManager[] trustManagers() {
                    new TrustManager[]{
                        new X509TrustManager() {
                            X509Certificate[] getAcceptedIssuers() {
                                return null
                            }

                            void checkClientTrusted(
                                X509Certificate[] certs, String authType) {
                            }

                            void checkServerTrusted(
                                X509Certificate[] certs, String authType) {
                            }
                        }
                    }
                }
            }
            builder.tlsTrustManagersProvider(allTrustingProvider)
        }
        return builder.build()
    }()

    @Lazy
    private ProxyConfiguration proxyConfiguration = {
        if (proxyUrl) {
            log.info "Using proxy URL $proxyUrl"

            ProxyConfiguration.Builder builder = ProxyConfiguration
                .builder()
                .endpoint(new URI(proxyUrl))

            if (proxyUser) {
                log.info("Using proxy user $proxyUser")
                assert proxyPassword: "Proxy password is not provided"
                builder.username(proxyUser)
                builder.password(proxyPassword)
                log.info "Using proxy password ${'*' * proxyPassword.size()}"
            }
            return builder.build()
        } else {
            log.debug("Using system property values for the proxy")
            return ProxyConfiguration.builder()
                .useSystemPropertyValues(true)
                .build()
        }
    }()


    @Lazy
    private Ec2Client ec2Client = {
        assert region: "No region is provided"

        return Ec2Client
            .builder()
            .httpClient(httpClient)
            .credentialsProvider(this.credentialsProvider)
            .region(Region.of(region))
            .build()
    }()

    void testConnection() {
        log.info ec2Client.describeAccountAttributes().accountAttributes()
    }

    @Lazy
    RawHttpRequestHandler rawHttpRequestHandler = {
        new RawHttpRequestHandler(
            credentials: credentialsProvider.resolveCredentials(),
            ignoreSslIssues: ignoreSslIssues
        )
    }()


    List<AvailabilityZone> describeAvailabilityZones() {
        return ec2Client.describeAvailabilityZones().availabilityZones()
    }

    String fetchAmi(String name) {
        Filter filter = Filter.builder().name("name").values(name).build()
        DescribeImagesRequest request = DescribeImagesRequest
            .builder()
            .filters(filter)
            .build()
        DescribeImagesResponse response = ec2Client.describeImages(request)
        if (!response.hasImages()) {
            throw new RuntimeException("Failed to fetch an AMI for the image name $name")
        }
        if (response.images().size() > 1) {
            throw new RuntimeException("More than one image found for the name $name")
        }
        return response.images().first().imageId()
    }

    List<Instance> terminateInstances(List<String> instanceIds) {
        TerminateInstancesRequest request = TerminateInstancesRequest
            .builder()
            .instanceIds(instanceIds)
            .build()
        log.debug "Terminate instances request: $request"
        ec2Client.terminateInstances(request)
        return describeInstances(instanceIds)
    }


    List<Instance> provisionInstances(RunInstancesParameters p) {
        assert p.ami
        assert p.type

        //todo validate type
        RunInstancesRequest.Builder builder = RunInstancesRequest.builder()
            .instanceType(p.type)
            .imageId(p.ami)
            .minCount(1)
            .maxCount(1)

        if (p.count) {
            builder.maxCount(p.count)
        }
        if (p.keyPairName) {
            log.info "Using key pair: $p.keyPairName"
            builder.keyName(p.keyPairName)
        }

        Placement.Builder placementBuilder = Placement.builder()
        //todo check max available instances
        if (p.subnet) {
            //todo id
            log.info "Using subnet ${p.subnet}"
            builder.subnetId(p.subnet)
        }
        if (p.zone) {
            placementBuilder.availabilityZone(p.zone)
            log.info "Using availability zone: $p.zone"
        }

        if (p.iamProfileName) {
            IamInstanceProfileSpecification instanceProfileSpecification = IamInstanceProfileSpecification.builder().name(p.iamProfileName).build()
            builder.iamInstanceProfile(instanceProfileSpecification)
            log.info "Using IAM instance profile $instanceProfileSpecification"
        }
        if (p.tenancy) {
            Tenancy tenancy = Tenancy.fromValue(p.tenancy)
            placementBuilder.tenancy(tenancy)
            log.info "Using tenancy: $tenancy"
        }
        if (p.privateIp) {
            builder.privateIpAddress(p.privateIp)
            log.info "Using private IP $p.privateIp"
        }
        if (p.sg) {
            //todo id
            builder.securityGroups(p.sg)
        }
        if (p.userData) {
            String userData = p.userData.bytes.encodeBase64().toString()
            builder.userData(userData)
            log.info "Using user data $userData"
        }
        if (p.instanceInitiatedShutdownBehavior) {
            builder.instanceInitiatedShutdownBehavior(p.instanceInitiatedShutdownBehavior)
            log.info "Using initiated shutdown behaviour: $p.instanceInitiatedShutdownBehavior"
        }

        Placement placement = placementBuilder.build()
        log.debug("Placement: $placement")
        builder.placement(placement)

        RunInstancesRequest request = builder.build()
        log.debug "Request: $request"

        //todo try
        RunInstancesResponse response = ec2Client.runInstances(request)
        log.info "Reservation Id: ${response.reservationId()}"

        List<String> instanceIds = response.instances().collect {
            it.instanceId()
        }
        log.info "Instances IDs: $instanceIds"
        //16 = running
        waitForInstances(instanceIds, InstanceState.RUNNING)

        //Attaching the name tag after the instance has been properly launched
        if (p.name) {
            log.info "Assigning name $p.name"
            if (instanceIds.size() > 1) {
                log.warning("More than one instance has been created.They will have the same name.")
            }
            Tag tag = Tag.builder().key("Name").value(p.name).build()
            CreateTagsRequest createTagsRequest = CreateTagsRequest.builder()
                .tags(tag)
                .resources(instanceIds)
                .build()
            try {
                ec2Client.createTags(createTagsRequest)
                log.info "Successfully assigned Name: $p.name to instances $instanceIds"
            } catch (Ec2Exception e) {
                log.error(e.awsErrorDetails().errorMessage())
                throw new RuntimeException(e.awsErrorDetails().errorMessage())
            }
        }

        return describeInstances(instanceIds)
    }


    /*
    0 : pending

    16 : running

    32 : shutting-down

    48 : terminated

    64 : stopping

    80 : stopped


     */

    List<Instance> describeInstances(List<String> ids) {
        List<Instance> instances = []
        ec2Client.describeInstances(
            DescribeInstancesRequest.builder().instanceIds(ids).build() as DescribeInstancesRequest
        ).reservations().each {
            log.debug "Found reservation ${it.reservationId()}"
            instances.addAll(it.instances())
        }
        return instances
    }


    void waitForInstances(List<String> ids, InstanceState expectedState) {
        int expectedStatus = 16
        switch (expectedState) {
            case InstanceState.RUNNING:
                expectedStatus = 16
                break
            case InstanceState.TERMINATED:
                expectedStatus = 48
                break
            default:
                throw new RuntimeException("Invalid status $expectedState")
        }
        DescribeInstancesRequest request = DescribeInstancesRequest
            .builder()
            .instanceIds(ids)
            .build()

        boolean done = false
        while (!done) {
            done = true
            ec2Client.describeInstances(request).reservations().each {
                it.instances().each {
                    if (it.state().code() != expectedStatus) {
                        done = false
                        log.info "Instance ${it.instanceId()} is not yet ready: status ${it.state().name()}"
                    } else {
                        log.info "Instance ${it.instanceId()} is ${it.state().name()}"
                    }
                }
            }
            sleep(5 * 1000)
        }
    }
}


enum InstanceState {
    RUNNING, TERMINATED
}

class DropdownOption {
    String name
    String value
}

class DropdownHandler {
    private PluginWrapper wrapper
    private static DropdownHandler instance

    private DropdownHandler() {}

    static DropdownHandler getInstance(def args) {
        if (instance) {
            return instance
        }
        def configurationParameters = args.configurationParameters
        def authType = configurationParameters.authType
        def region = configurationParameters.region
        def roleArn = configurationParameters.roleArn

        def credentials = args.credential
        if (credentials.size() != 1) {
            return
        }
        def secretKeyId = credentials.first().userName
        def secretKey = credentials.first().password
        PluginWrapper wrapper = new PluginWrapper(
            accessKeyId: secretKeyId,
            accessKeySecret: secretKey,
            environmentAuth: authType == 'environment',
            roleArn: roleArn,
            region: region,
            ignoreSslIssues: true
        )
        instance = new DropdownHandler()
        instance.wrapper = wrapper
        return instance
    }


    List<DropdownOption> fetchDropdown(String parameterName) {
        switch (parameterName) {
            case 'zone': return availabilityZones()
            case 'image': return images()
            case 'instanceType': return instanceTypes()
            case 'group': return groups()
            case 'subnet_id': return subnets()
            case 'keyname': return keys()
            default: return []
        }
    }


    List<DropdownOption> images() {
        HttpResponse response = wrapper.rawHttpRequestHandler.executeHttpRequest('ec2', [
            Version: "2016-11-15",
            Action : "DescribeImages",
            Owner  : "self"
        ])
        String xml = response.getEntity().content.text
        def node = new XmlSlurper().parseText(xml)
        return node.imagesSet.item.collect {
            new DropdownOption(name: it.name, value: it.imageId)
        }
    }

    List<DropdownOption> availabilityZones() {
        HttpResponse response = wrapper.rawHttpRequestHandler.executeHttpRequest('ec2', [
            Version: "2016-11-15",
            Action : "DescribeAvailabilityZones",
        ])
        String xml = response.getEntity().content.text
        def node = new XmlSlurper().parseText(xml)
        return node.availabilityZoneInfo.item.collect {
            new DropdownOption(name: it.zoneName, value: it.zoneName)
        }
    }

    List<DropdownOption> keys() {
        HttpResponse response = wrapper.rawHttpRequestHandler.executeHttpRequest('ec2', [
            Version: "2016-11-15",
            Action : "DescribeKeyPairs",
        ])
        String xml = response.getEntity().content.text
        def node = new XmlSlurper().parseText(xml)
        return node.keySet.item.collect {
            //groupId
            new DropdownOption(name: it.keyName, value: it.keyName)
        }

    }

    List<DropdownOption> subnets() {
        HttpResponse response = wrapper.rawHttpRequestHandler.executeHttpRequest('ec2', [
            Version: "2016-11-15",
            Action : "DescribeSubnets",
        ])
        String xml = response.getEntity().content.text
        def node = new XmlSlurper().parseText(xml)
        return node.subnetSet.item.collect {
            //groupId
            new DropdownOption(name: it.subnetId, value: it.subnetId)
        }
    }

    List<DropdownOption> groups() {
        HttpResponse response = wrapper.rawHttpRequestHandler.executeHttpRequest('ec2', [
            Version: "2016-11-15",
            Action : "DescribeSecurityGroups",
        ])
        String xml = response.getEntity().content.text
        def node = new XmlSlurper().parseText(xml)
        return node.securityGroupInfo.item.collect {
            //groupId
            new DropdownOption(name: it.groupName, value: it.groupName)
        }
    }

    List<DropdownOption> instanceTypes() {
        InstanceType.values().collect {
            new DropdownOption(name: it.toString(), value: it.toString())
        }
    }
}


class RunInstancesParameters {
    String ami
    String sg
    String subnet
    String type
    String name
    String keyPairName
    String zone
    int count
    String privateIp
    String iamProfileName
    String tenancy
    String userData
    String instanceInitiatedShutdownBehavior
}