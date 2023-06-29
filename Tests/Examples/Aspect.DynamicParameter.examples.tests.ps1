
describe 'Aspect.DynamicParameter' {
    it 'Aspect.DynamicParameter Example 1' {
        Get-Command Get-Command | 
            Aspect.DynamicParameter
    }
    it 'Aspect.DynamicParameter Example 2' {
        Get-Command Get-Process | 
            Aspect.DynamicParameter -IncludeParameter Name | Select -Expand Keys |  Should -Be Name
    }
}

