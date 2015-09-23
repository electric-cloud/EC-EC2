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
