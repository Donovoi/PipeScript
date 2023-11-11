Language function ATOM {
    <#
    .SYNOPSIS
        ATOM Language Definition
    .DESCRIPTION
        Defines ATOM within PipeScript.

        This allows ATOM to be templated.
        
        Multiline comments blocks like this ```<!--{}-->``` will be treated as blocks of PipeScript.
    #>
    [ValidatePattern('\.atom$')]
    param()

    # We start off by declaring a number of regular expressions:
    $startComment = '<\!--' # * Start Comments ```<!--```
    $endComment   = '-->'   # * End Comments   ```-->```
    $Whitespace   = '[\s\n\r]{0,}'
    # To support templates, a language has to declare `$StartPattern` and `$EndPattern`:
    $StartPattern = "(?<PSStart>${startComment}\{$Whitespace)"
    $EndPattern   = "(?<PSEnd>$Whitespace\}${endComment}\s{0,})"
}