$[/myProject/preamble.groovy]

def configName = '$[config]'
def instanceId = '$[instanceID]'
def securityGroupId = '$[group]'
def instanceType = '$[instanceType]'
def userData = '''$[userData]'''

def efClient = new EFClient()

try {
    def ec2Wrapper = EC2Wrapper.build(configName, efClient)
    ec2Wrapper.stepUpdateInstance(instanceId: instanceId, securityGroupId: securityGroupId, instanceType: instanceType, userData: userData)
} catch (PluginException e) {
    efClient.handleError(e.message)
}

