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

import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import groovy.util.GroovyShellTestCase

abstract public class BaseScriptsTestCase extends GroovyShellTestCase {

	protected ResourceBundle testProperties;

	//properties in the test property file
	protected final String PROP_SVC_URL = 'service_url'
	protected final String PROP_AWS_KEY_ID = 'aws_key_id'
	protected final String PROP_AWS_KEY = 'aws_key'

	@Override
	void setUp() {
		super.setUp()

		testProperties =
				new PropertyResourceBundle(new FileInputStream("ecplugin.properties"))
	}

	protected def evalScript(String script, def args) {
		def fileResource = this.class.classLoader.getResourceAsStream(script)
		def result = withBinding( [args: args] , fileResource.text)
		result
	}

}
