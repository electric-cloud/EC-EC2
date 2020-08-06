import org.apache.http.HttpRequest
import org.apache.http.HttpResponse
import org.apache.http.client.HttpClient
import org.apache.http.client.methods.HttpGet
import org.apache.http.config.Registry
import org.apache.http.config.RegistryBuilder
import org.apache.http.conn.socket.ConnectionSocketFactory
import org.apache.http.conn.socket.PlainConnectionSocketFactory
import org.apache.http.conn.ssl.NoopHostnameVerifier
import org.apache.http.conn.ssl.SSLConnectionSocketFactory
import org.apache.http.impl.client.CloseableHttpClient
import org.apache.http.impl.client.HttpClients
import org.apache.http.impl.conn.BasicHttpClientConnectionManager
import org.apache.http.ssl.SSLContexts
import org.apache.http.ssl.TrustStrategy
import software.amazon.awssdk.auth.credentials.AwsCredentials
import software.amazon.awssdk.auth.signer.Aws4Signer
import software.amazon.awssdk.auth.signer.params.Aws4PresignerParams
import software.amazon.awssdk.http.SdkHttpFullRequest
import software.amazon.awssdk.http.SdkHttpMethod
import software.amazon.awssdk.regions.Region

import javax.net.ssl.SSLContext
import java.time.Instant
//Made to work with httpcore 4.4.4
class RawHttpRequestHandler {
    private AwsCredentials credentials
    boolean ignoreSslIssues

    private Aws4PresignerParams buildPresignerParams(String serviceName) {
        return Aws4PresignerParams.builder()
            .signingName(serviceName)
            .signingRegion(Region.US_EAST_1)
            .awsCredentials(credentials)
            .expirationTime(Instant.ofEpochSecond(60 * 60))
            .build()
    }

    HttpResponse executeHttpRequest(String serviceName, Map query) {
        //We are not using sdk http client because of https://github.com/aws/aws-sdk-java-v2/issues/652
        //The server is using httpcore 4.4.4
        //Suffer
        def reformattedQuery = query.collectEntries { k, v ->
            [k, [v]]
        }
        def request = SdkHttpFullRequest.builder()
            .host("${serviceName}.amazonaws.com")
            .protocol("https")
            .rawQueryParameters(reformattedQuery)
            .method(SdkHttpMethod.GET)
            .encodedPath("/")
            .build()
        //todo proxy
        def presigned = Aws4Signer.create().presign(request, buildPresignerParams(serviceName))
        def client = buildHttpClient()
        HttpRequest rawRequest = new HttpGet(presigned.uri)
        HttpResponse response = client.execute(rawRequest)
        if (response.getStatusLine().statusCode != 200) {
            throw new RuntimeException("Failed to execute HTTP request: ${response.statusLine.reasonPhrase}")
        }
        return response
    }

    HttpClient buildHttpClient() {
        if (ignoreSslIssues) {
            TrustStrategy acceptingTrustStrategy = (cert, authType) -> true
            SSLContext sslContext = SSLContexts.custom().loadTrustMaterial(null, acceptingTrustStrategy).build();
            SSLConnectionSocketFactory sslsf = new SSLConnectionSocketFactory(sslContext,
                NoopHostnameVerifier.INSTANCE)

            Registry<ConnectionSocketFactory> socketFactoryRegistry =
                RegistryBuilder.<ConnectionSocketFactory> create()
                    .register("https", sslsf)
                    .register("http", new PlainConnectionSocketFactory())
                    .build()

            BasicHttpClientConnectionManager connectionManager =
                new BasicHttpClientConnectionManager(socketFactoryRegistry)

            CloseableHttpClient httpClient = HttpClients.custom().setSSLSocketFactory(sslsf)
                .setConnectionManager(connectionManager).build()
            return httpClient
        } else {
            //HttpHost proxy = new HttpHost("proxy.com", 80, "http");
            //DefaultProxyRoutePlanner routePlanner = new DefaultProxyRoutePlanner(proxy);
            CloseableHttpClient httpClient = HttpClients.custom().build()
            return httpClient
        }
    }
}