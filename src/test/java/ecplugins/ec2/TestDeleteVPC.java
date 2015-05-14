package ecplugins.ec2;

import com.amazonaws.AmazonServiceException;
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

/**
 * Created by clogeny on 5/13/2015.
 */
public class TestDeleteVPC {

    private static Properties props;
    private static String vpcId = null;
    private static AmazonEC2Client ec2Client;

    @BeforeClass
    public static void  setup() throws Exception {

        props = TestUtil.getProperties();
        TestUtil.deleteConfiguration();
        TestUtil.createConfiguration();
        ec2Client = TestUtil.getEC2client();

    }


    @Test(expected = AmazonServiceException.class)
    public  void testDeleteVPC() throws Exception {

        // Create a VPC that can be deleted through API_DeleteVPC procedure
        CreateVpcResult createVpcResult = ec2Client.createVpc(new CreateVpcRequest("10.0.0.0/20"));
        Vpc vpc = createVpcResult.getVpc();
        vpcId = vpc.getVpcId();

        long jobTimeoutMillis = 5 * 60 * 1000;

        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_DeleteVPC");


        JSONArray actualParameterArray = new JSONArray();
        actualParameterArray.put(new JSONObject()
                .put("value", "ec2cfg")
                .put("actualParameterName", "config"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "vpcId")
                .put("value", vpcId));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "propResult")
                .put("value", "/myJob"));

        jo.put("actualParameter", actualParameterArray);

        String jobId = TestUtil.callRunProcedure(jo);

        String response = TestUtil.waitForJob(jobId,jobTimeoutMillis);

        // Check job status
        assertEquals("Job completed with errors", "success", response);

        // Following method invocation must throw com.amazonaws.AmazonServiceException
        DescribeVpcsResult describeVpcsResult = ec2Client.describeVpcs(new DescribeVpcsRequest().withVpcIds(vpcId));

    }

    @Test
    public  void testDeleteVPCInvalidVPCID() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_DeleteVPC");


        JSONArray actualParameterArray = new JSONArray();
        actualParameterArray.put(new JSONObject()
                .put("value", "ec2cfg")
                .put("actualParameterName", "config"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "vpcId")
                .put("value", "SomeRandomID"));

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
        assertEquals("AWS Error: The vpc ID 'SomeRandomID' does not exist",failureReason);

    }

    @AfterClass
    public static void cleanup(){

        /*
            Delete the VPC created just as a precaution if testDeleteVPC test fails.
            If the test testDeleteVPC executes successfully, there will not be any VPC with vpcId.
            In that case deleteVpc() will throw an exception which is expected and hence catching it here.
         */
        try {
            ec2Client.deleteVpc(new DeleteVpcRequest(vpcId));
        } catch (com.amazonaws.AmazonServiceException e){
             System.out.println("API_DeleteVPC deleted " + vpcId + " successfully.No need of separate cleanup.");

        }

    }

}
