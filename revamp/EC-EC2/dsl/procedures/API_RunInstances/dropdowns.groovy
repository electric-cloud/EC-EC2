$[/myProject/groovy/lib/RawHttpRequestHandler.groovy]
$[/myProject/groovy/lib/PluginWrapper.groovy]

import com.electriccloud.domain.FormalParameterOptionsResult
import com.electriccloud.errors.EcException
import com.electriccloud.errors.ErrorCodes

def result = new FormalParameterOptionsResult()
def parameterName = args.formalParameterName

try {
    DropdownHandler dropdownHandler = DropdownHandler.getInstance(args)
    if (!dropdownHandler) {
        return result
    }
    List<DropdownOption> options = dropdownHandler.fetchDropdown(parameterName)
    options.each {
        result.add(it.value, it.name)
    }
}
catch (Throwable e) {
    throw e
    throw EcException
        .code(ErrorCodes.InvalidArgument)
        .message("Failed execute EC2 API call: ${e.message}")
        .build()
}

return result