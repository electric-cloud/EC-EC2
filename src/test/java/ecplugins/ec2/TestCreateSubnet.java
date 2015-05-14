package ecplugins.ec2;

import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.BeforeClass;
import org.junit.Test;

import java.util.Properties;

import static org.junit.Assert.assertEquals;

/**
 * Created by clogeny on 5/13/2015.
 */
public class TestCreateSubnet {
/*
    private static Properties props;

    @BeforeClass
    public static void  setup() throws Exception {

        props = TestUtil.getProperties();
        TestUtil.deleteConfiguration();
        TestUtil.createConfiguration();

    }
    @Test
    public  void testCreateSubnet() throws Exception {


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
                .put("value", "vpc-f2537997"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "propResult")
                .put("value", "/myJob"));

        jo.put("actualParameter", actualParameterArray);

        String jobId = TestUtil.callRunProcedure(jo);

        String response = TestUtil.waitForJob(jobId,jobTimeoutMillis);

        // Check job status
        assertEquals("Job completed with errors", "success", response);

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
                .put("value", "vpc-f2537997"));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "propResult")
                .put("value", "/myJob"));

        jo.put("actualParameter", actualParameterArray);

        String jobId = TestUtil.callRunProcedure(jo);

        String response = TestUtil.waitForJob(jobId,jobTimeoutMillis);

        // Check job status
        assertEquals("Job completed without errors", "error", response);

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
                .put("value", props.getProperty(StringConstants.AVAILABILITY_ZONE) + TestUtil.randInt()));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "VpcId")
                .put("value", TestUtil.randInt()));

        actualParameterArray.put(new JSONObject()
                .put("actualParameterName", "propResult")
                .put("value", "/myJob"));

        jo.put("actualParameter", actualParameterArray);

        String jobId = TestUtil.callRunProcedure(jo);

        String response = TestUtil.waitForJob(jobId,jobTimeoutMillis);

        // Check job status
        assertEquals("Job completed without errors", "error", response);

    }
    */
}
