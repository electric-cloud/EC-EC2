@Grapes([
    @Grab(group = 'com.amazonaws', module = 'aws-java-sdk-ec2', version = '1.11.360'),
    @Grab('org.codehaus.groovy.modules.http-builder:http-builder:0.7.1' ),
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
        def regionName = group.getAt(0)?.getAt(1) ?: 'us-east-1'
        def region = Regions.fromName(regionName)
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
            .withCredentials(credentialProvider)
            .build()

        return new EC2Wrapper(efClient: efClient, config: config, ec2Client: ec2, logger: logger)
    }


    def stepUpdateInstance(Map parameters) {
        String instanceId = parameters.instanceId
        if (!instanceId) {
            throw new PluginException("Instance ID must be provided")
        }
        if (parameters.securityGroupId) {
            logger.debug("Changing security group to ${parameters.securityGroupId}")
            ModifyInstanceAttributeRequest request = new ModifyInstanceAttributeRequest()
                .withInstanceId(instanceId)
                .withGroups(parameters.securityGroupId)
            ec2Client.modifyInstanceAttribute(request)
        }
        if (parameters.instanceType) {
            logger.debug("Setting instance type to ${parameters.instanceType}")
            ModifyInstanceAttributeRequest request = new ModifyInstanceAttributeRequest()
                .withInstanceId(instanceId)
                .withInstanceType(parameters.instanceType)
            ec2Client.modifyInstanceAttribute(request)
        }
        displayInstance(instanceId)
    }


    def fetchInstance(String instanceId) {
        DescribeInstancesRequest request = new DescribeInstancesRequest().withInstanceIds(instanceId)
        DescribeInstancesResult result = ec2Client.describeInstances(request)
        Instance instance = result.reservations?.getAt(0)?.instances?.getAt(0)
        logger.debug(instance)
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


    def setProperty( String jobStepId, String propertyName, String value) {
        def query = [
            propertyName: propertyName,
            value: value,
            jobStepId: jobStepId
        ]
        doHttpPost("properties", /* request body */ null, /* fail on error*/ true, query)
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

        def cred = getCredentials(config)
        values << [credential: [userName: cred.userName, password: cred.password]]

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
        logger(1, "QUery: $queryArgs")
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
