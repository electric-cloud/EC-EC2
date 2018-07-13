package com.electriccloud.plugin.spec.updateinstance

import com.electriccloud.plugin.spec.EC2Helper
import com.electriccloud.plugin.spec.TestHelper
import software.amazon.awssdk.services.ec2.model.Instance
import software.amazon.awssdk.services.ec2.model.ShutdownBehavior

import spock.lang.Shared
import spock.lang.Stepwise
import spock.lang.Ignore

class UpdateInstances extends TestHelper {
    @Shared
    def projectName = 'EC2 Update Instances Spec'

    @Shared
    def resourceTemplateName = 'EC2 Spec Template'

    @Shared
    def propResult = '/myJob/propResult'

    @Shared
    def keyname = 'ec2_specs'

    @Shared
    EC2Helper helper

	@Shared instances = []

//    @Shared
//    def defaultTemplateConfig = [
//        config: getConfigName(),
//        count: '1',
//        group: 'default',
//        image: getAmi('default'),
//        instanceType: 'm1.small',
//        keyname: keyname,
//        resource_zone: 'default',
//        zone: getZone('default'),
//        propResult: propResult
//    ]

    def doSetupSpec() {
        createConfig()
        helper = getHelperInstance()
		def result = runProcedure(
			'/plugins/EC-EC2/project',
			'API_RunInstances',
			[
				config			: getConfigName(),
				propResult		: '/myJob/EC-EC2-Test-UpdateInstances',
				image			: 'ami-6a003c0f',
				keyname			: 'EC-EC2-Test',
				zone			: "${getRegionName()}c",
				count			: 2,
				instanceType	: "t2.nano",
			])
		assert result
		assert result.outcome == "success"
		assert result.jobId
		def prop = dsl("getProperty(propertyName: '/myJob/EC-EC2-Test-UpdateInstances/InstanceList', jobId: '${result.jobId}')")
		def instanceList = prop?.property?.value
		assert instanceList
		instances = instanceList.split(';')
		instances.each { assert it ==~ /^i-[\da-f]+$/ }
    }

	def 'simple update 1'() {
		when:
		def result = runProcedure(
			'/plugins/EC-EC2/project',
			'API_UpdateInstances',
			[
				config			: getConfigName(),
				instanceIDs		: instances[0],
				group			: 'sg-688e3800'
			])
		then:
		assert result
		assert result.outcome == "success"
        Instance instance = helper.getInstance(instances[0])
		assert helper.instanceInSecurityGroup(instance, 'sg-688e3800')
	}

	def 'simple update 2'() {
		when:
		def result = runProcedure(
			'/plugins/EC-EC2/project',
			'API_UpdateInstances',
			[
				config			: getConfigName(),
				instanceIDs		: instances[0],
				group			: 'sg-6d728404'
			])
		then:
		assert result
		assert result.outcome == "success"
        Instance instance = helper.getInstance(instances[0])
		assert helper.instanceInSecurityGroup(instance, 'sg-6d728404')
		assert ! helper.instanceInSecurityGroup(instance, 'sg-688e3800')
	}

	def 'complex update'() {
		when:
		def result = runProcedure(
			'/plugins/EC-EC2/project',
			'API_UpdateInstances',
			[
				config			: getConfigName(),
				instanceIDs		: instances.join(','),
				group			: 'sg-6d728404',
				instanceType	: 't2.micro',
				instanceInitiatedShutdownBehavior: ShutdownBehavior.TERMINATE,
				userData		: 'test user data'


			], [], null, 1200)
		then:
		assert result
		assert result.outcome == "success"
		instances.each {
	        Instance instance = helper.getInstance(it)
			assert helper.instanceInSecurityGroup(instance, 'sg-6d728404')
			assert ! helper.instanceInSecurityGroup(instance, 'sg-688e3800')
			assert instance.instanceTypeAsString() == "t2.micro"
			assert helper.getInstanceAttribute(it, "userData") == 'test user data'
			assert ShutdownBehavior.fromValue(helper.getInstanceAttribute(it, "instanceInitiatedShutdownBehavior")) == ShutdownBehavior.TERMINATE
		}
	}
	def cleanupSpec() {
		instances.each {
			runProcedure('/plugins/EC-EC2/project', 'API_Terminate', [ config : getConfigName(), id : it ])
		}
	}
}
