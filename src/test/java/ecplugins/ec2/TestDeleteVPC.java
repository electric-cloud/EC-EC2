/**
 *  Copyright 2015 Electric Cloud, Inc.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
package ecplugins.ec2;

import com.amazonaws.AmazonServiceException;
import com.amazonaws.services.ec2.AmazonEC2Client;
import com.amazonaws.services.ec2.model.*;
import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import java.util.*;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

public class TestDeleteVPC {


    private static String m_vpcId = null;
    private static AmazonEC2Client m_ec2Client;

    @BeforeClass
    public static void  setup() throws Exception {

        TestUtil.deleteConfiguration();
        TestUtil.createConfiguration();
        m_ec2Client = TestUtil.getEC2client();

    }


    @Test(expected = AmazonServiceException.class)
    public  void testDeleteVPC() throws Exception {

        // Create a VPC that can be deleted through API_DeleteVPC procedure
        CreateVpcResult createVpcResult = m_ec2Client.createVpc(new CreateVpcRequest("10.0.0.0/20"));
        Vpc vpc = createVpcResult.getVpc();
        m_vpcId = vpc.getVpcId();

        long jobTimeoutMillis = 5 * 60 * 1000;

        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_DeleteVPC");

        HashMap actualParameters = new HashMap();

        actualParameters.put("config","ec2cfg");
        actualParameters.put("vpcId",m_vpcId);
        actualParameters.put("propResult", "/myJob");

        JSONArray actualParameterArray = TestUtil.getJSONActualParameterArray(actualParameters);

        jo.put("actualParameter", actualParameterArray);

        String jobId = TestUtil.callRunProcedure(jo);

        String response = TestUtil.waitForJob(jobId,jobTimeoutMillis);

        // Check job status
        assertEquals("Job completed with errors", "success", response);

        // Following method invocation must throw com.amazonaws.AmazonServiceException
        DescribeVpcsResult describeVpcsResult = m_ec2Client.describeVpcs(new DescribeVpcsRequest().withVpcIds(m_vpcId));

    }

    @Test
    public  void testDeleteVPCInvalidVPCID() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_DeleteVPC");

        HashMap actualParameters = new HashMap();

        actualParameters.put("config","ec2cfg");
        actualParameters.put("vpcId","SomeRandomID");
        actualParameters.put("propResult", "/myJob");

        JSONArray actualParameterArray = TestUtil.getJSONActualParameterArray(actualParameters);

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
            m_ec2Client.deleteVpc(new DeleteVpcRequest(m_vpcId));
        } catch (com.amazonaws.AmazonServiceException e){
             System.out.println("API_DeleteVPC deleted " + m_vpcId + " successfully.No need of separate cleanup.");

        }

    }

}
