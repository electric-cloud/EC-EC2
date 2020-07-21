package com.electriccloud.plugin.spec

import com.electriccloud.spec.PluginSpockTestSupport
import software.amazon.awssdk.services.ec2.model.CreateKeyPairRequest
import software.amazon.awssdk.services.ec2.model.DescribeKeyPairsRequest
import spock.util.concurrent.PollingConditions

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

    static def getAmi() {
        //Some ubuntu
        return 'ami-0ac80df6eff0e70b5'
    }

    static def getZone() {
        return getRegionName() + 'a'
    }

    static def getRegionName() {
        def regionName = System.getenv('AWS_REGION_NAME') ?: "us-east-1"
        return regionName
    }

    static def getConfigName() {
        return System.getenv('EC2_TEST_CONFIG_NAME') ?: "${getRegionName()}-config"
    }

    def deleteConfig() {
        deleteConfiguration(pluginName, getConfigName())
    }

    def createConfig() {
        String httpProxy = System.getenv('HTTP_PROXY') ?: ''
        String httpProxyUser = System.getenv('HTTP_PROXY_USER') ?: ''
        String httpProxyPass = System.getenv('HTTP_PROXY_PASS') ?: ''

        def pluginConfig = [
                service_url  : getEndpoint(),
                debug        : '10',
                attempt      : '1',
                desc         : 'Spec config',
                resource_pool: 'spec resource pool',
                workspace    : 'default',
                http_proxy   : httpProxy,
                credential   : configName,
                config       : configName,
        ]

        def credentials = [[credentialName: configName, userName: clientId, password: clientSecret]]
        if (httpProxy) {
            pluginConfig.proxy_credential = "${configName}_proxy_credential"
            credentials << [credentialName: configName + "_proxy_credential", userName: httpProxyUser, password: httpProxyPass]
        }

        def confPath = 'ec2_cfgs'
        def pluginName = 'EC-EC2'
        if (doesConfExist("/plugins/$pluginName/project/$confPath", configName)) {
//            TODO env
            if (System.getenv('RECREATE_CONFIG')) {
                deleteConfiguration(pluginName, configName)
            } else {
                println "Configuration $configName exists"
                return
            }
        }

        def result = runProcedure('/plugins/EC-EC2/project', 'CreateConfiguration', pluginConfig, credentials)
        assert result.outcome == 'success'
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

    def ensureKeyPair(name) {
        try {
            getHelperInstance().ec2Client.describeKeyPairs(DescribeKeyPairsRequest.builder().keyNames(name).build())
        } catch (Throwable e) {
            println e.message
            CreateKeyPairRequest request = CreateKeyPairRequest.builder().keyName(name).build()
            println getHelperInstance().ec2Client.createKeyPair(request)
        }
    }
}
