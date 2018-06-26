package com.electriccloud.plugin.spec

import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.ec2.EC2Client
import software.amazon.awssdk.services.ec2.model.DescribeInstancesResponse

class EC2Helper {
    String regionName

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


    def testConnection() {
        DescribeInstancesResponse response = ec2Client.describeInstances()
        assert response.reservations().size() > 0
    }

}
