@Grapes([
    @Grab(group='net.sf.json-lib', module='json-lib', version='2.3', classifier ='jdk15'),
    @Grab('org.codehaus.groovy.modules.http-builder:http-builder:0.7.1' ),
    @Grab(group = 'com.amazonaws', module = 'aws-java-sdk-ec2', version = '1.11.360'),
])
import com.amazonaws.auth.BasicAWSCredentials
import com.amazonaws.auth.AWSStaticCredentialsProvider
import com.amazonaws.regions.Regions
import com.amazonaws.services.ec2.*
import com.amazonaws.services.ec2.AmazonEC2ClientBuilder


