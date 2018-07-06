package com.electriccloud.plugin.spec

import com.electriccloud.spec.PluginSpockTestSupport
import spock.util.concurrent.PollingConditions
import sun.reflect.generics.reflectiveObjects.NotImplementedException

class TestHelper extends PluginSpockTestSupport {
    static EC2Helper helper
    static final String pluginName = 'EC-EC2'

    static EC2Helper getHelperInstance() {
        if (!helper) {
            helper = new EC2Helper(regionName: getRegionName())
        }
        return helper
    }

    static def getClientId() {
        def id = System.getenv('AWS_ACCESS_KEY_ID')
        assert id
        return id
    }

    static def getClientSecret() {
        def secret = System.getenv('AWS_SECRET_ACCESS_KEY')
        assert secret
        return secret
    }

    static def getEndpoint() {
        def regionName = getRegionName()
        def endpoint = "https://ec2.${regionName}.amazonaws.com"
        return endpoint
    }

    static def getRegionName() {
        def regionName = System.getenv('AWS_REGION_NAME') ?: "us-east-2"
        return regionName
    }

    static def getConfigName() {
        return "${getRegionName()}-config"
    }

    def deleteConfig() {
        deleteConfiguration(pluginName, getConfigName())
    }

    def createConfig(withProxy = false) {
        if (withProxy) {
            throw new NotImplementedException()
        }
        def pluginConfig = [
            service_url: getEndpoint(),
            debug: '10',
            attempt: '1',
            desc: 'Spec config',
            resource_pool: 'spec resource pool',
            workspace: 'default',
            http_proxy: '0'
        ]
        def props = [confPath: 'ec2_cfgs']

        if (System.getenv('RECREATE_CONFIG')) {
            props.recreate = true
        }
        def configName = getConfigName()
        createPluginConfiguration(
            pluginName,
            configName,
            pluginConfig,
            getClientId(),
            getClientSecret(),
            props
        )
    }

    def provisionEnvironment(projectName, templateName, environmentName) {
        def result = dsl """
            provisionEnvironment projectName: '$projectName', environmentName: '$environmentName', environmentTemplateName: '$templateName'
"""

        PollingConditions poll = createPoll(120)
        poll.eventually {
            jobStatus(result.jobId).status == 'completed'
        }
        def outcome = jobStatus(result.jobId).outcome
        def logs = readJobLogs(result.jobId)
        return [jobId: result.jobId, logs: logs, outcome: outcome]
    }

    def tearDownEnvironment(projectName, envName) {
        def result = dsl "tearDownEnvironment projectName: '$projectName', environmentName: '$envName'"
        PollingConditions poll = createPoll(240)
        poll.eventually {
            jobStatus(result.jobId).status == 'completed'
        }
        def outcome = jobStatus(result.jobId).outcome
        def logs = readJobLogs(result.jobId)
        return [jobId: result.jobId, logs: logs, outcome: outcome]
    }
}
