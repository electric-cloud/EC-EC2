import com.amazonaws.ClientConfiguration
@Grapes([
    @Grab('com.fasterxml.jackson.core:jackson-databind:2.11.1'),
    // @Grab(group='net.sf.json-lib', module='json-lib', version='2.3', classifier ='jdk15'),
    //
    // @Grab('org.codehaus.groovy.modules.http-builder:http-builder:0.7.1' ),
    @Grab(group = 'com.amazonaws', module = 'aws-java-sdk-ec2', version = '1.11.44'),
    @GrabExclude('org.apache.httpcomponents:httpclient'),
    @GrabExclude('net.sf.json-lib:json-lib'),
])
import com.amazonaws.auth.BasicAWSCredentials
import com.amazonaws.auth.AWSStaticCredentialsProvider
import com.amazonaws.regions.Regions
import com.amazonaws.services.ec2.*
import com.amazonaws.services.ec2.AmazonEC2ClientBuilder
import com.amazonaws.services.ec2.model.*
import groovy.json.JsonBuilder
import groovy.json.JsonOutput
import groovyx.net.http.HTTPBuilder
import groovyx.net.http.Method
import groovy.transform.InheritConstructors

import static groovyx.net.http.ContentType.JSON
import static groovyx.net.http.ContentType.URLENC
import static groovyx.net.http.Method.GET
import static groovyx.net.http.Method.POST
import static groovyx.net.http.Method.PUT


public class EC2Wrapper {
    def efClient
    def config
    AmazonEC2Client ec2Client
    def logger

    static def build(String configName, EFClient efClient) {
        def config = efClient.getConfigValues("ec2_cfgs", configName, '/plugins/EC-EC2/project')
        if (!config) {
            throw new PluginException("Config ${configName} does not exist")
        }
        def clientId = config.credential?.userName
        def clientSecret = config.credential?.password

        def credential = new BasicAWSCredentials(clientId, clientSecret)
        def credentialProvider = new AWSStaticCredentialsProvider(credential)
        def serviceUrl = config.service_url

        def group = serviceUrl =~ /ec2\.([\w-]+)\.amazonaws.com/
        def regionName
        try {
            regionName = group?.getAt(0)?.getAt(1) ?: 'us-east-1'
        }
        catch (IndexOutOfBoundsException e) {
            regionName = 'us-east-1'
        }
        def region = Regions.fromName(regionName)

        ClientConfiguration configuration = new ClientConfiguration()
        if (config.http_proxy) {
            URL url = new URL(config.http_proxy)
            configuration.withProxyPort(url.port).withProxyHost(url.host)
            String proxyUsername = config?.proxy_credential?.userName
            String proxyPassword = config?.proxy_credential?.password
            if (proxyUsername) {
                configuration.withProxyUsername(proxyUsername).withProxyPassword(proxyPassword)
            }
        }

        int debugLevel
        try {
            debugLevel = Integer.parseInt(config.debug)
        } catch (Throwable e) {
            debugLevel = 1
        }
        def logger = new PluginLogger(level: debugLevel)

        def ec2 = AmazonEC2ClientBuilder
            .standard()
            .withRegion(region)
            .withClientConfiguration(configuration)
            .withCredentials(credentialProvider)
            .build()

        return new EC2Wrapper(efClient: efClient, config: config, ec2Client: ec2, logger: logger)
    }

    def stepUpdateInstance(Map parameters) {
        String instanceIds = parameters.instanceIDs
        if (!instanceIds) {
            throw new PluginException("At least one instance ID must be provided")
        }
        List<Instance> instances = instanceIds?.split(/\s*,\s*/).collect {
            fetchInstance(it)
        }

        int updatedInstances = 0
        instances.each { Instance instance ->
            boolean updated = updateInstance(instance, parameters)
            logger.info("Finished updating instance")
            displayInstance(instance.instanceId)
            if (updated) {
                updatedInstances ++
            }
        }
        return updatedInstances
    }

