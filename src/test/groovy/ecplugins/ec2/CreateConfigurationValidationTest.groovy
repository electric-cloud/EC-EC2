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
package ecplugins.ec2

import groovy.json.JsonBuilder
import groovy.json.JsonOutput

class CreateConfigurationValidationTest extends BaseScriptsTestCase {
	def SCRIPT = 'project/procedures/form_scripts/validation/createConfiguration.groovy'

	void testInvalidSvcUrl() {

		def json = new JsonBuilder()

		def credential = json (
				credentialName: "testCredential",
				userName: testProperties.getString(PROP_AWS_KEY_ID),
				password: testProperties.getString(PROP_AWS_KEY)
				)

		def actualParams = json (
				service_url : 'https://invalidserver.amazon.com'
				)

		def input = json (
				parameters : actualParams,
				credential: [credential])

		checkErrorResponse(input, 'service_url', "Service URL is invalid")
	}

	void testInvalidKeyId() {

		def json = new JsonBuilder()

		def credential = json (
				credentialName: "testCredential",
				userName: 'dummyuser123',
				password: testProperties.getString(PROP_AWS_KEY)
				)

		def actualParams = json (
				service_url : testProperties.getString(PROP_SVC_URL)
				)

		def input = json (
				credential: [credential],
				parameters : actualParams
				)

		checkErrorResponse(input, 'testCredential.userName', "Invalid Access Key ID")
		checkErrorResponse(input, 'testCredential.password', "Invalid Access Key")
	}

	void testInvalidKey() {

		def json = new JsonBuilder()

		def credential = json (
				credentialName: "testCredential",
				userName: testProperties.getString(PROP_AWS_KEY_ID),
				password: 'dummykey'
				)

		def actualParams = json (
				service_url : testProperties.getString(PROP_SVC_URL)
				)

		def input = json (
				credential: [credential],
				parameters : actualParams
				)

		checkErrorResponse(input, 'testCredential.userName', "Invalid Access Key ID")
		checkErrorResponse(input, 'testCredential.password', "Invalid Access Key")
	}

	void testValidConfiguration() {

		def json = new JsonBuilder()

		def credential = json (
				credentialName: "testCredential",
				userName: testProperties.getString(PROP_AWS_KEY_ID),
				password: testProperties.getString(PROP_AWS_KEY)
				)

		def actualParams = json (
				service_url : testProperties.getString(PROP_SVC_URL)
				)
		def input = json (
				parameters : actualParams,
				credential: [credential])

		checkSuccessResponse(input)
	}

	void checkSuccessResponse(def inputParam) {

		def result = evalScript(SCRIPT, inputParam)
		assertEquals "Errors found: " + JsonOutput.toJson(result), "success", result.outcome.toString()
	}

	void checkErrorResponse(def inputParam, def parameter, def expectedError) {
		def result = evalScript(SCRIPT, inputParam)
		assertEquals "error", result.outcome.toString()
		if (expectedError) {
			def errMsg = findErrorMessage(result.messages, parameter)
			def json = JsonOutput.toJson(inputParam)
			assertEquals "Incorrect error message with input parameters: " + json, parameter, errMsg.parameterName
			assertEquals "Incorrect error message with input parameters: " + json, expectedError, errMsg.message
		}
	}

	def findErrorMessage(def messages, def parameter) {
		for (message in messages) {
			if (message.parameterName.equals(parameter)) {
				return message
			}
		}
		// fail if we did not find the message yet
		fail('Error message not found for parameter: ' + parameter +
				', in error messages: \n' + JsonOutput.toJson(messages))
	}
}
