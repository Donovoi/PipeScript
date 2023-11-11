Language function HLSL {
    <#
    .SYNOPSIS
        HLSL Language Definition.
    .DESCRIPTION
        Allows PipeScript to generate HLSL.

        Multiline comments with /*{}*/ will be treated as blocks of PipeScript.
    #>
    [ValidatePattern('\.hlsl$')]
    param(
    )

    
    # We start off by declaring a number of regular expressions:
    $startComment = '/\*' # * Start Comments ```\*```
    $endComment   = '\*/' # * End Comments   ```/*```
    $Whitespace   = '[\s\n\r]{0,}'
    # * StartRegex     ```$StartComment + '{' + $Whitespace```
    $StartPattern = "(?<PSStart>${startComment}\{$Whitespace)"
    # * EndRegex       ```$whitespace + '}' + $EndComment```
    $EndPattern   = "(?<PSEnd>$Whitespace\}${endComment}\s{0,})"

}