package com.electriccloud.plugin.spec.runinstance

import com.electriccloud.plugin.spec.EC2Helper
import com.electriccloud.plugin.spec.TestHelper
import software.amazon.awssdk.services.ec2.model.Instance
import spock.lang.Shared
import spock.lang.Unroll

class RunInstances extends TestHelper {
    @Shared
    def projectName = 'EC2 Run Instances Spec'

    @Shared
    def resourceTemplateName = 'EC2 Spec Template'

    @Shared
    def propResult = '/myJob/propResult'

    @Shared
    def keyname = 'ec2_specs'

    @Shared
    def iamProfile

    @Shared
    EC2Helper helper


    def doSetupSpec() {
        createConfig()
        helper = getHelperInstance()
        ensureKeyPair(keyname)
    }

    @Unroll
    def 'minimalistic template. IAM profile: "#iamProfile"'() {
        given:
        def templateName = 'simple specs'
        def environmentName = 'provisioned ec2 specs'
        def templateParams = [
            projectName : projectName,
            templateName: templateName,
            parameters  : [
                config        : getConfigName(),
                count         : '1',
                group         : group,
                image         : ami,
                keyname       : keyname,
                resource_zone : 'default',
                zone          : zone,
                propResult    : propResult,
                instanceType  : type,
                subnet_id     : '',
                use_private_ip: '0',
                iamProfileName: iamProfile,
            ]
        ]
        dslFile "dsl/template.dsl", templateParams
        when:
        def result = provisionEnvironment(projectName, templateName, environmentName)
        then:
        logger.debug(objectToJson(result))
        assert result.outcome == 'success'
        def instanceId = getJobProperty("${propResult}/instanceList", result.jobId)
        assert instanceId
        logger.debug(instanceId)
        Instance instance = helper.getInstance(instanceId)
        println instance
        logger.debug(objectToJson(instance))
        cleanup:
        def tearDownResult = tearDownEnvironment(projectName, environmentName)
        assert tearDownResult.outcome == 'success'
        assert tearDownResult.logs =~ /terminated/
        where:
        group     | ami      | zone      | type       | iamProfile
        'default' | getAmi() | getZone() | 't2.micro' | ''
        //'default' | TestHelper.getAmi() | getZone() | 't2.micro' | 'ecsInstanceRole'
    }


}
