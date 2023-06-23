
describe 'Get-PipeScript' {
    it 'Get-PipeScript Example 1' {
        # Get every specialized PipeScript command
        Get-PipeScript
    }
    it 'Get-PipeScript Example 2' {
        # Get all transpilers
        Get-PipeScript -PipeScriptType Transpiler
    }
    it 'Get-PipeScript Example 3' {
        # Get all template files within the current directory.
        Get-PipeScript -PipeScriptType Template -PipeScriptPath $pwd
    }
    it 'Get-PipeScript Example 4' {
        # You can use `noun verb` to call any core PipeScript command.
        PipeScript Invoke { "hello world" } |  Should -Be 'Hello World'
    }
    it 'Get-PipeScript Example 5' {
        # You can still use the object pipeline with `noun verb`
        { partial function f { } }  |
            PipeScript Import -PassThru |  Should -BeOfType ([Management.Automation.PSModuleInfo])
    }
    it 'Get-PipeScript Example 6' {
                            Get-Command Get-Command | 
                                Aspect.DynamicParameter
    }
    it 'Get-PipeScript Example 7' {
                            Get-Command Get-Process | 
                                Aspect.DynamicParameter -IncludeParameter Name | Select -Expand Keys |  Should -Be Name
    }
    it 'Get-PipeScript Example 8' {
                                                Aspect.ModuleExtendedCommand -Module PipeScript |  Should -BeOfType ([Management.Automation.CommandInfo])
    }
    it 'Get-PipeScript Example 9' {
                                                                          Aspect.ModuleCommandPattern -Module PipeScript |  Should -BeOfType ([Regex])
    }
    it 'Get-PipeScript Example 10' {
                                                                          Aspect.ModuleCommandPattern -Module PipeScript |  Should -BeOfType ([Regex])
    }
    it 'Get-PipeScript Example 11' {
                                      Aspect.ModuleCommandPattern -Module PipeScript |  Should -BeOfType ([Regex])
    }
}

