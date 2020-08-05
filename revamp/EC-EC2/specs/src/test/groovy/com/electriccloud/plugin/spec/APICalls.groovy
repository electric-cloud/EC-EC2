package com.electriccloud.plugin.spec

import org.xml.sax.SAXParseException
import software.amazon.awssdk.services.ec2.model.CreateVolumeRequest
import software.amazon.awssdk.services.ec2.model.DeregisterImageRequest
import software.amazon.awssdk.services.ec2.model.DescribeVolumesRequest
import spock.lang.Ignore
import spock.lang.IgnoreIf
import spock.lang.Shared
import spock.lang.Stepwise
import spock.util.concurrent.PollingConditions

@Stepwise
@Ignore
class APICalls extends TestHelper {
//	TODO get vars from environment or whatever
    static final String pluginName = 'EC-EC2'
    static final String timestamp = new Date().format("yyyyMMddHHmmss")
    static final String commonName = "EC-EC2-Test-${timestamp}"
    static final String amiToRun = 'ami-6a003c0f'
    static final EC2Helper ec2 = new EC2Helper()
    static final String httpProxy = System.getenv('HTTP_PROXY') ?: 0
    static final String httpProxyUser = System.getenv('HTTP_PROXY_USER') ?: ''
    static final String httpProxyPass = System.getenv('HTTP_PROXY_PASS') ?: ''
    static final Boolean skipElasticIp = System.getenv('SKIP_ELASTIC_IP') != null
    static final Boolean skipVolume = System.getenv('SKIP_VOLUME') != null
    static final Boolean skipImage = System.getenv('SKIP_IMAGE') != null
    static final Boolean skipKey = System.getenv('SKIP_KEY') != null
    static final Boolean skipInstance = skipKey || (System.getenv('SKIP_INSTANCE') != null)
    static final Boolean skipVPC = System.getenv('SKIP_VPC') != null
    @Shared
            projectName
    @Shared
            vpcId
    @Shared
            allocatedIp
    @Shared
            instanceId
    @Shared
            imageId
    @Shared
            volumeId

    @Ignore
    // for debugging purposes
    def 'Dump and fail'() {
        when:
        print """Parameters obtained:
			pluginName = ${pluginName}
			projectName = ${projectName}
			timestamp	= ${timestamp}
			commonName	= ${commonName}
			amiToRun = ${amiToRun}
			skipElasticIp = ${skipElasticIp}
			skipVolume = ${skipVolume}
			skipInstance = ${skipInstance}
			skipImage = ${skipImage}
			"""
        then:
        1 == 0
    }

    def doSetupSpec() {
        projectName = dsl("getPlugin(pluginName: '${pluginName}')").plugin.projectName
    }

    def 'CreateConfiguration'() {
        when: 'CreateConfiguration procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'CreateConfiguration',
                [
                        attempt         : 1,
                        config          : commonName,
                        debug           : 10,
                        desc            : 'Spec 2 config',
                        resource_pool   : 'spec 2 resource pool',
                        service_url     : getEndpoint(),
                        workspace       : 'default',
                        http_proxy      : httpProxy,
                        credential      : commonName,
                        proxy_credential: "${commonName}_proxy_credential"

                ], [[
                            credentialName: commonName,
                            userName      : getClientId(),
                            password      : getClientSecret()
                    ], [
                            credentialName: "${commonName}_proxy_credential",
                            userName      : httpProxyUser,
                            password      : httpProxyPass
                    ]
        ]
        )
        logger.info(objectToJson(result))
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    @IgnoreIf({ skipVPC })
    def 'API_CreateVPC'() {
        when: 'API_CreateVPC procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_CreateVPC',
                [
                        cidrBlock : '10.102.102.0/16',
                        config    : commonName,
                        vpcName   : commonName,
                        propResult: '/myJob/EC-EC2-Test'
                ])
        then: 'Job status is OK'
        result.outcome == 'success'

        when: 'jobId is retrieved'
        def jobId = result.jobId
        then: 'Job contains jobId'
        jobId != null

