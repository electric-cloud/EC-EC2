package com.electriccloud.plugin.spec

import com.electriccloud.spec.PluginSpockTestSupport
import com.jayway.restassured.http.ContentType
import com.jayway.restassured.response.Response
import groovy.json.JsonSlurper
import spock.util.concurrent.PollingConditions
import sun.reflect.generics.reflectiveObjects.NotImplementedException

import static com.jayway.restassured.RestAssured.given

class TestHelper extends PluginSpockTestSupport {
    static EC2Helper helper
    static final String pluginName = 'EC-EC2'

    static EC2Helper getHelperInstance() {
        if (!helper) {
            helper = new EC2Helper(regionName: getRegionName())
        }
        return helper
    }

    def commanderVersion() {
        def request
        retryOnConnectionError{
            request = given().get('/server/versions').then()
        }
        Response response = request.contentType(ContentType.JSON)
           .extract()
           .response()
        String json = response.asString()
        def slurper = new JsonSlurper()
        def version = slurper.parseText(json)
        return version?.serverVersion?.version
    }

    def compareVersion(desiredVersion) {
        def actualVersion = commanderVersion()

        def splitVersion = { version ->
            def parts = version.split(/\./)
            return [major: parts.getAt(0), minor: parts.getAt(1)]
        }

        def desired = splitVersion(desiredVersion)
        def actual = splitVersion(actualVersion)

        int result = actual.major <=> desired.major
        if (!result) {
            result = actual.minor <=> desired.minor
        }
        return result
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

    static def getHttpProxy() {
        return System.getenv('HTTP_PROXY') ?: 0
    }

    def createConfig(configName = null) {
        if (!configName) {
            configName = getConfigName()
        }
        def withProxy = getHttpProxy()
        def compare = compareVersion('8.4')
        println "Version comparison: $compare"
        if (withProxy && compare >= 0) {
            return createConfigWithProxy()
        }
        def pluginConfig = [
            service_url: getEndpoint(),
            debug: '10',
            attempt: '1',
            desc: 'Spec config',
            resource_pool: 'spec resource pool',
            workspace: 'default',
        ]
        def props = [confPath: 'ec2_cfgs']

        if (System.getenv('RECREATE_CONFIG')) {
            props.recreate = true
        }
        createPluginConfiguration(
            pluginName,
            configName,
            pluginConfig,
            getClientId(),
            getClientSecret(),
            props
        )
    }

    def createConfigWithProxy(configName) {

        String httpProxy		= System.getenv('HTTP_PROXY') ?: 0
        String httpProxyUser	= System.getenv('HTTP_PROXY_USER') ?: ''
        String httpProxyPass	= System.getenv('HTTP_PROXY_PASS') ?: ''

        def result = runProcedure(
            '/plugins/EC-EC2/project',
            'CreateConfiguration',
            [
                attempt			: 1,
                config			: configName,
                debug			: 10,
                desc			: 'Spec 2 config',
                resource_pool 	: 'spec 2 resource pool',
                service_url		: getEndpoint(),
                workspace		: 'default',
                http_proxy		: httpProxy,
                credential		: configName,
                proxy_credential: "${configName}_proxy_credential"

            ], [ [
                     credentialName	: configName,
                     userName		: getClientId(),
                     password		: getClientSecret()
                 ], [
                     credentialName	: "${configName}_proxy_credential",
                     userName		: httpProxyUser,
                     password		: httpProxyPass
                 ]
            ]
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
