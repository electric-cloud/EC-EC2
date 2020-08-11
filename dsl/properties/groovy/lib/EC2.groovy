import com.cloudbees.flowpdf.*
import software.amazon.awssdk.services.ec2.model.Instance

/**
 * EC2
 */
class EC2 extends FlowPlugin {

    @Override
    Map<String, Object> pluginInfo() {
        return [
            pluginName         : '@PLUGIN_KEY@',
            pluginVersion      : '@PLUGIN_VERSION@',
            configFields       : ['config'],
            configLocations    : ['ec_plugin_cfgs'],
            defaultConfigValues: [:]
        ]
    }

    PluginWrapper buildWrapper(Config config) {
        String region = config.getRequiredParameter("region")

        String proxyUrl = config.getParameter('httpProxyUrl')?.value
        String proxyUser = config.getCredential('proxy_credential')?.userName
        String proxyPassword = config.getCredential('proxy_credential')?.secretValue

        switch (config.getRequiredParameter('authType').value) {
            case 'environment':
                return new PluginWrapper(
                    environmentAuth: true,
                    log: log,
                    region: region,
                    proxyUrl: proxyUrl,
                    proxyUser: proxyUser,
                    proxyPassword: proxyPassword,
                )
            case 'basic':
                def credential = config.getRequiredCredential('credential')
                return new PluginWrapper(
                    accessKeyId: credential.userName,
                    accessKeySecret: credential.secretValue,
                    log: log,
                    region: region,
                    proxyUrl: proxyUrl,
                    proxyUser: proxyUser,
                    proxyPassword: proxyPassword,
                )
            case 'sts':
                def credential = config.getRequiredCredential('credential')
                String roleArn = config.getRequiredParameter('roleArn')
                return new PluginWrapper(
                    accessKeyId: credential.userName,
                    accessKeySecret: credential.secretValue,
                    roleArn: roleArn,
                    log: log,
                    region: region,
                    proxyUrl: proxyUrl,
                    proxyUser: proxyUser,
                    proxyPassword: proxyPassword,
                )
            case 'sessionToken':
                def credential = config.getRequiredCredential('credential')
                def token = config.getRequiredCredential('sessionToken_credential')
                return new PluginWrapper(
                    accessKeyId: credential.userName,
                    accessKeySecret: credential.secretValue,
                    log: log,
                    region: region,
                    sessionToken: token.secretValue,
                    proxyUrl: proxyUrl,
                    proxyUser: proxyUser,
                    proxyPassword: proxyPassword,
                )
            default:
                log.errorDiag("Invalid configuration. Auth type ${config.getRequiredParameter('authType').value} is not valid.")
                context.bailOut("Invalid configuration, invalid authType")
        }
    }

    @Lazy
    PluginWrapper wrapper = {
        return buildWrapper(getContext().getConfigValues())
    }()

    /** This is a special method for checking connection during configuration creation
     */
    def checkConnection(StepParameters p, StepResult sr) {

        try {
            // Put some checks here
            wrapper.testConnection()
        } catch (Throwable e) {
            // Set this property to show the error in the UI
            sr.setOutcomeProperty("/myJob/configError", e.message + System.lineSeparator())
            sr.apply()
            throw e
        }
    }

    // === check connection ends ===