        when: 'vpcId is retrieved'
        def prop = dsl("getProperty(propertyName: '/myJob/EC-EC2-Test/VpcId', jobId: '${jobId}')")
        vpcId = prop?.property?.value
        then: 'Job has corresponidng prorerties set'
        prop != null
        vpcId != null
        and: 'VPC ID looks like one'
        vpcId ==~ /^vpc-[\da-f]+$/
    }

    @IgnoreIf({ skipVPC })
    def 'API_CreateSubnet'() {
        when: 'API_CreateVPC procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_CreateSubnet',
                [
                        availabilityZone: "${getRegionName()}c",
                        cidrBlock       : '10.102.103.0/24',
                        config          : commonName,
                        vpcId           : vpcId
                ])
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    @IgnoreIf({ skipKey })
    def 'API_CreateKey'() {
        when: 'API_CreateKey procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_CreateKey',
                [
                        config : commonName,
                        keyname: commonName
                ])
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    @IgnoreIf({ skipElasticIp })
    // TODO implement skipping via environment variables and @IgnoreIf
    def 'API_AllocateIP'() {
        when: 'API_AllocateIP procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_AllocateIP',
                [
                        config    : commonName,
                        propResult: '/myJob/EC-EC2-Test'
                ])
        then: 'Job status is OK'
        result.outcome == 'success'

        when: 'jobId is retrieved'
        def jobId = result.jobId
        then: 'Job contains jobId'
        jobId != null

        when: 'IP is retrieved'
        def prop = dsl("getProperty(propertyName: '/myJob/EC-EC2-Test/ip', jobId: '${jobId}')")
        allocatedIp = prop?.property?.value
        then: 'Job has corresponidng prorerties set'
        prop != null
        allocatedIp != null
        and: 'IP address looks roughy like one'
        allocatedIp ==~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
    }

    @IgnoreIf({ skipInstance })
    def 'API_RunInstances'() {
        when: 'API_RunInstances procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_RunInstances',
                [
                        config      : commonName,
                        propResult  : '/myJob/EC-EC2-Test',
                        image       : amiToRun,
                        keyname     : commonName,
                        zone        : "${getRegionName()}c",
                        count       : 1,
                        instanceType: "t2.nano",
                ])
        then: 'Job status is OK'
        result.outcome == 'success'

        when: 'jobId is retrieved'
        def jobId = result.jobId
        then: 'Job contains jobId'
        jobId != null

        when: 'instanceId is retrieved'
        def prop = dsl("getProperty(propertyName: '/myJob/EC-EC2-Test/InstanceList', jobId: '${jobId}')")
        instanceId = prop?.property?.value
        then: 'Job has corresponidng prorerties set'
        prop != null
        instanceId != null
        and: 'Instance ID looks like one'
        instanceId ==~ /^i-[\da-f]+$/
    }

    @IgnoreIf({ skipInstance })
    def 'API_DescribeInstances'() {
        when: 'API_DescribeInstances procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_DescribeInstances',
                [
                        config    : commonName,
                        propResult: '/myJob/EC-EC2-Test',
                        instances : instanceId
                ])
        then: 'Job status is OK'
        result.outcome == 'success'

        when: 'jobId is retrieved'
        def jobId = result.jobId
        then: 'Job contains jobId'
        jobId != null

        when: 'describe XML exists'
        def prop = dsl("getProperty(propertyName: '/myJob/EC-EC2-Test/describe', jobId: '${jobId}')")
        def describeXml = prop?.property?.value
        then: 'Job has corresponidng prorerties set'
        prop != null
        describeXml != null

        when: 'Attempt to parse XML is made'
        def list = new XmlParser().parseText(describeXml)
        then: 'describe yielded a valid xml document'
        notThrown(SAXParseException)
    }

    @IgnoreIf({ skipElasticIp || skipInstance })
    def 'API_AssociateIP'() {
        when: 'API_AssociateIP procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_AssociateIP',
                [
                        config  : commonName,
                        instance: instanceId,
                        ip      : allocatedIp
                ])
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    @IgnoreIf({ skipElasticIp })
    def 'API_ReleaseIP'() {
        when: 'API_ReleaseIP procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_ReleaseIP',
                [
                        config: commonName,
                        ip    : allocatedIp
                ])
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    @IgnoreIf({ skipInstance })
    def 'API_StopInstance'() {
        when: 'API_StopInstance procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_StopInstance',
                [
                        config  : commonName,
                        instance: instanceId
                ])
        def poll = new PollingConditions(timeout: 120, initialDelay: 10, delay: 10, factor: 2)
        poll.eventually {
            def instance = ec2.getInstance(instanceId)
            instance.state().name() == "stopped"
        }
        then: 'Job status is OK'
        result.outcome == 'success'
        and: 'instance is actually stopped'
    }

    @IgnoreIf({ skipInstance })
    def 'API_StartInstance'() {
        when: 'API_StartInstance procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_StartInstance',
                [
                        config  : commonName,
                        instance: instanceId
                ], [], null, 300)
        def poll = new PollingConditions(timeout: 120, initialDelay: 10, delay: 10, factor: 2)
        poll.eventually {
            ec2.getInstance(instanceId).state().name() == "running"
        }
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    @IgnoreIf({ skipImage || skipInstance })
    def 'API_CreateImage'() {
        when: 'API_CreateImage procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_CreateImage',
                [
                        config    : commonName,
                        propResult: '/myJob/EC-EC2-Test',
                        instance  : instanceId,
                        desc      : "EC-EC2 testing process",
                        name      : commonName,
                        noreboot  : 1
                ], [], null, 300)
        then: 'Job status is OK'
        result.outcome == 'success'

        when: 'jobId is retrieved'
        def jobId = result.jobId
        then: 'Job contains jobId'
        jobId != null

        when: 'imageId is retrieved'
        def prop = dsl("getProperty(propertyName: '/myJob/EC-EC2-Test/NewAMI', jobId: '${jobId}')")
        imageId = prop?.property?.value
        then: 'Job has corresponidng prorerties set'
        prop != null
        imageId != null
        and: 'Image ID looks like one'
        imageId ==~ /^ami-[\da-f]+$/
    }

    @Ignore
    def 'API_DeleteImage'() { //
        // TODO implement this procedure using DeregisterInstance call in API_Run.pl
        // yes, DeregisterInstance does nothing to instances, instead it removes AMIs
    }

    @IgnoreIf({ skipVolume })
    def 'API_CreateVolume'() {
        // TODO implement this procedure using CreateVolume call in API_Run.pl
        when: "Volume is created via direct call"
        CreateVolumeRequest request = CreateVolumeRequest.builder().availabilityZone("${getRegionName()}c").size(1).build()
        def result = ec2.ec2Client.createVolume(request)
        volumeId = result.volume().volumeId()
        // Wait for volume to be actually created, otherwise next test will fail
        def poll = new PollingConditions(timeout: 1200, initialDelay: 10, delay: 10, factor: 2)
        poll.eventually {
            def volume = ec2.ec2Client.describeVolumes(DescribeVolumesRequest.builder().volumeIds(volumeId).build()).volumes.get(0)
            volume.stateAsString() == "available"
        }
        then: 'Volume ID looks roughly like one'
        volumeId ==~ /^vol-[\da-f]+$/
    }

    @IgnoreIf({ skipVolume || skipInstance })
    def 'API_AttachVolumes'() {
        when: 'API_AttachVolumes procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_AttachVolumes',
                [
                        config   : commonName,
                        device   : "/dev/sdh",
                        instances: instanceId,
                        volumes  : volumeId
                ], [], null, 3600)
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    @IgnoreIf({ skipVolume || skipInstance })
    def 'API_DeleteVolume - detachOnly'() {   // >>> detachOnly == 1 <<<
        when: 'API_DeleteVolume procedure is ran with detachOnly = 1'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_DeleteVolume',
                [
                        config    : commonName,
                        volumes   : volumeId,
                        detachOnly: 1
                ], [], null, 300)
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    @IgnoreIf({ skipVolume })
    def 'API_DeleteVolume'() {
        when: 'API_DeleteVolume procedure is ran with detachOnly = 0'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_DeleteVolume',
                [
                        config    : commonName,
                        volumes   : volumeId,
                        detachOnly: 0
                ])
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    @IgnoreIf({ skipInstance })
    def 'API_Terminate'() {
        when: 'API_Terminate procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_Terminate',
                [
                        config: commonName,
                        id    : instanceId
                ])
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    @IgnoreIf({ skipKey })
    def 'API_DeleteKey'() {
        when: 'API_DeleteKey procedure is ran'
        def result = runProcedure(
                '/plugins/EC-EC2/project',
                'API_DeleteKey',
                [
                        config : commonName,
                        keyname: commonName
                ])
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    @IgnoreIf({ skipVPC })
    def 'API_DeleteVPC'() {
        when: 'API_DeleteVPC procedure is ran'
        def result = runProcedure(projectName, 'API_DeleteVPC', [config: commonName, vpcId: vpcId])
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    def 'DeleteConfiguration'() {
        when: 'DeleteConfiguration procedure is ran'
        def result = runProcedure(
                projectName,
                'DeleteConfiguration',
                [
                        config: commonName,
                ])
        then: 'Job status is OK'
        result.outcome == 'success'
    }

    def cleanupSpec() {
        if (instanceId) {
            runProcedure(projectName, 'API_Terminate', [config: commonName, id: instanceId])
        }
        if (vpcId) {
            runProcedure(projectName, 'API_DeleteVPC', [config: commonName, vpcId: vpcId])
        }
        if (allocatedIp) {
            runProcedure(projectName, 'API_ReleaseIP', [config: commonName, ip: allocatedIp])
        }
        if (volumeId) {
            runProcedure(projectName, 'API_DeleteVolume', [config: commonName, volumes: volumeId, detachOnly: 0])
        }
        if (imageId) { //TODO re-implement with API_DeleteImage procedure
            DeregisterImageRequest request = DeregisterImageRequest.builder().imageId(imageId).build()
            ec2.ec2Client.deregisterImage(request)
        }
        if (!skipKey) {
            runProcedure(projectName, 'API_DeleteKey', [config: commonName, keyname: commonName])
        }
        // THIS ONE SHOULD BE LAST
        runProcedure(projectName, 'DeleteConfiguration', [config: commonName])
    }
}
