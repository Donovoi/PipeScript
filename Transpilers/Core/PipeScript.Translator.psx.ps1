<#
.SYNOPSIS
    PipeScript Translator
.DESCRIPTION
    Allows optional translation of PowerShell into another language.

    For this to work, the language must support this translation (by implementing `TranslatePowerShell()` or `TranslateNameOfASTType`).

    Any pair of statements taking the form `... in <Language>` will attempt a translation.

.EXAMPLE
    {
        enum Foo {
            Bar = 1
            Baz = 2
            Bing = 3
        } in CSharp
    } | Use-PipeScript
#>
[ValidateScript({
    $validating = $_
    # This only applies to commands:
    if ($validating -isnot [Management.Automation.Language.CommandAst]) {
        return $false
    }

    # * That start with '-?in/as'
    if ($validating.CommandElements[0].Value -notmatch '^-?[in|as]') {
        return $false
    }

    # * That contain exactly two elements,
    if ($validating.CommandElements.Count -ne 2) { return $false }

    # * Whose second element is a bareword,
    if ($validating.CommandElements[1] -isnot [Management.Automation.Language.StringConstantExpressionAst]) { return $false }

    # * That are within a pipeline with multiple statements
    if (-not $validating.Parent.Parent.Statements) { return $false }    
    
    # * That are not the first statement.
    $statementIndex = $validating.Parent.Parent.Statements.IndexOf($validating.Parent)
    if ($statementIndex -le 0) {
        return $false
    }
    return $true
})]
param(
# The CommandAST
[Parameter(Mandatory,ValueFromPipeline,ParameterSetName='CommandAst')]
[Management.Automation.Language.CommandAst]
$CommandAst
)

process {
    # If this command was not within statements, return.
    if (-not $CommandAst.Parent.Parent.Statements) { return }
    # Determine the index of this statement    
    $statementIndex = $CommandAst.Parent.Parent.Statements.IndexOf($CommandAst.Parent)
    # and get the previous statement.
    $previousStatement = $CommandAst.Parent.Parent.Statements[$statementIndex -1]

    # If we don't have a previous statement, return.
    if (-not $previousStatement) { return }

    # Determine the desired language.  It should be the second element's bareword
    $desiredLanguage = $CommandAst.CommandElements[1].Value

    # Get all of the language commands
    $languageCommands = Get-PipeScript -PipeScriptType Language
    # and pick out this one
    $languageIsDefined = $languageCommands -match "^Language\.$desiredLanguage"

    # If we don't have a match, return.
    if (-not $languageIsDefined) { return }
    
    # Determine the type of the previous statement
    $previousStatementType = $previousStatement.GetType()
    

    # And attempt to translate to each potential matching language
    $translationResult = foreach ($definedLanguageCommand in $languageIsDefined) {
        # Running the language command will give us it's definition.
        $definedLanguage = & $definedLanguageCommand
        # Now we look over each potential method for a translator
        switch -regex ($definedLanguage.PSObject.Methods) {
            # It's name can start with Translate or TranslateFrom
            "Translate(?>From)?(?>$(@(
                # Followed by the fullname (minus periods)                
                $previousStatementType.FullName -replace '\.'
                # Or followed by the name 
                $previousStatementType.Name -replace '\.'
                # Or simple "TranslatePowerShell"
                'PowerShell'
            ) -join '|'
            ))" {                
                $translationMethod = $_
                # If we found a matching translation method, run it
                $translationOutput = $translationMethod.Invoke($previousStatement)
                if ($translationOutput) { 
                    # If it had output, that's our translation result, and we can stop now.
                    $translationOutput
                    break
                }
            }
            default {}
        }
    }

    # If we had a translation result,
    if ($translationResult) {
        # Output it, and attach the .ToRemove property, which will tell PipeScript to remove the previous statement.
        $translationResult | Add-Member ToRemove $previousStatement -Force -PassThru
    }
}