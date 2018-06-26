package com.electriccloud.plugin.spec

import spock.lang.Shared

class RunInstances extends TestHelper {
    @Shared
    def projectName = 'EC2 Run Instances Spec'

    @Shared
    def resourceTemplateName = 'EC2 Spec Template'

    @Shared
    def defaultTemplateConfig = [
        config: getConfigName(),
        count: '1',
        group: 'default',
        image: getAmi('default'),
        instanceType: 'm1.small',
        keyname: getKeyname('default'),
        resource_zone: 'default',
        zone: getZone('default')
    ]

    def doSetupSpec() {
        createConfig()
    }

    def 'simple template'() {
        given:
        def templateName = 'simple specs'
        def environmentName = 'provisioned ec2 specs'
        def templateParams = [
            projectName: projectName,
            templateName: templateName,
            parameters: defaultTemplateConfig
        ]
        dslFile "dsl/template.dsl", templateParams
        when:
        def result = provisionEnvironment(projectName, templateName, environmentName)
        then:
        logger.debug(objectToJson(result))
        assert result.outcome == 'success'
        cleanup:
        tearDownEnvironment(projectName, environmentName)
    }

    def getAmi(String name = 'default') {
//        TODO logic
        return 'ami-002d5b60'
    }

    def getKeyname(String name = 'default') {
        return 'pshubina_chronic3'
    }

    def getType(String name = 'default') {
        return 'm1.small'
    }

    def getZone(String name = 'default') {
        return 'us-west-1b'
    }
}
