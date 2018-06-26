package com.electriccloud.plugin.spec

import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.ec2.EC2Client
import software.amazon.awssdk.services.ec2.model.*

class EC2Helper {
    @Lazy(soft=true)
    String regionName = {return System.getenv('AWS_REGION_NAME')}()

    @Lazy
    EC2Client ec2Client = {
//        Builds credentials provider using environment variables
        DefaultCredentialsProvider provider = DefaultCredentialsProvider.builder().build()
        EC2Client client = EC2Client.builder()
                                    .region(Region.of(regionName))
                                    .credentialsProvider(provider)
                                    .build()
        return client
    }()

    Instance getInstance(String instanceId) {
        DescribeInstancesRequest request = DescribeInstancesRequest.builder().instanceIds(instanceId).build()
        DescribeInstancesResponse response = ec2Client.describeInstances(request)
        assert response.reservations().size() == 1
        Reservation reservation = response.reservations().first()
        Instance instance = reservation.instances().first()
        return instance
    }
}