    def updateInstance(Instance instance, Map parameters) {
        logger.info("Updating instance ${instance.instanceId}")
//        Security Group
        String oldSecurityGroups = instance.securityGroups.collect { it.groupId }.join(', ')
        if (parameters.group && oldSecurityGroups != parameters.group) {
            logger.debug("Going to update security group: old ${oldSecurityGroups}, new ${parameters.group}")
            ModifyInstanceAttributeRequest request = new ModifyInstanceAttributeRequest()
                .withInstanceId(instance.instanceId)
                .withGroups(parameters.group)
            ec2Client.modifyInstanceAttribute(request)
            logger.info("Set security group to ${parameters.group}")
        }

//        Shutdown Behaviour
        DescribeInstanceAttributeResult response = ec2Client.describeInstanceAttribute(
            new DescribeInstanceAttributeRequest(instance.instanceId, "instanceInitiatedShutdownBehavior")
        )
        if (parameters.instanceInitiatedShutdownBehavior &&
            response.instanceAttribute.instanceInitiatedShutdownBehavior != parameters.instanceInitiatedShutdownBehavior) {
            logger.debug("Going to update Instance Initiated Shutdown Behaviour")
            ec2Client.modifyInstanceAttribute(
                new ModifyInstanceAttributeRequest()
                    .withInstanceId(instance.instanceId)
                    .withInstanceInitiatedShutdownBehavior(parameters.instanceInitiatedShutdownBehavior)
                )
            logger.info("Set Initiated Shutdown Behaviour to ${parameters.instanceInitiatedShutdownBehavior}")
        }

        InstanceState oldState = instance.state
        if (!oldState.name in [InstanceStateName.Running.toString(), InstanceStateName.Stopped.toString()]) {
            logger.warning("Instance is in wrong state: ${oldState.name}, other attributes won't be updated")
            return false
        }
//        User Data
        response = ec2Client.describeInstanceAttribute(
            new DescribeInstanceAttributeRequest(instance.instanceId, "userData")
        )

        String userData = parameters.userData ?: ''
        String encodedUserData = userData.bytes.encodeBase64()
        if (parameters.userData && response.instanceAttribute.userData != encodedUserData) {
            logger.info("Instance must be stopped in order to change User Data")
            stopInstance(instance.instanceId)
            ec2Client.modifyInstanceAttribute(new ModifyInstanceAttributeRequest()
                .withInstanceId(instance.instanceId)
                .withUserData(encodedUserData)
            )
            logger.info("Set User Data to ${parameters.userData}")
        }

//        Instance Type
        if (parameters.instanceType && instance.instanceType != parameters.instanceType) {
            logger.info("Instance must be stopped in order to change Instance Type")
            stopInstance(instance.instanceId)
            ec2Client.modifyInstanceAttribute(new ModifyInstanceAttributeRequest()
                .withInstanceId(instance.instanceId)
                .withInstanceType(parameters.instanceType)
            )
            logger.info("Changed Instance Type to ${parameters.instanceType}")
        }

        instance = fetchInstance(instance.instanceId)
        if (instance.state.name != oldState.name) {
            if (oldState.name == InstanceStateName.Running.toString()) {
                startInstance(instance.instanceId, 120)
            }
        }
        return true
    }


    def fetchInstance(String instanceId) {
        DescribeInstancesRequest request = new DescribeInstancesRequest().withInstanceIds(instanceId)
        DescribeInstancesResult result = ec2Client.describeInstances(request)
        Instance instance = result.reservations?.getAt(0)?.instances?.getAt(0)
        return instance
    }

    String getInstanceName(Instance instance) {
        Tag nameTag = instance?.tags?.find { it.key == 'Name' }
        String retval
        if (nameTag) {
            retval = nameTag.value
        }
        return retval
    }

