/*
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
package project.procedures.form_scripts.validation

import groovy.transform.Field
import sun.net.util.IPAddressUtil;

import java.util.logging.Level
import java.util.logging.Logger;

import com.amazonaws.ClientConfiguration
import com.amazonaws.auth.BasicAWSCredentials
import com.amazonaws.metrics.AwsSdkMetrics;
import com.amazonaws.services.ec2.AmazonEC2Client
import com.amazonaws.services.ec2.model.DescribeSubnetsRequest
import com.amazonaws.services.ec2.model.Filter;
import com.electriccloud.domain.FormalParameterValidationResult

@Field
		final String CREDENTIAL_NAME = "credentialName"
@Field
		final String USER_NAME = "userName"
@Field
		final String PASSWORD = "password"
@Field
		final String CREDENTIAL = "credential"
@Field
		final String SERVICE_URL = "service_url"

@Field
		final String SUBNET_ID = "subnet_id"
@Field
		final String PRIVATE_IP = "privateIp"

// Disable Amazon SDK logging
Logger.getLogger("com.amazonaws").setLevel(Level.OFF);

// Main driver

if (canValidate(args)) {
	doValidations(args)
} else {
	// simply return success if cannot do validations
	// yet on the given input
	FormalParameterValidationResult.SUCCESS
}

//--------------------Helper functions-----------------------------//

boolean canValidate(args) {
	args?.parameters &&
			args.credential &&
			args.credential.size() > 0 &&
			args.credential[0][USER_NAME] &&
			args.credential[0][PASSWORD] &&
			args.configurationParameters[SERVICE_URL] &&
			args.parameters[SUBNET_ID] &&
			args.parameters[PRIVATE_IP]
}

def doValidations(args) {
	def credential = args.credential[0]
	def parameters = args.parameters
	def result = FormalParameterValidationResult.SUCCESS

	// Disable HTTPS certificate verification
	System.setProperty("com.amazonaws.sdk.disableCertChecking", "true")

	try {
		def ec2 = loginEC2(credential, args.configurationParameters[SERVICE_URL])
		def privateIp = parameters[PRIVATE_IP]
		def subnetId = parameters[SUBNET_ID]

		if(privateIp?.trim() && subnetId?.trim() && !checkIpInRange(getSubnetCIDR(ec2, subnetId), privateIp)) {
			result = buildErrorResponse(PRIVATE_IP, "Private IP address is not in range of subnet ${subnetId}")
		}
	} catch(Throwable e) {
		result = buildErrorResponse(PRIVATE_IP, "Fatal error checking private IP address: " + e.getMessage())
	}

	result
}

def loginEC2(credential, serviceURL) {
	// Disable HTTPS certificate verification
	System.setProperty("com.amazonaws.sdk.disableCertChecking", "true")

	def awsCreds = new BasicAWSCredentials(credential[USER_NAME], credential[PASSWORD])
	def clientConfig = new ClientConfiguration()

	clientConfig.setConnectionTimeout(5 * 1000)
	clientConfig.setMaxErrorRetry(1)

	def ec2 = new AmazonEC2Client(awsCreds, clientConfig)
	ec2.setEndpoint(serviceURL)

	ec2
}

def getSubnetCIDR(AmazonEC2Client ec2, subnedId) {

	def request = new DescribeSubnetsRequest()
	request.withFilters([
		new Filter("subnet-id", [subnedId])
	])

	ec2.describeSubnets(request).getSubnets().first().cidrBlock
}

/**
 * Convert IP address from String to integer
 **/
def IPToInteger(ip) {
	def inetAddress = Inet4Address.getByName(ip)
	def bytes = inetAddress.getAddress()

	((bytes[0] & 0xFF) << 24) |
			((bytes[1] & 0xFF) << 16) |
			((bytes[2] & 0xFF) << 8)  |
			((bytes[3] & 0xFF) << 0)
}

/**
 * Check that IP in CIDR range
 **/
def checkIpInRange(cidr, ip) {

	// Check that IP address is valid
	if(!IPAddressUtil.isIPv4LiteralAddress(ip)) {
		return false
	}

	def (net, mask) = cidr.split('/')
	def intMask = -1 << (32 - (mask as int))

	(IPToInteger(net) & intMask) == (IPToInteger(ip) & intMask)
}

/**
 * Constructs and returns an error response object using the given
 * <code>errorMessage</code>
 */
def buildErrorResponse(String parameter, String errorMessage) {
	def errors = FormalParameterValidationResult.errorResult()
	errors.error(parameter, errorMessage)
}
