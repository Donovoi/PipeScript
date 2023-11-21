function Export-Pipescript {
    <#
    .Synopsis
        Builds and Exports using PipeScript
    .Description
        Builds and Exports a path, using PipeScript.
        
        Any Source Generator Files Discovered by PipeScript will be run, which will convert them into source code.
    .EXAMPLE
        Export-PipeScript
    #>
    [Alias('Build-PipeScript','bps','eps','psc')]
    param(
    # One or more input paths.  If no -InputPath is provided, will build all scripts beneath the current directory.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string[]]
    $InputPath
    )

    begin {
        function AutoRequiresSimple {
            param(
            [Management.Automation.CommandInfo]
            $CommandInfo
            )

            process {
                if (-not $CommandInfo.ScriptBlock) { return }
                $simpleRequirements = 
                    foreach ($requiredModule in $CommandInfo.ScriptBlock.Ast.ScriptRequirements.RequiredModules) {
                        if ($requiredModule.Name -and 
                            (-not $requiredModule.MaximumVersion) -and
                            (-not $requiredModule.RequiredVersion)
                        ) {
                            $requiredModule.Name
                        }
                    }

                if ($simpleRequirements) {
                    Invoke-PipeScript "require latest $($simpleRequirements)"
                }                
            }
        }

        $filesWithErrors = @()
        $errorsByFile = @{}
    }

    process {
        if ($env:GITHUB_WORKSPACE) {
            "::group::Discovering files", "from: $InputPath" | Out-Host
        }
        $filesToBuild = 
            @(if (-not $InputPath) {
                Get-PipeScript -PipeScriptPath $pwd |
                    Where-Object PipeScriptType -Match '(?>Template|BuildScript)' |
                    Sort-Object PipeScriptType, Source
            } else {
                foreach ($inPath in $InputPath) {
                    Get-PipeScript -PipeScriptPath $inPath |
                        Where-Object PipeScriptType -Match '(?>Template|BuildScript)' |
                        Sort-Object PipeScriptType, Source
                }
            })

        if ($env:GITHUB_WORKSPACE) {
            "$($filesToBuild.Length) files to build:" | Out-Host
            $filesToBuild.Source -join [Environment]::NewLine | Out-Host
            "::endgroup::" | Out-Host
        }
        
        $buildStarted = [DateTime]::Now
        $alreadyBuilt = [Ordered]@{}
        $filesToBuildCount, $filesToBuildTotal, $filesToBuildID  = 0, $filesToBuild.Length, $(Get-Random)

        if ($env:GITHUB_WORKSPACE) {
            "::group::Building PipeScripts [$FilesToBuildCount / $filesToBuildTotal]" | Out-Host                
        }
        # Keep track of how much is input and output.
        [long]$TotalInputFileLength  = 0 
        [long]$TotalOutputFileLength = 0 
        foreach ($buildFile in $filesToBuild) {            
            $ThisBuildStartedAt = [DateTime]::Now
            Write-Progress "Building PipeScripts [$FilesToBuildCount / $filesToBuildTotal]" "$($buildFile.Source) " -PercentComplete $(
                $FilesToBuildCount++
                $FilesToBuildCount * 100 / $filesToBuildTotal 
            ) -id $filesToBuildID
            
            if (-not $buildFile.Source) { continue }
            if ($alreadyBuilt[$buildFile.Source]) { continue }
            $buildFileInfo = $buildFile.Source -as [IO.FileInfo]
            $TotalInputFileLength += $buildFileInfo.Length

            $buildFileTemplate = $buildFile.Template
            if ($buildFileTemplate -and $buildFile.PipeScriptType -ne 'Template') {
                AutoRequiresSimple -CommandInfo $buildFileTemplate
                try {
                    Invoke-PipeScript $buildFileTemplate.Source
                } catch {
                    $ex = $_
                    Write-Error -ErrorRecord $ex
                    if ($env:GITHUB_WORKSPACE) {
                        $fileAndLine = @(@($ex.ScriptStackTrace -split [Environment]::newLine)[-1] -split ',\s',2)[-1]
                        $file, $line = $fileAndLine -split ':\s\D+\s', 2
                        
                        "::error file=$($buildFile.FullName),line=$line::$($ex.Exception.Message)" | Out-Host
                    }
                }
                $alreadyBuilt[$buildFileTemplate.Source] = $true
            }

            $EventsFromThisBuild = Get-Event |
                Where-Object TimeGenerated -gt $ThisBuildStartedAt |
                Where-Object SourceIdentifier -Like '*PipeScript*'
            AutoRequiresSimple -CommandInfo $buildFile
            $FileBuildStarted = [datetime]::now
            $buildOutput = 
                try {
                    if ($buildFile.PipeScriptType -match 'BuildScript') {
                        if ($buildFile.ScriptBlock.Ast -and $buildFile.ScriptBlock.Ast.Find({param($ast)
                            if ($ast -isnot [Management.Automation.Language.CommandAst]) { return $false }
                            if ('task' -ne $ast.CommandElements[0]) { return $false }
                            return $true
                        }, $true)) {
                            Invoke-PipeScript "require latest InvokeBuild"
                            Invoke-Build -File $buildFile.Source -Result InvokeBuildResult
                        } else {
                            Invoke-PipeScript $buildFile.Source    
                        }
                    } else {
                        Invoke-PipeScript $buildFile.Source
                    }                    
                } catch {
                    $ex = $_
                    Write-Error -ErrorRecord $ex
                    $filesWithErrors += $buildFile.Source -as [IO.FileInfo]
                    $errorsByFile[$buildFile.Source] = $ex
                }

            $EventsFromFileBuild = Get-Event -SourceIdentifier *PipeScript* |
                Where-Object TimeGenerated -gt $FileBuildStarted |
                Where-Object SourceIdentifier -Like '*PipeScript*'

            if ($buildOutput) {
                
                if ($buildOutput -is [IO.FileInfo]) {
                    $TotalOutputFileLength += $buildOutput.Length
                }
                elseif ($buildOutput -as [IO.FileInfo[]]) {
                    foreach ($_ in $buildOutput) {
                        if ($_.Length) {
                            $TotalOutputFileLength += $_.Length
                        }
                    }
                }

                if ($env:GITHUB_WORKSPACE) {
                    $FileBuildEnded = [DateTime]::now
                    "$($buildFile.Source)", "$('=' * $buildFile.Source.Length)", "Output:" -join [Environment]::newLine | Out-Host
                    if ($buildOutput -is [Management.Automation.ErrorRecord]) {
                        $buildOutput | Out-Host
                    } else {
                        $buildOutput.FullName | Out-Host
                    }
                    $totalProcessTime = 0 
                    $timingOfCommands = $EventsFromFileBuild | 
                        Where-Object { $_.MessageData.Command -and $_.MessageData.Duration} |
                        Select-Object -ExpandProperty MessageData | 
                        Group-Object Command |
                        Select-Object -Property @{
                            Name = 'Command'
                            Expression = { $_.Name }
                        }, Count, @{
                            Name= 'Duration'
                            Expression = { 
                                $totalDuration = 0
                                foreach ($duration in $_.Group.Duration) { 
                                    $totalDuration += $duration.TotalMilliseconds
                                }
                                [timespan]::FromMilliseconds($totalDuration)
                            }
                        } | 
                        Sort-Object Duration -Descending
                        
                    $postProcessMessage = @(
                        
                    foreach ($evt in $completionEvents) {
                        $totalProcessTime += $evt.MessageData.TotalMilliseconds
                        $evt.SourceArgs[0]
                        $evt.MessageData
                    }) -join ' '
                    "Built in $($FileBuildEnded - $FileBuildStarted)" | Out-Host
                    "Commands Run:" | Out-Host
                    $timingOfCommands | Out-Host
                    Get-Event -SourceIdentifier PipeScript.PostProcess.Complete -ErrorAction Ignore | Remove-Event
                }
                
                $buildOutput
            }
            
            $alreadyBuilt[$buildFile.Source] = $true
        }
        $BuildTime = [DateTime]::Now - $buildStarted
        if ($env:GITHUB_WORKSPACE) {
            "$filesToBuildTotal in $($BuildTime)" | Out-Host
            "::endgroup::Building PipeScripts [$FilesToBuildCount / $filesToBuildTotal] : $($buildFile.Source)" | Out-Host
            if ($TotalInputFileLength) {
                "$([Math]::Round($TotalInputFileLength / 1kb)) kb input"
                "$([Math]::Round($TotalOutputFileLength / 1kb)) kb output",
                "PipeScript Factor: X$([Math]::round([double]$TotalOutputFileLength/[double]$TotalInputFileLength,4))"
            }
            
        }

        if ($filesWithErrors -and $env:GITHUB_WORKSPACE) {
            "$($filesWithErrors.Length) files with Errors" | Out-Host
            foreach ($fileWithError in $filesWithErrors) {
                "$fileWithError : $($errorsByFile[$fileWithError.FullName] | Out-String)"| Out-Host
            }
        }
        
        Write-Progress "Building PipeScripts [$FilesToBuildCount / $filesToBuildTotal]" "Finished In $($BuildTime) " -Completed -id $filesToBuildID
    }
}
