import org.junit.jupiter.api.Disabled
import org.junit.jupiter.api.Test
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.ec2.Ec2Client
import software.amazon.awssdk.services.ec2.model.CreateKeyPairRequest
import software.amazon.awssdk.services.ec2.model.DescribeKeyPairsRequest

class WrapperTest {

    @Test
    void testConnection() {
        def wrapper = createWrapper()
        wrapper.testConnection()
    }

    @Test
    void runInstance() {
        def wrapper = createWrapper()
        String keyName = 'ec2_specs'
        ensureKeyPair(keyName)
        RunInstancesParameters p = new RunInstancesParameters(
            ami: 'ami-0ac80df6eff0e70b5',
            type: 't2.micro',
            sg: 'default',
            zone: 'us-east-1a',
            keyPairName: keyName,
            name: 'ec2 specs instance',
        )
        wrapper.provisionInstances(p)
    }

    @Test
    @Disabled
    void testWithProxy() {
        def wrapper = new PluginWrapper(
            accessKeySecret: accessKeySecret,
            accessKeyId: accessKeyId,
            region: 'us-east-1',
            proxyUrl: 'http://localhost:3128',
            proxyUser: 'user1',
            proxyPassword: 'password1'
        )
        wrapper.testConnection()
    }

    @Test
    void getAmi() {
        def wrapper = createWrapper()
        String amiName = 'aws-elasticbeanstalk-amzn-2015.09.09.x86_64-WindowsServer2012R2Core-pv-201510211032'
        def ami = wrapper.fetchAmi(amiName)
        println(ami)
        assert ami
    }

    static String getAccessKeyId() {
        def key = System.getenv('AWS_ACCESS_KEY_ID')
        assert key
        return key
    }

    static String getAccessKeySecret() {
        def secret = System.getenv('AWS_SECRET_ACCESS_KEY')
        assert secret
        return secret
    }

    static String getRoleArn() {
        def arn = System.getenv('AWS_ROLE_ARN')
        assert arn
        return arn
    }


    PluginWrapper createWrapper() {
        return new PluginWrapper(
            accessKeySecret: accessKeySecret,
            accessKeyId: accessKeyId,
            region: 'us-east-1'
        )
    }

    Ec2Client createClient() {
        Ec2Client.builder().region(Region.of('us-east-1'))
            .credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create(accessKeyId, accessKeySecret))).build()
    }

    def ensureKeyPair(name) {
        Ec2Client client = createClient()
        try {
            DescribeKeyPairsRequest request = DescribeKeyPairsRequest.builder().keyNames(name).build()
            client.describeKeyPairs(request)
        } catch (Throwable e) {
            println e.message
            CreateKeyPairRequest request = CreateKeyPairRequest.builder().keyName(name).build()
            println client.createKeyPair(request)
        }
    }

}