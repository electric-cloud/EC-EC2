$[/myProject/preamble.groovy]

def efClient = new EFClient()
Map parameters = efClient.readParameters('config', 'instanceIDs', 'group', 'instanceType', 'userData', 'instanceInitiatedShutdownBehavior')

try {
    def ec2Wrapper = EC2Wrapper.build(parameters.config, efClient)
    int updatedInstances = ec2Wrapper.stepUpdateInstance(parameters)
    efClient.setSummary("Updated instances: $updatedInstances")
} catch (PluginException e) {
    efClient.handleError(e.message)
}

