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

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;

import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import com.amazonaws.services.ec2.AmazonEC2Client;
import com.amazonaws.services.ec2.model.DeleteVpcRequest;
import com.amazonaws.services.ec2.model.DescribeVpcsRequest;
import com.amazonaws.services.ec2.model.DescribeVpcsResult;
import com.amazonaws.services.ec2.model.Tag;
import com.amazonaws.services.ec2.model.Vpc;


public class TestCreateVPC {


    private static String m_vpcId = null;
    private static AmazonEC2Client m_ec2Client;

    @BeforeClass
    public static void  setup() throws Exception {


        TestUtil.deleteConfiguration();
        TestUtil.createConfiguration();
        m_ec2Client = TestUtil.getEC2client();

    }

    @Test
    public  void testCreateVPC() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        String cidrBlock = "10.0.0.0/20";
        String vpcName = "AutomatedTest-TestVPC";

        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateVPC");

        HashMap actualParameters = new HashMap();

        actualParameters.put("config","ec2cfg");
        actualParameters.put("vpcName",vpcName);
        actualParameters.put("cidrBlock",cidrBlock);
        actualParameters.put("propResult", "/myJob");

        JSONArray actualParameterArray = TestUtil.getJSONActualParameterArray(actualParameters);

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
            if (object.getJSONObject("property").get("propertyName").toString().equalsIgnoreCase("VpcId")) {
                m_vpcId = object.getJSONObject("property").get("value").toString();
            }
        }

        // VpcId is the must output property to be stored in property sheet.
        assertNotNull("No VPC ID is set in property sheet",m_vpcId);

        DescribeVpcsResult describeVpcsResult = m_ec2Client.describeVpcs(new DescribeVpcsRequest().withVpcIds(m_vpcId));
        assertNotNull("No VPC with id " + m_vpcId + " found",describeVpcsResult);

        List<Vpc> vpcList = describeVpcsResult.getVpcs();
        Iterator<Vpc> i = vpcList.listIterator();
        Vpc requiredVPC = null;
        Vpc vpc = null;

        while (i.hasNext()) {
            vpc = i.next();
            if (vpc.getVpcId().equalsIgnoreCase(m_vpcId)){
                requiredVPC = vpc;
                break;
            }
        }

        // Check that vpc with the VPC ID reported by procedure in property sheet actually exists on AWS.
        assertNotNull(requiredVPC);

        assertEquals("VPC is not in available state", "available", requiredVPC.getState());
        assertEquals("CIDR block is not correctly set", cidrBlock, requiredVPC.getCidrBlock());

        ListIterator<Tag> tagListIterator = requiredVPC.getTags().listIterator();
        Tag requiredTag = null;

        while (tagListIterator.hasNext()){
            Tag tag = tagListIterator.next();
            if(tag.getKey().equalsIgnoreCase("Name")){
                requiredTag = tag;
            }
            break;
        }

        assertNotNull("No name got attached to VPC", requiredTag);
        assertEquals("VPC name does not match", requiredTag.getValue(), vpcName);

    }

    @Test
    public  void testCreateVPCInvalidCIDR() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateVPC");

        HashMap actualParameters = new HashMap();

        actualParameters.put("config","ec2cfg");
        actualParameters.put("vpcName","AutomatedTest-TestVPC");
        actualParameters.put("cidrBlock","SomeRandomIp");
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

        assertNotNull("No failure reason is set",failureReason);
        assertEquals("No proper failure reason is set","AWS Error: Value (SomeRandomIp) for parameter cidrBlock is invalid. This is not a valid CIDR block.",failureReason);

    }

    @AfterClass
    public static void cleanup(){

        /*
            Cleanup the vpc created by the API_CreateVPC procedure during test
         */
        m_ec2Client.deleteVpc(new DeleteVpcRequest(m_vpcId));
    }

}
