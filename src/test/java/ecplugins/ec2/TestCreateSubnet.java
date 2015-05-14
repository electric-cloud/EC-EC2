package ecplugins.ec2;

import com.amazonaws.services.ec2.AmazonEC2Client;
import com.amazonaws.services.ec2.model.*;
import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;
import java.util.Properties;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

/**
 * Created by clogeny on 5/13/2015.
 */
public class TestCreateSubnet {

    private static Properties props;
    private static AmazonEC2Client ec2Client;
    private static String VpcId = null;
    private static String SubnetId = null;

    @BeforeClass
    public static void  setup() throws Exception {

        props = TestUtil.getProperties();
        TestUtil.deleteConfiguration();
        TestUtil.createConfiguration();
        ec2Client = TestUtil.getEC2client();

        // Create a VPC before creating a subnet
        CreateVpcResult createVpcResult = ec2Client.createVpc(new CreateVpcRequest("10.0.0.0/20"));
        Vpc vpc = createVpcResult.getVpc();
        VpcId = vpc.getVpcId();

    }

    @Test
    public  void testCreateSubnet() throws Exception {



        long jobTimeoutMillis = 5 * 60 * 1000;
        String subnetName = "AutomatedTest-TestSubnet";
        String cidrBlock = "10.0.0.0/24";

        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateSubnet");


        JSONArray actualParameterArray = new JSONArray();
        actualParameterArray.put(new JSONObject()
                .put("value", "ec2cfg")
                .put("actualParameterName", "config"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "subnetName")
                .put("value", subnetName));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "CidrBlock")
                .put("value", cidrBlock));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "availabilityZone")
                .put("value", props.getProperty(StringConstants.AVAILABILITY_ZONE)));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "VpcId")
                .put("value", VpcId));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "propResult")
                .put("value", "/myJob"));

        jo.put("actualParameter", actualParameterArray);

        String jobId = TestUtil.callRunProcedure(jo);

        String response = TestUtil.waitForJob(jobId,jobTimeoutMillis);

        // Check job status
        assertEquals("Job completed with errors", "success", response);

        JSONObject outputProperties = TestUtil.getJobOutputProperties(jobId);
        JSONArray objectArray = outputProperties.getJSONArray("object");
        JSONObject object = null;

        for (int i = 0 ; i < objectArray.length(); i++) {
            object = objectArray.getJSONObject(i);
            if (object.getJSONObject("property").get("propertyName").toString().equalsIgnoreCase("SubnetId")) {
                SubnetId = object.getJSONObject("property").get("value").toString();
            }
        }

        // SubnetId is the must output property to be stored in property sheet.
        assertNotNull("No subnet ID is set in property sheet",SubnetId);

        DescribeSubnetsResult describeSubnetsResult = ec2Client.describeSubnets(new DescribeSubnetsRequest().withSubnetIds(SubnetId));
        assertNotNull("No subnet with id " + SubnetId + " found",describeSubnetsResult);

        List<Subnet> subnetList = describeSubnetsResult.getSubnets();
        Iterator<Subnet> i = subnetList.listIterator();
        Subnet requiredSubnet = null;
        Subnet subnet = null;

        while (i.hasNext()) {
            subnet = i.next();
            if (subnet.getSubnetId().equalsIgnoreCase(SubnetId)){
                requiredSubnet = subnet;
                break;
            }
        }

        // Check that subnet with the subnet ID reported by procedure in property sheet actually exists on AWS.
        assertNotNull(requiredSubnet);

        assertEquals("Subnet is not in available state", "available", requiredSubnet.getState());
        assertEquals("CIDR block is not correctly set", cidrBlock, requiredSubnet.getCidrBlock());

        ListIterator<Tag> tagListIterator = requiredSubnet.getTags().listIterator();
        Tag requiredTag = null;

        while (tagListIterator.hasNext()){
            Tag tag = tagListIterator.next();
            if(tag.getKey().equalsIgnoreCase("Name")){
                requiredTag = tag;
            }
            break;
        }

        assertNotNull("No name got attached to subnet", requiredTag);
        assertEquals("Subnet name does not match", requiredTag.getValue(), subnetName);
        assertEquals("Availability zone not set properly", requiredSubnet.getAvailabilityZone(), props.getProperty(StringConstants.AVAILABILITY_ZONE));
        assertEquals("Subnet created in some other VPC", VpcId, requiredSubnet.getVpcId());

    }

    @Test
    public  void testCreateSubnetInvalidCIDR() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateSubnet");


        JSONArray actualParameterArray = new JSONArray();
        actualParameterArray.put(new JSONObject()
                .put("value", "ec2cfg")
                .put("actualParameterName", "config"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "subnetName")
                .put("value", "AutomatedTest-TestSubnet"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "CidrBlock")
                .put("value", "SomeRandomString"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "availabilityZone")
                .put("value", props.getProperty(StringConstants.AVAILABILITY_ZONE)));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "VpcId")
                .put("value", VpcId));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "propResult")
                .put("value", "/myJob"));

        jo.put("actualParameter", actualParameterArray);

        String jobId = TestUtil.callRunProcedure(jo);

        String response = TestUtil.waitForJob(jobId,jobTimeoutMillis);

        // Check job status
        assertEquals("Job completed without errors", "error", response);

        JSONObject outputProperties = TestUtil.getJobOutputProperties(jobId);
        JSONArray objectArray = outputProperties.getJSONArray("object");
        JSONObject object = null;
        String failureReason = null;
        for (int i = 0 ; i < objectArray.length(); i++) {
            object = objectArray.getJSONObject(i);
            if (object.getJSONObject("property").get("propertyName").toString().equalsIgnoreCase("summary")) {
                failureReason = object.getJSONObject("property").get("value").toString();
            }
        }

        assertNotNull("No failure reason is set",failureReason);
        assertEquals("No proper failure reason is set","AWS Error: Value (SomeRandomString) for parameter cidrBlock is invalid. This is not a valid CIDR block.",failureReason);

    }

    @Test
    public  void testCreateSubnetInvalidAvailabilityZone() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateSubnet");


        JSONArray actualParameterArray = new JSONArray();
        actualParameterArray.put(new JSONObject()
                .put("value", "ec2cfg")
                .put("actualParameterName", "config"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "subnetName")
                .put("value", "AutomatedTest-TestSubnet"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "CidrBlock")
                .put("value", "10.0.0.0/20"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "availabilityZone")
                .put("value", props.getProperty(StringConstants.AVAILABILITY_ZONE) + TestUtil.randInt()));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "VpcId")
                .put("value", "vpc-f2537997"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "propResult")
                .put("value", "/myJob"));

        jo.put("actualParameter", actualParameterArray);

        String jobId = TestUtil.callRunProcedure(jo);

        String response = TestUtil.waitForJob(jobId,jobTimeoutMillis);

        // Check job status
        assertEquals("Job completed without errors", "error", response);

        JSONObject outputProperties = TestUtil.getJobOutputProperties(jobId);
        JSONArray objectArray = outputProperties.getJSONArray("object");
        JSONObject object = null;
        String failureReason = null;
        for (int i = 0 ; i < objectArray.length(); i++) {
            object = objectArray.getJSONObject(i);
            if (object.getJSONObject("property").get("propertyName").toString().equalsIgnoreCase("summary")) {
                failureReason = object.getJSONObject("property").get("value").toString();
            }
        }

        assertNotNull("No failure reason is set", failureReason);
        assertTrue("No proper failure reason is set", failureReason.contains("parameter availabilityZone is invalid"));

    }

    @Test
    public  void testCreateSubnetInvalidVPCID() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateSubnet");


        JSONArray actualParameterArray = new JSONArray();
        actualParameterArray.put(new JSONObject()
                .put("value", "ec2cfg")
                .put("actualParameterName", "config"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "subnetName")
                .put("value", "AutomatedTest-TestSubnet"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "CidrBlock")
                .put("value", "10.0.0.0/20"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "availabilityZone")
                .put("value", props.getProperty(StringConstants.AVAILABILITY_ZONE)));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "VpcId")
                .put("value", "xyzad"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "propResult")
                .put("value", "/myJob"));

        jo.put("actualParameter", actualParameterArray);

        String jobId = TestUtil.callRunProcedure(jo);

        String response = TestUtil.waitForJob(jobId,jobTimeoutMillis);

        // Check job status
        assertEquals("Job completed without errors", "error", response);

        JSONObject outputProperties = TestUtil.getJobOutputProperties(jobId);
        JSONArray objectArray = outputProperties.getJSONArray("object");
        JSONObject object = null;
        String failureReason = null;
        for (int i = 0 ; i < objectArray.length(); i++) {
            object = objectArray.getJSONObject(i);
            if (object.getJSONObject("property").get("propertyName").toString().equalsIgnoreCase("summary")) {
                failureReason = object.getJSONObject("property").get("value").toString();
            }
        }

        assertNotNull("No failure reason is set",failureReason);
        assertEquals("AWS Error: The vpc ID 'xyzad' does not exist",failureReason);

    }

    @AfterClass
    public static void cleanup(){

        /*
            Cleanup the vpc and the subnet created.
         */
        ec2Client.deleteSubnet(new DeleteSubnetRequest(SubnetId));
        ec2Client.deleteVpc(new DeleteVpcRequest(VpcId));
    }

}