    /**
     * aPI_RunInstances - API_RunInstances/API_RunInstances
     * Add your code into this method and it will be called when the step runs
     * @param config (required: true)
     * @param image (required: true)
     * @param zone (required: true)
     * @param name (required: false)
     * @param instanceType (required: true)
     * @param subnet_id (required: false)
     * @param group (required: false)
     * @param keyname (required: true)
     * @param instanceInitiatedShutdownBehavior (required: false)
     * @param iamProfileName (required: false)
     * @param privateIp (required: false)
     * @param tenancy (required: false)
     * @param userData (required: false)
     * @param use_private_ip (required: false)
     * @param count (required: false)
     * @param res_poolName (required: false)
     * @param res_port (required: false)
     * @param res_workspace (required: )
     * @param resource_zone (required: )
     * @param pingResource (required: )
     * @param propResult (required: )

     */
    def aPI_RunInstances(StepParameters p, StepResult sr) {
        // Use this parameters wrapper for convenient access to your parameters
        API_RunInstancesParameters sp = API_RunInstancesParameters.initParameters(p)


        RunInstancesParameters runInstancesParameters = new RunInstancesParameters(
            ami: sp.image,
            type: sp.instanceType,
            zone: sp.zone,
            name: sp.name ?: sp.res_poolName,
            subnet: sp.subnet_id,
            keyPairName: sp.keyname,
            sg: sp.group,
            userData: sp.userData,
            iamProfileName: sp.iamProfileName,
            tenancy: sp.tenancy,
            instanceInitiatedShutdownBehavior: sp.instanceInitiatedShutdownBehavior,
            count: sp.count as int,
            privateIp: sp.privateIp,
        )

        List<Instance> instances
        try {
            instances = wrapper.provisionInstances(runInstancesParameters)
            log.debug "Provisioned instances $instances"
        } catch (Throwable e) {
            return context.bailOut("Failed to provision instances: $e.message")
        }

        if (sp.propResult) {
            log.info "Saving results to the property sheet $sp.propResult"
            def ids = instances.collect { it.instanceId() }
            FlowAPI.setFlowProperty("$sp.propResult/InstanceList", ids.join(";"))
            instances.each {
                if (sp.count as int > 1) {
                    FlowAPI.setFlowProperty("$sp.propResult/Instance-${it.instanceId()}/AMI", it.imageId())
                    FlowAPI.setFlowProperty("$sp.propResult/Instance-${it.instanceId()}/Address", it.publicIpAddress())
                    FlowAPI.setFlowProperty("$sp.propResult/Instance-${it.instanceId()}/Private", it.privateIpAddress())
                    FlowAPI.setFlowProperty("$sp.propResult/Instance-${it.instanceId()}/Zone", it.placement().availabilityZone())
                } else {
                    FlowAPI.setFlowProperty("$sp.propResult/AMI", it.imageId())
                    FlowAPI.setFlowProperty("$sp.propResult/Address", it.publicIpAddress())
                    FlowAPI.setFlowProperty("$sp.propResult/Private", it.privateIpAddress())
                    FlowAPI.setFlowProperty("$sp.propResult/Zone", it.placement().availabilityZone())
                    FlowAPI.setFlowProperty("$sp.propResult/InstanceId", it.instanceId())
                }
            }
        }

        if (sp.res_poolName) {
            log.info "Provisioning resources in the pool $sp.res_poolName"
            int port = sp.res_port ? sp.res_port as int : 7800
            String me = '$[/myJob/launchedByUser]'

            instances.each {
                String id = it.instanceId()
                String ip = sp.use_private_ip == 'true' ? it.privateIpAddress() : it.publicIpAddress()
                log.info "Using IP address for the instance ${it.instanceId()}: $ip"

                String resourceName = "${sp.res_poolName}_${id}"
                FlowAPI.ec.createResource(
                    resourceName: resourceName,
                    description: 'EC2 provisioned resource (dynamic)',
                    resourcePools: sp.res_poolName,
                    workspaceName: sp.res_workspace ?: 'default',
                    port: port,
                    hostName: ip,
                    zoneName: sp.resource_zone ?: 'default'
                )
                log.info "Resource $resourceName has been created"

                try {
                    FlowAPI.ec.createAclEntry(
                        principalType: 'user',
                        principalName: "project: @PLUGIN_NAME@",
                        modifyPrivilege: 'allow',
                        readPrivilege: 'allow',
                        changePermissionPrivilege: 'allow',
                        executePrivilege: 'allow',
                        resourceName: resourceName
                    )
                }
                catch (Throwable e) {
                    log.info("Failed to grant ACL for the principal project: @PLUGIN_NAME@ at the resource: ${e.message}")
                }

                if (me) {
                    log.info "Launched by user: $me"
                    try {
                        FlowAPI.ec.createAclEntry(
                            principalType: 'user',
                            principalName: me,
                            modifyPrivilege: 'allow',
                            readPrivilege: 'allow',
                            changePermissionPrivilege: 'allow',
                            executePrivilege: 'allow',
                            resourceName: resourceName
                        )
                        log.info "Created ACL entry fot the resource $resourceName"
                    } catch (Throwable e) {
                        log.info "Failed to grant ACL for $me: ${e.message}"
                    }
                }

                String configName = p.getRequiredParameter('config').value as String
                FlowAPI.setFlowProperty("/resources/$resourceName/ec_cloud_instance_details/createdBy", "@PLUGIN_KEY@")
                FlowAPI.setFlowProperty("/resources/$resourceName/ec_cloud_instance_details/instance_id", id)
                FlowAPI.setFlowProperty("/resources/$resourceName/ec_cloud_instance_details/config", configName)
                FlowAPI.setFlowProperty("/resources/$resourceName/ec_cloud_instance_details/etc/private_ip", it.privateIpAddress())
                FlowAPI.setFlowProperty("/resources/$resourceName/ec_cloud_instance_details/etc/public_ip", it.publicIpAddress())

                if (sp.pingResource) {
                    log.info "Going to ping resource $resourceName"
                    def slept = 0
                    def ready = false
                    def sleepTime = 5
                    def timeout = 60 * 1000
                    while (!ready && slept < timeout) {
                        sleep(sleepTime * 1000)
                        slept += sleepTime
                        log.info "Pinging resource $resourceName (waiting for $slept seconds).."
                        def state = FlowAPI.ec.pingResource(resourceName: resourceName)
                        if (state?.resource?.agentState?.alive == "1") {
                            ready = true
                            log.info "Resource $resourceName is ready"
                        }
                    }
                    if (!ready) {
                        throw new RuntimeException("Failed to bring resource up in $timeout seconds, resource is not ready yet")
                    }
                }
            }
        }
    }

