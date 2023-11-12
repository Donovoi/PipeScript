Language function Ruby {
<#
.SYNOPSIS
    Ruby Language Definition.
.DESCRIPTION
    Allows PipeScript to generate Ruby.

    PipeScript can be embedded in a multiline block that starts with ```=begin{``` and ends with } (followed by ```=end```)
#>
[ValidatePattern('\.rb$')]
param()


    # We start off by declaring a number of regular expressions:
    
    $startComment = '(?>[\r\n]{1,3}\s{0,}=begin[\s\r\n]{0,}\{)'
    $endComment   = '(?>}[\r\n]{1,3}\s{0,}=end)'

    $ignoreEach = '[\d\.]+',
        '""',
        "''"

    $IgnoredContext = "(?<ignore>(?>$($ignoreEach -join '|'))\s{0,}){0,1}"
    
    $startPattern = "(?<PSStart>${IgnoredContext}${startComment})"    
    $endPattern   = "(?<PSEnd>${endComment}${IgnoredContext})"
}