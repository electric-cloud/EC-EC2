package com.electriccloud.plugin.spec.ec2autocleanup

import com.electriccloud.plugin.spec.EC2Helper
import com.electriccloud.plugin.spec.TestHelper
import software.amazon.awssdk.services.ec2.model.Instance
import software.amazon.awssdk.services.ec2.model.ShutdownBehavior

import spock.lang.Shared
import spock.lang.Stepwise
import spock.lang.Ignore

class EC2AutoCleanup extends TestHelper {
    @Shared EC2Helper helper

    @Shared instances = []
    @Shared keyName
    @Shared reservation

    @Shared projectName

    def doSetupSpec() {
        createConfig()

        def result = createWrapperProject("EC2 Auto Cleanup", ['config', 'keyname', 'reservation', 'resources', 'volumes'])
        assert result?.project
        projectName = result.project.projectName

        result = runProcedure(
            '/plugins/EC-EC2/project',
            'EC2 Auto Deploy',
            [
                cleanup_tag : "ec2 spec test",
                config      : getConfigName(),
                count       : 2,
                'EC2 AMI'   : getAmi(),
                group       : 'default',
                instanceType: getInstanceType(),
                propResult  : '/myJob/AutoCleanup',
                zone        : "${getRegionName()}c"
            ], [], null, 3600 )
        assert result
        assert result.outcome == "success"
		def jobId = result.jobId
        def prop = dsl("getProperty(propertyName: '/myJob/AutoCleanup/InstanceList', jobId: '${jobId}')")
        instances = prop?.property?.value.split(/[;,]/)
        assert instances.size() == 2
        keyName = dsl("getProperty(propertyName: '/myJob/AutoCleanup/KeyPairId', jobId: '${jobId}')").property?.value
        reservation = dsl("getProperty(propertyName: '/myJob/AutoCleanup/Reservation', jobId: '${jobId}')").property?.value


    }

    def 'autocleanup'() {
        when:
        def result = runProcedure(
            projectName,
            'EC2 Auto Cleanup',
            [
                config      : getConfigName(),
                keyname     : keyName,
                reservation : reservation
            ], [], null, 3600 )
        then:
        assert result
        assert result.outcome == "success"
    }

    def cleanupSpec() {
        instances.each {
            runProcedure('/plugins/EC-EC2/project', 'API_Terminate', [ config : getConfigName(), id : it ])
        }
    }
}
