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

import groovy.transform.Field

import java.util.logging.Level
import java.util.logging.Logger;

import com.amazonaws.ClientConfiguration
import com.amazonaws.auth.BasicAWSCredentials
import com.amazonaws.metrics.AwsSdkMetrics;
import com.amazonaws.services.ec2.AmazonEC2Client
import com.electriccloud.domain.FormalParameterValidationResult

/**
 * This script validates the EC2 settings provided to the
 * Create/Edit configuration. It takes the same input parameters as the
 * CreateConfiguration procedure and authenticates the user with the
 * given credentials against the EC2 Identity service URL.
 * Input parameter: {
 *   "parameters" : {
 *      "service_url" : "eg, https://ec2.us-west-2.amazonaws.com",
 *      "credential" : [
 *                      {
 *                         "credentialName" : "<credentialName>",
 *                         "userName" : "<username>",
 *                         "password" : "<pwd>"
 *                      }
 *                     ]
 *   },
 * }
 * Output: {
 *   "outcome" : "success|error"
 *   If error then
 *   "messages" : [
 *                  {
 *                    parameterName : 'param1',
 *                          message : 'error message1'
 *                  }, {
 *                    parameterName : '<credentialName>.userName',
 *                          message : 'error message for invalid userName'
 *                  }, {
 *                    parameterName : '<credentialName>.password',
 *                          message : 'error message for invalid password'
 *                  }
 *               ]
 *   }
 * }
 */

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
			args.parameters[SERVICE_URL]
}

def doValidations(args) {
	def credential = args.credential[0]
	def parameters = args.parameters
	def result

	// Disable HTTPS certificate verification
	System.setProperty("com.amazonaws.sdk.disableCertChecking", "true")

	try {
		def awsCreds = new BasicAWSCredentials(credential[USER_NAME], credential[PASSWORD])
		def clientConfig = new ClientConfiguration()

		clientConfig.setConnectionTimeout(5 * 1000)
		clientConfig.setMaxErrorRetry(1)

		def ec2 = new AmazonEC2Client(awsCreds, clientConfig)
		ec2.setEndpoint(parameters[SERVICE_URL])

		// Test Amazon EC2 connection with credentials passed by user
		ec2.describeAvailabilityZones()

		result = FormalParameterValidationResult.SUCCESS
	} catch(Throwable e) {
		if(e.cause && e.cause instanceof IOException) {
			result = buildErrorResponse(SERVICE_URL, "Service URL is invalid")
		} else {
			result = buildErrorResponse("${credential[CREDENTIAL_NAME]}.$USER_NAME", "Invalid Access Key ID").
					error("${credential[CREDENTIAL_NAME]}.$PASSWORD", "Invalid Access Key")
		}
	}

	result
}

/**
 * Constructs and returns an error response object using the given
 * <code>errorMessage</code>
 */
def buildErrorResponse(String parameter, String errorMessage) {
	def errors = FormalParameterValidationResult.errorResult()
	errors.error(parameter, errorMessage)
}
