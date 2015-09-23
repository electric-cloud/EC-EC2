package ecplugins.ec2

import groovy.json.JsonBuilder
import groovy.json.JsonOutput

class EC2ValidationsTest extends BaseScriptsTestCase {
	def SCRIPT = 'project/procedures/form_scripts/validation/ec2Validations.groovy'
	def json = new JsonBuilder()
	def subnetId = 'subnet-be3293db'

	def credential = json (
	credentialName: 'testCredential',
	userName: testProperties.getString(PROP_AWS_KEY_ID),
	password: testProperties.getString(PROP_AWS_KEY)
	)

	def configurationParams = json (
	service_url : testProperties.getString(PROP_SVC_URL)
	)


	void testIpNotInSubnetRange() {

		def actualParams = json (
				subnet_id: subnetId,
				privateIp: '192.168.1.1'
				)

		def input = json (
				parameters : actualParams,
				configurationParameters: configurationParams,
				credential: [credential])

		checkErrorResponse(input, 'privateIp', "Private IP address is not in range of subnet ${subnetId}")
	}

	void testIpInSubnetRange() {

		def actualParams = json (
				subnet_id: subnetId,
				privateIp: '10.20.0.1'
				)

		def input = json (
				parameters : actualParams,
				configurationParameters: configurationParams,
				credential: [credential])

		checkErrorResponse(input, 'privateIp', "Private IP address is not in range of subnet ${subnetId}")
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
