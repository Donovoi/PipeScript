
function Language.TOML {
<#
.SYNOPSIS
    TOML Language Definition.
.DESCRIPTION
    Allows PipeScript to generate TOML.
    Because TOML does not support comment blocks, PipeScript can be written inline inside of specialized Multiline string
    PipeScript can be included in a TOML string that starts and ends with ```{}```, for example ```"""{}"""```
.Example
    .> {
        $tomlContent = @'
[seed]
RandomNumber = """{Get-Random}"""
'@
        [OutputFile('.\RandomExample.ps1.toml')]$tomlContent
    }
    .> .\RandomExample.ps1.toml
#>
[ValidatePattern('\.toml$')]
param(
                    
                )
$this = $myInvocation.MyCommand
if (-not $this.Self) {
$languageDefinition =
New-Module {
<#
.SYNOPSIS
    TOML Language Definition.
.DESCRIPTION
    Allows PipeScript to generate TOML.
    Because TOML does not support comment blocks, PipeScript can be written inline inside of specialized Multiline string
    PipeScript can be included in a TOML string that starts and ends with ```{}```, for example ```"""{}"""```
.Example
    .> {
        $tomlContent = @'
[seed]
RandomNumber = """{Get-Random}"""
'@
        [OutputFile('.\RandomExample.ps1.toml')]$tomlContent
    }
    .> .\RandomExample.ps1.toml
#>
[ValidatePattern('\.toml$')]
param()
    # We start off by declaring a number of regular expressions:
    
    $startComment = '(?>"""\{)'
    $endComment   = '(?>\}""")'
    
    $startPattern = "(?<PSStart>${startComment})"    
    $endPattern   = "(?<PSEnd>${endComment})"
    Export-ModuleMember -Variable * -Function * -Alias *
} -AsCustomObject
$languageDefinition.pstypenames.clear()
$languageDefinition.pstypenames.add("Language.TOML")
$this.psobject.properties.add([PSNoteProperty]::new('Self',$languageDefinition))
}
$this.Self
}


