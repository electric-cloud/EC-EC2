package com.electriccloud.plugin.spec.ec2autodeploy

import com.electriccloud.plugin.spec.EC2Helper
import com.electriccloud.plugin.spec.TestHelper
import software.amazon.awssdk.services.ec2.model.Instance
import software.amazon.awssdk.services.ec2.model.ShutdownBehavior

import spock.lang.Shared
import spock.lang.Stepwise
import spock.lang.Ignore

class EC2AutoDeploy extends TestHelper {
    @Shared EC2Helper helper

    @Shared instances = []

    @Shared projectName

    def doSetupSpec() {
        createConfig()

        def result = createWrapperProject("EC2 Auto Deploy", ['cleanup_tag', 'config', 'count', 'EC2 AMI', 'group', 'instanceType', 'propResult', 'zone'])
        assert result?.project
        projectName = result.project.projectName
    }

    def 'deploy'() {
        when:
        def result = runProcedure(
            projectName,
            'EC2 Auto Deploy',
            [
                cleanup_tag : "ec2 spec test",
                config      : getConfigName(),
                count       : 2,
                'EC2 AMI'   : getAmi(),
                group       : 'default',
                instanceType: getInstanceType(),
                propResult  : '/myJob/AutoDeploy',
                zone        : "${getRegionName()}c"
            ], [], null, 3600 )
        then:
        assert result
        assert result.outcome == "success"

		when: 'jobId is retrieved'
			def jobId = result.jobId
		then: 'Job contains jobId'
			jobId != null

		when: 'instanceId is retrieved'
			def prop = dsl("getProperty(propertyName: '/myJob/AutoDeploy/InstanceList', jobId: '${jobId}')")
			instances = prop?.property?.value.split(/[;,]/)
        then:
            instances.size() == 2
    }

    def cleanupSpec() {
        instances.each {
            runProcedure('/plugins/EC-EC2/project', 'API_Terminate', [ config : getConfigName(), id : it ])
        }
    }
}
