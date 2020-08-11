package com.electriccloud.plugin.spec

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.sts.StsClient
import software.amazon.awssdk.services.sts.model.AssumeRoleRequest
import software.amazon.awssdk.services.sts.model.AssumeRoleResponse
import spock.lang.Shared

class ConfigurationSpec extends TestHelper {
    @Shared
    def projectName = 'EC2 Run Instances Spec'

    @Shared
    EC2Helper helper

    def 'basic configuration'() {
        when:
        def configName = 'test basic config'
        def pluginConfig = [
            region         : getRegionName(),
            debugLevel     : '10',
            checkConnection: '1',
            desc           : 'Spec config',
            credential     : configName,
            config         : configName,
            authType       : 'basic'
        ]

        createPluginConfig(pluginConfig)
        then:
        assert true
        cleanup:
        deleteConfiguration(pluginName, configName)
    }

    def 'configuration with role'() {
        when:
        def configName = 'test sts config'
        def pluginConfig = [
            region         : getRegionName(),
            debugLevel     : '10',
            checkConnection: '1',
            desc           : 'Spec config',
            credential     : configName,
            config         : configName,
            authType       : 'sts',
            roleArn        : roleArn
        ]

        createPluginConfig(pluginConfig)
        then:
        assert true
        cleanup:
        deleteConfiguration(pluginName, configName)
    }

    def 'configuration with token'() {
        setup:
        def credentials = AwsBasicCredentials.create(
            clientId,
            clientSecret
        )
        StsClient stsClient = StsClient
            .builder()
            .region(Region.of(regionName))
            .credentialsProvider(StaticCredentialsProvider.create(credentials))
            .build()
        String sessionName = 'test-session-id-' + new Random().nextInt()
        AssumeRoleRequest request = AssumeRoleRequest.builder()
            .roleArn(roleArn)
            .roleSessionName(sessionName)
            .build()
        AssumeRoleResponse response = stsClient.assumeRole(request)
        when:
        def configName = 'test session token config'
        def pluginConfig = [
            region                 : getRegionName(),
            debugLevel             : '10',
            checkConnection        : '1',
            desc                   : 'Spec config',
            credential             : 'credential',
            config                 : configName,
            authType               : 'sessionToken',
            roleArn                : '',
            sessionToken_credential: 'sessionToken_credential'
        ]
        createPluginConfig(pluginConfig, [
            [credentialName: 'credential', userName: response.credentials().accessKeyId(), password: response.credentials().secretAccessKey()],
            [credentialName: 'sessionToken_credential', userName: '', password: response.credentials().sessionToken()]
        ])
        then:
        assert true
        cleanup:
        deleteConfiguration(pluginName, configName)
    }
}
