package com.electriccloud.plugin.spec

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

        createPluginConfiguration(pluginName,
            configName,
            pluginConfig,
            clientId,
            clientSecret
        )
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

        createPluginConfiguration(pluginName,
            configName,
            pluginConfig,
            clientId,
            clientSecret
        )
        then:
        assert true
        cleanup:
        deleteConfiguration(pluginName, configName)

    }
}
