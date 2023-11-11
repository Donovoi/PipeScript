Language.Rust
-------------




### Synopsis
Rust Language Definition



---


### Description

Defines Rust within PipeScript.
This allows Rust to be templated.



---


### Examples
> EXAMPLE 1

```PowerShell
Invoke-PipeScript -ScriptBlock {
    $HelloWorldRustString = '    
    fn main() {
        let msg = /*{param($msg = ''hello world'') "`"$msg`""}*/ ;
        println!("{}",msg);
    }
    '
    $HelloWorldRust = HelloWorld_Rust.rs template $HelloWorldRustString
    "$HelloWorldRust"
}
```
> EXAMPLE 2

```PowerShell
Invoke-PipeScript -ScriptBlock {
    $HelloWorldRust = HelloWorld_Rust.rs template '    
    $HelloWorld = {param([Alias(''msg'')]$message = "Hello world") "`"$message`""}
    fn main() {
        let msg = /*{param($msg = ''hello world'') "`"$msg`""}*/ ;
        println!("{}",msg);
    }
    '
$HelloWorldRust.Evaluate('hi')
    $HelloWorldRust.Save(@{Message='Hello'}) |
        Foreach-Object { 
            $file = $_
            if (Get-Command rustc -commandType Application) {
                $null = rustc $file.FullName
                & ".\$($file.Name.Replace($file.Extension, '.exe'))"
            } else {
                Write-Error "Go install Rust"
            }
        }
}
```
> EXAMPLE 3

```PowerShell
'    
fn main() {
    let msg = /*{param($msg = ''hello world'') "`"$msg`""}*/ ;
    println!("{}",msg);
}
' | Set-Content .\HelloWorld_Rust.ps.rs
Invoke-PipeScript .\HelloWorld_Rust.ps.rs
```
> EXAMPLE 4

```PowerShell
$HelloWorld = {param([Alias('msg')]$message = "Hello world") "`"$message`""}
"    
fn main() {
    let msg = /*{$HelloWorld}*/ ;
    println!(`"{}`",msg);
}
" | Set-Content .\HelloWorld_Rust.ps1.rs
Invoke-PipeScript .\HelloWorld_Rust.ps1.rs -Parameter @{message='hi'} |
    Foreach-Object { 
        $file = $_
        if (Get-Command rustc -commandType Application) {
            $null = rustc $file.FullName
            & ".\$($file.Name.Replace($file.Extension, '.exe'))"
        } else {
            Write-Error "Go install Rust"
        }
    }
```


---


### Syntax
```PowerShell
Language.Rust [<CommonParameters>]
```
