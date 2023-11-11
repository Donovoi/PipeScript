<div align='center'>
<img src='Assets/PipeScript.svg' style='width:80%' />
</div>

# What Is PipeScript?

PipeScript is a new programming language built atop PowerShell.

It is designed to make programming more scriptable and scripting more programmable.

PipeScript is transpiled into PowerShell.

PipeScript can be run interactively, or used to build more PowerShell with less code.

PipeScript can also be embedded in many other languages to dynamically generate source code.

If you like PipeScript, why not use it to star this repository?:

~~~PowerShell
# Install PipeScript
Install-Module PipeScript -Scope CurrentUser
# Import PipeScript
Import-Module  PipeScript -Force

# Then use Invoke-PipeScript to run
Invoke-PipeScript -ScriptBlock {    
    param([Parameter(Mandatory)]$gitHubPat)
    # Using PipeScript, you can use URLs as commands, so we just need to call the REST api
    put https://api.github.com/user/starred/StartAutomating/PipeScript -Headers @{
        Authorization="token $gitHubPat"
    }
} -Parameter @{GitHubPat = $YourGitHubPat}
~~~

## Making Scripting more Programmable

Interpreted languages often lack a key component required for reliability:  a compiler.

PipeScript allows you to build PowerShell scripts, and provides you with an engine to change any part of your code dynamically.

This allows us to fine-tune the way we build PowerShell and lets us [extend the language](docs/PipeScriptSyntax.md) to make complex scenarios simple.

See the [List of Transpilers](docs/ListOfTranspilers.md) you can use to transform your scripts.

## Making Programming more Scriptable

Programming is tedious, not hard.

Often, programming involves implementing small functional changes within a specific templatable scenario.

For example, if implementing an interface or subclass, the only things that will change are the class name and method details.

PipeScript can be be embedded within 39 languages.

Embedding PipeScript within any of these languages allows you to generate any of these languages with parameterized scripts, thus removing some of the tedium of programming.

See the [Supported Languages](docs/SupportedLanguages.md) you can use to transform your scripts.
