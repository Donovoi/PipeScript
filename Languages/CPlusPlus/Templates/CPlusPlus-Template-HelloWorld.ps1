
function Template.HelloWorld.cpp {

    <#
    .SYNOPSIS
        Hello World in C++
    .DESCRIPTION
        A Template for Hello World, in C++.    
    #>
    param(
    # The message to print.  By default, "hello world".
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $Message = "hello world"
    )
    process {
@"
#include <iostream>

int main() {
    std::cout << "$Message";
    return 0;
}
"@
    }

}


