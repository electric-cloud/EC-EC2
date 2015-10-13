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

class EC2OptionsRetrievalTest extends BaseScriptsTestCase {
	def SCRIPT = 'project/procedures/form_scripts/parameterOptions/ec2Options.groovy'
	def json = new JsonBuilder()

	void testImagesOptionsRetrieval() {

		def inputParams = createScriptInputParams(json(), 'image')
		assertOptionPresent(inputParams, 'ami-17b75453 (Commander Agent and Chef)', 'image')
	}

	void testKeysOptionsRetrieval() {

		def inputParams = createScriptInputParams(json(), 'keyname')
		assertOptionPresent(inputParams, 'Github Plugins KeyPair', 'keyname')
	}

	void testSubnetsOptionsRetrieval() {

		def inputParams = createScriptInputParams(json(zone: 'us-west-1c'), 'subnet_id')
		assertOptionPresent(inputParams, 'subnet-be3293db (10.20.1.0/24)', 'subnet_id')
	}

	void testInstanceTypesOptionsRetrieval() {

		def inputParams = createScriptInputParams(json(), 'instanceType')
		assertOptionPresent(inputParams, 'c1.medium', 'instanceType')
	}

	void testSecurityGroupsOptionsRetrieval() {

		def inputParams = createScriptInputParams(json(), 'group')
		assertOptionPresent(inputParams, 'sg-02a22f67 (launch-wizard-16)', 'group')
	}

	void testAvailabilityZonesOptionsRetrieval() {

		def inputParams = createScriptInputParams(json(), 'zone')
		assertOptionPresent(inputParams, 'us-west-1b', 'zone')
	}

	def createScriptInputParams(def inputParams, def paramName) {
		def credential = json (
				credentialName: 'testCredential',
				userName: testProperties.getString(PROP_AWS_KEY_ID),
				password: testProperties.getString(PROP_AWS_KEY)
				)

		def configurationParams = json (
				service_url : testProperties.getString(PROP_SVC_URL)
				)

		def actualParams = json (
				connection_config:'test'
				)

		json (
				parameters : actualParams + inputParams,
				configurationParameters : configurationParams,
				credential: [credential],
				formalParameterName: paramName
				)
	}

	def assertOptionPresent(def inputParam, def expectedOption, def paramName) {
		def result = evalScript(SCRIPT, inputParam)
		for (option in result?.options) {
			if (option.displayString?.equals(expectedOption)) {
				assertNotNull "Option value is required to be present", option.value
				return
			}
		}
		// fail if we did not find the expected option
		def list = JsonOutput.toJson(result)
		fail("Expected option $expectedOption  not found for $paramName in :\n $list")
	}
}
