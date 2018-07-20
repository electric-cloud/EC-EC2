package com.electriccloud.plugin.spec.cloudmanagergrow

import groovy.util.XmlParser
import org.xml.sax.SAXParseException

import com.electriccloud.plugin.spec.EC2Helper
import com.electriccloud.plugin.spec.TestHelper
import software.amazon.awssdk.services.ec2.model.Instance
import software.amazon.awssdk.services.ec2.model.ShutdownBehavior



import spock.lang.Shared
import spock.lang.Stepwise
import spock.lang.Ignore

class CloudManagerGrow extends TestHelper {
    @Shared EC2Helper helper

    @Shared instances = []

    @Shared projectName

    def doSetupSpec() {
        createConfig()

        def result = createWrapperProject("CloudManagerGrow", ['ec2_config', 'ec2_image', 'ec2_instance_type', 'ec2_security_group', 'ec2_snapshot', 'ec2_userData', 'ec2_zone', 'number', 'poolName'])
        assert result?.project
        projectName = result.project.projectName

		def pluginProjectName = dsl("getPlugin(pluginName: '${pluginName}')").plugin?.projectName
        assert pluginProjectName
        result = grantPrivilegesOnResourceZone(pluginProjectName, 'default')
        assert result.aclEntry
    }

    def 'grow'() {
        when:
        def result = runProcedure(
            projectName,
            'CloudManagerGrow',
            [
                ec2_config          : getConfigName(),
                ec2_image           : getAmi(),
                ec2_instance_type   : getInstanceType(),
                ec2_security_group  : 'default',
                ec2_snapshot        : 'snap-091c80427ba24cc7f',
                ec2_userData        : "user data",
                ec2_zone            : "${getRegionName()}c",
                number              : 3,
                poolName            : 'blah'
            ], [], null, 3600 )
        then:
        assert result
        assert result.outcome == "success"

        when:
        def prop = dsl("getProperty(propertyName: '/myJob/CLoudManager/grow', jobId: '${result.jobId}')") // CLoud is not a typo, at least not a typo *from here*
		def growXmlText = prop?.property?.value
        then:
        assert growXmlText

        when:
        def growXml = new XmlParser().parseText(growXmlText)
        then:
        assert growXml

        when:
        instances = growXml.Deployment.collect { grow -> grow.handle.text() }
        then:
        assert instances.size == 3
    }

    def cleanupSpec() {
        instances.each {
            runProcedure('/plugins/EC-EC2/project', 'API_Terminate', [ config : getConfigName(), id : it ])
        }
    }
}
