package ecplugins.ec2;

import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.services.ec2.AmazonEC2Client;
import com.amazonaws.services.ec2.model.*;
import org.junit.BeforeClass;
import org.junit.Test;

import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;
import java.util.Properties;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import org.json.JSONArray;

import org.json.JSONObject;

/**
 * Created by clogeny on 5/13/2015.
 */
public class TestCreateVPC {

    private static Properties props;
    private static AmazonEC2Client ec2Client;

    @BeforeClass
    public static void  setup() throws Exception {

        props = TestUtil.getProperties();
        TestUtil.deleteConfiguration();
        TestUtil.createConfiguration();
        ec2Client = TestUtil.getEC2client();

    }
    @Test
    public  void testCreateVPC() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        String cidrBlock = "10.0.0.0/20";
        String VpcName = "AutomatedTest-TestVPC";

        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateVPC");


        JSONArray actualParameterArray = new JSONArray();
        actualParameterArray.put(new JSONObject()
                .put("value", "ec2cfg")
                .put("actualParameterName", "config"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "VpcName")
                .put("value", VpcName));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "CidrBlock")
                .put("value", cidrBlock));

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
        String vpcId = null;
        for (int i = 0 ; i < objectArray.length(); i++) {
            object = objectArray.getJSONObject(i);
            if (object.getJSONObject("property").get("propertyName").toString().equalsIgnoreCase("VpcId")) {
                vpcId = object.getJSONObject("property").get("value").toString();
            }
        }

        // VpcId is the must output property to be stored in property sheet.
        assertNotNull("No VPC ID is set in property sheet",vpcId);

        DescribeVpcsResult describeVpcsResult = ec2Client.describeVpcs(new DescribeVpcsRequest().withVpcIds(vpcId));
        assertNotNull("No VPC with id " + vpcId + " found",describeVpcsResult);

        List<Vpc> vpcList = describeVpcsResult.getVpcs();
        Iterator<Vpc> i = vpcList.listIterator();
        Vpc requiredVPC = null;
        Vpc vpc = null;

        while (i.hasNext()) {
            vpc = i.next();
            if (vpc.getVpcId().equalsIgnoreCase(vpcId)){
                requiredVPC = vpc;
                break;
            }
        }

        // Check that vpc with the VPC ID reported by procedure in property sheet actually exists on AWS.
        assertNotNull(vpc);

        assertEquals("VPC is not in available state", "available", vpc.getState());
        assertEquals("CIDR block is not correctly set", cidrBlock, vpc.getCidrBlock());

        ListIterator<Tag> tagListIterator = vpc.getTags().listIterator();
        Tag requiredTag = null;

        while (tagListIterator.hasNext()){
            Tag tag = tagListIterator.next();
            if(tag.getKey().equalsIgnoreCase("Name")){
                requiredTag = tag;
            }
            break;
        }

        assertNotNull("No name got attached to VPC",requiredTag);
        assertEquals("VPC name does not match", requiredTag.getValue(), VpcName);

        /*
            Cleanup the vpc created by the API_CreateVPC procedure during test
         */
        ec2Client.deleteVpc(new DeleteVpcRequest(vpcId));

    }

    @Test
    public  void testCreateVPCInvalidCIDR() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateVPC");


        JSONArray actualParameterArray = new JSONArray();
        actualParameterArray.put(new JSONObject()
                .put("value", "ec2cfg")
                .put("actualParameterName", "config"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "VpcName")
                .put("value", "AutomatedTest-TestVPC"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "CidrBlock")
                .put("value", "SomeRandomIp"));

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
        assertEquals("No proper failure reason is set","AWS Error: Value (SomeRandomIp) for parameter cidrBlock is invalid. This is not a valid CIDR block.",failureReason);

    }

}
