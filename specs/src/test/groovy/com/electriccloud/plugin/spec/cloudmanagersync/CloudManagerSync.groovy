package com.electriccloud.plugin.spec.cloudmanagersync

import groovy.util.XmlParser
import groovy.xml.XmlUtil
import groovy.xml.QName

import com.electriccloud.plugin.spec.EC2Helper
import com.electriccloud.plugin.spec.TestHelper
import software.amazon.awssdk.services.ec2.model.Instance
import software.amazon.awssdk.services.ec2.model.ShutdownBehavior

import spock.lang.Shared
import spock.lang.Stepwise
import spock.lang.Ignore

class CloudManagerSync extends TestHelper {
    @Shared EC2Helper helper

    @Shared growXmlText

    @Shared instances = []

    @Shared projectName

    def doSetupSpec() {
        createConfig()
        def result = createWrapperProject('CloudManagerSync', ['ec2_config', 'deployments'])
        assert result?.project
        projectName = result.project.projectName

        result = runProcedure(
            '/plugins/EC-EC2/project',
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
            ], [], null, 3600
        )
        assert result
        assert result.outcome == "success"
        def prop = dsl("getProperty(propertyName: '/myJob/CLoudManager/grow', jobId: '${result.jobId}')")
		growXmlText = prop?.property?.value
        assert growXmlText

        def growXml = new XmlParser().parseText(growXmlText)
        instances = growXml.Deployment.collect { grow -> grow.handle.text() }
        assert instances.size == 3
    }

    def 'shrink'() {
        when:
        def result = runProcedure(
            projectName,
            'CloudManagerSync',
            [
                ec2_config          : getConfigName(),
                deployments         : growXmlText
            ], [], null, 3600
        )
        then:
        assert result
        assert result.outcome == "success"

        when:
        def prop = dsl("getProperty(propertyName: '/myJob/CloudManager/sync', jobId: '${result.jobId}')")
		def syncXmlText = prop?.property?.value
        then:
        assert syncXmlText

        when:
        def syncXml = new XmlParser().parseText(syncXmlText)
        then:
        assert syncXml.size == 3
    }

    def cleanupSpec() {
        instances.each {
            runProcedure('/plugins/EC-EC2/project', 'API_Terminate', [ config : getConfigName(), id : it ])
        }
    }
}
