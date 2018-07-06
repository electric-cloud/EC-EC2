package com.electriccloud.plugin.spec.runinstance

import com.electriccloud.plugin.spec.EC2Helper
import com.electriccloud.plugin.spec.TestHelper
import software.amazon.awssdk.services.ec2.model.Instance
import spock.lang.Shared

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
    EC2Helper helper

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
    }

    def 'minimalistic template'() {
        given:
        def templateName = 'simple specs'
        def environmentName = 'provisioned ec2 specs'
        def templateParams = [
            projectName: projectName,
            templateName: templateName,
            parameters: [
                config: getConfigName(),
                count: '1',
                group: group,
                image: ami,
                keyname: keyname,
                resource_zone: 'default',
                zone: zone,
                propResult: propResult,
                instanceType: type,
                subnet_id: '',
                use_private_ip: '0'
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
        tearDownEnvironment(projectName, environmentName)
        where:
        group            |    ami           | zone            | type
        'default'        | 'ami-23e8c646'   | 'us-east-2c'    | 't2.micro'
    }


}
