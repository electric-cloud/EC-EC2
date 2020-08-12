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

    static def getRoleArn() {
        return 'arn:aws:iam::372416831963:role/test-role-to-play-with-sts'
    }


    def createPluginConfig(config, credentials = []) {
        String httpProxy = System.getenv('HTTP_PROXY') ?: ''
        String httpProxyUser = System.getenv('HTTP_PROXY_USER') ?: ''
        String httpProxyPass = System.getenv('HTTP_PROXY_PASS') ?: ''

        config.credential = 'credential'
        config.proxy_credential = 'proxy_credential'
        config.httpProxyUrl = httpProxy
        config.sessionToken_credential = 'sessionToken_credential'

        if (!credentials.find { it.credentialName == 'credential' }) {
            credentials << [credentialName: 'credential', userName: clientId, password: clientSecret]
        }
        if (!credentials.find { it.credentialName == 'proxy_credential' }) {
            credentials << [credentialName: 'proxy_credential', userName: httpProxyUser, password: httpProxyPass]
        }
        if (doesConfExist("/plugins/$pluginName/project/ec_plugin_cfgs", configName)) {
            println "Configuration $configName exists"
        }
        if (!credentials.find { it.credentialName == 'sessionToken_credential' }) {
            credentials << [credentialName: 'sessionToken_credential', userName: '', password: '']
        }
        println credentials

        def result = runProcedure('/plugins/EC-EC2/project', 'CreateConfiguration', config, credentials)
        assert result.outcome == 'success'
    }

    def createConfig() {
        String httpProxy = System.getenv('HTTP_PROXY') ?: ''
        String httpProxyUser = System.getenv('HTTP_PROXY_USER') ?: ''
        String httpProxyPass = System.getenv('HTTP_PROXY_PASS') ?: ''

        def pluginConfig = [
            region                 : getRegionName(),
            debugLevel             : '10',
            checkConnection        : '0',
            desc                   : 'Spec config',
            credential             : 'credential',
            config                 : configName,
            authType               : 'basic',
            proxy_credential       : 'proxy_credential',
            httpProxyUrl           : httpProxy,
            sessionToken_credential: 'sessionToken_credential'
        ]

        def credentials = [
            [credentialName: 'credential', userName: clientId, password: clientSecret],
            [credentialName: 'proxy_credential', userName: httpProxyUser, password: httpProxyPass],
            [credentialName: 'sessionToken_credential', userName: '', password: '']
        ]
        if (doesConfExist("/plugins/$pluginName/project/ec_plugin_cfgs", configName)) {
            println "Configuration $configName exists"
            return
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

    List<Map> getFormalParameterOptions(String pluginName, String procedureName, String parameterName, Map actualParameters) {
        String params = actualParameters.collect { k, v -> "$k: '$v'" }.join(",")
        String script = """
getFormalParameterOptions formalParameterName: '$parameterName',
    projectName: '/plugins/$pluginName/project',
    procedureName: '$procedureName',
    actualParameter: [$params]
            """
        def formalParameterOptions = dsl(script)?.option
        return formalParameterOptions
    }


    def switchUser() {
        String userName = 'ec2-provision-spec-user'

        try {
            dsl """
                createUser userName: "$userName", email: '$userName', password: "$userName"
            """
            println ":Created user $userName"
        } catch (Throwable e) {

        }
        //ACL

        def allowAll = """
 changePermissionsPrivilege = 'allow'
 executePrivilege = 'allow'
 modifyPrivilege = 'allow'
 readPrivilege = 'allow'
"""

        dsl """
aclEntry principalType: 'user', principalName: '$userName', {
    systemObjectName = 'projects'
    objectType = 'systemObject'
$allowAll
}


aclEntry principalType: 'user', principalName: '$userName', {
    systemObjectName = 'resources'
    objectType = 'systemObject'
$allowAll
}


aclEntry principalType: 'user', principalName: '$userName', {
    zoneName = 'default'
    objectType = 'zone'
$allowAll
}

"""
        login(userName, userName)
    }

    def switchAdmin() {
        def userName = System.getProperty("COMMANDER_USER", "admin")
        def password = System.getProperty("COMMANDER_PASSWORD", "changeme")
        login(userName, password)
    }
}
