﻿function New-PipeScript
{
    <#
    .Synopsis
        Creates new PipeScript.
    .Description
        Creates new PipeScript and PowerShell ScriptBlocks.
    .EXAMPLE
        New-PipeScript -Parameter @{a='b'}
    .EXAMPLE
        New-PipeScript -Parameter ([Net.HttpWebRequest].GetProperties()) -ParameterHelp @{
            Accept='
HTTP Accept.

HTTP Accept indicates what content types the web request will accept as a response.
'
        }
    .EXAMPLE
        New-PipeScript -Parameter @{"bar"=@{
            Name = "foo"
            Help = 'Foobar'
            Attributes = "Mandatory","ValueFromPipelineByPropertyName"
            Aliases = "fubar"
            Type = "string"
        }}
    .EXAMPLE
        New-PipeScript -FunctionName New-TableControl -Parameter [Management.Automation.TableControl].GetProperties() -WeaklyTyped
    #>
    [Alias('New-ScriptBlock')]
    [CmdletBinding(PositionalBinding=$false)]
    param(

    # An input object.  
    # This can be anything, but will override certain parameters if it is a ScriptBlock.
    [vfp()]
    $InputObject,

    # Defines one or more parameters for a ScriptBlock.
    # Parameters can be defined in a few ways:
    # * As a ```[Collections.Dictionary]``` of Parameters
    # * As the ```[string]``` name of an untyped parameter.
    # * As a ```[ScriptBlock]``` containing only parameters.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('Parameters','Property','Properties')]
    $Parameter,

    # The dynamic parameter block.
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateScriptBlock(NoBlocks, NoParameters)]
    [Alias('DynamicParameterBlock')]
    [ScriptBlock]
    $DynamicParameter,

    # The begin block.
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateScriptBlock(NoBlocks, NoParameters)]
    [Alias('BeginBlock')]
    [ScriptBlock]
    $Begin,

    # The process block.
    # If a [ScriptBlock] is piped in and this has not been provided,
    # -Process will be mapped to that script.
    [Parameter(ValueFromPipelineByPropertyName)]    
    [Alias('ProcessBlock','ScriptBlock')]
    [ScriptBlock]
    $Process,

    # The end block.
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateScriptBlock(NoBlocks, NoParameters)]
    [Alias('EndBlock')]
    [ScriptBlock]
    $End,

    # The script header.
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $Header,

    # If provided, will automatically create parameters.
    # Parameters will be automatically created for any unassigned variables.
    [Alias('AutoParameterize','AutoParameters')]
    [switch]
    $AutoParameter,

    # The type used for automatically generated parameters.
    # By default, ```[PSObject]```.
    [type]
    $AutoParameterType = [PSObject],

    # If provided, will add inline help to parameters.
    [Collections.IDictionary]
    $ParameterHelp,

    <#
    If set, will weakly type parameters generated by reflection.

    1. Any parameter type implements IList should be made a [PSObject[]]
    2. Any parameter that implements IDictionary should be made an [Collections.IDictionary]
    3. Booleans should be made into [switch]es
    4. All other parameter types should be [PSObject]
    #>
    [Alias('WeakType', 'WeakParameters', 'WeaklyTypedParameters', 'WeakProperties', 'WeaklyTypedProperties')]
    [switch]
    $WeaklyTyped,

    # The name of the function to create.
    [string]
    $FunctionName,

    # The type or namespace the function to create.  This will be ignored if -FunctionName is not passed.
    # If the function type is not function or filter, it will be treated as a function namespace.
    [Alias('FunctionNamespace','CommandNamespace')]
    [string]
    $FunctionType = 'function',

    # A description of the script's functionality.  If provided with -Synopsis, will generate help.
    [vbn()]
    [string]
    $Description,

    # A short synopsis of the script's functionality.  If provided with -Description, will generate help.
    [vbn()]
    [Alias('Summary')]
    [string]
    $Synopsis,

    # A list of examples to use in help.  Will be ignored if -Synopsis and -Description are not passed.
    [Alias('Examples')]
    [string[]]
    $Example,

    # A list of links to use in help.  Will be ignored if -Synopsis and -Description are not passed.
    [Alias('Links')]
    [string[]]
    $Link,

    # A list of attributes to declare on the scriptblock.
    [string[]]
    $Attribute,

    # If set, will not transpile the created code.
    [switch]
    $NoTranspile,
    
    # A Reference Object.
    # This can be used for properties that are provided from a JSON Schema or OpenAPI definition or some similar structure.
    # It will take a slash based path to a component or property and use that as it's value.    
    $ReferenceObject
    )

    begin {
        $ParametersToCreate    = [Ordered]@{}
        $parameterScriptBlocks = @()
        $allDynamicParameters  = @()
        $allBeginBlocks        = @()
        $allEndBlocks          = @()
        $allProcessBlocks      = @()
        $allHeaders            = @()

        ${?<EmptyParameterBlock>} = '^[\s\r\n]{0,}param\(' -replace '\)[\s\r\n]{0,}$'

        filter embedParameterHelp {
            if ($_ -notmatch '^\s\<\#' -and $_ -notmatch '^\s\#') {
                $commentLines = @($_ -split '(?>\r\n|\n)')
                if ($commentLines.Count -gt 1) {
                    '<#' + [Environment]::NewLine + "$_".Trim() + [Environment]::newLine + '#>'
                } else {
                    "# $_"
                }
            } else {
                $_
            }
        }

        filter psuedoTypeToRealType {
            switch ($_) {
                string { [string] }
                integer { [int] }
                number { [double]}
                boolean { [switch] }
                array { [PSObject[]] }
                object { [PSObject] }
                default {
                    if ($_ -as [type]) {
                        $_ -as [type]
                    }                    
                }
            }
        }

        filter oneOfTheseProperties
        {
            foreach ($arg in $args) {
                if ($_.$arg) { return $_.$arg }
            }
        }

    }

    process {
        # If the input was a dictionary
        if ($InputObject -is [Collections.IDictionary]) {
            # make it a custom object.
            $InputObject = [PSCustomObject]$InputObject            
            $myCmd = $MyInvocation.MyCommand
            # Since we're too late to do a `[ValueFromPipelineByPropertyName]` binding to the parameters,
            # do it ourselves by walking over each parameter.
            :nextParameter foreach ($param in $myCmd.Parameters.Values) {
                if ($null -ne $inputObject.($param.Name)) { # If the -InputObject contains a parameter name
                    # bind it by setting the variable
                    $ExecutionContext.SessionState.PSVariable.Set($param.Name, $inputObject.($param.Name))
                }
                else {
                    # Otherwise, check each of the aliases for this parameter
                    foreach ($paramAlias in $param.Aliases) {
                        # and if the -InputObject has that alias
                        if ($null -ne $inputObject.$paramAlias) {
                            # bind it by setting the variable.
                            $ExecutionContext.SessionState.PSVariable.Set($param.Name, $inputObject.$paramAlias)
                            continue nextParameter
                        }                           
                    }
                }
            }
        }

        # If the inputobject is a [Type]
        if ($InputObject -is [Type]) {
                
        }

        if ($Synopsis) {
            if (-not $Description) { $Description = $Synopsis }
            function indentHelpLine {
                foreach ($line in $args -split '(?>\r\n|\n)') {
                    (' ' * 4) + $line.TrimEnd()
                }
            }

            $helpHeader = @(
                "<#"
                ".Synopsis"
                indentHelpLine $Synopsis
                ".Description"
                indentHelpLine $Description
                
                foreach ($helpExample in $Example) {
                    ".Example"
                    indentHelpLine $helpExample
                }
                foreach ($helplink in $Link) {
                    ".Link"
                    indentHelpLine $helplink
                } 
                "#>"
            ) -join [Environment]::Newline

            $allHeaders += $helpHeader
        }
        
        if ($Attribute) {
            $allHeaders += $Attribute
        }



        # If -Parameter was passed, we will need to define parameters.        
        if ($parameter) {
            # We may also effectively want to recurse thru these values
            # (that is, a parameter can imply the existence of other parameters)
            # So, instead of going thru a normal list, we're putting everything into a queue
            $parameterQueue = [Collections.Queue]::new(@($parameter))
            while ($parameterQueue.Count) {
                $param = $parameterQueue.Dequeue()
                # this will end up populating an [Ordered] dictionary, $parametersToCreate.
                # However, for ease of use, -Parameter can be very flexible.
                # The -Parameter can be a dictionary of parameters.
                if ($Param -is [Collections.IDictionary]) {
                    $parameterType = ''
                    # If it is, walk thur each parameter in the dictionary
                    foreach ($EachParameter in $Param.GetEnumerator()) {
                        # Continue past any parameters we already have
                        if ($ParametersToCreate.Contains($EachParameter.Key)) {
                            continue
                        }
                        # If the parameter is a string and the value is not a variable
                        if ($EachParameter.Value -is [string] -and $EachParameter.Value -notlike '*$*') {
                            $parameterName = $EachParameter.Key
                            $ParametersToCreate[$EachParameter.Key] =
                                @(
                                    if ($parameterHelp -and $parameterHelp[$eachParameter.Key]) {
                                        $parameterHelp[$eachParameter.Key] | embedParameterHelp
                                    }
                                    $parameterAttribute = "[Parameter(ValueFromPipelineByPropertyName)]"
                                    $parameterType
                                    '$' + $parameterName
                                ) -ne ''
                        }
                        # If the value is a string and the value contains variables
                        elseif ($EachParameter.Value -is [string]) {
                            # embed it directly.
                            $ParametersToCreate[$EachParameter.Key] = $EachParameter.Value
                        }                    
                        # If the value is a ScriptBlock
                        elseif ($EachParameter.Value -is [ScriptBlock]) {
                            # Embed it
                            $ParametersToCreate[$EachParameter.Key] =
                                # If there was a param block on the script block
                                if ($EachParameter.Value.Ast.ParamBlock) {
                                    # embed the parameter block (except for the param keyword)
                                    $EachParameter.Value.Ast.ParamBlock.Extent.ToString() -replace
                                        ${?<EmptyParameterBlock>}
                                } else {
                                    # Otherwise
                                    '[Parameter(ValueFromPipelineByPropertyName)]' + (
                                    $EachParameter.Value.ToString() -replace
                                        "\`$$($eachParameter.Key)[\s\r\n]$" -replace # Replace any trailing variables
                                        ${?<EmptyParameterBlock>}  # then replace any empty param blocks.
                                    )
                                }
                        }
                        # If the value was an array
                        elseif ($EachParameter.Value -is [Object[]]) {
                            $ParametersToCreate[$EachParameter.Key] = # join it's elements by newlines
                                $EachParameter.Value -join [Environment]::Newline
                        }
                        elseif ($EachParameter.Value -is [Collections.IDictionary] -or 
                            $EachParameter.Value -is [PSObject]) {
                            $parameterMetadata = $EachParameter.Value
                            $parameterName = $EachParameter.Key
                            if ($parameterMetadata.Name) {
                                $parameterName = $parameterMetadata.Name
                            }                            
                            
                            $parameterAttributeParts = @()
                            $ParameterOtherAttributes = @()
                            $attrs = @($parameterMetadata | oneOfTheseProperties Attribute Attributes)
                            [string[]]$aliases = @($parameterMetadata | oneOfTheseProperties Alias Aliases)

                            [string]$parameterHelpText = 
                                $parameterMetadata | oneOfTheseProperties Help Description Synopsis Summary

                            $Bindings = @(
                                $parameterMetadata | oneOfTheseProperties Binding DefaultBinding DefaultBindingProperty
                            )
                            
                            $aliasAttribute = @(foreach ($alias in $aliases) {
                                $alias -replace "'","''"                            
                            }) -join "','"
                            if ($aliasAttribute) {
                                $aliasAttribute = "[Alias('$aliasAttribute')]"
                            }

                            if ($Bindings) {
                                foreach ($bindingProperty in $Bindings) {
                                    "[ComponentModel.DefaultBindingProperty('$bindingProperty')]"
                                }
                            }
                                                       
                            foreach ($attr in $attrs) {
                                if ($attr -notmatch '^\[') {
                                    $parameterAttributeParts += $attr
                                } else {
                                    $ParameterOtherAttributes += $attr
                                }
                            }

                            if (
                                ($parameterMetadata.Mandatory -or $parameterMetadata.required) -and 
                                ($parameterAttributeParts -notmatch 'Mandatory')) {
                                $parameterAttributeParts = @('Mandatory') + $parameterAttributeParts
                            }

                            $parameterType = $parameterMetadata | oneOfTheseProperties Type ParameterType                            
                            
                            $ParametersToCreate[$parameterName] = @(
                                if ($ParameterHelpText) {
                                    $ParameterHelpText | embedParameterHelp
                                }
                                if ($parameterAttributeParts) {
                                    "[Parameter($($parameterAttributeParts -join ','))]"
                                }
                                if ($aliasAttribute) {
                                    $aliasAttribute
                                }                                
                                if ($parameterType -as [type]) {
                                    $parameterType = $parameterType -as [type]
                                    switch ($parameterType) {
                                        [bool] { [switch]}
                                        [array] { [PSObject[]] }
                                        [object] { [PSObject] }
                                    }
                                    if ($parameterType -eq [bool]) {
                                        "[switch]"
                                    } 
                                    elseif ($parameterType -eq [array]) {
                                        "[PSObject[]]"
                                    }
                                    else {
                                        if ($WeaklyTyped) {
                                            if ($parameterType.GetInterface -and 
                                                $parameterType.GetInterface([Collections.IDictionary])) {
                                                "[Collections.IDictionary]"
                                            }                                            
                                            elseif ($parameterType.GetInterface -and 
                                                $parameterType.GetInterface([Collections.IList])) {
                                                "[PSObject[]]"
                                            }
                                            else {
                                                "[PSObject]"
                                            }
                                        } else {
                                            if ($parameterType.IsGenericType -and
                                                $parameterType.GetInterface -and 
                                                $parameterType.GetInterface(([Collections.IList])) -and
                                                $parameterType.GenericTypeArguments.Count -eq 1
                                            ) {
                                                "[$($parameterType.GenericTypeArguments[0].Fullname -replace '^System\.')[]]"
                                            } else {
                                                "[$($parameterType.FullName -replace '^System\.')]"
                                            }
                                            
                                        }
                                    }                                    
                                }
                                elseif ($parameterType) {
                                    $PsuedoTypeName = $parameterType | psuedoTypeToRealType
                                    if ($PsuedoTypeName) {
                                        $PsuedoTypeName
                                    } else {
                                        "[PSTypeName('$($parameterType -replace '^System\.')')]"
                                    }                                    
                                }
                                
                                if ($ParameterOtherAttributes) {
                                    $ParameterOtherAttributes
                                }
                                '$' + ($parameterName -replace '^$')
                            ) -join [Environment]::newLine
                        }
                    }
                }
                # If the parameter was a string
                elseif ($Param -is [string])
                {
                    # treat it as  parameter name
                    $ParametersToCreate[$Param] =
                        @(
                        if ($parameterHelp -and $parameterHelp[$Param]) {
                            $parameterHelp[$Param] | embedParameterHelp
                        }
                        "[Parameter(ValueFromPipelineByPropertyName)]"
                        "`$$Param"
                        ) -join [Environment]::NewLine
                }
                # If the parameter is a [ScriptBlock]
                elseif ($Param -is [scriptblock])
                {
                    # add it to a list of parameter script blocks.
                    $parameterScriptBlocks +=
                        if ($Param.Ast.ParamBlock) {
                            $Param
                        }
                }
                # If the -Parameter was provided via reflection
                elseif ($Param -is [Reflection.PropertyInfo] -or
                    $Param -as [Reflection.PropertyInfo[]] -or
                    $Param -is [Reflection.ParameterInfo] -or
                    $Param -as [Reflection.ParameterInfo[]] -or
                    $Param -is [Reflection.MethodInfo] -or
                    $Param -as [Reflection.MethodInfo[]]
                ) {
                    # Find an XML documentation file for the type, if available
                    if (-not $Script:FoundXmlDocsForAssembly) {
                        $Script:FoundXmlDocsForAssembly = @{}
                    }
                    
                    if (-not $Script:FoundXmlDocsForType) {
                        $Script:FoundXmlDocsForType = @{}
                    }

                    $declaringType = $param.DeclaringType
                    $declaringAssembly = $param.DeclaringType.Assembly
                    if (-not $Script:FoundXmlDocsForAssembly[$declaringAssembly]) {
                        $likelyXmlLocation = $declaringAssembly.Location -replace '\.dll$', '.xml'
                        if (Test-Path $likelyXmlLocation) {
                            $Script:FoundXmlDocsForAssembly[$declaringAssembly] = [IO.File]::ReadAllText($likelyXmlLocation) -as [xml]
                        }
                    }

                    if ($Script:FoundXmlDocsForAssembly[$declaringAssembly] -and 
                        -not $Script:FoundXmlDocsForType[$declaringType]) {
                        $Script:FoundXmlDocsForType[$declaringType] =
                            foreach ($node in $Script:FoundXmlDocsForAssembly[$declaringAssembly].SelectNodes("//member")) {
                                if ($node.Name -like "*$($declaringType.FullName)*") {
                                    $node
                                }
                            }
                    }

                    # check to see if it's a method
                    if ($Param -is [Reflection.MethodInfo] -or
                        $Param -as [Reflection.MethodInfo[]]) {
                        $Param = @(foreach ($methodInfo in $Param) {
                            $methodInfo.GetParameters() # if so, reflect the method's parameters
                        })
                    }

                    
                    # Walk over each parameter and turn it into a dictionary of dictionaries
                    $propertiesToParameters = [Ordered]@{}

                    foreach ($prop in $Param) {
                        # If it is a property info that cannot be written, skip.
                        if ($prop -is [Reflection.PropertyInfo] -and -not $prop.CanWrite) { continue }
                        # Determine the reflected parameter type.
                        $paramType =
                            if ($prop.ParameterType) {
                                $prop.ParameterType
                            } elseif ($prop.PropertyType) {
                                $prop.PropertyType
                            } else {
                                [PSObject]
                            }

                        $NewParamName = $prop.Name
                        $NewParameterInfo = [Ordered]@{
                            Name = $NewParamName
                            Attribute = @('ValueFromPipelineByPropertyName')
                            ParameterType = $paramType
                        }

                        if ($ParameterHelp -and $ParameterHelp[$prop.Name]) {
                            $NewParameterInfo.Help = $ParameterHelp[$prop.Name]
                        } elseif ($Script:FoundXmlDocsForType[$declaringType]) {
                            $lookingForString = @("$prop" -split ' ')[-1]
                            $foundXmlDocsForProp = foreach ($docXmlNode in $Script:FoundXmlDocsForType[$declaringType]) {
                                if ($docXmlNode.Name.EndsWith($lookingForString)) {
                                    $docXmlNode
                                    break
                                } 
                            }
                            if ($foundXmlDocsForProp -and $foundXmlDocsForProp.Summary -is [string]) {
                                $NewParameterInfo.Help = $foundXmlDocsForProp.Summary
                                $null = $null
                            }
                        }

                        $propertiesToParameters[$NewParamName] = $NewParameterInfo                        
                    }
                    $parameterQueue.Enqueue($propertiesToParameters)
                }
                elseif ($Param -is [PSObject]) {
                    $paramIsReference = $param.'$ref'
                    if ($paramIsReference -and $ReferenceObject) {
                        $ptr = $ReferenceObject
                        $objectPath = $paramIsReference -replace '^#' -replace '^/' -split '[/\.]' -ne ''
                        foreach ($op in $objectPath) {
                            $ptr = $ptr.$op
                        }
                        if ($ptr) {
                            $parameterQueue.Enqueue($ptr)
                        }
                        continue
                    }

                    # If there's a parameter name and schema, we can turn this into something useful.
                    if ($param.Name -and $param.schema) {
                        $newParameterInfo = [Ordered]@{name=$param.Name}
                        if ($param.description) {
                            $newParameterInfo.Description = $param.Description
                        }
                        if ($param.schema.type) {
                            $newParameterInfo.ParameterType = $param.schema.type | psuedoTypeToRealType
                        }
                        if ($param.required -or $param.Mandatory) {
                            $newParameterInfo.Mandatory = $true
                        }
                                                
                        $parameterQueue.Enqueue([Ordered]@{$param.Name=$newParameterInfo})                                                
                    }                    
                }
            }
            
        }

        # If there is header content,
        if ($header) {
            $allHeaders += $Header
        }

        # dynamic parameters,
        if ($DynamicParameter) {
            $allDynamicParameters += $DynamicParameter
        }

        # begin,
        if ($Begin) {
            $allBeginBlocks += $begin
        }

        if ($InputObject -is [scriptblock] -and -not $PSBoundParameters['Process']) {
            $process = $InputObject
        }

        # process,
        if ($process) {
            if ($process.BeginBlock -or 
                $process.ProcessBlock -or 
                $process.DynamicParameterBlock -or 
                $Process.ParamBlock) {
                if ($process.DynamicParameterBlock) {
                    $allDynamicParameters += $process.DynamicParameterBlock
                }
                if ($process.ParamBlock) {
                    $parameterScriptBlocks += $Process
                }
                if ($Process.BeginBlock) {
                    $allBeginBlocks += $Process.BeginBlock -replace ${?<EmptyParameterBlock>}
                }
                if ($process.ProcessBlock) {
                    $allProcessBlocks += $process.ProcessBlock
                }
                if ($process.EndBlock) {
                    $allEndBlocks += $Process.EndBlock -replace ${?<EmptyParameterBlock>}
                }
            } else {
                $allProcessBlocks += $process -replace ${?<EmptyParameterBlock>}
            }            
        }

        # or end blocks.
        if ($end) {
            # accumulate them.
            $allEndBlocks += $end
        }

        # If -AutoParameter was passed
        if ($AutoParameter) {
            # Find all of the variable expressions within -Begin, -Process, and -End
            $variableDefinitions = $Begin, $Process, $End |
                Where-Object { $_ } |
                Search-PipeScript -AstType VariableExpressionAST |
                Select-Object -ExpandProperty Result
            foreach ($var in $variableDefinitions) {
                # Then, see where those variables were assigned
                $assigned = $var.GetAssignments()
                # (if they were assigned, keep moving)
                if ($assigned) { continue }
                # If there were not assigned
                $varName = $var.VariablePath.userPath.ToString()
                # add it to the list of parameters to create.
                $ParametersToCreate[$varName] = @(
                    @(
                    "[Parameter(ValueFromPipelineByPropertyName)]"
                    "[$($AutoParameterType.FullName -replace '^System\.')]"
                    "$var"
                    ) -join [Environment]::NewLine
                )
            }
        }
    }

    end {
        # Take all of the accumulated parameters and create a parameter block
        $newParamBlock =
            "param(" + [Environment]::newLine +
            $(@(foreach ($toCreate in $ParametersToCreate.GetEnumerator()) {
                $toCreate.Value -join [Environment]::NewLine
            }) -join (',' + [Environment]::NewLine)) +
            [Environment]::NewLine +
            ')'

        # If any parameters were passed in as ```[ScriptBlock]```s,
        if ($parameterScriptBlocks) {
            $parameterScriptBlocks += [ScriptBlock]::Create($newParamBlock)
            # join them with the new parameter block.
            $newParamBlock = $parameterScriptBlocks | Join-PipeScript -IncludeBlockType param
        }
        
        # If we provided a -FunctionName, we'll be declaring a function.
        $functionDeclaration =
            # If the -FunctionType is function or filter
            if ($functionName -and $functionType -in 'function', 'filter') {
                # we declare it naturally.
                "$functionType $FunctionName  {"
            } elseif ($FunctionName) {
                # Otherwise, we declare it as a command namespace
                "$functionType function $functionName {"
                # (which means we have to transpile).
                $NoTranspile = $false
            }

        # Create the script block by combining together the provided parts.
        $ScriptToBe = "$(if ($functionDeclaration) { "$functionDeclaration"})
$($allHeaders -join [Environment]::Newline)
$newParamBlock
$(if ($allDynamicParameters) {
    @(@("dynamicParam {") + $allDynamicParameters + '}') -join [Environment]::Newline
})
$(if ($allBeginBlocks) {
    @(@("begin {") + $allBeginBlocks + '}') -join [Environment]::Newline
})
$(if ($allProcessBlocks) {
    @(@("process {") + $allProcessBlocks + '}') -join [Environment]::Newline
})
$(if ($allEndBlocks -and -not $allBeginBlocks -and -not $allProcessBlocks) {
    $allEndBlocks -join [Environment]::Newline
} elseif ($allEndBlocks) {
    @(@("end {") + $allEndBlocks + '}') -join [Environment]::Newline
})
$(if ($functionDeclaration) { '}'}) 
"

        $createdScriptBlock = [scriptblock]::Create($ScriptToBe)

        # If -NoTranspile was passed, 
        if ($createdScriptBlock -and $NoTranspile) {
            $createdScriptBlock # output the script as-is
        } elseif ($createdScriptBlock) { # otherwise            
            $createdScriptBlock | .>PipeScript # output the transpiled script.
        }
    }
}
