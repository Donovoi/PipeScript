Markdown.Template
-----------------




### Synopsis
Markdown Template Transpiler.



---


### Description

Allows PipeScript to generate Markdown.

Because Markdown does not support comment blocks, PipeScript can be written inline inside of specialized Markdown code blocks.

PipeScript can be included in a Markdown code block that has the Language ```PipeScript{```

In Markdown, PipeScript can also be specified as the language using any two of the following characters ```.<>```



---


### Examples
> EXAMPLE 1

```PowerShell
{
    $markdownContent = @'
# Thinking of a Number Between 1 and 100: ```.<{Get-Random -Min 1 -Max 100}>.``` is the number
### abc

~~~PipeScript{
'* ' + @("a", "b", "c" -join ([Environment]::Newline + '* '))
}
~~~

#### Guess what, other code blocks are unaffected
~~~PowerShell
1 + 1 -eq 2
~~~


'@
    [OutputFile('.\HelloWorld.ps1.md')]$markdownContent
}

.> .\HelloWorld.ps1.md
```


---


### Parameters
#### **CommandInfo**

The command information.  This will include the path to the file.






|Type           |Required|Position|PipelineInput |
|---------------|--------|--------|--------------|
|`[CommandInfo]`|true    |named   |true (ByValue)|



#### **AsTemplateObject**

If set, will return the information required to dynamically apply this template to any text.






|Type      |Required|Position|PipelineInput|
|----------|--------|--------|-------------|
|`[Switch]`|true    |named   |false        |



#### **Parameter**

A dictionary of parameters.






|Type           |Required|Position|PipelineInput|
|---------------|--------|--------|-------------|
|`[IDictionary]`|false   |named   |false        |



#### **ArgumentList**

A list of arguments.






|Type          |Required|Position|PipelineInput|
|--------------|--------|--------|-------------|
|`[PSObject[]]`|false   |named   |false        |





---


### Syntax
```PowerShell
Markdown.Template -CommandInfo <CommandInfo> [-Parameter <IDictionary>] [-ArgumentList <PSObject[]>] [<CommonParameters>]
```
```PowerShell
Markdown.Template -AsTemplateObject [-Parameter <IDictionary>] [-ArgumentList <PSObject[]>] [<CommonParameters>]
```