    def displayInstance(String instanceId) {
        Instance instance = fetchInstance(instanceId)
        logger.info("Instance ID: ${instance.instanceId}")
        logger.info("Instance Type: ${instance.instanceType}")
        logger.info("Instance Name: ${getInstanceName(instance)}")
        List groupNames = instance.securityGroups?.collect { it.groupName }
        if (groupNames) {
            logger.info("Security Groups: ${groupNames.join(', ')}")
        }
        DescribeInstanceAttributeResult userData = ec2Client.describeInstanceAttribute(
            new DescribeInstanceAttributeRequest(instanceId, "userData")
        )
        logger.info("User Data: ${new String(userData.instanceAttribute.userData.decodeBase64())}")
        DescribeInstanceAttributeResult shutdownBehaviour = ec2Client.describeInstanceAttribute(
            new DescribeInstanceAttributeRequest(instanceId, "instanceInitiatedShutdownBehavior")
        )
        logger.info("Shutdown Behaviour: ${shutdownBehaviour.instanceAttribute.instanceInitiatedShutdownBehavior}")
    }


    def stopInstance(String instanceId, timeout = 0) {
        Instance instance = fetchInstance(instanceId)
        if (instance.state.name == InstanceStateName.Stopped.toString()) {
            logger.debug("Instance $instanceId is already stopped")
            return
        }
        logger.info("Stopping instance $instanceId")
        ec2Client.stopInstances(new StopInstancesRequest().withInstanceIds(instanceId))
        Poll poll = new Poll(timeout: timeout)
        poll.poll {
            instance = fetchInstance(instanceId)
            instance.state.name == InstanceStateName.Stopped.toString()
        }
        logger.info("Instance $instanceId has been stopped")
    }

    def startInstance(String instanceId, timeout = 0) {
        Instance instance = fetchInstance(instanceId)
        if (instance.state.name == InstanceStateName.Running.toString()) {
            logger.debug("Instance $instanceId is already running")
            return
        }
        logger.info("Starting instance $instanceId")
        ec2Client.startInstances(new StartInstancesRequest().withInstanceIds(instanceId))
        Poll poll = new Poll(timeout: timeout)
        poll.poll {
            instance = fetchInstance(instanceId)
            instance.state.name == InstanceStateName.Running.toString()
        }
        logger.info("Instance $instanceId has been started")
    }

}


public class Poll {
    int timeout = 120
    def initialDelay = 0
    def factor = 1.5

    def poll(Closure closure) {
        if (initialDelay) {
            sleep(initialDelay * 1000)
        }
        int elapsed = 0
        boolean finished = false
        def delay = 2
        while(!finished && (elapsed < timeout || timeout == 0)) {
            try {
                finished = closure.call()
            } catch (Throwable e) {
                finished = false
            }
            elapsed += delay
            sleep((long) delay * 1000)
            delay *= factor
        }
        if (!finished) {
            throw new PluginException("The condition was not satisfied in the provided timeout $timeout")
        }
    }
}

public class EFClient extends BaseClient {

    def getServerUrl() {
        def commanderServer = System.getenv('COMMANDER_SERVER')
        def commanderPort = System.getenv("COMMANDER_HTTPS_PORT")
        def secure = Integer.getInteger("COMMANDER_SECURE", 1).intValue()
        def protocol = secure ? "https" : "http"

        return "$protocol://$commanderServer:$commanderPort"
    }

    // Shared uri prefix for all API calls
    private String uriPrefix = "/rest/v1.0/"

    public static def splitCommaSeparatedList( String list ) {
        if ( !list ) {
            return null
        }
        return list.split(/,\s/)
    }

    Object doHttpGet(String requestUri, boolean failOnErrorCode = true, def query = null) {
        def sessionId = System.getenv('COMMANDER_SESSIONID')
        doHttpRequest(GET, getServerUrl(), uriPrefix + requestUri, ['Cookie': "sessionId=$sessionId"],
            failOnErrorCode, /*requestBody*/ null, query)
    }

