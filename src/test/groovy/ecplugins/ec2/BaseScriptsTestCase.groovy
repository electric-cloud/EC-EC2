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