    /**
     * aPI_TearDownResource - API_TearDownResource/API_TearDownResource
     * Add your code into this method and it will be called when the step runs
     * @param resName (required: true)

     */
    def aPI_TearDownResource(StepParameters p, StepResult sr) {
        // Use this parameters wrapper for convenient access to your parameters
        API_TearDownResourceParameters sp = API_TearDownResourceParameters.initParameters(p)

        String resourceName = sp.resName

        def resourcePool
        def resources = []
        try {
            resourcePool = FlowAPI.ec.getResourcePool(resourcePoolName: resourceName)
            log.info "Resource Pool: $resourcePool"
            resourcePool?.resourcePool?.resourceNames?.resourceName?.each {
                resources << it
            }
        } catch (Throwable e) {
            log.info "Failed to get resource pool $resourceName"
            log.info "${e.message}"
        }

        try {
            def resource = FlowAPI.ec.getResource(resourceName: resourceName)
            resources << resourceName
        }
        catch (Throwable e) {
            log.info "Failed to get resource $resourceName"
            log.info("${e.message}")
        }
        log.info("Found resources $resources")
        def clients = [:]
        def errors = []
        def instances = [:]
        int opsDone = 0
        def totalOps = resources.size() * 2

        //Issuing terminate requests
        for (String resName in resources) {
            String createdBy = FlowAPI.getFlowProperty("/resources/$resName/ec_cloud_instance_details/createdBy")
            log.info "The resource $resName is created by $createdBy"
            String instanceId = FlowAPI.getFlowProperty("/resources/$resName/ec_cloud_instance_details/instance_id")
            log.info "The instance id is $instanceId"
            String config = FlowAPI.getFlowProperty("/resources/$resName/ec_cloud_instance_details/config")
            log.info "The config name is $config"
            if (createdBy == '@PLUGIN_KEY@') {
                PluginWrapper wrapper = clients[config]

                if (!wrapper) {
                    log.debug("Loading configuration for $config")
                    def cfg = context.retrieveConfigByNameAndLocation(config, pluginInfo().configLocations[0])
                    log.debug "Config $config is $cfg"
                    wrapper = buildWrapper(cfg)
                    clients[config] = wrapper
                    log.trace "Wrapper for config $config $wrapper"
                }

                try {
                    wrapper.terminateInstances([instanceId])
                    //should be only one instance
                    if (!instances[config]) {
                        instances[config] = []
                    }
                    instances[config] << instanceId
                    opsDone++
                    progressBar("Delete requests progress: ", opsDone / totalOps as double)
                    log.info "Terminating instance $instanceId"
                    FlowAPI.ec.deleteResource(resourceName: resName)
                    log.info "Deleted resource $resName"
                } catch (Throwable e) {
                    log.warning("Failed to delete $instanceId: $e.message")
                }
            } else {
                errors << "The resource $resName is not created by the plugin @PLUGIN_NAME@"
                log.warning("The resource $resName is not created by the plugin @PLUGIN_NAME@")
            }
        }

        //Now gathering statuses
        for (String configName in instances.keySet()) {
            PluginWrapper wrapper = clients[configName]
            List<String> instanceIds = instances[configName]
            log.info "Waiting for instances $instanceIds to be terminated"
            wrapper.waitForInstances(instanceIds, InstanceState.TERMINATED)
            opsDone++
            progressBar("Complete teardown progress:", opsDone / totalOps)
        }

        if (errors) {
            sr.setJobStepOutcome("error")
            sr.setJobStepSummary(errors.join("\n"))
            sr.apply()
        }
    }

    // === step ends ===
    private progressBar(String summary, double percent = 0) {
        def totalWidth = 100
        if (percent <= 1) {
            percent *= 100
        }
        def progressed = totalWidth * percent / 100
        def bar = "|" + ("=" * progressed) + ">" + ('-' * (totalWidth - progressed)) + "| $percent%"
        StepResult sr = context.newStepResult()
        sr.setJobStepSummary(summary + "\n" + bar)
        sr.apply()
    }
}