Language function CSS {
    <#
    .SYNOPSIS
        CSS Language Definition.
    .DESCRIPTION
        Allows PipeScript to generate CSS.

        Multiline comments with /*{}*/ will be treated as blocks of PipeScript.

        Multiline comments can be preceeded or followed by 'empty' syntax, which will be ignored.

        The CSS Inline Transpiler will consider the following syntax to be empty:

        * ```(?<q>["'])\#[a-f0-9]{3}(\k<q>)```
        * ```\#[a-f0-9]{6}```
        * ```[\d\.](?>pt|px|em)```
        * ```auto```
    .EXAMPLE
        .> {
            $StyleSheet = '
    MyClass {
        text-color: "#000000" /*{
    "''red''", "''green''","''blue''" | Get-Random
        }*/;
    }
    '
            [Save(".\StyleSheet.ps1.css")]$StyleSheet
        }

        .> .\StyleSheet.ps1.css
    #>
    [ValidatePattern('\.s{0,1}css$')]
    param(
    )


    # We start off by declaring a number of regular expressions:
    $startComment = '/\*' # * Start Comments ```\*```
    $endComment   = '\*/' # * End Comments   ```/*```
    $Whitespace   = '[\s\n\r]{0,}'
    $ignoreEach = '[''"]{0,1}\#[a-f0-9]{6}[''"]{0,1}', 
        '[''"]{0,1}\#[a-f0-9]{3}[''"]{0,1}',
        '[\d\.]+(?>em|pt|px){0,1}',
        'auto',
        "''"

    $IgnoredContext = "(?<ignore>(?>$($ignoreEach -join '|'))\s{0,}){0,1}"
    # * StartRegex     ```$IgnoredContext + $StartComment + '{' + $Whitespace```
    $StartPattern = "(?<PSStart>${IgnoredContext}${startComment}\{$Whitespace)"
    # * EndRegex       ```$whitespace + '}' + $EndComment + $ignoredContext```
    $EndPattern   = "(?<PSEnd>$Whitespace\}${endComment}\s{0,}${IgnoredContext})"
    $begin = {
        filter OutputCSS($depth) {
            $in = $_ # Capture the input object into a variable.
            if ($in -is [string]) { # If the input was a string
                return $in # directly embed it.
            } 
            elseif ($in -is [object[]]) { # If the input was an array
                # pipe back to ourself (increasing the depth)
                @($in | & $MyInvocation.MyCommand.ScriptBlock -Depth ($depth + 1)) -join [Environment]::NewLine
            }
            else { # Otherwise
                
                # we want to treat everything as a dictionary
                $inDictionary = [Ordered]@{}
                # so take any object that isn't a dictionary
                if ($in -isnot [Collections.IDictionary]) {
                    # and make it one.
                    foreach ($prop in $in.PSObject.properties) {
                        $inDictionary[$prop.Name] = $prop.Value
                    }                
                } else {
                    $inDictionary += $in
                }
        
                # Then walk over each key/valye in the dictionary
                $innerCss = $(@(foreach ($kv in $inDictionary.GetEnumerator()) {                            
                    if ($kv.Value -isnot [string]) {
                        $kv.Key + ' ' + "$($kv.Value | 
                            & $MyInvocation.MyCommand.ScriptBlock -Depth ($depth + 1))" 
                    }
                    else {
                        $kv.Key + ':' + $kv.Value
                    }                                                        
                }) -join (
                    ';' + [Environment]::NewLine + (' ' * 2 * ($depth))
                ))
        
                $(if ($depth){'{'} else {''}) + 
                    [Environment]::NewLine + 
                    (' ' * 2 * ($depth)) + 
                    $innerCss + 
                    [Environment]::NewLine + 
                    (' ' * 2 * ([Math]::max($depth - 1,0))) +
                    $(if ($depth){'}'} else {''})
            }
        }
    }
    
    $ForeachObject = {
        $_ | OutputCSS        
    }
}