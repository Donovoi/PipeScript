
Rest
----
### Synopsis
Generates PowerShell to talk to a REST api.

---
### Description

Generates PowerShell that communicates with a REST api.

---
### Examples
#### EXAMPLE 1
```PowerShell
{
    function Get-Sentiment {
        [Rest("http://text-processing.com/api/sentiment/",
            ContentType="application/x-www-form-urlencoded",
            Method = "POST",
            BodyParameter="Text",
            ForeachOutput = {
                $_ | Select-Object -ExpandProperty Probability -Property Label
            }
        )]
        param()
    } 
} | .>PipeScript | Set-Content .\Get-Sentiment.ps1
```

#### EXAMPLE 2
```PowerShell
Invoke-PipeScript {
    [Rest("http://text-processing.com/api/sentiment/",
        ContentType="application/x-www-form-urlencoded",
        Method = "POST",
        BodyParameter="Text",
        ForeachOutput = {
            $_ | Select-Object -ExpandProperty Probability -Property Label
        }
    )]
    param()
} -Parameter @{Text='wow!'}
```

#### EXAMPLE 3
```PowerShell
{
    [Rest("https://api.github.com/users/{username}/repos",
        QueryParameter={"type", "sort", "direction", "page", "per_page"}
    )]
    param()
} | .>PipeScript
```

#### EXAMPLE 4
```PowerShell
Invoke-PipeScript {
    [Rest("https://api.github.com/users/{username}/repos",
        QueryParameter={"type", "sort", "direction", "page", "per_page"}
    )]
    param()
} -UserName StartAutomating
```

#### EXAMPLE 5
```PowerShell
{
    [Rest("http://text-processing.com/api/sentiment/",
        ContentType="application/x-www-form-urlencoded",
        Method = "POST",
        BodyParameter={@{
            Text = '
                [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
                [string]
                $Text
            '
        }})]
    param()
} | .>PipeScript
```

---
### Parameters
#### **ScriptBlock**

The ScriptBlock.
If not empty, the contents of this ScriptBlock will preceed the REST api call.



> **Type**: ```[ScriptBlock]```

> **Required**: false

> **Position**: named

> **PipelineInput**:true (ByValue)



---
#### **RESTEndpoint**

One or more REST endpoints.  This endpoint will be parsed for REST variables.



> **Type**: ```[String[]]```

> **Required**: true

> **Position**: 1

> **PipelineInput**:false



---
#### **ContentType**

The content type.  If provided, this parameter will be passed to the -InvokeCommand.



> **Type**: ```[String]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
#### **Method**

The method.  If provided, this parameter will be passed to the -InvokeCommand.



> **Type**: ```[String]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
#### **InvokeCommand**

The invoke command.  This command _must_ have a parameter -URI.



> **Type**: ```[String]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
#### **InvokeParameterVariable**

The name of a variable containing additional invoke parameters.
By default, this is 'InvokeParams'



> **Type**: ```[String]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
#### **UriParameterHelp**

A dictionary of help for uri parameters.



> **Type**: ```[IDictionary]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
#### **UriParameterType**

A dictionary of URI parameter types.



> **Type**: ```[IDictionary]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
#### **BodyParameter**

A dictionary or list of parameters for the body.


If a parameter has a ```[ComponentModel.DefaultBindingProperty]``` attribute,
it will be used to rename the body parameter.


If a parameter has a ```[ComponentModel.AmbientValue]``` attribute with a ```[ScriptBlock]``` value,
it will be used to redefine the value.


If a parameter value is a [DateTime], it will be turned into a [string] using the standard format.

If a parameter is a [switch], it will be turned into a [bool].



> **Type**: ```[PSObject]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
#### **QueryParameter**

A dictionary or list of query parameters.


If a parameter has a ```[ComponentModel.DefaultBindingProperty]``` attribute,
it will be used to rename the body parameter.


If a parameter has a ```[ComponentModel.AmbientValue]``` attribute with a ```[ScriptBlock]``` value,
it will be used to redefine the value.


If a parameter value is a [DateTime], it will be turned into a [string] using the standard format.

If a parameter is a [switch], it will be turned into a [bool].



> **Type**: ```[PSObject]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
#### **JoinQueryValue**

If provided, will join multiple values of a query by this string.
If the string is '&', each value will be provided as a key-value pair.



> **Type**: ```[String]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
#### **ForEachOutput**

A script block to be run on each output.



> **Type**: ```[ScriptBlock]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
### Syntax
```PowerShell
Rest [-ScriptBlock <ScriptBlock>] [-RESTEndpoint] <String[]> [-ContentType <String>] [-Method <String>] [-InvokeCommand <String>] [-InvokeParameterVariable <String>] [-UriParameterHelp <IDictionary>] [-UriParameterType <IDictionary>] [-BodyParameter <PSObject>] [-QueryParameter <PSObject>] [-JoinQueryValue <String>] [-ForEachOutput <ScriptBlock>] [<CommonParameters>]
```
---



