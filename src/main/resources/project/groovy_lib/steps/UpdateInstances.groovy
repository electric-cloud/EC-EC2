$[/myProject/preamble.groovy]

def efClient = new EFClient()
Map parameters = efClient.readParameters('config', 'instanceIDs', 'group', 'instanceType', 'userData', 'instanceInitiatedShutdownBehavior')

try {
    def ec2Wrapper = EC2Wrapper.build(parameters.config, efClient)
    ec2Wrapper.stepUpdateInstance(parameters)
} catch (PluginException e) {
    efClient.handleError(e.message)
}

