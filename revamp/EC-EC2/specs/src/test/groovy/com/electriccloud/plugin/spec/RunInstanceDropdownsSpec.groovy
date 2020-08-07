package com.electriccloud.plugin.spec

class RunInstanceDropdownsSpec extends TestHelper {

    static String procedureName = 'API_RunInstances'

    def setupSpec() {
        deleteConfiguration(pluginName, configName)
        createConfig()
    }

    def 'list images'() {
        when:
        def options = getFormalParameterOptions(pluginName, procedureName, 'image'
            , [config: configName])
        then:
        assert options.size() > 0
        println options
    }

    def 'list zones'() {
        when:
        def options = getFormalParameterOptions(pluginName, procedureName, 'zone'
            , [config: configName])
        then:
        assert options.size() > 0
        println options
    }

    def 'instanceTypes'() {
        when:
        def options = getFormalParameterOptions(pluginName, procedureName, 'instanceType'
            , [config: configName])
        then:
        assert options.size() > 0
        println options
    }

    def 'list groups'() {
        when:
        def options = getFormalParameterOptions(pluginName, procedureName, 'group'
            , [config: configName])
        then:
        assert options.size() > 0
        println options
    }

    def 'list subnets'() {
        when:
        def options = getFormalParameterOptions(pluginName, procedureName, 'subnet_id'
            , [config: configName])
        then:
        assert options.size() > 0
        println options
    }

    def 'list keys'() {
        when:
        def options = getFormalParameterOptions(pluginName, procedureName, 'keyname'
            , [config: configName])
        then:
        assert options.size() > 0
        println options
    }
}
