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
import static org.junit.Assert.assertTrue;

public class TestCreateSubnet {

    private static Properties m_props;
    private static AmazonEC2Client m_ec2Client;
    private static String m_vpcId = null;
    private static String m_subnetId = null;

    @BeforeClass
    public static void  setup() throws Exception {

        m_props = TestUtil.getProperties();
        TestUtil.deleteConfiguration();
        TestUtil.createConfiguration();
        m_ec2Client = TestUtil.getEC2client();

        // Create a VPC before creating a subnet
        CreateVpcResult createVpcResult = m_ec2Client.createVpc(new CreateVpcRequest("10.0.0.0/20"));
        Vpc vpc = createVpcResult.getVpc();
        m_vpcId = vpc.getVpcId();

    }

    @Test
    public  void testCreateSubnet() throws Exception {



        long jobTimeoutMillis = 5 * 60 * 1000;
        String subnetName = "AutomatedTest-TestSubnet";
        String cidrBlock = "10.0.0.0/24";

        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateSubnet");

        HashMap actualParameters = new HashMap();

        actualParameters.put("config","ec2cfg");
        actualParameters.put("subnetName",subnetName);
        actualParameters.put("cidrBlock",cidrBlock);
        actualParameters.put("availabilityZone",m_props.getProperty(StringConstants.AVAILABILITY_ZONE));
        actualParameters.put("vpcId",m_vpcId);
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
            if (object.getJSONObject("property").get("propertyName").toString().equalsIgnoreCase("SubnetId")) {
                m_subnetId = object.getJSONObject("property").get("value").toString();
            }
        }

        // SubnetId is the must output property to be stored in property sheet.
        assertNotNull("No subnet ID is set in property sheet",m_subnetId);

        DescribeSubnetsResult describeSubnetsResult = m_ec2Client.describeSubnets(new DescribeSubnetsRequest().withSubnetIds(m_subnetId));
        assertNotNull("No subnet with id " + m_subnetId + " found",describeSubnetsResult);

        List<Subnet> subnetList = describeSubnetsResult.getSubnets();
        Iterator<Subnet> i = subnetList.listIterator();
        Subnet requiredSubnet = null;
        Subnet subnet = null;

        while (i.hasNext()) {
            subnet = i.next();
            if (subnet.getSubnetId().equalsIgnoreCase(m_subnetId)){
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
        assertEquals("Availability zone not set properly", requiredSubnet.getAvailabilityZone(), m_props.getProperty(StringConstants.AVAILABILITY_ZONE));
        assertEquals("Subnet created in some other VPC", m_vpcId, requiredSubnet.getVpcId());

    }

    @Test
    public  void testCreateSubnetInvalidCIDR() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateSubnet");

        HashMap actualParameters = new HashMap();

        actualParameters.put("config","ec2cfg");
        actualParameters.put("subnetName","AutomatedTest-TestSubnet");
        actualParameters.put("cidrBlock","SomeRandomString");
        actualParameters.put("availabilityZone",m_props.getProperty(StringConstants.AVAILABILITY_ZONE));
        actualParameters.put("vpcId",m_vpcId);
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
        assertEquals("No proper failure reason is set","AWS Error: Value (SomeRandomString) for parameter cidrBlock is invalid. This is not a valid CIDR block.",failureReason);

    }

    @Test
    public  void testCreateSubnetInvalidAvailabilityZone() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateSubnet");


        HashMap actualParameters = new HashMap();

        actualParameters.put("config","ec2cfg");
        actualParameters.put("subnetName","AutomatedTest-TestSubnet");
        actualParameters.put("cidrBlock","10.0.0.0/20");
        actualParameters.put("availabilityZone",m_props.getProperty(StringConstants.AVAILABILITY_ZONE) + TestUtil.randInt());
        actualParameters.put("vpcId",m_vpcId);
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
        assertTrue("No proper failure reason is set", failureReason.contains("parameter availabilityZone is invalid"));

    }

    @Test
    public  void testCreateSubnetInvalidVPCID() throws Exception {


        long jobTimeoutMillis = 5 * 60 * 1000;
        JSONObject jo = new JSONObject();

        jo.put("projectName", "EC-EC2-" + StringConstants.PLUGIN_VERSION);
        jo.put("procedureName", "API_CreateSubnet");

        HashMap actualParameters = new HashMap();

        actualParameters.put("config","ec2cfg");
        actualParameters.put("subnetName","AutomatedTest-TestSubnet");
        actualParameters.put("cidrBlock","10.0.0.0/20");
        actualParameters.put("availabilityZone",m_props.getProperty(StringConstants.AVAILABILITY_ZONE));
        actualParameters.put("vpcId","xyzad");
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
        assertEquals("AWS Error: The vpc ID 'xyzad' does not exist",failureReason);

    }

    @AfterClass
    public static void cleanup(){

        /*
            Cleanup the vpc and the subnet created.
         */
        m_ec2Client.deleteSubnet(new DeleteSubnetRequest(m_subnetId));
        m_ec2Client.deleteVpc(new DeleteVpcRequest(m_vpcId));
    }

}
