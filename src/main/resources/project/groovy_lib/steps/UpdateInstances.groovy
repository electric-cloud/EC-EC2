$[/myProject/preamble.groovy]

def configName = '$[config]'
def instanceIds = '$[instanceIDs]'
def securityGroupId = '$[group]'
def instanceType = '$[instanceType]'
def userData = '''$[userData]'''
def instanceShutdownBehaviour = '$[instanceInitiatedShutdownBehavior]'

def efClient = new EFClient()

try {
    def ec2Wrapper = EC2Wrapper.build(configName, efClient)
    ec2Wrapper.stepUpdateInstance(instanceIds: instanceIds,
        securityGroupId: securityGroupId,
        instanceType: instanceType,
        userData: userData,
        instanceShutdownBehaviour: instanceShutdownBehaviour
    )
} catch (PluginException e) {
    efClient.handleError(e.message)
}