    Object doHttpPost(String requestUri, Object requestBody, boolean failOnErrorCode = true, def query = null) {
        def sessionId = System.getenv('COMMANDER_SESSIONID')
        doHttpRequest(POST, getServerUrl(), uriPrefix + requestUri, ['Cookie': "sessionId=$sessionId"], failOnErrorCode, requestBody, query)
    }

    Object doHttpPut(String requestUri, Object requestBody, boolean failOnErrorCode = true, def query = null) {
        def sessionId = System.getenv('COMMANDER_SESSIONID')
        doHttpRequest(PUT, getServerUrl(), uriPrefix + requestUri, ['Cookie': "sessionId=$sessionId"], failOnErrorCode, requestBody, query)
    }

    def readParameters(String ... names) {
//        TODO expansion
        Map params = names.sort().collectEntries {name ->
            String value = getEFProperty(name)
            println "Got parameter $name with value \"$value\""
            [(name): value]
        }
        return params
    }


    def getEFProperty(String propertyName) {
        def jobStepId = System.getenv('COMMANDER_JOBSTEPID')
        doHttpGet("properties/${propertyName}", true, [jobStepId: jobStepId])?.data?.property?.value
    }

    def setProperty( String jobStepId, String propertyName, String value) {
        def query = [
            propertyName: propertyName,
            value: value,
            jobStepId: jobStepId
        ]
        doHttpPost("properties", /* request body */ null, /* fail on error*/ true, query)
    }

    def setSummary(String summary) {
        def jobStepId = System.getenv('COMMANDER_JOBSTEPID')
        setProperty(jobStepId, "/myJobStep/summary", summary)
    }

    def getConfigValues(def configPropertySheet, def config, def pluginProjectName) {

        // Get configs property sheet
        def result = doHttpGet("projects/$pluginProjectName/$configPropertySheet", false)

        def configPropSheetId = result.data?.property?.propertySheetId
        if (!configPropSheetId) {
            throw new RuntimeException("No plugin configurations exist!")
        }

        result = doHttpGet("propertySheets/$configPropSheetId", false)
        // Get the property sheet id of the config from the result
        def configProp = result.data.propertySheet.property.find{
            it.propertyName == config
        }

        if (!configProp) {
            throw new RuntimeException("Configuration $config does not exist!")
        }

        result = doHttpGet("propertySheets/$configProp.propertySheetId")

        def values = result.data.propertySheet.property.collectEntries{
            [(it.propertyName): it.value]
        }


        logger(1, "Config values: " + values)

        values.each { k, v ->
            if (k =~ /credential/ && v) {
                def cred = getCredentials(v)
                values << [(k): [userName: cred.userName, password: cred.password]]
            }
        }

        logger(1, "After Config values: " + values ) // TODO DANGER!! CREDENTIALS!!!

        if ( values.debugLevel ) {
            values.debugLevel = values.debugLevel as int
        }
        else {
            values.debugLevel = 1
        }

        values
    }

    def getProvisionClusterParameters(String clusterName,
                                      String clusterOrEnvProjectName,
                                      String environmentName) {

        def partialUri = environmentName ?
            "projects/$clusterOrEnvProjectName/environments/$environmentName/clusters/$clusterName" :
            "projects/$clusterOrEnvProjectName/clusters/$clusterName"

        def result = doHttpGet(partialUri, true)

        def params = result.data.cluster?.provisionParameters?.parameterDetail

        if(!params) {
            handleError("No provision parameters found for cluster $clusterName!")
        }

        def provisionParams = params.collectEntries {
            [(it.parameterName): it.parameterValue]
        }

        return provisionParams
    }

