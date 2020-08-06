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
        switchUser()
    }

    def doCleanupSpec() {
        switchAdmin()
    }

    @Unroll
    def 'minimalistic template. IAM profile: "#iamProfile", sg: #group'() {
        given:
        def templateName = 'simple specs'
        def environmentName = 'provisioned ec2 specs'
        def templateParams = [
            projectName : projectName,
            templateName: templateName,
            parameters  : [
                config                           : getConfigName(),
                count                            : '1',
                group                            : group,
                image                            : ami,
                keyname                          : keyname,
                resource_zone                    : 'default',
                zone                             : zone,
                propResult                       : propResult,
                instanceType                     : type,
                subnet_id                        : 'subnet-28240574',
                use_private_ip                   : '0',
                userData                         : userData,
                iamProfileName                   : iamProfile,
                instanceInitiatedShutdownBehavior: 'terminate'
            ]
        ]
        dslFile "dsl/template.dsl", templateParams
        when:
        def result = provisionEnvironment(projectName, templateName, environmentName)
        then:
        logger.debug(objectToJson(result))
        assert result.outcome == 'success'
        def instanceId = getJobProperty("${propResult}/InstanceList", result.jobId)
        assert instanceId
        logger.debug(instanceId)
        Instance instance = helper.getInstance(instanceId)
        println instance
        if (group) {
            assert instance.securityGroups().find { it.groupName() == group || it.groupId() == group }
        }
        println instance.securityGroups()
        println instance.iamInstanceProfile()
        logger.debug(objectToJson(instance))
        println instance.placement()
        assert instance.placement().availabilityZone() == zone
        cleanup:
        def tearDownResult = tearDownEnvironment(projectName, environmentName)
        assert tearDownResult.outcome == 'success'
        assert tearDownResult.logs =~ /terminated/
        where:
        group                  | ami      | zone      | type       | iamProfile | userData
        ''                     | getAmi() | getZone() | 't2.micro' | ''         | ''
        'default'              | getAmi() | getZone() | 't2.micro' | ''         | ''
        'another-sg'           | getAmi() | getZone() | 't2.micro' | ''         | ''
        //does not work
        //'sg-0f795e024778c1c53' | getAmi() | getZone() | 't2.micro' | 'test-role-for-iam-instance-profile' |
        'sg-0f795e024778c1c53' | getAmi() | getZone() | 't2.micro' | ''         | "#!/bin/bash\necho hello"
    }

}