    def getServiceDeploymentDetails(String serviceName,
                                    String serviceProjectName,
                                    String applicationName,
                                    String applicationRevisionId,
                                    String clusterName,
                                    String clusterProjectName,
                                    String environmentName,
                                    String serviceEntityRevisionId) {

        def partialUri = applicationName ?
            "projects/$serviceProjectName/applications/$applicationName/services/$serviceName" :
            "projects/$serviceProjectName/services/$serviceName"

        def queryArgs = [
            request: 'getServiceDeploymentDetails',
            clusterName: clusterName,
            clusterProjectName: clusterProjectName,
            environmentName: environmentName,
            applicationEntityRevisionId: applicationRevisionId
        ]

        if (serviceEntityRevisionId) {
            queryArgs << [serviceEntityRevisionId: serviceEntityRevisionId]
        }

        def result = doHttpGet(partialUri, true, queryArgs)
        def svcDetails = result.data.service

        svcDetails
    }


    def getCredentials(def credentialName) {
        assert credentialName
        def jobStepId = '$[/myJobStep/jobStepId]'
        def result = doHttpGet("jobsSteps/$jobStepId/credentials/$credentialName")
        logger(1, result)
        result.data.credential
    }


    def handleError (String msg) {
        println "ERROR: $msg"
        System.exit(-1)
    }
}

public class BaseClient {

    def logLevel = 2

    Object doHttpRequest(Method method, String requestUrl,
                         String requestUri, def requestHeaders,
                         Boolean failOnErrorCode = true,
                         Object requestBody = null,
                         def queryArgs = null) {

        logger(1, "requestUrl: $requestUrl")
        logger(1, "URI: $requestUri")
        logger(1, "Query: $queryArgs")
        if (requestBody) logger(1, "Payload: $requestBody")

        def http = new HTTPBuilder(requestUrl)
        http.ignoreSSLIssues()

        http.request(method, JSON) {
            uri.path = requestUri
            headers = requestHeaders
            body = requestBody
            uri.query = queryArgs

            response.success = { resp, json ->
                logger(1, "request was successful $resp.statusLine.statusCode $json")
                [statusLine: resp.statusLine,
                 data      : json]
            }

            response.failure = { resp, reader ->
                println "Request $requestUri"
                println "Query: $queryArgs"
                println "request failed $resp.statusLine Error details:\n$reader"
                if ( failOnErrorCode ) {
                    handleError("Request failed with $resp.statusLine")
                }
                [statusLine: resp.statusLine]
            }
        }
    }

    def logger (int level, def message) {
        if ( level >= this.logLevel ) {
            println message
        }
    }
}

public class Validation {
    def static int readInteger(String param, String fieldName) {
        int value
        try {
            value = param as int
        } catch (def exception) {
            println "ERROR: Field $fieldName should contain an integer value!"
            System.exit(-1)
        }
        return value
    }
}

@InheritConstructors
class PluginException extends Exception {}


class PluginLogger {
    def level = 1
    static int INFO = 1
    static int DEBUG = 2
    static int TRACE = 3
    static int ALWAYS = 0

    def info(Object... objects) {
        logger(INFO, objects)
    }

    def debug(Object... objects) {
        logger(DEBUG, '[DEBUG] ', objects)
    }

    def trace(Object... objects) {
        logger(TRACE, '[TRACE] ', objects)
    }

    def error(Object... objects) {
        logger(ALWAYS, "[ERROR] ", objects)
    }

    def warning(Object... objects) {
        logger(ALWAYS, '[WARNING] ', objects)
    }

    def printStackTrace( Throwable e ) {
        if (DEBUG <= level) {
            e.printStackTrace()
        }
    }

    def logger(def currentLevel, Object ... objects) {
        if ( currentLevel <= level || currentLevel == ALWAYS ) {
            objects.each { o ->
                if (o instanceof String || o instanceof GString) {
                    print o
                }
                else {
                    print JsonOutput.prettyPrint(JsonOutput.toJson(o))
                }
            }
            println ''
        }
    }
}
