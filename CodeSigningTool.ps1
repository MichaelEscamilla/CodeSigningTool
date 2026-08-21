<#PSScriptInfo

.VERSION 2026.8.19.0

.GUID 6f2c1e5a-8b3d-4c7e-9a1f-2d4e6b8c0a3f

.AUTHOR Michael Escamilla

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI https://github.com/MichaelEscamilla/CodeSigningTool

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
2026.8.19.0   - Initial scaffold. Loads the themed window only.
                Added listing of available code-signing certificates from the CurrentUser and LocalMachine personal stores.
                Reworked the main window to a thumbprint field with a 'Select Certificate' button that opens a certificate picker pop-up.
                Added a 'Create...' button that opens a dialog to generate a self-signed code-signing certificate (subject, validity, key length, target store, non-exportable key).

.PRIVATEDATA

#> 

<#
.SYNOPSIS
This script provides a graphical user interface (GUI) for code-signing files.

.DESCRIPTION
The script creates a WPF-based GUI styled to match the GetMSIInformation tool.
This initial version loads the window shell only.

.NOTES

#>

param (
  [Parameter(Mandatory = $false)]
  [Alias('FilePath')]
  [string[]]$Path,

  [Parameter(Mandatory = $false)]
  [string]$Thumbprint,

  [Parameter(Mandatory = $false)]
  [string]$TimestampServer
)

#############################################
################# Variables #################
#############################################
# Script Name
$Script:ScriptName = "CodeSigningTool.ps1"
# Script Version
[System.Version]$Script:ScriptVersion = "2026.8.19.0"
# GitHub Repository (used for the update check)
$Script:GitHubRepo = "MichaelEscamilla/CodeSigningTool"
$Script:ReleasesApiUrl = "https://api.github.com/repos/$Script:GitHubRepo/releases/latest"
$Script:ReleasesPageUrl = "https://github.com/$Script:GitHubRepo/releases"
# Headers required by the GitHub REST API (a User-Agent is mandatory)
$Script:UpdateCheckHeaders = @{
  'User-Agent' = 'CodeSigningTool-UpdateCheck'
  'Accept'     = 'application/vnd.github+json'
}
# How this script was launched; drives which update action the 'Update Available' click takes.
$Script:UpdateChannel = $null
# Right-click menu registration
$Script:RightClickMenuName = "Sign with Code Signing Tool"
$Script:RightClickMenuFolderPath = "$env:LOCALAPPDATA\CodeSigningTool"
# File extensions the right-click menu is registered for (limited to types Set-AuthenticodeSignature can sign).
$Script:SignableExtensions = @(
  '.exe', '.dll', '.sys', '.ocx', '.cpl', '.efi',
  '.msi', '.msp', '.cab', '.cat',
  '.ps1', '.psm1', '.psd1', '.ps1xml', '.cdxml',
  '.vbs', '.js', '.wsf',
  '.appx', '.appxbundle', '.msix', '.msixbundle'
)
# Get PowerShell Version
$Script:ScriptPSVersion = $PSVersionTable.PSVersion
# Get Pwsh Path
$Script:PowerShellPath = (Get-Command pwsh.exe -ErrorAction SilentlyContinue)
# michaeltheadmin.com Icon
$Script:WindowIconBase64 = "AAABAAEAIBwAAAEAIACYDgAAFgAAACgAAAAgAAAAOAAAAAEAIAAAAAAAcA4AAMQOAADEDgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABaSFoNRkZGEUtLSxBLS0sQS0tLEEtLSxBLS0sQS0tLEEtLSxBLS0sQS0tLEEtLSxBLS0sQS0tLEEtLSxBLS0sQS0tLEEtLSxBLS0sQS0tLEEtLSxBLS0sQS0tLEEtLSxBLS0sQS0tLEFRGRhFaSEgNAAAAAAAAAABUVFQLUkxPrFNOUOlRTE7tUUxO7FFMTuxRTE7sUUxO7FFMTuxRTE7sUUxO7FFMTuxRTE7sUUxO7FFMTuxRTE7sUUxO7FFMTuxRTE7sUUxO7FFMTuxRTE7sUUxO7FFMTuxRTE7sUUxO7FFMTuxRTE7sUUxO7VROUOhSTU+qTExMCU5KTH5lYWP/bm1t/25tbf9ubW3/bm1t/25tbf9ubW3/bm1t/25tbf9ubW3/bm1t/25tbf9ubW3/bm1t/25tbf9ubW3/bm1t/25tbf9ubW3/bm1t/25tbf9ubW3/bm1t/25tbf9ubW3/bm1t/25tbf9ubW3/bmxt/2RfYf9OSkx6TkhLtWtoaf94eHj/dnZ2/3V1df91dXX/dXV1/3V1df91dXX/dXV1/3V1df91dXX/dXV1/3V1df91dXX/dXV1/3V1df91dXX/dXV1/3V1df91dXX/dXV1/3V1df91dXX/dXV1/3V1df91dXX/dXV1/3Z2dv94eHj/aWZn/05IS69OSUuxamdo/3h4eP9mZGX/Uk1P/05JS/9OSUv/VVFT/1VRUv9OSUv/T0pM/09KTP9PSkz/T0pM/09KTP9PSkz/T0pM/09KTP9PSkz/T0pM/09KTP9PSkz/TklL/1VRU/9VUVP/TklL/05JS/9STlD/ZmRl/3h4eP9oZWb/T0lMqk9JTLBqZ2j/eHl4/1dUVf90cHH/rqys/62rrP9rZ2j/b2tt/66srP+npaX/p6Wl/6elpf+npaX/p6Wl/6elpf+npaX/p6Wl/6elpf+npaX/p6Wl/6elpf+tq6z/a2do/29rbP+urKz/rays/3Bsbv9YVVb/eHl5/2hlZv9PSUyqT0lMsGpnaP94eXj/U1BR/5GPkP/09PT/8/Pz/399ff+Hg4X/9PT0/+jo6P/o6Oj/6Ojo/+jo6P/o6Oj/6Ojo/+jo6P/o6Oj/6Ojo/+jo6P/o6Oj/6Ojo//Pz8/9/fX3/hoOE//T09P/z9PP/i4iJ/1VRUv94eXn/aGVm/09JTKpPSUywamdo/3h5eP9VUlP/hIGC/9PS0v/S0dH/dXJz/3t3ef/T0tL/ycjI/8rJyv/Kycr/ycjI/8nIyP/Kycr/ysnK/8nIyP/JyMj/ysnK/8vKyf/Lycj/1NLR/3dzc/98eHj/1dPS/9TT0f9/fHz/V1NU/3h5ef9oZWb/T0lMqk9JTLBqZ2j/eHl4/19cXv9TTU//V1JU/1dSVP9TTlD/VE9R/1dSVP9XUlT/V1NV/1dTVf9XUlT/V1JU/1dTVf9XU1X/V1JU/1dSVP9XU1X/WFNU/1hSVP9ZU1T/VU9Q/1VPUP9ZU1T/WVNU/1JNTv9gXV7/eHl5/2hlZv9PSUyqT0lMsGpnaP94eXj/V1NV/3x4ef/Hx8j/v76//8HAwf/BwMD/v76//8jHx/9ybnD/dnN0/8jIyP/Ix8f/cm9w/3Vxc//Ix8j/yMfI/4B2cP85VYL/LXrf/y933P8xed7/MXne/y933P8tet7/Q1p//2NaU/94eXn/aGVm/09JTKpPSUywamdo/3h5eP9UUFL/jImK//L09P/n6Oj/5+jo/+fo6P/n6Oj/8/Pz/4B9f/+Gg4T/9PT0//L08/+Afn//hICC//L09P/y9PT/k4h//zRblv8jjf//J4n//yeJ//8nif//J4n//yON//9AYJL/Y1lQ/3h5ef9oZWb/T0lMqk9JTLBqZ2j/eHl4/1hUVv95dHP/v7u3/7izr/+3tLP/tLO0/7GwsP+5t7j/cGxu/3Rwcf+5uLj/ubi4/3Bsbv9ybnD/ubi4/7m4uP98c27/PVV9/y5zzf8xcMr/NHTO/zR0zv8xcMr/LnPN/0RXef9jWlX/eHl5/2hlZv9PSUyqT0lMsGpnaP94eXj/YFxd/01LUv9ITVz/SE5d/0pJUP9TTU7/XFdZ/1tXWf9VUVL/VlFT/1tXWf9bV1n/VVFT/1ZRU/9cV1n/XFdZ/1VQU/9ZU1L/ZFtY/2RbV/9ZUEz/WlFN/2RbWP9kW1j/VlBQ/19cXv94eXn/aGVm/09JTKpPSUywamdo/3h5eP9jWFH/QF+Q/ymE+f8phPn/OFiJ/4yCe//e3t7/3d3d/3p2eP9/fH3/3t7e/93e3f96d3j/fXl7/93e3v/d3t7/fXp7/4B9fv/f3t7/3t3d/3p2d/9/fH3/397e/97e3f+DgIH/VlJT/3h5ef9oZWb/T0lMqk9JTLBqZ2j/eHl4/2NYT/8+Ypr/JI3//ySN//81WpL/lYuC//Pz8//y8vL/gHx+/4aDhP/z8/P/8vPy/4B9fv+DgIL/8vPz//Lz8/+DgYL/h4SF//Pz8//y8vL/f3x9/4aDhP/z8/P/8vPy/4qIiP9VUVL/eHl5/2hlZv9PSUyqT0lMsGpnaP94eXj/YFhV/0ZTbv87aaj/O2mo/0NRbP9waGX/m5iZ/5uYmf9mYWP/aGRm/5uYmf+bmJn/ZmJj/2djZf+bmJn/m5iZ/2djZf9pZWb/m5iZ/5uYmf9lYWL/amZo/6Cdnv+fnZ7/a2Zo/1lVV/94eXn/aGVm/09JTKpOSUuxamdo/3d4eP9nZmj/XFVT/2BUTP9gVEz/X1hV/1dUVv9QTE7/UExO/1lVV/9ZVVb/UExO/1BMTv9ZVVf/WVVW/1BMTv9QTE7/WVVW/1hVVv9QTE7/UExO/1lVV/9ZVVb/UE1O/1FNTv9WUlT/aWdo/3d4eP9oZWb/TkhLq09JTLNraGn/eHl5/3d3d/93eHj/d3h3/3d4d/93eHf/d3h3/3d4d/93eHf/d3h3/3d4d/93eHf/d3h3/3d4d/93eHf/d3h3/3d4d/93eHf/d3h3/3d4d/93eHf/d3h3/3d4d/93eHf/d3h3/3d4eP93d3f/eHl4/2hmZ/9OSEuuUUpMbWRfYf9ta2z/bWts/21rbP9ta2z/bWts/21rbP9ta2z/bWts/21rbP9ta2z/bWts/21rbP9ta2z/amhp/2poaf9ta2z/bWts/21rbP9ta2z/bWts/21rbP9ta2z/bWts/21rbP9ta2z/bWts/21rbP9samv/Yl1f/1BLS2hRUVECUUtNjFNNT89QS0zTUEpM01BKTNNQSkzTUEpM01BKTNNQSkzTUEpM01BKTNNQSkzTUEpM01BLTdFQS03yUEtN8FBLTdFQSkzTUEpM01BKTNNQSkzTUEpM01BKTNNQSkzTUEpM01BKTNNQSkzTUEtM01NNT89RTE6IfHx8AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFNMT7lTTVCmAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAU01Qs1JNT7gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABTTU1RWFNV/1NOUIhUTE9pVFBSaExMTBYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABRTE9mVlFS11NOUOJWUVLdUEtQNQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//////////wAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//n////5////+B////wf///////////8="

#############################################
############### Load Assemblies ##############
#############################################
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

#############################################
################# Functions #################
#############################################
#region Functions
function Test-FileLock {
  # Returns $true when the file can't be opened for writing (e.g. open in an editor).
  param (
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  try {
    $FileStream = [System.IO.File]::Open("$($Path)", 'Open', 'Write')
    $FileStream.Close()
    $FileStream.Dispose()
    return $false
  }
  catch {
    return $true
  }
}

# Authored as a scriptblock because it's passed to a runspace.
$Script:TestForUpdate = {
  param(
    [string]$ApiUrl,
    [hashtable]$Headers,
    [System.Version]$CurrentVersion
  )
  $release = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -TimeoutSec 10 -ErrorAction Stop
  $latestVersion = [System.Version]($release.tag_name -replace '^v', '')
  [PSCustomObject]@{
    UpdateAvailable = ($latestVersion -gt $CurrentVersion)
    LatestVersion   = $latestVersion
    HtmlUrl         = $release.html_url
    Tag             = $release.tag_name
  }
}

function Start-BackgroundUpdateCheck {
  [CmdletBinding()]
  param([switch]$Manual)

  # Don't start a second check while one is still running (e.g. manual click during the startup check).
  if ($Script:UpdateHandle -and -not $Script:UpdateHandle.IsCompleted) { return }
  $Script:UpdateCheckManual = $Manual.IsPresent

  # Detect the distribution channel once so the update click is a cheap lookup.
  if (-not $Script:UpdateChannel) { $Script:UpdateChannel = Get-UpdateChannel }

  try {
    $Script:UpdatePowerShell = [powershell]::Create()
    $Script:UpdatePowerShell.AddScript($Script:TestForUpdate).
      AddArgument($Script:ReleasesApiUrl).
      AddArgument($Script:UpdateCheckHeaders).
      AddArgument($Script:ScriptVersion) | Out-Null
    $Script:UpdateHandle = $Script:UpdatePowerShell.BeginInvoke()

    $Script:UpdateTimer = New-Object System.Windows.Threading.DispatcherTimer
    $Script:UpdateTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $Script:UpdateTimer.Add_Tick({
        if (-not $Script:UpdateHandle.IsCompleted) { return }
        $Script:UpdateTimer.Stop()
        try {
          $result = $Script:UpdatePowerShell.EndInvoke($Script:UpdateHandle) | Select-Object -First 1
          Write-Host "Background update check: UpdateAvailable=$($result.UpdateAvailable) | Installed [$($Script:ScriptVersion)] | Latest [$($result.LatestVersion)]"
          Show-UpdateAvailable -Result $result
          # Manual check only: confirm when already current (an available update is surfaced by the menu item).
          if ($Script:UpdateCheckManual -and -not $result.UpdateAvailable) {
            Set-StatusMessage -Message "You're running the latest version ($($Script:ScriptVersion))." -Type 'Success'
          }
        }
        catch {
          Write-Host "Background update check failed: $($_.Exception.Message)"
          if ($Script:UpdateCheckManual) {
            [System.Windows.MessageBox]::Show("Update check failed:`n$($_.Exception.Message)", "Check for Updates", 'OK', 'Warning') | Out-Null
          }
        }
        finally {
          $Script:UpdatePowerShell.Dispose()
        }
      })
    $Script:UpdateTimer.Start()
  }
  catch {
    Write-Host "Unable to start background update check: $($_.Exception.Message)"
  }
}

function Show-UpdateAvailable {
  # Reveals the 'Update Available' menu item when a newer release exists, so both the background and
  # manual checks surface the result the same way. Remembers the download link for the click handler.
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    $Result
  )

  if (-not $Result.UpdateAvailable) { return }

  $Script:LatestReleaseUrl = if ($Result.HtmlUrl) { $Result.HtmlUrl } else { $Script:ReleasesPageUrl }
  $Script:LatestReleaseTag = $Result.Tag
  $MenuItem_UpdateAvailable.Header = "Update Available: $($Result.LatestVersion)"
  $MenuItem_UpdateAvailable.Visibility = [System.Windows.Visibility]::Visible
}

function Get-UpdateChannel {
  # Detects how the script was launched so the update action can match the channel.
  # Cached once in $Script:UpdateChannel; ordering matters because RightClick and LooseFile
  # both have a non-empty $PSCommandPath.
  [CmdletBinding()]
  param()

  # Web: launched via iex (irm ...); nothing on disk to update, next launch is always latest.
  if ([string]::IsNullOrEmpty($PSCommandPath)) {
    $channel = 'Web'
  }
  else {
    $scriptFolder = Split-Path -Path $PSCommandPath -Parent

    # Right-click install: running from the LOCALAPPDATA copy.
    if ($scriptFolder -eq $Script:RightClickMenuFolderPath) {
      $channel = 'RightClick'
    }
    else {
      # PowerShell Gallery install: Install-Script location matches where we're running from.
      $installed = Get-InstalledScript -Name 'CodeSigningTool' -ErrorAction SilentlyContinue
      if ($installed -and $installed.InstalledLocation -eq $scriptFolder) {
        $channel = 'PSGallery'
      }
      else {
        # Anything else: a loose .ps1 on disk.
        $channel = 'LooseFile'
      }
    }
  }

  Write-Host "Update channel: [$channel]"
  return $channel
}

function Open-ReleasePage {
  # Universal fallback for the update action: open the newer release (or the releases list).
  if ($Script:LatestReleaseUrl) { Start-Process $Script:LatestReleaseUrl }
  else { Start-Process $Script:ReleasesPageUrl }
}

function Update-ScriptFile {
  # Overwrites the target .ps1 with the latest release. Returns $false so the caller can fall
  # back to the releases page when the file can't be replaced in place (locked, read-only, offline).
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [Parameter(Mandatory = $true)]
    [string]$Tag
  )

  # Can't overwrite a file that's locked (e.g. open in an editor).
  if (Test-FileLock -Path $ScriptPath) {
    Write-Host "Update aborted: script file is locked [$ScriptPath]"
    return $false
  }

  $downloadUrl = "https://raw.githubusercontent.com/$($Script:GitHubRepo)/$Tag/$($Script:ScriptName)"
  $tempFile = Join-Path -Path $env:TEMP -ChildPath 'CodeSigningTool.update.ps1'

  try {
    Write-Host "Downloading update: [$downloadUrl]"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
    if (-not (Test-Path $tempFile) -or (Get-Item $tempFile).Length -eq 0) {
      throw 'Downloaded file is empty.'
    }
    Write-Host "Replacing script:   [$ScriptPath]"
    Copy-Item -Path $tempFile -Destination $ScriptPath -Force -ErrorAction Stop
    return $true
  }
  catch {
    Write-Host "Update failed: $($_.Exception.Message)"
    return $false
  }
  finally {
    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
  }
}

function Restart-Script {
  # Relaunches the on-disk script so an applied update takes effect, then closes this instance.
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath
  )

  # Prefer pwsh 7.4+; fall back to Windows PowerShell.
  if ($Script:PowerShellPath -and $Script:PowerShellPath.Version -ge [Version]"7.4") {
    $CommandExe = $Script:PowerShellPath.Path
  }
  else {
    $CommandExe = "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe"
  }

  $argList = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Minimized -File `"$ScriptPath`""

  Write-Host "Relaunching updated script: [$ScriptPath]"
  Start-Process -FilePath $CommandExe -ArgumentList $argList
  $formCodeSigning.Close()
}

function Install-RightClickMenu {
  # Installs or refreshes the LOCALAPPDATA copy, icon, and per-extension right-click registry entries.
  # Shared by the Install menu item and the RightClick update path. Returns the LOCALAPPDATA script path.
  [CmdletBinding()]
  param(
    # When set, the menu command pre-selects this certificate via -Thumbprint.
    [string]$Thumbprint
  )

  # Create the LOCALAPPDATA folder that holds the launched copy and icon.
  Write-Host "Creating Folder:       [$($Script:RightClickMenuFolderPath)]"
  if (-not (Test-Path $Script:RightClickMenuFolderPath)) {
    $DestinationFolder = New-Item -ItemType Directory -Path $Script:RightClickMenuFolderPath -ErrorAction SilentlyContinue
  }
  else {
    $DestinationFolder = Get-Item -Path $Script:RightClickMenuFolderPath
  }

  # Write the window icon out as an .ico for the menu entry.
  $IconFilePath = Join-Path -Path $DestinationFolder.FullName -ChildPath 'CodeSigningTool.ico'
  Remove-Item $IconFilePath -Force -ErrorAction SilentlyContinue | Out-Null
  Write-Host "Creating Icon file:    [$IconFilePath]"
  $IconByteArray = [System.Convert]::FromBase64String($Script:WindowIconBase64)
  [System.IO.File]::WriteAllBytes($IconFilePath, $IconByteArray)

  $DestinationScriptPath = Join-Path -Path $DestinationFolder.FullName -ChildPath $Script:ScriptName

  # Copy the running script into place, or download it when launched from the web (no file on disk).
  if (-not [string]::IsNullOrEmpty($PSCommandPath)) {
    Write-Host "Creating Script:       [$DestinationScriptPath]"
    Copy-Item -Path $PSCommandPath -Destination $DestinationScriptPath -Force -ErrorAction SilentlyContinue
  }
  else {
    $ScriptURL = "https://raw.githubusercontent.com/$($Script:GitHubRepo)/main/$($Script:ScriptName)"
    Write-Host "Downloading script:    [$ScriptURL]"
    try {
      Invoke-WebRequest -Uri $ScriptURL -OutFile $DestinationScriptPath -UseBasicParsing -ErrorAction Stop
      Write-Host "Script saved:          [$DestinationScriptPath]"
    }
    catch {
      Write-Host "Failed to download the script: $($_.Exception.Message)"
    }
  }

  # Prefer pwsh 7.4+ so the menu launches directly; fall back to Windows PowerShell (always present).
  if ($Script:PowerShellPath -and $Script:PowerShellPath.Version -ge [Version]"7.4") {
    $CommandExe = $Script:PowerShellPath.Path
  }
  else {
    $CommandExe = "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe"
  }

  # Pick the icon: prefer the extracted .ico, then pwsh, then Windows PowerShell.
  if (Test-Path -LiteralPath $IconFilePath) {
    $IconValue = $IconFilePath
  }
  elseif ($Script:PowerShellPath) {
    $IconValue = $Script:PowerShellPath.Path
  }
  else {
    $IconValue = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
  }

  $CommandLine = "`"$CommandExe`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Minimized -File `"$DestinationScriptPath`" -Path `"%1`""
  # Bake in the selected certificate so the right-click launch pre-selects it.
  if (-not [string]::IsNullOrWhiteSpace($Thumbprint)) {
    $CommandLine += " -Thumbprint `"$Thumbprint`""
    Write-Host "Configured Thumbprint: [$Thumbprint]"
  }
  else {
    Write-Host "Configured Thumbprint: [none]"
  }


  # Register one entry per signable extension under SystemFileAssociations so the menu only appears
  # on file types the tool can actually sign.
  foreach ($extension in $Script:SignableExtensions) {
    $MenuKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("Software\Classes\SystemFileAssociations\$extension\shell\$($Script:RightClickMenuName)")
    $MenuKey.SetValue('', $Script:RightClickMenuName)
    $MenuKey.SetValue('icon', $IconValue)
    $CommandKey = $MenuKey.CreateSubKey('command')
    $CommandKey.SetValue('', $CommandLine)
    $CommandKey.Close()
    $MenuKey.Close()
  }
  Write-Host "Registry Modified:     [HKCU:\Software\Classes\SystemFileAssociations\<ext>\shell\$($Script:RightClickMenuName)] for $($Script:SignableExtensions.Count) extension(s)"
  Write-Host "Installation Complete"

  return $DestinationScriptPath
}

function Uninstall-RightClickMenu {
  # Removes the per-extension registry entries and the LOCALAPPDATA folder.
  [CmdletBinding()]
  param()

  foreach ($extension in $Script:SignableExtensions) {
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Classes\SystemFileAssociations\$extension\shell\$($Script:RightClickMenuName)", $false)
  }
  Write-Host "Deleted Registry: [HKCU:\Software\Classes\SystemFileAssociations\<ext>\shell\$($Script:RightClickMenuName)]"

  Remove-Item -Path $Script:RightClickMenuFolderPath -Force -Recurse -ErrorAction SilentlyContinue
  Write-Host "Deleted Folder:   [$($Script:RightClickMenuFolderPath)]"
  Write-Host "Uninstallation Complete"
}

function Get-CertCommonName {
  # Extracts the CN from a distinguished name, falling back to the full string.
  param (
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$DistinguishedName
  )

  $match = [regex]::Match($DistinguishedName, 'CN=(?:"(?<quoted>[^"]*)"|(?<plain>[^,]+))')
  if ($match.Success) {
    if ($match.Groups['quoted'].Success) { return $match.Groups['quoted'].Value }
    return $match.Groups['plain'].Value.Trim()
  }
  return $DistinguishedName
}

function Test-IsCodeSigningCertificate {
  # Returns $true when the certificate has the Code Signing EKU (1.3.6.1.5.5.7.3.3).
  param (
    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
  )

  $codeSigningOid = '1.3.6.1.5.5.7.3.3'
  foreach ($extension in $Certificate.Extensions) {
    if ($extension -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]) {
      foreach ($usage in $extension.EnhancedKeyUsages) {
        if ($usage.Value -eq $codeSigningOid) { return $true }
      }
    }
  }
  return $false
}

function Get-CodeSigningCertificate {
  # Collects all code-signing certificates from the standard personal stores.
  $stores = @(
    [PSCustomObject]@{ Path = 'Cert:\CurrentUser\My';  Name = 'CurrentUser\My' }
    [PSCustomObject]@{ Path = 'Cert:\LocalMachine\My'; Name = 'LocalMachine\My' }
  )

  $results = foreach ($store in $stores) {
    try {
      Get-ChildItem -Path $store.Path -ErrorAction Stop | Where-Object { $_.HasPrivateKey -and (Test-IsCodeSigningCertificate -Certificate $_) } | ForEach-Object {
        [PSCustomObject]@{
          FriendlyName = $_.FriendlyName
          Subject      = Get-CertCommonName -DistinguishedName $_.Subject
          Issuer       = Get-CertCommonName -DistinguishedName $_.Issuer
          Expiration   = $_.NotAfter.ToString('yyyy-MM-dd')
          Store        = $store.Name
          Thumbprint   = $_.Thumbprint
          Certificate  = $_
        }
      }
    }
    catch {
      Write-Host "Unable to read certificates from [$($store.Path)]: $($_.Exception.Message)"
    }
  }

  return @($results | Sort-Object -Property Expiration -Descending)
}

function Get-SigningCertificateByThumbprint {
  # Finds a certificate in the personal stores by thumbprint (case/format-insensitive).
  param (
    [Parameter(Mandatory = $true)]
    [string]$Thumbprint
  )

  $clean = ($Thumbprint -replace '[^0-9A-Fa-f]', '').ToUpperInvariant()
  if ([string]::IsNullOrEmpty($clean)) { return $null }

  foreach ($storePath in @('Cert:\CurrentUser\My', 'Cert:\LocalMachine\My')) {
    $match = Get-ChildItem -Path $storePath -ErrorAction SilentlyContinue | Where-Object { $_.Thumbprint -eq $clean } | Select-Object -First 1
    if ($match) { return $match }
  }
  return $null
}

function Test-IsAdministrator {
  # Returns $true when the current process is elevated (required to write to LocalMachine\My).
  $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function New-CodeSigningSelfSignedCertificate {
  # Creates a self-signed code-signing certificate in the chosen personal store.
  param (
    [Parameter(Mandatory = $true)]
    [string]$Subject,

    [Parameter(Mandatory = $true)]
    [int]$ValidYears,

    [Parameter(Mandatory = $true)]
    [int]$KeyLength,

    [ValidateSet('CurrentUser', 'LocalMachine')]
    [string]$StoreLocation = 'CurrentUser',

    [switch]$NonExportable,

    [switch]$SkipTrustedRoot,

    [switch]$SkipTrustedPublisher
  )

  $subjectValue = $Subject.Trim()
  if ($subjectValue -notmatch '^CN=') { $subjectValue = "CN=$subjectValue" }

  $params = @{
    Type              = 'CodeSigningCert'
    Subject           = $subjectValue
    KeyLength         = $KeyLength
    KeyExportPolicy   = if ($NonExportable) { 'NonExportable' } else { 'Exportable' }
    NotAfter          = (Get-Date).AddYears($ValidYears)
    CertStoreLocation = "Cert:\$StoreLocation\My"
    ErrorAction       = 'Stop'
  }

  $certificate = New-SelfSignedCertificate @params

  $location = [System.Security.Cryptography.X509Certificates.StoreLocation]::$StoreLocation
  if (-not $SkipTrustedRoot) {
    Add-CertificateToStore -Certificate $certificate -StoreName 'Root' -StoreLocation $location
  }
  if (-not $SkipTrustedPublisher) {
    Add-CertificateToStore -Certificate $certificate -StoreName 'TrustedPublisher' -StoreLocation $location
  }

  return $certificate
}

function Add-CertificateToStore {
  # Adds a certificate to the named store in the given location using the X509Store API.
  param (
    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.StoreName]$StoreName,

    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation
  )

  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($StoreName, $StoreLocation)
  try {
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $store.Add($Certificate)
  }
  finally {
    $store.Close()
  }
}

function Test-CertificateInStore {
  # Returns $true when a certificate with the same thumbprint exists in the named store (either location).
  param (
    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.StoreName]$StoreName
  )

  foreach ($location in @('CurrentUser', 'LocalMachine')) {
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($StoreName, $location)
    try {
      $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
      foreach ($item in $store.Certificates) {
        if ($item.Thumbprint -eq $Certificate.Thumbprint) { return $true }
      }
    }
    catch {
      # Store may be inaccessible (e.g. LocalMachine without rights); treat as not present.
    }
    finally {
      $store.Close()
    }
  }
  return $false
}

function Get-CertificateUsageText {
  # Returns a comma-separated list of the certificate's enhanced key usage friendly names.
  param (
    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
  )

  $usages = @()
  foreach ($extension in $Certificate.Extensions) {
    if ($extension -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]) {
      foreach ($oid in $extension.EnhancedKeyUsages) {
        if ($oid.FriendlyName) { $usages += $oid.FriendlyName } else { $usages += $oid.Value }
      }
    }
  }
  if ($usages.Count -eq 0) { return 'All usages' }
  return ($usages -join ', ')
}

function Get-CertificatePublicKeyText {
  # Returns a friendly description of the public key, e.g. "RSA (2048 Bits)".
  param (
    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
  )

  $algorithm = switch -Wildcard ($Certificate.PublicKey.Oid.FriendlyName) {
    'RSA*'   { 'RSA'; break }
    'ECC*'   { 'ECC'; break }
    'ECDSA*' { 'ECDSA'; break }
    default  { if ($Certificate.PublicKey.Oid.FriendlyName) { $Certificate.PublicKey.Oid.FriendlyName } else { 'Unknown' } }
  }

  $bits = 0
  try { $bits = $Certificate.PublicKey.Key.KeySize } catch { $bits = 0 }
  if ($bits -gt 0) { return "$algorithm ($bits Bits)" }
  return $algorithm
}

function Get-CertificateStatus {
  # Returns $null when the certificate can sign, otherwise a human-readable problem message.
  param (
    [Parameter(Mandatory = $false)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
  )

  if (-not $Certificate) { return 'No certificate selected.' }
  if (-not $Certificate.HasPrivateKey) { return 'Certificate has no private key.' }
  if (-not (Test-IsCodeSigningCertificate -Certificate $Certificate)) { return 'Certificate is not valid for code signing.' }

  $now = Get-Date
  if ($Certificate.NotBefore -gt $now) { return "Certificate is not yet valid (starts $($Certificate.NotBefore.ToString('yyyy-MM-dd')))." }
  if ($Certificate.NotAfter -lt $now) { return "Certificate expired on $($Certificate.NotAfter.ToString('yyyy-MM-dd'))." }
  return $null
}

function Set-StatusText {
  # Sets a status TextBlock's text and colors it by state, matching the GetMSIInformation status pattern.
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Controls.TextBlock]$Target,

    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Message,

    [ValidateSet('Success', 'Danger', 'Accent', 'Muted')]
    [string]$Type = 'Muted'
  )

  if (-not $Target) { return }

  $brushKey = switch ($Type) {
    'Success' { 'Success' }
    'Danger' { 'Danger' }
    'Accent' { 'Accent' }
    default { 'TextMuted' }
  }

  $Target.Text = $Message
  $Target.Foreground = $formCodeSigning.FindResource($brushKey)
  $Target.FontWeight = [System.Windows.FontWeights]::SemiBold
}

function Set-StatusMessage {
  # Flashes a temporary message in the main status bar, then restores the previous text after a few seconds.
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message,

    [ValidateSet('Success', 'Danger', 'Accent', 'Muted')]
    [string]$Type = 'Success'
  )

  if (-not $txtblk_StatusBar) { return }

  $brushKey = switch ($Type) {
    'Success' { 'Success' }
    'Danger' { 'Danger' }
    'Accent' { 'Accent' }
    default { 'TextMuted' }
  }

  # Snapshot the resting state so the revert restores whatever was there before, not a hardcoded string.
  # Only capture when the bar is at rest; otherwise a rapid second flash would capture the first transient.
  if (-not ($Script:StatusTimer -and $Script:StatusTimer.IsEnabled)) {
    $Script:StatusRestoreText = $txtblk_StatusBar.Text
    $Script:StatusRestoreBrush = $txtblk_StatusBar.Foreground
    $Script:StatusRestoreWeight = $txtblk_StatusBar.FontWeight
  }

  $txtblk_StatusBar.Text = $Message
  $txtblk_StatusBar.Foreground = $formCodeSigning.FindResource($brushKey)
  $txtblk_StatusBar.FontWeight = [System.Windows.FontWeights]::SemiBold

  # Reuse a single timer so rapid clicks don't stack revert callbacks.
  if (-not $Script:StatusTimer) {
    $Script:StatusTimer = New-Object System.Windows.Threading.DispatcherTimer
    $Script:StatusTimer.Interval = [TimeSpan]::FromSeconds(4)
    # Stop via $timer and read the restore state off the timer's Tag: script-scoped
    # variables aren't reliably visible inside the Tick callback, so keep it self-contained.
    $Script:StatusTimer.Add_Tick({
        param($timer, $e)
        $timer.Stop()
        $restore = $timer.Tag
        if ($restore) {
          $restore.Bar.Text = $restore.Text
          $restore.Bar.Foreground = $restore.Brush
          $restore.Bar.FontWeight = $restore.Weight
        }
      })
  }
  $Script:StatusTimer.Stop()
  $Script:StatusTimer.Tag = [pscustomobject]@{
    Bar    = $txtblk_StatusBar
    Text   = $Script:StatusRestoreText
    Brush  = $Script:StatusRestoreBrush
    Weight = $Script:StatusRestoreWeight
  }
  $Script:StatusTimer.Start()
}

function Get-FileSignatureInfo {
  # Returns the Authenticode signature for a file, or $null when the path is not a readable file.
  param (
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
  try { return Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop }
  catch { return $null }
}

function Read-Asn1GeneralizedTime {
  # Scans DER bytes for the first GeneralizedTime (tag 0x18) and returns it as a UTC DateTime, or $null.
  param (
    [Parameter(Mandatory = $true)]
    [byte[]]$Data
  )

  for ($i = 0; $i -lt $Data.Length - 1; $i++) {
    if ($Data[$i] -ne 0x18) { continue }
    $len = $Data[$i + 1]
    $start = $i + 2
    if ($len -band 0x80) {
      $n = $len -band 0x7F
      if ($n -lt 1 -or $n -gt 2) { continue }
      $len = 0
      for ($k = 0; $k -lt $n; $k++) { $len = ($len -shl 8) -bor $Data[$i + 2 + $k] }
      $start = $i + 2 + $n
    }
    if ($len -lt 14 -or ($start + $len) -gt $Data.Length) { continue }

    # GeneralizedTime is YYYYMMDDHHMMSS[.fff]Z (UTC); drop any fraction and the trailing Z.
    $raw = [System.Text.Encoding]::ASCII.GetString($Data, $start, $len).TrimEnd('Z')
    $dot = $raw.IndexOf('.')
    if ($dot -ge 0) { $raw = $raw.Substring(0, $dot) }
    $parsed = [datetime]::MinValue
    if ([datetime]::TryParseExact($raw, 'yyyyMMddHHmmss', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$parsed)) {
      return $parsed
    }
    return $null
  }
  return $null
}

function Get-SignatureTimestampTime {
  # Returns the signature's timestamp time (DateTime) for a signed file, or $null when not timestamped.
  # Dependency-free: uses CryptQueryObject (crypt32) + SignedCms, works on Windows PowerShell 5.1+.
  param (
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }

  if (-not ('CodeSigningTool.CryptTools' -as [type])) {
    try {
      Add-Type -ErrorAction Stop -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace CodeSigningTool {
  public static class CryptTools {
    const int CERT_QUERY_OBJECT_FILE = 1;
    const int CERT_QUERY_CONTENT_FLAG_ALL = 16382;
    const int CERT_QUERY_FORMAT_FLAG_ALL = 14;
    const int CMSG_ENCODED_MESSAGE_PARAM = 29;
    [DllImport("crypt32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern bool CryptQueryObject(int dwObjectType, [MarshalAs(UnmanagedType.LPWStr)] string pvObject, int dwExpectedContentTypeFlags, int dwExpectedFormatTypeFlags, int dwFlags, out int pdwMsgAndCertEncodingType, out int pdwContentType, out int pdwFormatType, out IntPtr phCertStore, out IntPtr phMsg, out IntPtr ppvContext);
    [DllImport("crypt32.dll", SetLastError = true)]
    static extern bool CryptMsgGetParam(IntPtr hCryptMsg, int dwParamType, int dwIndex, byte[] pvData, ref int pcbData);
    [DllImport("crypt32.dll", SetLastError = true)]
    static extern bool CryptMsgClose(IntPtr hCryptMsg);
    [DllImport("crypt32.dll", SetLastError = true)]
    static extern bool CertCloseStore(IntPtr hCertStore, int dwFlags);
    public static byte[] GetEncodedMessage(string path) {
      int enc, content, format; IntPtr store, msg, ctx;
      if (!CryptQueryObject(CERT_QUERY_OBJECT_FILE, path, CERT_QUERY_CONTENT_FLAG_ALL, CERT_QUERY_FORMAT_FLAG_ALL, 0, out enc, out content, out format, out store, out msg, out ctx)) return null;
      try {
        int cb = 0;
        if (!CryptMsgGetParam(msg, CMSG_ENCODED_MESSAGE_PARAM, 0, null, ref cb) || cb == 0) return null;
        byte[] data = new byte[cb];
        if (!CryptMsgGetParam(msg, CMSG_ENCODED_MESSAGE_PARAM, 0, data, ref cb)) return null;
        return data;
      } finally {
        if (msg != IntPtr.Zero) CryptMsgClose(msg);
        if (store != IntPtr.Zero) CertCloseStore(store, 0);
      }
    }
  }
}
'@
    }
    catch {
      Write-Host "Failed to load CryptTools: $($_.Exception.Message)"
      return $null
    }
  }

  # Windows PowerShell 5.1 does not load System.Security.dll (SignedCms) by default; PowerShell 7 already has it.
  if (-not ('System.Security.Cryptography.Pkcs.SignedCms' -as [type])) {
    try { Add-Type -AssemblyName System.Security -ErrorAction Stop } catch { return $null }
  }

  try {
    $blob = [CodeSigningTool.CryptTools]::GetEncodedMessage((Resolve-Path -LiteralPath $Path).Path)
    if ($null -eq $blob -or $blob.Length -eq 0) { return $null }

    $cms = New-Object System.Security.Cryptography.Pkcs.SignedCms
    $cms.Decode($blob)
    if ($cms.SignerInfos.Count -eq 0) { return $null }
    $signer = $cms.SignerInfos[0]

    # Legacy Authenticode timestamp: a counter-signer that carries a signing-time attribute.
    foreach ($cs in $signer.CounterSignerInfos) {
      foreach ($attr in $cs.SignedAttributes) {
        if ($attr.Oid.Value -eq '1.2.840.113549.1.9.5') {
          $st = New-Object System.Security.Cryptography.Pkcs.Pkcs9SigningTime
          $st.CopyFrom($attr.Values[0])
          return $st.SigningTime
        }
      }
    }

    # RFC3161 timestamp token (unsigned attribute); read genTime from the nested TSTInfo.
    foreach ($attr in $signer.UnsignedAttributes) {
      if ($attr.Oid.Value -eq '1.3.6.1.4.1.311.3.3.1') {
        $tsCms = New-Object System.Security.Cryptography.Pkcs.SignedCms
        $tsCms.Decode($attr.Values[0].RawData)
        $genTime = Read-Asn1GeneralizedTime -Data $tsCms.ContentInfo.Content
        if ($genTime) { return $genTime }
      }
    }
  }
  catch {
    Write-Host "Timestamp extraction failed: $($_.Exception.Message)"
  }
  return $null
}

function Invoke-CodeSignature {
  # Signs a single file. Isolated here so the signing backend can later swap to SignerSignEx2.
  param (
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
    [Parameter(Mandatory = $false)]
    [string]$TimestampServer
  )

  $signParams = @{
    FilePath    = $Path
    Certificate = $Certificate
    ErrorAction = 'Stop'
  }
  if (-not [string]::IsNullOrWhiteSpace($TimestampServer)) {
    $signParams.TimestampServer = $TimestampServer
  }

  try {
    $signature = Set-AuthenticodeSignature @signParams
    $applied = ($null -ne $signature.SignerCertificate)

    Write-Host "Signing: [$Path]"
    $signature | Format-List * | Out-String | Write-Host

    return [PSCustomObject]@{
      Success = $applied
      Status  = $signature.Status
      Message = $signature.StatusMessage
    }
  }
  catch {
    Write-Host "Signing failed: [$Path]"
    Write-Host $_.Exception.Message

    return [PSCustomObject]@{
      Success = $false
      Status  = 'Error'
      Message = $_.Exception.Message
    }
  }
}

function Show-CertificatePicker {
  # Displays a modal window listing all code-signing certificates and returns the selected one (or $null).
  param (
    [Parameter(Mandatory = $false)]
    [System.Windows.Window]$Owner
  )

  $readerPicker = New-Object System.Xml.XmlNodeReader $Script:XAMLpicker
  [System.Windows.Window]$pickerWindow = [Windows.Markup.XamlReader]::Load($readerPicker)

  # Resolve the controls used by this window
  $dg_Certificates = $pickerWindow.FindName('dg_Certificates')
  $btn_Refresh = $pickerWindow.FindName('btn_Refresh')
  $btn_Select = $pickerWindow.FindName('btn_Select')
  $btn_Cancel = $pickerWindow.FindName('btn_Cancel')
  $titlebar = $pickerWindow.FindName('titlebar')
  $titlebar_Close = $pickerWindow.FindName('titlebar_Close')
  $txtblk_StatusBar = $pickerWindow.FindName('txtblk_StatusBar')

  # Populates the grid and reports the count in the status bar.
  $loadGrid = {
    try {
      $certificates = @(Get-CodeSigningCertificate)
      $dg_Certificates.ItemsSource = $certificates
      $count = $certificates.Count
      $txtblk_StatusBar.Text = "Found $count code-signing certificate$(if ($count -ne 1) { 's' })."
    }
    catch {
      $txtblk_StatusBar.Text = "Error loading certificates: $($_.Exception.Message)"
      Write-Host "Error loading certificates: $($_.Exception.Message)"
    }
  }

  # Confirms the current selection and closes the dialog.
  $confirmSelection = {
    if ($null -ne $dg_Certificates.SelectedItem) {
      $Script:PickerSelectedCertificate = $dg_Certificates.SelectedItem
      $pickerWindow.DialogResult = $true
    }
    else {
      $txtblk_StatusBar.Text = "Please select a certificate first."
    }
  }

  $Script:PickerSelectedCertificate = $null

  $pickerWindow.Add_Loaded({
      try {
        $WindowIconBitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
        $WindowIconBitmap.BeginInit()
        $WindowIconBitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($Script:WindowIconBase64)
        $WindowIconBitmap.EndInit()
        $WindowIconBitmap.Freeze()
        $pickerWindow.Icon = $WindowIconBitmap
      }
      catch {
        Write-Host "Error setting picker icon: $_"
      }
      & $loadGrid
    })

  $btn_Refresh.add_Click($loadGrid)
  $btn_Select.add_Click($confirmSelection)
  $dg_Certificates.add_MouseDoubleClick($confirmSelection)
  $btn_Cancel.add_Click({ $pickerWindow.DialogResult = $false })
  $titlebar_Close.add_Click({ $pickerWindow.DialogResult = $false })
  $titlebar.add_MouseLeftButtonDown({ try { $pickerWindow.DragMove() } catch { } })

  if ($Owner) {
    $pickerWindow.Owner = $Owner
    $pickerWindow.WindowStartupLocation = "CenterOwner"
  }
  else {
    $pickerWindow.WindowStartupLocation = "CenterScreen"
  }

  $result = $pickerWindow.ShowDialog()
  if ($result -eq $true) { return $Script:PickerSelectedCertificate }
  return $null
}

function Show-CertificateCreator {
  # Displays a modal window that generates a self-signed code-signing certificate and returns it (or $null).
  param (
    [Parameter(Mandatory = $false)]
    [System.Windows.Window]$Owner
  )

  $readerCreator = New-Object System.Xml.XmlNodeReader $Script:XAMLcreator
  [System.Windows.Window]$creatorWindow = [Windows.Markup.XamlReader]::Load($readerCreator)

  # Resolve the controls used by this window
  $txt_Subject = $creatorWindow.FindName('txt_Subject')
  $txtblk_SubjectDefault = $creatorWindow.FindName('txtblk_SubjectDefault')
  $txt_ValidYears = $creatorWindow.FindName('txt_ValidYears')
  $btn_YearsUp = $creatorWindow.FindName('btn_YearsUp')
  $btn_YearsDown = $creatorWindow.FindName('btn_YearsDown')
  $cmb_KeyLength = $creatorWindow.FindName('cmb_KeyLength')
  $cmb_Store = $creatorWindow.FindName('cmb_Store')
  $chk_NonExportable = $creatorWindow.FindName('chk_NonExportable')
  $chk_SkipTrustedRoot = $creatorWindow.FindName('chk_SkipTrustedRoot')
  $chk_SkipTrustedPublisher = $creatorWindow.FindName('chk_SkipTrustedPublisher')
  $btn_Generate = $creatorWindow.FindName('btn_Generate')
  $btn_CancelCreate = $creatorWindow.FindName('btn_CancelCreate')
  $titlebar = $creatorWindow.FindName('titlebar')
  $titlebar_Close = $creatorWindow.FindName('titlebar_Close')
  $txtblk_StatusBar = $creatorWindow.FindName('txtblk_StatusBar')

  $defaultSubject = 'CodeSigningTool'

  # Reports the selected store's write requirement in the status bar.
  $updateStoreHint = {
    $store = if ($cmb_Store.SelectedItem) { $cmb_Store.SelectedItem.Content } else { 'CurrentUser' }
    if ($store -eq 'LocalMachine' -and -not (Test-IsAdministrator)) {
      Set-StatusText -Target $txtblk_StatusBar -Message 'LocalMachine requires running as administrator.' -Type 'Danger'
    }
    else {
      Set-StatusText -Target $txtblk_StatusBar -Message '' -Type 'Muted'
    }
  }

  # Validates input, creates the certificate and closes the dialog on success.
  $generate = {
    $subject = $txt_Subject.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($subject)) {
      $txtblk_StatusBar.Text = 'Enter a subject name.'
      return
    }

    $years = 0
    if (-not [int]::TryParse($txt_ValidYears.Text.Trim(), [ref]$years) -or $years -lt 1 -or $years -gt 30) {
      $txtblk_StatusBar.Text = 'Valid for must be a whole number between 1 and 30 years.'
      return
    }

    $keyLength = [int]$cmb_KeyLength.SelectedItem.Content
    $store = $cmb_Store.SelectedItem.Content

    if ($store -eq 'LocalMachine' -and -not (Test-IsAdministrator)) {
      $txtblk_StatusBar.Text = 'Cannot write to LocalMachine: run this tool as administrator.'
      return
    }

    try {
      $txtblk_StatusBar.Text = 'Generating certificate...'
      $creatorWindow.Cursor = [System.Windows.Input.Cursors]::Wait
      $certificate = New-CodeSigningSelfSignedCertificate -Subject $subject -ValidYears $years -KeyLength $keyLength -StoreLocation $store -NonExportable:$chk_NonExportable.IsChecked -SkipTrustedRoot:$chk_SkipTrustedRoot.IsChecked -SkipTrustedPublisher:$chk_SkipTrustedPublisher.IsChecked
      $Script:CreatorCertificate = $certificate
      $creatorWindow.DialogResult = $true
    }
    catch {
      $creatorWindow.Cursor = [System.Windows.Input.Cursors]::Arrow
      $txtblk_StatusBar.Text = "Failed to create certificate: $($_.Exception.Message)"
      Write-Host "Failed to create certificate: $($_.Exception.Message)"
    }
  }

  $Script:CreatorCertificate = $null

  $creatorWindow.Add_Loaded({
      try {
        $WindowIconBitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
        $WindowIconBitmap.BeginInit()
        $WindowIconBitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($Script:WindowIconBase64)
        $WindowIconBitmap.EndInit()
        $WindowIconBitmap.Freeze()
        $creatorWindow.Icon = $WindowIconBitmap
      }
      catch {
        Write-Host "Error setting creator icon: $_"
      }
      $txt_Subject.Text = $defaultSubject
      $cmb_KeyLength.SelectedIndex = 0
      $cmb_Store.SelectedIndex = 0
      & $updateStoreHint
    })

  $txtblk_SubjectDefault.add_MouseLeftButtonUp({
      $txt_Subject.Text = $defaultSubject
      [System.Windows.Input.Keyboard]::ClearFocus()
    })
  # On first click, focus and drop the caret where the mouse is instead of the left edge.
  $txt_Subject.add_PreviewMouseLeftButtonDown({
      param($textBox, $e)
      if (-not $txt_Subject.IsKeyboardFocusWithin) {
        $e.Handled = $true
        $txt_Subject.Focus()
        $point = $e.GetPosition($txt_Subject)
        $index = $txt_Subject.GetCharacterIndexFromPoint($point, $true)
        if ($index -lt 0) {
          $index = $txt_Subject.Text.Length
        }
        else {
          # GetCharacterIndexFromPoint snaps to the nearest glyph start; if the click lands past
          # that glyph's midpoint, advance one so a click near the end lands after the character.
          $rect = $txt_Subject.GetRectFromCharacterIndex($index)
          if ($point.X -gt ($rect.X + ($rect.Width / 2))) { $index++ }
        }
        $txt_Subject.CaretIndex = $index
      }
    })
  # Restrict the validity field to digits only.
  $txt_ValidYears.add_PreviewTextInput({
      param($textBox, $e)
      if ($e.Text -notmatch '^[0-9]+$') { $e.Handled = $true }
    })
  # Select the whole value on focus so a click doesn't drop the caret at the left edge.
  $txt_ValidYears.add_GotKeyboardFocus({ $txt_ValidYears.SelectAll() })
  $txt_ValidYears.add_PreviewMouseLeftButtonDown({
      param($textBox, $e)
      if (-not $txt_ValidYears.IsKeyboardFocusWithin) {
        $e.Handled = $true
        $txt_ValidYears.Focus()
      }
    })
  # Steps the validity field within the 1-30 year range.
  $adjustYears = {
    param($delta)
    $current = 0
    [void][int]::TryParse($txt_ValidYears.Text.Trim(), [ref]$current)
    $current += $delta
    if ($current -lt 1) { $current = 1 }
    if ($current -gt 30) { $current = 30 }
    $txt_ValidYears.Text = "$current"
  }
  $btn_YearsUp.add_Click({ & $adjustYears 1 })
  $btn_YearsDown.add_Click({ & $adjustYears -1 })
  $cmb_Store.add_SelectionChanged($updateStoreHint)
  $btn_Generate.add_Click($generate)
  $btn_CancelCreate.add_Click({ $creatorWindow.DialogResult = $false })
  $titlebar_Close.add_Click({ $creatorWindow.DialogResult = $false })
  $titlebar.add_MouseLeftButtonDown({ try { $creatorWindow.DragMove() } catch { } })

  if ($Owner) {
    $creatorWindow.Owner = $Owner
    $creatorWindow.WindowStartupLocation = "CenterOwner"
  }
  else {
    $creatorWindow.WindowStartupLocation = "CenterScreen"
  }

  $result = $creatorWindow.ShowDialog()
  if ($result -eq $true) { return $Script:CreatorCertificate }
  return $null
}

function Show-CertificateInformation {
  # Displays a modal, read-only view of a certificate's details and trust status.
  param (
    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

    [Parameter(Mandatory = $false)]
    [System.Windows.Window]$Owner,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.Signature]$Signature,

    [Parameter(Mandatory = $false)]
    [string]$FileName,

    [Parameter(Mandatory = $false)]
    [string]$FilePath
  )

  $readerViewer = New-Object System.Xml.XmlNodeReader $Script:XAMLviewer
  [System.Windows.Window]$viewerWindow = [Windows.Markup.XamlReader]::Load($readerViewer)

  # Resolve the controls used by this window
  $txt_Issuer = $viewerWindow.FindName('txt_Issuer')
  $txt_Subject = $viewerWindow.FindName('txt_Subject')
  $txt_Effective = $viewerWindow.FindName('txt_Effective')
  $txt_Expiration = $viewerWindow.FindName('txt_Expiration')
  $txt_Usage = $viewerWindow.FindName('txt_Usage')
  $txt_PublicKey = $viewerWindow.FindName('txt_PublicKey')
  $txt_Thumbprint = $viewerWindow.FindName('txt_Thumbprint')
  $icn_TrustedPublisher = $viewerWindow.FindName('icn_TrustedPublisher')
  $icn_TrustedRoot = $viewerWindow.FindName('icn_TrustedRoot')
  $icn_SelfSigned = $viewerWindow.FindName('icn_SelfSigned')
  $btn_Validate = $viewerWindow.FindName('btn_Validate')
  $btn_Close = $viewerWindow.FindName('btn_Close')
  $titlebar = $viewerWindow.FindName('titlebar')
  $titlebar_Close = $viewerWindow.FindName('titlebar_Close')
  $txtblk_StatusBar = $viewerWindow.FindName('txtblk_StatusBar')
  $txt_ViewerTitle = $viewerWindow.FindName('txt_ViewerTitle')
  $pnl_Signature = $viewerWindow.FindName('pnl_Signature')
  $txt_SigStatus = $viewerWindow.FindName('txt_SigStatus')
  $txt_SigTimestamp = $viewerWindow.FindName('txt_SigTimestamp')
  $txt_SigTimestampDate = $viewerWindow.FindName('txt_SigTimestampDate')
  $txt_SigAuthority = $viewerWindow.FindName('txt_SigAuthority')

  # Sets a status glyph to a green check or a red cross.
  $setStatusIcon = {
    param($Icon, [bool]$Value)
    if ($Value) {
      $Icon.Text = [char]0xEC61
      $Icon.Foreground = $viewerWindow.FindResource('Success')
    }
    else {
      $Icon.Text = [char]0xEB90
      $Icon.Foreground = $viewerWindow.FindResource('Danger')
    }
  }

  $txt_Issuer.Text = $Certificate.Issuer
  $txt_Subject.Text = $Certificate.Subject
  $txt_Effective.Text = $Certificate.NotBefore.ToString('g')
  $txt_Expiration.Text = $Certificate.NotAfter.ToString('g')
  $txt_Usage.Text = Get-CertificateUsageText -Certificate $Certificate
  $txt_PublicKey.Text = Get-CertificatePublicKeyText -Certificate $Certificate
  $txt_Thumbprint.Text = $Certificate.Thumbprint

  & $setStatusIcon $icn_TrustedPublisher ([bool](Test-CertificateInStore -Certificate $Certificate -StoreName 'TrustedPublisher'))
  & $setStatusIcon $icn_TrustedRoot ([bool](Test-CertificateInStore -Certificate $Certificate -StoreName 'Root'))
  & $setStatusIcon $icn_SelfSigned ([bool]($Certificate.Subject -eq $Certificate.Issuer))

  # When a file signature is supplied, reveal and populate the Signature section.
  if ($null -ne $Signature) {
    $pnl_Signature.Visibility = [System.Windows.Visibility]::Visible
    if ($txt_ViewerTitle) { $txt_ViewerTitle.Text = 'Signature Information' }
    $viewerWindow.Title = 'Signature Information'

    $statusName = "$($Signature.Status)"
    $txt_SigStatus.Text = switch ($statusName) {
      'Valid' { 'Valid' }
      'UnknownError' { 'Signed (untrusted or unverified)' }
      'NotTrusted' { 'Signed (untrusted publisher)' }
      'HashMismatch' { 'Invalid (hash mismatch)' }
      'NotSigned' { 'Not signed' }
      default { $statusName }
    }
    $brushKey = if ($statusName -eq 'Valid') { 'Success' } elseif ($statusName -in 'UnknownError', 'NotTrusted') { 'Accent' } else { 'Danger' }
    $txt_SigStatus.Foreground = $viewerWindow.FindResource($brushKey)

    if ($null -ne $Signature.TimeStamperCertificate) {
      $txt_SigTimestamp.Text = 'Yes'
      $txt_SigAuthority.Text = Get-CertCommonName -DistinguishedName $Signature.TimeStamperCertificate.Subject

      $tsTime = $null
      if (-not [string]::IsNullOrWhiteSpace($FilePath)) { $tsTime = Get-SignatureTimestampTime -Path $FilePath }
      if ($tsTime) {
        $txt_SigTimestampDate.Text = $tsTime.ToUniversalTime().ToString('g') + ' UTC'
      }
      else {
        $txt_SigTimestampDate.Text = 'Unavailable'
      }
    }
    else {
      $txt_SigTimestamp.Text = 'No'
      $txt_SigTimestampDate.Text = 'Not timestamped'
      $txt_SigAuthority.Text = 'Not timestamped'
    }

    if (-not [string]::IsNullOrWhiteSpace($FileName)) {
      Set-StatusText -Target $txtblk_StatusBar -Message "Signature for $FileName" -Type 'Muted'
    }
  }

  # Builds the certificate chain and reports whether it is trusted.
  $validate = {
    $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
    try {
      $built = $chain.Build($Certificate)
      if ($built) {
        Set-StatusText -Target $txtblk_StatusBar -Message 'Trust chain is valid.' -Type 'Success'
      }
      else {
        $reasons = ($chain.ChainStatus | ForEach-Object { $_.StatusInformation.Trim() } | Where-Object { $_ }) -join '; '
        if (-not $reasons) { $reasons = 'Chain could not be validated.' }
        Set-StatusText -Target $txtblk_StatusBar -Message "Trust chain is not valid: $reasons" -Type 'Danger'
      }
    }
    catch {
      Set-StatusText -Target $txtblk_StatusBar -Message "Validation failed: $($_.Exception.Message)" -Type 'Danger'
    }
    finally {
      $chain.Reset()
    }
  }

  $viewerWindow.Add_Loaded({
      try {
        $WindowIconBitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
        $WindowIconBitmap.BeginInit()
        $WindowIconBitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($Script:WindowIconBase64)
        $WindowIconBitmap.EndInit()
        $WindowIconBitmap.Freeze()
        $viewerWindow.Icon = $WindowIconBitmap
      }
      catch {
        Write-Host "Error setting viewer icon: $_"
      }
    })

  $btn_Validate.add_Click($validate)
  $btn_Close.add_Click({ $viewerWindow.DialogResult = $true })
  $titlebar_Close.add_Click({ $viewerWindow.DialogResult = $true })
  $titlebar.add_MouseLeftButtonDown({ try { $viewerWindow.DragMove() } catch { } })

  if ($Owner) {
    $viewerWindow.Owner = $Owner
    $viewerWindow.WindowStartupLocation = "CenterOwner"
  }
  else {
    $viewerWindow.WindowStartupLocation = "CenterScreen"
  }

  return $viewerWindow.ShowDialog()
}

function Show-StatusWindow {
  # Themed, reusable modal message window that replaces the built-in MessageBox.
  param (
    [Parameter(Mandatory = $true)]
    [string]$Message,

    [Parameter(Mandatory = $false)]
    [string]$Title = 'Status',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Info', 'Success', 'Warning', 'Error')]
    [string]$Type = 'Info',

    [Parameter(Mandatory = $false)]
    [System.Windows.Window]$Owner
  )

  $readerStatus = New-Object System.Xml.XmlNodeReader $Script:XAMLstatus
  [System.Windows.Window]$statusWindow = [Windows.Markup.XamlReader]::Load($readerStatus)

  # Resolve the controls used by this window
  $txt_StatusTitle = $statusWindow.FindName('txt_StatusTitle')
  $txt_StatusMessage = $statusWindow.FindName('txt_StatusMessage')
  $icn_Status = $statusWindow.FindName('icn_Status')
  $btn_Close = $statusWindow.FindName('btn_Close')
  $titlebar = $statusWindow.FindName('titlebar')
  $titlebar_Close = $statusWindow.FindName('titlebar_Close')

  $statusWindow.Title = $Title
  $txt_StatusTitle.Text = $Title
  $txt_StatusMessage.Text = $Message

  # Map severity to a glyph and accent colour.
  $glyph, $brushKey = switch ($Type) {
    'Success' { [char]0xEC61, 'Success' }
    'Warning' { [char]0xE7BA, 'Accent' }
    'Error' { [char]0xEB90, 'Danger' }
    default { [char]0xE946, 'Accent' }
  }
  $icn_Status.Text = $glyph
  $icn_Status.Foreground = $statusWindow.FindResource($brushKey)

  $statusWindow.Add_Loaded({
      try {
        $WindowIconBitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
        $WindowIconBitmap.BeginInit()
        $WindowIconBitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($Script:WindowIconBase64)
        $WindowIconBitmap.EndInit()
        $WindowIconBitmap.Freeze()
        $statusWindow.Icon = $WindowIconBitmap
      }
      catch {
        Write-Host "Error setting status icon: $_"
      }
    })

  $btn_Close.add_Click({ $statusWindow.DialogResult = $true })
  $titlebar_Close.add_Click({ $statusWindow.DialogResult = $true })
  $titlebar.add_MouseLeftButtonDown({ try { $statusWindow.DragMove() } catch { } })

  if ($Owner) {
    $statusWindow.Owner = $Owner
    $statusWindow.WindowStartupLocation = "CenterOwner"
  }
  else {
    $statusWindow.WindowStartupLocation = "CenterScreen"
  }

  return $statusWindow.ShowDialog()
}

function Show-ConfirmWindow {
  # Themed, reusable confirmation window with configurable buttons.
  # Returns the label of the clicked button, or $null if dismissed via the title-bar close.
  param (
    [Parameter(Mandatory = $true)]
    [string]$Message,

    [Parameter(Mandatory = $false)]
    [string]$Title = 'Confirm',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Question')]
    [string]$Type = 'Question',

    # Button labels, listed left to right. The first (primary) button is styled with the accent fill.
    [Parameter(Mandatory = $false)]
    [string[]]$Buttons = @('OK', 'Cancel'),

    [Parameter(Mandatory = $false)]
    [System.Windows.Window]$Owner
  )

  $readerConfirm = New-Object System.Xml.XmlNodeReader $Script:XAMLconfirm
  [System.Windows.Window]$confirmWindow = [Windows.Markup.XamlReader]::Load($readerConfirm)

  # Resolve the controls used by this window
  $txt_ConfirmTitle = $confirmWindow.FindName('txt_ConfirmTitle')
  $txt_ConfirmMessage = $confirmWindow.FindName('txt_ConfirmMessage')
  $icn_Confirm = $confirmWindow.FindName('icn_Confirm')
  $pnl_Buttons = $confirmWindow.FindName('pnl_Buttons')
  $titlebar = $confirmWindow.FindName('titlebar')
  $titlebar_Close = $confirmWindow.FindName('titlebar_Close')

  $confirmWindow.Title = $Title
  $txt_ConfirmTitle.Text = $Title
  $txt_ConfirmMessage.Text = $Message

  # Map severity to a glyph and accent colour.
  $glyph, $brushKey = switch ($Type) {
    'Success' { [char]0xEC61, 'Success'; break }
    'Warning' { [char]0xE7BA, 'Accent'; break }
    'Error' { [char]0xEB90, 'Danger'; break }
    'Question' { [char]0xE9CE, 'Accent'; break }
    default { [char]0xE946, 'Accent' }
  }
  $icn_Confirm.Text = $glyph
  $icn_Confirm.Foreground = $confirmWindow.FindResource($brushKey)

  # Tracks the button the user clicked; stays $null when the window is closed via the title bar.
  $Script:ConfirmResult = $null

  $primaryStyle = $confirmWindow.FindResource('PrimaryButton')
  for ($i = 0; $i -lt $Buttons.Count; $i++) {
    $label = $Buttons[$i]
    $button = New-Object System.Windows.Controls.Button
    $button.Content = $label
    $button.MinWidth = 96
    if ($i -eq 0) { $button.Style = $primaryStyle }
    $button.Tag = $label
    $button.add_Click({
        $Script:ConfirmResult = $this.Tag
        $confirmWindow.DialogResult = $true
      })
    [void]$pnl_Buttons.Children.Add($button)
  }

  $confirmWindow.Add_Loaded({
      try {
        $WindowIconBitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
        $WindowIconBitmap.BeginInit()
        $WindowIconBitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($Script:WindowIconBase64)
        $WindowIconBitmap.EndInit()
        $WindowIconBitmap.Freeze()
        $confirmWindow.Icon = $WindowIconBitmap
      }
      catch {
        Write-Host "Error setting confirm icon: $_"
      }
    })

  $titlebar_Close.add_Click({ $confirmWindow.DialogResult = $false })
  $titlebar.add_MouseLeftButtonDown({ try { $confirmWindow.DragMove() } catch { } })

  if ($Owner) {
    $confirmWindow.Owner = $Owner
    $confirmWindow.WindowStartupLocation = "CenterOwner"
  }
  else {
    $confirmWindow.WindowStartupLocation = "CenterScreen"
  }

  [void]$confirmWindow.ShowDialog()
  return $Script:ConfirmResult
}
#endregion Functions

#############################################
################### XAML ####################
#############################################
[xml]$XAMLformCodeSigning = @"
<Window
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Name="form1"
  Width="920"
  Height="620"
  ResizeMode="NoResize"
  WindowStyle="None"
  AllowsTransparency="True"
  Background="Transparent"
  Title="Code Signing Tool"
  FontFamily="Segoe UI"
  FontSize="14">

  <Window.Resources>
    <!-- Color tokens (michaeltheadmin.com palette) -->
    <SolidColorBrush x:Key="Bg"
        Color="#292524"/>
    <SolidColorBrush x:Key="Surface"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Surface2"
        Color="#44403C"/>
    <SolidColorBrush x:Key="Border"
        Color="#3A3633"/>
    <SolidColorBrush x:Key="BorderMuted"
        Color="#57534E"/>
    <SolidColorBrush x:Key="Text"
        Color="#F5F5F4"/>
    <SolidColorBrush x:Key="TextMuted"
        Color="#A8A29E"/>
    <SolidColorBrush x:Key="Accent"
        Color="#FB923C"/>
    <SolidColorBrush x:Key="AccentHover"
        Color="#F97316"/>
    <SolidColorBrush x:Key="AccentText"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Danger"
        Color="#EF4444"/>
    <SolidColorBrush x:Key="Success"
        Color="#22C55E"/>

    <!-- Menu item templates -->
    <ControlTemplate x:Key="MenuTopLevelHeader"
        TargetType="MenuItem">
      <Grid>
        <Border x:Name="Bd"
            Background="{TemplateBinding Background}"
            BorderBrush="{StaticResource Accent}"
            BorderThickness="1"
            CornerRadius="6"
            Margin="2,0"
            Padding="10,4">
          <ContentPresenter ContentSource="Header"
              VerticalAlignment="Center"/>
        </Border>
        <Popup x:Name="PART_Popup"
            Placement="Bottom"
            IsOpen="{TemplateBinding IsSubmenuOpen}"
            AllowsTransparency="True"
            Focusable="False"
            PopupAnimation="Fade">
          <Border Background="{StaticResource Surface}"
              BorderBrush="{StaticResource Border}"
              BorderThickness="1"
              CornerRadius="8"
              Padding="4"
              Margin="0,4,10,10">
            <Border.Effect>
              <DropShadowEffect BlurRadius="14"
                  ShadowDepth="2"
                  Opacity="0.5"
                  Color="#000000"/>
            </Border.Effect>
            <StackPanel IsItemsHost="True"
                KeyboardNavigation.DirectionalNavigation="Cycle"/>
          </Border>
        </Popup>
      </Grid>
      <ControlTemplate.Triggers>
        <Trigger Property="IsHighlighted"
            Value="True">
          <Setter TargetName="Bd"
              Property="Background"
              Value="{StaticResource Accent}"/>
          <Setter Property="Foreground"
              Value="{StaticResource AccentText}"/>
        </Trigger>
        <Trigger Property="IsSubmenuOpen"
            Value="True">
          <Setter TargetName="Bd"
              Property="Background"
              Value="{StaticResource Accent}"/>
          <Setter Property="Foreground"
              Value="{StaticResource AccentText}"/>
        </Trigger>
      </ControlTemplate.Triggers>
    </ControlTemplate>

    <ControlTemplate x:Key="MenuTopLevelItem"
        TargetType="MenuItem">
      <Border x:Name="Bd"
          Background="{TemplateBinding Background}"
          BorderBrush="{StaticResource Accent}"
          BorderThickness="1"
          CornerRadius="6"
          Margin="2,0"
          Padding="10,4">
        <ContentPresenter ContentSource="Header"
            VerticalAlignment="Center"/>
      </Border>
      <ControlTemplate.Triggers>
        <Trigger Property="IsHighlighted"
            Value="True">
          <Setter TargetName="Bd"
              Property="Background"
              Value="{StaticResource AccentHover}"/>
          <Setter Property="Foreground"
              Value="{StaticResource AccentText}"/>
        </Trigger>
      </ControlTemplate.Triggers>
    </ControlTemplate>

    <ControlTemplate x:Key="MenuSubmenuItem"
        TargetType="MenuItem">
      <Border x:Name="Bd"
          Background="{TemplateBinding Background}"
          CornerRadius="6"
          Padding="12,6"
          Margin="1">
        <ContentPresenter ContentSource="Header"
            VerticalAlignment="Center"/>
      </Border>
      <ControlTemplate.Triggers>
        <Trigger Property="IsHighlighted"
            Value="True">
          <Setter TargetName="Bd"
              Property="Background"
              Value="{StaticResource Accent}"/>
          <Setter Property="Foreground"
              Value="{StaticResource AccentText}"/>
        </Trigger>
        <Trigger Property="IsEnabled"
            Value="False">
          <Setter Property="Foreground"
              Value="{StaticResource TextMuted}"/>
        </Trigger>
      </ControlTemplate.Triggers>
    </ControlTemplate>

    <ControlTemplate x:Key="MenuSubmenuHeader"
        TargetType="MenuItem">
      <Grid>
        <Border x:Name="Bd"
            Background="{TemplateBinding Background}"
            CornerRadius="6"
            Padding="12,6"
            Margin="1">
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <ContentPresenter Grid.Column="0"
                ContentSource="Header"
                VerticalAlignment="Center"/>
            <TextBlock Grid.Column="1"
                Text="&#xE76C;"
                FontFamily="Segoe MDL2 Assets"
                FontSize="10"
                VerticalAlignment="Center"
                Margin="16,0,0,0"/>
          </Grid>
        </Border>
        <Popup Placement="Right"
            IsOpen="{TemplateBinding IsSubmenuOpen}"
            AllowsTransparency="True"
            Focusable="False"
            PopupAnimation="Fade">
          <Border Background="{StaticResource Surface}"
              BorderBrush="{StaticResource Border}"
              BorderThickness="1"
              CornerRadius="8"
              Padding="4"
              Margin="0,0,10,10">
            <Border.Effect>
              <DropShadowEffect BlurRadius="14"
                  ShadowDepth="2"
                  Opacity="0.5"
                  Color="#000000"/>
            </Border.Effect>
            <StackPanel IsItemsHost="True"
                KeyboardNavigation.DirectionalNavigation="Cycle"/>
          </Border>
        </Popup>
      </Grid>
      <ControlTemplate.Triggers>
        <Trigger Property="IsHighlighted"
            Value="True">
          <Setter TargetName="Bd"
              Property="Background"
              Value="{StaticResource Accent}"/>
          <Setter Property="Foreground"
              Value="{StaticResource AccentText}"/>
        </Trigger>
      </ControlTemplate.Triggers>
    </ControlTemplate>

    <!-- Menu -->
    <Style TargetType="Menu">
      <Setter Property="Background"
          Value="Transparent"/>
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Padding"
          Value="6,2"/>
      <Setter Property="BorderThickness"
          Value="0"/>
    </Style>
    <Style TargetType="MenuItem">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Background"
          Value="Transparent"/>
      <Style.Triggers>
        <Trigger Property="Role"
            Value="TopLevelHeader">
          <Setter Property="Template"
              Value="{StaticResource MenuTopLevelHeader}"/>
        </Trigger>
        <Trigger Property="Role"
            Value="TopLevelItem">
          <Setter Property="Template"
              Value="{StaticResource MenuTopLevelItem}"/>
        </Trigger>
        <Trigger Property="Role"
            Value="SubmenuHeader">
          <Setter Property="Template"
              Value="{StaticResource MenuSubmenuHeader}"/>
        </Trigger>
        <Trigger Property="Role"
            Value="SubmenuItem">
          <Setter Property="Template"
              Value="{StaticResource MenuSubmenuItem}"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <Style x:Key="{x:Static MenuItem.SeparatorStyleKey}"
        TargetType="Separator">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Separator">
            <Border Height="1"
                Background="{StaticResource Border}"
                Margin="0,4"/>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Buttons -->
    <Style x:Key="ThemedButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Background"
          Value="{StaticResource Surface2}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource BorderMuted}"/>
      <Setter Property="BorderThickness"
          Value="1"/>
      <Setter Property="Margin"
          Value="2.5"/>
      <Setter Property="Padding"
          Value="10,4"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="HorizontalContentAlignment"
          Value="Center"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="6">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"
                  Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Accent}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
              <Trigger Property="IsPressed"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource AccentHover}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource AccentHover}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
              <Trigger Property="IsEnabled"
                  Value="False">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Surface}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Border}"/>
                <Setter TargetName="Bd"
                    Property="Opacity"
                    Value="0.6"/>
                <Setter Property="Foreground"
                    Value="{StaticResource TextMuted}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="Button"
        BasedOn="{StaticResource ThemedButton}"/>

    <!-- Labels -->
    <Style TargetType="Label">
      <Setter Property="Foreground"
          Value="{StaticResource TextMuted}"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="Padding"
          Value="0"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
    </Style>

    <!-- Read-only info textbox -->
    <Style TargetType="TextBox">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Background"
          Value="{StaticResource Surface}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness"
          Value="1"/>
      <Setter Property="Padding"
          Value="8,0"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="CaretBrush"
          Value="{StaticResource Accent}"/>
      <Setter Property="SelectionBrush"
          Value="{StaticResource Accent}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TextBox">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="6">
              <ScrollViewer x:Name="PART_ContentHost"
                  Margin="{TemplateBinding Padding}"
                  VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Check box -->
    <Style TargetType="CheckBox">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <StackPanel Orientation="Horizontal"
                Background="Transparent">
              <Border x:Name="Box"
                  Width="18"
                  Height="18"
                  CornerRadius="4"
                  Background="{StaticResource Surface}"
                  BorderBrush="{StaticResource BorderMuted}"
                  BorderThickness="1"
                  VerticalAlignment="Center">
                <TextBlock x:Name="Check"
                    Text="&#xE73E;"
                    FontFamily="Segoe MDL2 Assets"
                    FontSize="12"
                    Foreground="{StaticResource AccentText}"
                    HorizontalAlignment="Center"
                    VerticalAlignment="Center"
                    Visibility="Collapsed"/>
              </Border>
              <ContentPresenter Margin="8,0,0,0"
                  VerticalAlignment="Center"/>
            </StackPanel>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked"
                  Value="True">
                <Setter TargetName="Box"
                    Property="Background"
                    Value="{StaticResource Accent}"/>
                <Setter TargetName="Box"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
                <Setter TargetName="Check"
                    Property="Visibility"
                    Value="Visible"/>
              </Trigger>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Box"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
              </Trigger>
              <Trigger Property="IsEnabled"
                  Value="False">
                <Setter Property="Foreground"
                    Value="{StaticResource TextMuted}"/>
                <Setter TargetName="Box"
                    Property="Opacity"
                    Value="0.6"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Title bar buttons -->
    <Style x:Key="TitleBarButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource TextMuted}"/>
      <Setter Property="Background"
          Value="Transparent"/>
      <Setter Property="BorderThickness"
          Value="0"/>
      <Setter Property="Width"
          Value="46"/>
      <Setter Property="FontFamily"
          Value="Segoe MDL2 Assets"/>
      <Setter Property="FontSize"
          Value="10"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Surface2}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource Text}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="TitleBarCloseButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource TextMuted}"/>
      <Setter Property="Background"
          Value="Transparent"/>
      <Setter Property="BorderThickness"
          Value="0"/>
      <Setter Property="Width"
          Value="46"/>
      <Setter Property="FontFamily"
          Value="Segoe MDL2 Assets"/>
      <Setter Property="FontSize"
          Value="10"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                CornerRadius="0,11,0,0">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Danger}"/>
                <Setter Property="Foreground"
                    Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Section header -->
    <Style x:Key="SectionHeader"
        TargetType="TextBlock">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="FontSize"
          Value="15"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="VerticalAlignment"
          Value="Center"/>
    </Style>

    <!-- Certificate data grid -->
    <Style TargetType="DataGrid">
      <Setter Property="Background"
          Value="{StaticResource Surface}"/>
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness"
          Value="1"/>
      <Setter Property="RowBackground"
          Value="{StaticResource Surface}"/>
      <Setter Property="AlternatingRowBackground"
          Value="{StaticResource Bg}"/>
      <Setter Property="GridLinesVisibility"
          Value="Horizontal"/>
      <Setter Property="HorizontalGridLinesBrush"
          Value="{StaticResource Border}"/>
      <Setter Property="HeadersVisibility"
          Value="Column"/>
      <Setter Property="AutoGenerateColumns"
          Value="False"/>
      <Setter Property="CanUserAddRows"
          Value="False"/>
      <Setter Property="CanUserDeleteRows"
          Value="False"/>
      <Setter Property="CanUserResizeRows"
          Value="False"/>
      <Setter Property="IsReadOnly"
          Value="True"/>
      <Setter Property="SelectionMode"
          Value="Single"/>
      <Setter Property="SelectionUnit"
          Value="FullRow"/>
      <Setter Property="RowHeaderWidth"
          Value="0"/>
      <Setter Property="EnableRowVirtualization"
          Value="True"/>
      <Setter Property="VerticalScrollBarVisibility"
          Value="Auto"/>
      <Setter Property="HorizontalScrollBarVisibility"
          Value="Auto"/>
    </Style>

    <Style TargetType="DataGridColumnHeader">
      <Setter Property="Background"
          Value="{StaticResource Surface2}"/>
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="Padding"
          Value="10,6"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness"
          Value="0,0,1,1"/>
      <Setter Property="HorizontalContentAlignment"
          Value="Left"/>
    </Style>

    <Style TargetType="DataGridRow">
      <Setter Property="Background"
          Value="{StaticResource Surface}"/>
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver"
            Value="True">
          <Setter Property="Background"
              Value="{StaticResource Surface2}"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <Style TargetType="DataGridCell">
      <Setter Property="Padding"
          Value="10,4"/>
      <Setter Property="BorderThickness"
          Value="0"/>
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="DataGridCell">
            <Border Background="{TemplateBinding Background}"
                Padding="{TemplateBinding Padding}">
              <ContentPresenter VerticalAlignment="Center"/>
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
      <Style.Triggers>
        <Trigger Property="IsSelected"
            Value="True">
          <Setter Property="Background"
              Value="{StaticResource Accent}"/>
          <Setter Property="Foreground"
              Value="{StaticResource AccentText}"/>
        </Trigger>
      </Style.Triggers>
    </Style>
  </Window.Resources>

  <Border Background="{StaticResource Bg}"
      CornerRadius="12"
      BorderBrush="{StaticResource BorderMuted}"
      BorderThickness="1"
      Margin="0">
    <DockPanel>
      <Border Name="titlebar"
          DockPanel.Dock="Top"
          Background="{StaticResource Surface}"
          CornerRadius="11,11,0,0"
          Height="42">
        <DockPanel LastChildFill="False">
          <Button Name="titlebar_Close"
              DockPanel.Dock="Right"
              Style="{StaticResource TitleBarCloseButton}"
              Content="&#xE8BB;"/>
          <Button Name="titlebar_Minimize"
              DockPanel.Dock="Right"
              Style="{StaticResource TitleBarButton}"
              Content="&#xE921;"/>
          <Image DockPanel.Dock="Left"
              Margin="14,0,0,0"
              Width="20"
              Height="20"
              VerticalAlignment="Center"
              RenderOptions.BitmapScalingMode="HighQuality"
              Source="{Binding Icon, RelativeSource={RelativeSource AncestorType=Window}}"/>
          <StackPanel DockPanel.Dock="Left"
              Orientation="Horizontal"
              VerticalAlignment="Center"
              Margin="10,0,8,0">
            <TextBlock FontSize="15"
                FontWeight="SemiBold"
                Foreground="{StaticResource Text}"
                Text="Code Signing Tool"
                VerticalAlignment="Center"/>
            <TextBlock Name="txtblk_TitleVersion"
                FontWeight="Normal"
                Foreground="{StaticResource TextMuted}"
                VerticalAlignment="Center"
                Margin="6,0,0,1"/>
          </StackPanel>
          <Menu DockPanel.Dock="Left"
              VerticalAlignment="Center">
            <MenuItem Header="Right Click Menu">
              <MenuItem Name="MenuItem_Install"
                  Header="Install"/>
              <MenuItem Name="MenuItem_Uninstall"
                  Header="Uninstall"/>
              <MenuItem Name="MenuItem_Open_RCM"
                  Header="Open Right Click Menu Folder"/>
            </MenuItem>
            <MenuItem Header="About">
              <MenuItem Name="MenuItem_GitHub"
                  Header="GitHub - CodeSigningTool"/>
              <MenuItem Name="MenuItem_About"
                  Header="michaeltheadmin.com"/>
              <MenuItem Name="MenuItem_CheckForUpdates"
                  Header="Check for Updates"/>
              <Separator/>
              <MenuItem Name="MenuItem_Version"
                  Header="Version 1.0.0"
                  IsEnabled="False"
                  FontWeight="Normal"/>
            </MenuItem>
            <MenuItem Name="MenuItem_UpdateAvailable"
                Header="Update Available"
                Visibility="Collapsed"
                Background="{StaticResource Accent}"
                Foreground="{StaticResource AccentText}"
                FontWeight="Bold"/>
          </Menu>
        </DockPanel>
      </Border>
      <Border DockPanel.Dock="Bottom"
          Background="{StaticResource Surface}"
          Height="24"
          CornerRadius="0,0,11,11">
        <TextBlock Name="txtblk_StatusBar"
            VerticalAlignment="Center"
            Foreground="{StaticResource TextMuted}"
            FontSize="12"
            Margin="12,0"
            Text="Created By Michael Escamilla | michaeltheadmin.com"/>
      </Border>

      <Grid Margin="12"
          Grid.IsSharedSizeScope="True">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Certificate -->
        <TextBlock Grid.Row="0"
            Style="{StaticResource SectionHeader}"
            Text="Certificate"
            Margin="0,0,0,8"/>

        <Border Grid.Row="1"
            Background="{StaticResource Surface}"
            BorderBrush="{StaticResource Border}"
            BorderThickness="1"
            CornerRadius="8"
            Padding="16">
          <Grid>
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"
                  SharedSizeGroup="CertButton"/>
              <ColumnDefinition Width="Auto"
                  SharedSizeGroup="CertButton"/>
            </Grid.ColumnDefinitions>

            <TextBox Grid.Row="0"
                Grid.Column="0"
                Name="txt_Thumbprint"
                IsReadOnly="True"
                VerticalAlignment="Stretch"/>
            <Button Grid.Row="0"
                Grid.Column="1"
                Name="btn_Browse"
                Content="Browse..."
                Margin="8,2.5,0,2.5"/>
            <Button Grid.Row="0"
                Grid.Column="2"
                Name="btn_View"
                Content="View..."
                IsEnabled="False"
                Margin="8,2.5,0,2.5"/>

            <TextBlock Grid.Row="1"
                Grid.Column="0"
                Name="txtblk_CertInfo"
                Foreground="{StaticResource TextMuted}"
                Margin="2,10,0,0"
                TextTrimming="CharacterEllipsis"
                VerticalAlignment="Center"
                Text="No certificate selected."/>
            <Button Grid.Row="1"
                Grid.Column="2"
                Name="btn_Create"
                Content="Create..."
                Margin="8,8,0,2.5"/>
          </Grid>
        </Border>

        <!-- Timestamp -->
        <TextBlock Grid.Row="2"
            Style="{StaticResource SectionHeader}"
            Text="Timestamp"
            Margin="0,16,0,8"/>

        <Border Grid.Row="3"
            Background="{StaticResource Surface}"
            BorderBrush="{StaticResource Border}"
            BorderThickness="1"
            CornerRadius="8"
            Padding="16">
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBox Grid.Column="0"
                Name="txt_TimestampServer"
                Text="http://timestamp.digicert.com"
                Height="{Binding ElementName=txt_Thumbprint, Path=ActualHeight}"
                VerticalAlignment="Center"/>
            <CheckBox Grid.Column="1"
                Name="chk_Timestamp"
                Content="Enabled"
                IsChecked="True"
                Margin="10,0,0,0"
                VerticalAlignment="Center"/>
          </Grid>
        </Border>

        <!-- Files header -->
        <Grid Grid.Row="4"
            Margin="0,16,0,6">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <TextBlock Grid.Column="0"
              Style="{StaticResource SectionHeader}"
              VerticalAlignment="Center"
              Text="FILES TO SIGN"/>
          <StackPanel Grid.Column="1"
              Orientation="Horizontal">
            <Button Name="btn_AddFiles"
                Content="Add Files..."/>
            <Button Name="btn_RemoveFiles"
                Content="Remove"/>
            <Button Name="btn_ClearFiles"
                Content="Clear"/>
          </StackPanel>
        </Grid>

        <DataGrid Grid.Row="5"
            Name="dg_Files"
            AllowDrop="True">
          <DataGrid.Columns>
            <DataGridTextColumn Header="File"
                Binding="{Binding FileName}"
                Width="Auto"/>
            <DataGridTextColumn Header="Signed"
                Binding="{Binding Signed}"
                Width="70">
              <DataGridTextColumn.ElementStyle>
                <Style TargetType="TextBlock">
                  <Setter Property="VerticalAlignment"
                      Value="Center"/>
                  <Setter Property="Cursor"
                      Value="Hand"/>
                  <Setter Property="TextDecorations"
                      Value="Underline"/>
                  <Setter Property="Foreground"
                      Value="{StaticResource TextMuted}"/>
                  <Setter Property="ToolTip"
                      Value="Click to view signature details"/>
                  <Style.Triggers>
                    <DataTrigger Binding="{Binding Signed}"
                        Value="Yes">
                      <Setter Property="Foreground"
                          Value="{StaticResource Success}"/>
                    </DataTrigger>
                    <DataTrigger Binding="{Binding Signed}"
                        Value="Invalid">
                      <Setter Property="Foreground"
                          Value="{StaticResource Danger}"/>
                    </DataTrigger>
                    <DataTrigger Binding="{Binding IsSelected, RelativeSource={RelativeSource AncestorType=DataGridRow}}"
                        Value="True">
                      <Setter Property="Foreground"
                          Value="{StaticResource AccentText}"/>
                    </DataTrigger>
                  </Style.Triggers>
                </Style>
              </DataGridTextColumn.ElementStyle>
            </DataGridTextColumn>
            <DataGridTextColumn Header="Status"
                Binding="{Binding Status}"
                Width="110">
              <DataGridTextColumn.ElementStyle>
                <Style TargetType="TextBlock">
                  <Setter Property="TextTrimming"
                      Value="CharacterEllipsis"/>
                  <Setter Property="VerticalAlignment"
                      Value="Center"/>
                  <Setter Property="Cursor"
                      Value="Hand"/>
                  <Setter Property="Foreground"
                      Value="{StaticResource Accent}"/>
                  <Setter Property="TextDecorations"
                      Value="Underline"/>
                  <Setter Property="ToolTip"
                      Value="Click to view details"/>
                  <Style.Triggers>
                    <DataTrigger Binding="{Binding IsSelected, RelativeSource={RelativeSource AncestorType=DataGridRow}}"
                        Value="True">
                      <Setter Property="Foreground"
                          Value="{StaticResource AccentText}"/>
                    </DataTrigger>
                  </Style.Triggers>
                </Style>
              </DataGridTextColumn.ElementStyle>
            </DataGridTextColumn>
            <DataGridTextColumn Header="Full Path"
                Binding="{Binding FullPath}"
                Width="*"/>
          </DataGrid.Columns>
        </DataGrid>

        <StackPanel Grid.Row="6"
            Orientation="Horizontal"
            HorizontalAlignment="Right"
            Margin="0,12,0,0">
          <Button Name="btn_Sign"
              Content="Sign"
              Padding="24,6"/>
        </StackPanel>
      </Grid>
    </DockPanel>
  </Border>
</Window>
"@

#############################################
########### Certificate Picker XAML #########
#############################################
[xml]$Script:XAMLpicker = @"
<Window
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Name="pickerWindow"
  Width="1150"
  Height="520"
  ResizeMode="NoResize"
  WindowStyle="None"
  AllowsTransparency="True"
  Background="Transparent"
  Title="Select Certificate"
  FontFamily="Segoe UI"
  FontSize="14">

  <Window.Resources>
    <SolidColorBrush x:Key="Bg"
        Color="#292524"/>
    <SolidColorBrush x:Key="Surface"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Surface2"
        Color="#44403C"/>
    <SolidColorBrush x:Key="Border"
        Color="#3A3633"/>
    <SolidColorBrush x:Key="BorderMuted"
        Color="#57534E"/>
    <SolidColorBrush x:Key="Text"
        Color="#F5F5F4"/>
    <SolidColorBrush x:Key="TextMuted"
        Color="#A8A29E"/>
    <SolidColorBrush x:Key="Accent"
        Color="#FB923C"/>
    <SolidColorBrush x:Key="AccentHover"
        Color="#F97316"/>
    <SolidColorBrush x:Key="AccentText"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Danger"
        Color="#EF4444"/>

    <Style x:Key="SectionHeader"
        TargetType="TextBlock">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="FontSize"
          Value="15"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="VerticalAlignment"
          Value="Center"/>
    </Style>

    <Style x:Key="ThemedButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Background"
          Value="{StaticResource Surface2}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource BorderMuted}"/>
      <Setter Property="BorderThickness"
          Value="1"/>
      <Setter Property="Margin"
          Value="2.5"/>
      <Setter Property="Padding"
          Value="10,4"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="HorizontalContentAlignment"
          Value="Center"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="6">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"
                  Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Accent}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
              <Trigger Property="IsPressed"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource AccentHover}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource AccentHover}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
              <Trigger Property="IsEnabled"
                  Value="False">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Surface}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Border}"/>
                <Setter TargetName="Bd"
                    Property="Opacity"
                    Value="0.6"/>
                <Setter Property="Foreground"
                    Value="{StaticResource TextMuted}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="Button"
        BasedOn="{StaticResource ThemedButton}"/>

    <Style x:Key="TitleBarCloseButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource TextMuted}"/>
      <Setter Property="Background"
          Value="Transparent"/>
      <Setter Property="BorderThickness"
          Value="0"/>
      <Setter Property="Width"
          Value="46"/>
      <Setter Property="FontFamily"
          Value="Segoe MDL2 Assets"/>
      <Setter Property="FontSize"
          Value="10"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                CornerRadius="0,11,0,0">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Danger}"/>
                <Setter Property="Foreground"
                    Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="DataGrid">
      <Setter Property="Background"
          Value="{StaticResource Surface}"/>
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness"
          Value="1"/>
      <Setter Property="RowBackground"
          Value="{StaticResource Surface}"/>
      <Setter Property="AlternatingRowBackground"
          Value="{StaticResource Bg}"/>
      <Setter Property="GridLinesVisibility"
          Value="Horizontal"/>
      <Setter Property="HorizontalGridLinesBrush"
          Value="{StaticResource Border}"/>
      <Setter Property="HeadersVisibility"
          Value="Column"/>
      <Setter Property="AutoGenerateColumns"
          Value="False"/>
      <Setter Property="CanUserAddRows"
          Value="False"/>
      <Setter Property="CanUserDeleteRows"
          Value="False"/>
      <Setter Property="CanUserResizeRows"
          Value="False"/>
      <Setter Property="IsReadOnly"
          Value="True"/>
      <Setter Property="SelectionMode"
          Value="Single"/>
      <Setter Property="SelectionUnit"
          Value="FullRow"/>
      <Setter Property="RowHeaderWidth"
          Value="0"/>
      <Setter Property="EnableRowVirtualization"
          Value="True"/>
      <Setter Property="VerticalScrollBarVisibility"
          Value="Auto"/>
      <Setter Property="HorizontalScrollBarVisibility"
          Value="Auto"/>
    </Style>

    <Style TargetType="DataGridColumnHeader">
      <Setter Property="Background"
          Value="{StaticResource Surface2}"/>
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="Padding"
          Value="10,6"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness"
          Value="0,0,1,1"/>
      <Setter Property="HorizontalContentAlignment"
          Value="Left"/>
    </Style>

    <Style TargetType="DataGridRow">
      <Setter Property="Background"
          Value="{StaticResource Surface}"/>
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver"
            Value="True">
          <Setter Property="Background"
              Value="{StaticResource Surface2}"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <Style TargetType="DataGridCell">
      <Setter Property="Padding"
          Value="10,4"/>
      <Setter Property="BorderThickness"
          Value="0"/>
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="DataGridCell">
            <Border Background="{TemplateBinding Background}"
                Padding="{TemplateBinding Padding}">
              <ContentPresenter VerticalAlignment="Center"/>
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
      <Style.Triggers>
        <Trigger Property="IsSelected"
            Value="True">
          <Setter Property="Background"
              Value="{StaticResource Accent}"/>
          <Setter Property="Foreground"
              Value="{StaticResource AccentText}"/>
        </Trigger>
      </Style.Triggers>
    </Style>
  </Window.Resources>

  <Border Background="{StaticResource Bg}"
      CornerRadius="12"
      BorderBrush="{StaticResource BorderMuted}"
      BorderThickness="1"
      Margin="0">
    <DockPanel>
      <Border Name="titlebar"
          DockPanel.Dock="Top"
          Background="{StaticResource Surface}"
          CornerRadius="11,11,0,0"
          Height="42">
        <DockPanel LastChildFill="False">
          <Button Name="titlebar_Close"
              DockPanel.Dock="Right"
              Style="{StaticResource TitleBarCloseButton}"
              Content="&#xE8BB;"/>
          <Image DockPanel.Dock="Left"
              Margin="14,0,0,0"
              Width="20"
              Height="20"
              VerticalAlignment="Center"
              RenderOptions.BitmapScalingMode="HighQuality"
              Source="{Binding Icon, RelativeSource={RelativeSource AncestorType=Window}}"/>
          <TextBlock DockPanel.Dock="Left"
              FontSize="15"
              FontWeight="SemiBold"
              Foreground="{StaticResource Text}"
              Text="Select Certificate"
              VerticalAlignment="Center"
              Margin="10,0,0,0"/>
        </DockPanel>
      </Border>
      <Border DockPanel.Dock="Bottom"
          Background="{StaticResource Surface}"
          Height="24"
          CornerRadius="0,0,11,11">
        <TextBlock Name="txtblk_StatusBar"
            VerticalAlignment="Center"
            Foreground="{StaticResource TextMuted}"
            FontSize="12"
            Margin="12,0"
            Text=""/>
      </Border>

      <Grid Margin="12">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0"
            Margin="0,0,0,8">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <TextBlock Grid.Column="0"
              Style="{StaticResource SectionHeader}"
              Text="Available Code Signing Certificates"/>
          <Button Grid.Column="1"
              Name="btn_Refresh"
              Content="Refresh"
              Width="90"/>
        </Grid>

        <DataGrid Grid.Row="1"
            Name="dg_Certificates">
          <DataGrid.Columns>
            <DataGridTextColumn Header="Thumbprint"
                Binding="{Binding Thumbprint}"
                Width="Auto"/>
            <DataGridTextColumn Header="Friendly Name"
                Binding="{Binding FriendlyName}"
                Width="Auto"/>
            <DataGridTextColumn Header="Subject"
                Binding="{Binding Subject}"
                Width="Auto"/>
            <DataGridTextColumn Header="Issuer"
                Binding="{Binding Issuer}"
                Width="Auto"/>
            <DataGridTextColumn Header="Expiration"
                Binding="{Binding Expiration}"
                Width="Auto"/>
            <DataGridTextColumn Header="Store"
                Binding="{Binding Store}"
                Width="Auto"/>
          </DataGrid.Columns>
        </DataGrid>

        <StackPanel Grid.Row="2"
            Orientation="Horizontal"
            HorizontalAlignment="Right"
            Margin="0,10,0,0">
          <Button Name="btn_Cancel"
              Content="Cancel"
              Width="90"/>
          <Button Name="btn_Select"
              Content="Select"
              Width="90"/>
        </StackPanel>
      </Grid>
    </DockPanel>
  </Border>
</Window>
"@

#############################################
########## Certificate Creator XAML #########
#############################################
[xml]$Script:XAMLcreator = @"
<Window
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Name="creatorWindow"
  Width="560"
  SizeToContent="Height"
  ResizeMode="NoResize"
  WindowStyle="None"
  AllowsTransparency="True"
  Background="Transparent"
  Title="Create Self-Signed Certificate"
  FontFamily="Segoe UI"
  FontSize="14">

  <Window.Resources>
    <SolidColorBrush x:Key="Bg"
        Color="#292524"/>
    <SolidColorBrush x:Key="Surface"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Surface2"
        Color="#44403C"/>
    <SolidColorBrush x:Key="Border"
        Color="#3A3633"/>
    <SolidColorBrush x:Key="BorderMuted"
        Color="#57534E"/>
    <SolidColorBrush x:Key="Text"
        Color="#F5F5F4"/>
    <SolidColorBrush x:Key="TextMuted"
        Color="#A8A29E"/>
    <SolidColorBrush x:Key="Accent"
        Color="#FB923C"/>
    <SolidColorBrush x:Key="AccentHover"
        Color="#F97316"/>
    <SolidColorBrush x:Key="AccentText"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Danger"
        Color="#EF4444"/>

    <Style x:Key="SectionHeader"
        TargetType="TextBlock">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="FontSize"
          Value="15"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="VerticalAlignment"
          Value="Center"/>
    </Style>

    <Style TargetType="Label">
      <Setter Property="Foreground"
          Value="{StaticResource TextMuted}"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="Padding"
          Value="0"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
    </Style>

    <Style TargetType="TextBox">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Background"
          Value="{StaticResource Surface}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness"
          Value="1"/>
      <Setter Property="Padding"
          Value="8,0"/>
      <Setter Property="Height"
          Value="30"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="CaretBrush"
          Value="{StaticResource Accent}"/>
      <Setter Property="SelectionBrush"
          Value="{StaticResource Accent}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TextBox">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="6">
              <ScrollViewer x:Name="PART_ContentHost"
                  Margin="{TemplateBinding Padding}"
                  VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="CheckBox">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <StackPanel Orientation="Horizontal"
                Background="Transparent">
              <Border x:Name="Box"
                  Width="18"
                  Height="18"
                  CornerRadius="4"
                  Background="{StaticResource Surface}"
                  BorderBrush="{StaticResource BorderMuted}"
                  BorderThickness="1"
                  VerticalAlignment="Center">
                <TextBlock x:Name="Check"
                    Text="&#xE73E;"
                    FontFamily="Segoe MDL2 Assets"
                    FontSize="12"
                    Foreground="{StaticResource AccentText}"
                    HorizontalAlignment="Center"
                    VerticalAlignment="Center"
                    Visibility="Collapsed"/>
              </Border>
              <ContentPresenter Margin="8,0,0,0"
                  VerticalAlignment="Center"/>
            </StackPanel>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked"
                  Value="True">
                <Setter TargetName="Box"
                    Property="Background"
                    Value="{StaticResource Accent}"/>
                <Setter TargetName="Box"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
                <Setter TargetName="Check"
                    Property="Visibility"
                    Value="Visible"/>
              </Trigger>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Box"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <ControlTemplate x:Key="ComboBoxToggleButton"
        TargetType="ToggleButton">
      <Border x:Name="Bd"
          Background="{StaticResource Surface}"
          BorderBrush="{StaticResource Border}"
          BorderThickness="1"
          CornerRadius="6">
        <Grid>
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="26"/>
          </Grid.ColumnDefinitions>
          <TextBlock Grid.Column="1"
              Text="&#xE70D;"
              FontFamily="Segoe MDL2 Assets"
              FontSize="10"
              Foreground="{StaticResource TextMuted}"
              HorizontalAlignment="Center"
              VerticalAlignment="Center"/>
        </Grid>
      </Border>
      <ControlTemplate.Triggers>
        <Trigger Property="IsMouseOver"
            Value="True">
          <Setter TargetName="Bd"
              Property="BorderBrush"
              Value="{StaticResource Accent}"/>
        </Trigger>
      </ControlTemplate.Triggers>
    </ControlTemplate>

    <Style TargetType="ComboBox">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Background"
          Value="{StaticResource Surface}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource Border}"/>
      <Setter Property="Height"
          Value="30"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ComboBox">
            <Grid>
              <ToggleButton Template="{StaticResource ComboBoxToggleButton}"
                  Focusable="False"
                  IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"
                  ClickMode="Press"/>
              <ContentPresenter x:Name="ContentSite"
                  IsHitTestVisible="False"
                  Content="{TemplateBinding SelectionBoxItem}"
                  ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                  Margin="10,0,30,0"
                  VerticalAlignment="Center"
                  HorizontalAlignment="Left"/>
              <Popup x:Name="Popup"
                  Placement="Bottom"
                  IsOpen="{TemplateBinding IsDropDownOpen}"
                  AllowsTransparency="True"
                  Focusable="False"
                  PopupAnimation="Slide">
                <Border Background="{StaticResource Surface}"
                    BorderBrush="{StaticResource Border}"
                    BorderThickness="1"
                    CornerRadius="6"
                    MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}"
                    MaxHeight="220"
                    Margin="0,2,0,0">
                  <ScrollViewer>
                    <StackPanel IsItemsHost="True"
                        KeyboardNavigation.DirectionalNavigation="Contained"/>
                  </ScrollViewer>
                </Border>
              </Popup>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="ComboBoxItem">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Padding"
          Value="10,6"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ComboBoxItem">
            <Border x:Name="Bd"
                Background="Transparent"
                Padding="{TemplateBinding Padding}"
                CornerRadius="4"
                Margin="2,1">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsHighlighted"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Accent}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="SpinnerButton"
        TargetType="RepeatButton">
      <Setter Property="Background"
          Value="{StaticResource Surface2}"/>
      <Setter Property="Foreground"
          Value="{StaticResource TextMuted}"/>
      <Setter Property="FontFamily"
          Value="Segoe MDL2 Assets"/>
      <Setter Property="FontSize"
          Value="7"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RepeatButton">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Accent}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="ThemedButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Background"
          Value="{StaticResource Surface2}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource BorderMuted}"/>
      <Setter Property="BorderThickness"
          Value="1"/>
      <Setter Property="Margin"
          Value="2.5"/>
      <Setter Property="Padding"
          Value="10,4"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="HorizontalContentAlignment"
          Value="Center"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="6">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"
                  Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Accent}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
              <Trigger Property="IsPressed"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource AccentHover}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource AccentHover}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
              <Trigger Property="IsEnabled"
                  Value="False">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Surface}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Border}"/>
                <Setter TargetName="Bd"
                    Property="Opacity"
                    Value="0.6"/>
                <Setter Property="Foreground"
                    Value="{StaticResource TextMuted}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="Button"
        BasedOn="{StaticResource ThemedButton}"/>

    <Style x:Key="TitleBarCloseButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource TextMuted}"/>
      <Setter Property="Background"
          Value="Transparent"/>
      <Setter Property="BorderThickness"
          Value="0"/>
      <Setter Property="Width"
          Value="46"/>
      <Setter Property="FontFamily"
          Value="Segoe MDL2 Assets"/>
      <Setter Property="FontSize"
          Value="10"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                CornerRadius="0,11,0,0">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Danger}"/>
                <Setter Property="Foreground"
                    Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border Background="{StaticResource Bg}"
      CornerRadius="12"
      BorderBrush="{StaticResource BorderMuted}"
      BorderThickness="1"
      Margin="0">
    <DockPanel>
      <Border Name="titlebar"
          DockPanel.Dock="Top"
          Background="{StaticResource Surface}"
          CornerRadius="11,11,0,0"
          Height="42">
        <DockPanel LastChildFill="False">
          <Button Name="titlebar_Close"
              DockPanel.Dock="Right"
              Style="{StaticResource TitleBarCloseButton}"
              Content="&#xE8BB;"/>
          <Image DockPanel.Dock="Left"
              Margin="14,0,0,0"
              Width="20"
              Height="20"
              VerticalAlignment="Center"
              RenderOptions.BitmapScalingMode="HighQuality"
              Source="{Binding Icon, RelativeSource={RelativeSource AncestorType=Window}}"/>
          <TextBlock DockPanel.Dock="Left"
              FontSize="15"
              FontWeight="SemiBold"
              Foreground="{StaticResource Text}"
              Text="Create Self-Signed Certificate"
              VerticalAlignment="Center"
              Margin="10,0,0,0"/>
        </DockPanel>
      </Border>
      <Border DockPanel.Dock="Bottom"
          Background="{StaticResource Surface}"
          Height="24"
          CornerRadius="0,0,11,11">
        <TextBlock Name="txtblk_StatusBar"
            VerticalAlignment="Center"
            Foreground="{StaticResource TextMuted}"
            FontSize="12"
            Margin="12,0"
            Text=""/>
      </Border>

      <Grid Margin="16">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Certificate Configuration -->
        <TextBlock Grid.Row="0"
            Style="{StaticResource SectionHeader}"
            Text="Certificate Configuration"
            Margin="0,0,0,8"/>

        <Border Grid.Row="1"
            Background="{StaticResource Surface}"
            BorderBrush="{StaticResource Border}"
            BorderThickness="1"
            CornerRadius="8"
            Padding="16">
          <Grid>
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="110"/>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <Label Grid.Row="0"
                Grid.Column="0"
                Content="Subject:"/>
            <TextBox Grid.Row="0"
                Grid.Column="1"
                Name="txt_Subject"/>
            <TextBlock Grid.Row="0"
                Grid.Column="2"
                Name="txtblk_SubjectDefault"
                Text="Default"
                Foreground="{StaticResource Accent}"
                TextDecorations="Underline"
                Cursor="Hand"
                VerticalAlignment="Center"
                Margin="12,0,0,0"/>

            <Label Grid.Row="1"
                Grid.Column="0"
                Content="Valid for:"
                Margin="0,12,0,0"/>
            <StackPanel Grid.Row="1"
                Grid.Column="1"
                Grid.ColumnSpan="2"
                Orientation="Horizontal"
                Margin="0,12,0,0">
              <Border Width="80"
                  Height="30"
                  Background="{StaticResource Surface}"
                  BorderBrush="{StaticResource Border}"
                  BorderThickness="1"
                  CornerRadius="6">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="20"/>
                  </Grid.ColumnDefinitions>
                  <TextBox Grid.Column="0"
                      Name="txt_ValidYears"
                      Text="5"
                      MaxLength="2"
                      Background="Transparent"
                      BorderThickness="0"
                      HorizontalContentAlignment="Center"/>
                  <Grid Grid.Column="1">
                    <Grid.RowDefinitions>
                      <RowDefinition Height="*"/>
                      <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <RepeatButton Grid.Row="0"
                        Name="btn_YearsUp"
                        Style="{StaticResource SpinnerButton}"
                        Content="&#xE70E;"/>
                    <RepeatButton Grid.Row="1"
                        Name="btn_YearsDown"
                        Style="{StaticResource SpinnerButton}"
                        Content="&#xE70D;"/>
                  </Grid>
                </Grid>
              </Border>
              <TextBlock Text="years"
                  Foreground="{StaticResource TextMuted}"
                  VerticalAlignment="Center"
                  Margin="10,0,0,0"/>
            </StackPanel>

            <Label Grid.Row="2"
                Grid.Column="0"
                Content="Key length:"
                Margin="0,12,0,0"/>
            <StackPanel Grid.Row="2"
                Grid.Column="1"
                Grid.ColumnSpan="2"
                Orientation="Horizontal"
                Margin="0,12,0,0">
              <ComboBox Name="cmb_KeyLength"
                  Width="120">
                <ComboBoxItem Content="2048"/>
                <ComboBoxItem Content="4096"/>
              </ComboBox>
              <TextBlock Text="bits"
                  Foreground="{StaticResource TextMuted}"
                  VerticalAlignment="Center"
                  Margin="10,0,0,0"/>
            </StackPanel>

            <Label Grid.Row="3"
                Grid.Column="0"
                Content="Store:"
                Margin="0,12,0,0"/>
            <ComboBox Grid.Row="3"
                Grid.Column="1"
                Grid.ColumnSpan="2"
                Name="cmb_Store"
                HorizontalAlignment="Left"
                Width="200"
                Margin="0,12,0,0">
              <ComboBoxItem Content="CurrentUser"/>
              <ComboBoxItem Content="LocalMachine"/>
            </ComboBox>
          </Grid>
        </Border>

        <!-- Private Key Options -->
        <TextBlock Grid.Row="2"
            Style="{StaticResource SectionHeader}"
            Text="Private Key Options"
            Margin="0,16,0,8"/>

        <Border Grid.Row="3"
            VerticalAlignment="Top"
            Background="{StaticResource Surface}"
            BorderBrush="{StaticResource Border}"
            BorderThickness="1"
            CornerRadius="8"
            Padding="16">
          <StackPanel>
            <CheckBox Name="chk_NonExportable"
                Content="Disable Private Key Export"/>
            <TextBlock Text="When enabled, the private key cannot be exported after generation."
                Foreground="{StaticResource TextMuted}"
                FontSize="12"
                TextWrapping="Wrap"
                Margin="0,8,0,0"/>
          </StackPanel>
        </Border>

        <!-- Trust Options -->
        <TextBlock Grid.Row="4"
            Style="{StaticResource SectionHeader}"
            Text="Trust Options"
            Margin="0,16,0,8"/>

        <Border Grid.Row="5"
            VerticalAlignment="Top"
            Background="{StaticResource Surface}"
            BorderBrush="{StaticResource Border}"
            BorderThickness="1"
            CornerRadius="8"
            Padding="16">
          <StackPanel>
            <CheckBox Name="chk_SkipTrustedRoot"
                Content="Don't add to Trusted Root Certification Authorities"/>
            <CheckBox Name="chk_SkipTrustedPublisher"
                Content="Don't add to Trusted Publishers"
                Margin="0,10,0,0"/>
            <TextBlock Text="By default the certificate is added to these stores so files signed with it are trusted on this machine."
                Foreground="{StaticResource TextMuted}"
                FontSize="12"
                TextWrapping="Wrap"
                Margin="0,8,0,0"/>
          </StackPanel>
        </Border>

        <StackPanel Grid.Row="6"
            Orientation="Horizontal"
            HorizontalAlignment="Right"
            Margin="0,16,0,0">
          <Button Name="btn_CancelCreate"
              Content="Cancel"
              Width="110"/>
          <Button Name="btn_Generate"
              Content="Generate"
              Width="110"/>
        </StackPanel>
      </Grid>
    </DockPanel>
  </Border>
</Window>
"@

#############################################
######### Certificate Information XAML ######
#############################################
[xml]$Script:XAMLviewer = @"
<Window
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Name="viewerWindow"
  Width="620"
  SizeToContent="Height"
  ResizeMode="NoResize"
  WindowStyle="None"
  AllowsTransparency="True"
  Background="Transparent"
  Title="Certificate Information"
  FontFamily="Segoe UI"
  FontSize="14">

  <Window.Resources>
    <SolidColorBrush x:Key="Bg"
        Color="#292524"/>
    <SolidColorBrush x:Key="Surface"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Surface2"
        Color="#44403C"/>
    <SolidColorBrush x:Key="Border"
        Color="#3A3633"/>
    <SolidColorBrush x:Key="BorderMuted"
        Color="#57534E"/>
    <SolidColorBrush x:Key="Text"
        Color="#F5F5F4"/>
    <SolidColorBrush x:Key="TextMuted"
        Color="#A8A29E"/>
    <SolidColorBrush x:Key="Accent"
        Color="#FB923C"/>
    <SolidColorBrush x:Key="AccentHover"
        Color="#F97316"/>
    <SolidColorBrush x:Key="AccentText"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Danger"
        Color="#EF4444"/>
    <SolidColorBrush x:Key="Success"
        Color="#22C55E"/>

    <Style x:Key="SectionHeader"
        TargetType="TextBlock">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="FontSize"
          Value="15"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="VerticalAlignment"
          Value="Center"/>
    </Style>

    <Style TargetType="Label">
      <Setter Property="Foreground"
          Value="{StaticResource TextMuted}"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="Padding"
          Value="0"/>
      <Setter Property="HorizontalContentAlignment"
          Value="Right"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
    </Style>

    <Style TargetType="TextBox">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Background"
          Value="{StaticResource Surface}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness"
          Value="1"/>
      <Setter Property="Padding"
          Value="8,0"/>
      <Setter Property="Height"
          Value="30"/>
      <Setter Property="IsReadOnly"
          Value="True"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="CaretBrush"
          Value="{StaticResource Accent}"/>
      <Setter Property="SelectionBrush"
          Value="{StaticResource Accent}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TextBox">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="6">
              <ScrollViewer x:Name="PART_ContentHost"
                  Margin="{TemplateBinding Padding}"
                  VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="ThemedButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Background"
          Value="{StaticResource Surface2}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource BorderMuted}"/>
      <Setter Property="BorderThickness"
          Value="1"/>
      <Setter Property="Margin"
          Value="2.5"/>
      <Setter Property="Padding"
          Value="14,6"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="HorizontalContentAlignment"
          Value="Center"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="6">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"
                  Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Accent}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
              <Trigger Property="IsPressed"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource AccentHover}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource AccentHover}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="Button"
        BasedOn="{StaticResource ThemedButton}"/>

    <Style x:Key="TitleBarCloseButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource TextMuted}"/>
      <Setter Property="Background"
          Value="Transparent"/>
      <Setter Property="BorderThickness"
          Value="0"/>
      <Setter Property="Width"
          Value="46"/>
      <Setter Property="FontFamily"
          Value="Segoe MDL2 Assets"/>
      <Setter Property="FontSize"
          Value="10"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                CornerRadius="0,11,0,0">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Danger}"/>
                <Setter Property="Foreground"
                    Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border Background="{StaticResource Bg}"
      CornerRadius="12"
      BorderBrush="{StaticResource BorderMuted}"
      BorderThickness="1"
      Margin="0">
    <DockPanel>
      <Border Name="titlebar"
          DockPanel.Dock="Top"
          Background="{StaticResource Surface}"
          CornerRadius="11,11,0,0"
          Height="42">
        <DockPanel LastChildFill="False">
          <Button Name="titlebar_Close"
              DockPanel.Dock="Right"
              Style="{StaticResource TitleBarCloseButton}"
              Content="&#xE8BB;"/>
          <Image DockPanel.Dock="Left"
              Margin="14,0,0,0"
              Width="20"
              Height="20"
              VerticalAlignment="Center"
              RenderOptions.BitmapScalingMode="HighQuality"
              Source="{Binding Icon, RelativeSource={RelativeSource AncestorType=Window}}"/>
          <TextBlock DockPanel.Dock="Left"
              Name="txt_ViewerTitle"
              FontSize="15"
              FontWeight="SemiBold"
              Foreground="{StaticResource Text}"
              Text="Certificate Information"
              VerticalAlignment="Center"
              Margin="10,0,0,0"/>
        </DockPanel>
      </Border>
      <Border DockPanel.Dock="Bottom"
          Background="{StaticResource Surface}"
          Height="24"
          CornerRadius="0,0,11,11">
        <TextBlock Name="txtblk_StatusBar"
            VerticalAlignment="Center"
            Foreground="{StaticResource TextMuted}"
            FontSize="12"
            Margin="12,0"
            Text=""/>
      </Border>

      <Grid Margin="16">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- File signature (shown only when viewing a file's signature) -->
        <StackPanel Grid.Row="0"
            Name="pnl_Signature"
            Visibility="Collapsed">
          <TextBlock Style="{StaticResource SectionHeader}"
              Text="Signature"
              Margin="0,0,0,8"/>
          <Border Background="{StaticResource Surface}"
              BorderBrush="{StaticResource Border}"
              BorderThickness="1"
              CornerRadius="8"
              Padding="16"
              Margin="0,0,0,12">
            <Grid>
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
              </Grid.RowDefinitions>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="120"/>
                <ColumnDefinition Width="*"/>
              </Grid.ColumnDefinitions>

              <Label Grid.Row="0"
                  Grid.Column="0"
                  Content="Status:"
                  Margin="0,0,10,0"/>
              <TextBox Grid.Row="0"
                  Grid.Column="1"
                  Name="txt_SigStatus"/>

              <Label Grid.Row="1"
                  Grid.Column="0"
                  Content="Timestamped:"
                  Margin="0,10,10,0"/>
              <TextBox Grid.Row="1"
                  Grid.Column="1"
                  Name="txt_SigTimestamp"
                  Margin="0,10,0,0"/>

              <Label Grid.Row="2"
                  Grid.Column="0"
                  Content="Timestamp Date:"
                  Margin="0,10,10,0"/>
              <TextBox Grid.Row="2"
                  Grid.Column="1"
                  Name="txt_SigTimestampDate"
                  Margin="0,10,0,0"/>

              <Label Grid.Row="3"
                  Grid.Column="0"
                  Content="Authority:"
                  Margin="0,10,10,0"/>
              <TextBox Grid.Row="3"
                  Grid.Column="1"
                  Name="txt_SigAuthority"
                  Margin="0,10,0,0"/>
            </Grid>
          </Border>
        </StackPanel>

        <!-- Details -->
        <TextBlock Grid.Row="1"
            Style="{StaticResource SectionHeader}"
            Text="Details"
            Margin="0,0,0,8"/>

        <Border Grid.Row="2"
            Background="{StaticResource Surface}"
            BorderBrush="{StaticResource Border}"
            BorderThickness="1"
            CornerRadius="8"
            Padding="16">
          <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
              </Grid.RowDefinitions>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="120"/>
                <ColumnDefinition Width="*"/>
              </Grid.ColumnDefinitions>

              <Label Grid.Row="0"
                  Grid.Column="0"
                  Content="Issuer:"
                  Margin="0,0,10,0"/>
              <TextBox Grid.Row="0"
                  Grid.Column="1"
                  Name="txt_Issuer"/>

              <Label Grid.Row="1"
                  Grid.Column="0"
                  Content="Subject:"
                  Margin="0,10,10,0"/>
              <TextBox Grid.Row="1"
                  Grid.Column="1"
                  Name="txt_Subject"
                  Margin="0,10,0,0"/>

              <Label Grid.Row="2"
                  Grid.Column="0"
                  Content="Effective Date:"
                  Margin="0,10,10,0"/>
              <TextBox Grid.Row="2"
                  Grid.Column="1"
                  Name="txt_Effective"
                  Margin="0,10,0,0"/>

              <Label Grid.Row="3"
                  Grid.Column="0"
                  Content="Expiration Date:"
                  Margin="0,10,10,0"/>
              <TextBox Grid.Row="3"
                  Grid.Column="1"
                  Name="txt_Expiration"
                  Margin="0,10,0,0"/>

              <Label Grid.Row="4"
                  Grid.Column="0"
                  Content="Cert Usage:"
                  Margin="0,10,10,0"/>
              <TextBox Grid.Row="4"
                  Grid.Column="1"
                  Name="txt_Usage"
                  Margin="0,10,0,0"/>

              <Label Grid.Row="5"
                  Grid.Column="0"
                  Content="Public Key:"
                  Margin="0,10,10,0"/>
              <TextBox Grid.Row="5"
                  Grid.Column="1"
                  Name="txt_PublicKey"
                  Margin="0,10,0,0"/>

              <Label Grid.Row="6"
                  Grid.Column="0"
                  Content="Thumbprint:"
                  Margin="0,10,10,0"/>
              <TextBox Grid.Row="6"
                  Grid.Column="1"
                  Name="txt_Thumbprint"
                  Margin="0,10,0,0"/>
          </Grid>
        </Border>

        <!-- Trust status -->
        <Border Grid.Row="3"
            Background="{StaticResource Surface}"
            BorderBrush="{StaticResource Border}"
            BorderThickness="1"
            CornerRadius="8"
            Padding="16"
            Margin="0,12,0,0">
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <StackPanel Grid.Column="0"
                Orientation="Horizontal">
              <TextBlock Text="Trusted Publisher:"
                  Foreground="{StaticResource Text}"
                  FontWeight="SemiBold"
                  VerticalAlignment="Center"/>
              <TextBlock Name="icn_TrustedPublisher"
                  FontFamily="Segoe MDL2 Assets"
                  FontSize="16"
                  VerticalAlignment="Center"
                  Margin="8,0,0,0"/>
            </StackPanel>

            <StackPanel Grid.Column="1"
                Orientation="Horizontal"
                HorizontalAlignment="Center">
              <TextBlock Text="Trusted Root Authority:"
                  Foreground="{StaticResource Text}"
                  FontWeight="SemiBold"
                  VerticalAlignment="Center"/>
              <TextBlock Name="icn_TrustedRoot"
                  FontFamily="Segoe MDL2 Assets"
                  FontSize="16"
                  VerticalAlignment="Center"
                  Margin="8,0,0,0"/>
            </StackPanel>

            <StackPanel Grid.Column="2"
                Orientation="Horizontal"
                HorizontalAlignment="Right">
              <TextBlock Text="Self Signed:"
                  Foreground="{StaticResource Text}"
                  FontWeight="SemiBold"
                  VerticalAlignment="Center"/>
              <TextBlock Name="icn_SelfSigned"
                  FontFamily="Segoe MDL2 Assets"
                  FontSize="16"
                  VerticalAlignment="Center"
                  Margin="8,0,0,0"/>
            </StackPanel>
          </Grid>
        </Border>

        <Grid Grid.Row="4"
            Margin="0,16,0,0">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <Button Grid.Column="0"
              Name="btn_Validate"
              Content="Validate Trust Chain"/>
          <Button Grid.Column="2"
              Name="btn_Close"
              Content="Close"
              Width="110"/>
        </Grid>
      </Grid>
    </DockPanel>
  </Border>
</Window>
"@

#############################################
############# Status Window #################
#############################################
# Generic, reusable themed message window (replaces the built-in MessageBox for status details).
[xml]$Script:XAMLstatus = @"
<Window
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Name="statusWindow"
  Width="480"
  SizeToContent="Height"
  ResizeMode="NoResize"
  WindowStyle="None"
  AllowsTransparency="True"
  Background="Transparent"
  Title="Status"
  FontFamily="Segoe UI"
  FontSize="14">

  <Window.Resources>
    <SolidColorBrush x:Key="Bg"
        Color="#292524"/>
    <SolidColorBrush x:Key="Surface"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Surface2"
        Color="#44403C"/>
    <SolidColorBrush x:Key="Border"
        Color="#3A3633"/>
    <SolidColorBrush x:Key="BorderMuted"
        Color="#57534E"/>
    <SolidColorBrush x:Key="Text"
        Color="#F5F5F4"/>
    <SolidColorBrush x:Key="TextMuted"
        Color="#A8A29E"/>
    <SolidColorBrush x:Key="Accent"
        Color="#FB923C"/>
    <SolidColorBrush x:Key="AccentHover"
        Color="#F97316"/>
    <SolidColorBrush x:Key="AccentText"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Danger"
        Color="#EF4444"/>
    <SolidColorBrush x:Key="Success"
        Color="#22C55E"/>

    <Style x:Key="ThemedButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Background"
          Value="{StaticResource Surface2}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource BorderMuted}"/>
      <Setter Property="BorderThickness"
          Value="1"/>
      <Setter Property="Margin"
          Value="2.5"/>
      <Setter Property="Padding"
          Value="14,6"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="HorizontalContentAlignment"
          Value="Center"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="6">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"
                  Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Accent}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
              <Trigger Property="IsPressed"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource AccentHover}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource AccentHover}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="Button"
        BasedOn="{StaticResource ThemedButton}"/>

    <Style x:Key="TitleBarCloseButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource TextMuted}"/>
      <Setter Property="Background"
          Value="Transparent"/>
      <Setter Property="BorderThickness"
          Value="0"/>
      <Setter Property="Width"
          Value="46"/>
      <Setter Property="FontFamily"
          Value="Segoe MDL2 Assets"/>
      <Setter Property="FontSize"
          Value="10"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                CornerRadius="0,11,0,0">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Danger}"/>
                <Setter Property="Foreground"
                    Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border Background="{StaticResource Bg}"
      CornerRadius="12"
      BorderBrush="{StaticResource BorderMuted}"
      BorderThickness="1"
      Margin="0">
    <DockPanel>
      <Border Name="titlebar"
          DockPanel.Dock="Top"
          Background="{StaticResource Surface}"
          CornerRadius="11,11,0,0"
          Height="42">
        <DockPanel LastChildFill="False">
          <Button Name="titlebar_Close"
              DockPanel.Dock="Right"
              Style="{StaticResource TitleBarCloseButton}"
              Content="&#xE8BB;"/>
          <Image DockPanel.Dock="Left"
              Margin="14,0,0,0"
              Width="20"
              Height="20"
              VerticalAlignment="Center"
              RenderOptions.BitmapScalingMode="HighQuality"
              Source="{Binding Icon, RelativeSource={RelativeSource AncestorType=Window}}"/>
          <TextBlock DockPanel.Dock="Left"
              Name="txt_StatusTitle"
              FontSize="15"
              FontWeight="SemiBold"
              Foreground="{StaticResource Text}"
              Text="Status"
              VerticalAlignment="Center"
              Margin="10,0,0,0"/>
        </DockPanel>
      </Border>

      <Grid Margin="16">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0"
            Background="{StaticResource Surface}"
            BorderBrush="{StaticResource Border}"
            BorderThickness="1"
            CornerRadius="8"
            Padding="16">
          <DockPanel>
            <TextBlock Name="icn_Status"
                DockPanel.Dock="Left"
                FontFamily="Segoe MDL2 Assets"
                FontSize="24"
                VerticalAlignment="Top"
                Margin="0,0,14,0"
                Foreground="{StaticResource Accent}"
                Text="&#xE946;"/>
            <TextBox Name="txt_StatusMessage"
                Background="Transparent"
                BorderThickness="0"
                Foreground="{StaticResource Text}"
                IsReadOnly="True"
                TextWrapping="Wrap"
                MaxHeight="360"
                VerticalAlignment="Center"
                VerticalScrollBarVisibility="Auto"
                CaretBrush="{StaticResource Accent}"
                SelectionBrush="{StaticResource Accent}"
                Text=""/>
          </DockPanel>
        </Border>

        <Grid Grid.Row="1"
            Margin="0,16,0,0">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <Button Grid.Column="1"
              Name="btn_Close"
              Content="Close"
              Width="110"/>
        </Grid>
      </Grid>
    </DockPanel>
  </Border>
</Window>
"@

#############################################
############ Confirmation Window ############
#############################################
# Generic, reusable themed confirmation window with dynamically added buttons.
[xml]$Script:XAMLconfirm = @"
<Window
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Name="confirmWindow"
  Width="480"
  SizeToContent="Height"
  ResizeMode="NoResize"
  WindowStyle="None"
  AllowsTransparency="True"
  Background="Transparent"
  Title="Confirm"
  FontFamily="Segoe UI"
  FontSize="14">

  <Window.Resources>
    <SolidColorBrush x:Key="Bg"
        Color="#292524"/>
    <SolidColorBrush x:Key="Surface"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Surface2"
        Color="#44403C"/>
    <SolidColorBrush x:Key="Border"
        Color="#3A3633"/>
    <SolidColorBrush x:Key="BorderMuted"
        Color="#57534E"/>
    <SolidColorBrush x:Key="Text"
        Color="#F5F5F4"/>
    <SolidColorBrush x:Key="TextMuted"
        Color="#A8A29E"/>
    <SolidColorBrush x:Key="Accent"
        Color="#FB923C"/>
    <SolidColorBrush x:Key="AccentHover"
        Color="#F97316"/>
    <SolidColorBrush x:Key="AccentText"
        Color="#1C1917"/>
    <SolidColorBrush x:Key="Danger"
        Color="#EF4444"/>
    <SolidColorBrush x:Key="Success"
        Color="#22C55E"/>

    <Style x:Key="ThemedButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource Text}"/>
      <Setter Property="Background"
          Value="{StaticResource Surface2}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource BorderMuted}"/>
      <Setter Property="BorderThickness"
          Value="1"/>
      <Setter Property="Margin"
          Value="2.5"/>
      <Setter Property="Padding"
          Value="14,6"/>
      <Setter Property="FontWeight"
          Value="SemiBold"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="HorizontalContentAlignment"
          Value="Center"/>
      <Setter Property="VerticalContentAlignment"
          Value="Center"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="6">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"
                  Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Accent}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource Accent}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
              <Trigger Property="IsPressed"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource AccentHover}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource AccentHover}"/>
                <Setter Property="Foreground"
                    Value="{StaticResource AccentText}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="Button"
        BasedOn="{StaticResource ThemedButton}"/>

    <!-- Primary (affirmative) button: filled accent by default -->
    <Style x:Key="PrimaryButton"
        TargetType="Button"
        BasedOn="{StaticResource ThemedButton}">
      <Setter Property="Foreground"
          Value="{StaticResource AccentText}"/>
      <Setter Property="Background"
          Value="{StaticResource Accent}"/>
      <Setter Property="BorderBrush"
          Value="{StaticResource Accent}"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                BorderBrush="{TemplateBinding BorderBrush}"
                BorderThickness="{TemplateBinding BorderThickness}"
                CornerRadius="6">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"
                  Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource AccentHover}"/>
                <Setter TargetName="Bd"
                    Property="BorderBrush"
                    Value="{StaticResource AccentHover}"/>
              </Trigger>
              <Trigger Property="IsPressed"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource AccentHover}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="TitleBarCloseButton"
        TargetType="Button">
      <Setter Property="Foreground"
          Value="{StaticResource TextMuted}"/>
      <Setter Property="Background"
          Value="Transparent"/>
      <Setter Property="BorderThickness"
          Value="0"/>
      <Setter Property="Width"
          Value="46"/>
      <Setter Property="FontFamily"
          Value="Segoe MDL2 Assets"/>
      <Setter Property="FontSize"
          Value="10"/>
      <Setter Property="Cursor"
          Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd"
                Background="{TemplateBinding Background}"
                CornerRadius="0,11,0,0">
              <ContentPresenter HorizontalAlignment="Center"
                  VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver"
                  Value="True">
                <Setter TargetName="Bd"
                    Property="Background"
                    Value="{StaticResource Danger}"/>
                <Setter Property="Foreground"
                    Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border Background="{StaticResource Bg}"
      CornerRadius="12"
      BorderBrush="{StaticResource BorderMuted}"
      BorderThickness="1"
      Margin="0">
    <DockPanel>
      <Border Name="titlebar"
          DockPanel.Dock="Top"
          Background="{StaticResource Surface}"
          CornerRadius="11,11,0,0"
          Height="42">
        <DockPanel LastChildFill="False">
          <Button Name="titlebar_Close"
              DockPanel.Dock="Right"
              Style="{StaticResource TitleBarCloseButton}"
              Content="&#xE8BB;"/>
          <Image DockPanel.Dock="Left"
              Margin="14,0,0,0"
              Width="20"
              Height="20"
              VerticalAlignment="Center"
              RenderOptions.BitmapScalingMode="HighQuality"
              Source="{Binding Icon, RelativeSource={RelativeSource AncestorType=Window}}"/>
          <TextBlock DockPanel.Dock="Left"
              Name="txt_ConfirmTitle"
              FontSize="15"
              FontWeight="SemiBold"
              Foreground="{StaticResource Text}"
              Text="Confirm"
              VerticalAlignment="Center"
              Margin="10,0,0,0"/>
        </DockPanel>
      </Border>

      <Grid Margin="16">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0"
            Background="{StaticResource Surface}"
            BorderBrush="{StaticResource Border}"
            BorderThickness="1"
            CornerRadius="8"
            Padding="16">
          <DockPanel>
            <TextBlock Name="icn_Confirm"
                DockPanel.Dock="Left"
                FontFamily="Segoe MDL2 Assets"
                FontSize="24"
                VerticalAlignment="Top"
                Margin="0,0,14,0"
                Foreground="{StaticResource Accent}"
                Text="&#xE9CE;"/>
            <TextBox Name="txt_ConfirmMessage"
                Background="Transparent"
                BorderThickness="0"
                Foreground="{StaticResource Text}"
                IsReadOnly="True"
                TextWrapping="Wrap"
                MaxHeight="360"
                VerticalAlignment="Center"
                VerticalScrollBarVisibility="Auto"
                CaretBrush="{StaticResource Accent}"
                SelectionBrush="{StaticResource Accent}"
                Text=""/>
          </DockPanel>
        </Border>

        <StackPanel Grid.Row="1"
            Name="pnl_Buttons"
            Orientation="Horizontal"
            HorizontalAlignment="Right"
            Margin="0,16,0,0"/>
      </Grid>
    </DockPanel>
  </Border>
</Window>
"@

#############################################
############### Window Setup #################
#############################################
# Create a new XML node reader for reading the XAML content
$readerformCodeSigning = New-Object System.Xml.XmlNodeReader $XAMLformCodeSigning

# Load the XAML content into a WPF window object using the XAML reader
[System.Windows.Window]$formCodeSigning = [Windows.Markup.XamlReader]::Load($readerformCodeSigning)

# Create Variables for all the controls in the XAML form
$XAMLformCodeSigning.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name ($_.Name) -Value $formCodeSigning.FindName($_.Name) -Scope Script }

#############################################
############### State + Helpers #############
#############################################
# Backing collection for the files-to-sign grid.
$Script:FilesCollection = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$dg_Files.ItemsSource = $Script:FilesCollection

# Currently selected signing certificate (X509Certificate2) or $null.
$Script:SelectedCertificate = $null

# Applies a certificate to the UI and validates it, reporting any problem in the status bar.
$Script:ApplyCertificate = {
  param($Certificate)

  $Script:SelectedCertificate = $Certificate
  if ($null -eq $Certificate) {
    $txt_Thumbprint.Text = ''
    $btn_View.IsEnabled = $false
    Set-StatusText -Target $txtblk_CertInfo -Message 'No certificate selected.' -Type 'Muted'
    return
  }

  $btn_View.IsEnabled = $true
  $txt_Thumbprint.Text = $Certificate.Thumbprint
  $subject = Get-CertCommonName -DistinguishedName $Certificate.Subject
  $expires = $Certificate.NotAfter.ToString('yyyy-MM-dd')

  $problem = Get-CertificateStatus -Certificate $Certificate
  if ($problem) {
    Set-StatusText -Target $txtblk_CertInfo -Message "$subject  |  $problem" -Type 'Danger'
    Set-StatusMessage -Message "Warning: $problem" -Type 'Danger'
  }
  else {
    Set-StatusText -Target $txtblk_CertInfo -Message "$subject  |  Valid for code signing  |  Expires $expires" -Type 'Success'
    Set-StatusMessage -Message "Selected certificate: $subject" -Type 'Success'
  }
}

# Adds file paths to the grid, skipping duplicates and paths that are not existing files.
$Script:AddFilesToList = {
  param([string[]]$Paths)

  $candidates = @($Paths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  if ($candidates.Count -eq 0) { return }
  $total = $candidates.Count

  # Reading each file's signature runs on the UI thread and can be slow (many files / network paths),
  # so surface a wait cursor and a per-file progress message that repaints instead of freezing silently.
  $restText = $txtblk_StatusBar.Text
  $restBrush = $txtblk_StatusBar.Foreground
  $restWeight = $txtblk_StatusBar.FontWeight
  $previousCursor = $formCodeSigning.Cursor
  $formCodeSigning.Cursor = [System.Windows.Input.Cursors]::Wait
  $accentBrush = $formCodeSigning.FindResource('Accent')

  $added = 0
  try {
    $index = 0
    foreach ($p in $candidates) {
      $index++
      $txtblk_StatusBar.Text = "Loading $index of $total file(s)..."
      $txtblk_StatusBar.Foreground = $accentBrush
      $txtblk_StatusBar.FontWeight = [System.Windows.FontWeights]::SemiBold
      # Flush the render queue so the message actually paints before the next (blocking) signature read.
      $formCodeSigning.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Render)

      if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { continue }
      $full = (Resolve-Path -LiteralPath $p).Path

      $exists = $false
      foreach ($f in $Script:FilesCollection) { if ($f.FullPath -eq $full) { $exists = $true; break } }
      if ($exists) { continue }

      $sig = Get-FileSignatureInfo -Path $full
      $signedValue = 'No'
      if ($null -ne $sig -and $null -ne $sig.SignerCertificate) {
        # Untrusted/unverified self-signed still counts as signed; only broken signatures show as Invalid.
        $signedValue = if ("$($sig.Status)" -in 'Valid', 'UnknownError', 'NotTrusted') { 'Yes' } else { 'Invalid' }
      }

      $Script:FilesCollection.Add([PSCustomObject]@{
          FileName     = [System.IO.Path]::GetFileName($full)
          FullPath     = $full
          Signed       = $signedValue
          Status       = 'Pending'
          StatusDetail = 'Pending'
        })
      $added++
    }
  }
  finally {
    $formCodeSigning.Cursor = $previousCursor
    # Restore the resting bar so the queued-count flash reverts to the correct baseline afterward.
    $txtblk_StatusBar.Text = $restText
    $txtblk_StatusBar.Foreground = $restBrush
    $txtblk_StatusBar.FontWeight = $restWeight
  }

  if ($added -gt 0) {
    Set-StatusMessage -Message "$($Script:FilesCollection.Count) file(s) queued." -Type 'Muted'
  }
}

#############################################
############## Event Handlers ###############
#############################################
#### Form Load ####
$formCodeSigning.Add_Loaded({
    try {
      # Convert the AppIcon byte array to an Icon and set as the form icon
      $WindowIconBitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
      $WindowIconBitmap.BeginInit()
      $WindowIconBitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($Script:WindowIconBase64)
      $WindowIconBitmap.EndInit()
      $WindowIconBitmap.Freeze()
      $formCodeSigning.Icon = $WindowIconBitmap
    }
    catch {
      # Write the error to the host but continue on. It's an icon, who cares.
      Write-Host "Error setting form icon: $_"
    }

    # Update Version Information
    $formCodeSigning.Title = "Code Signing Tool - Version $($ScriptVersion)"
    $MenuItem_Version.Header = "Version $($ScriptVersion)"
    $txtblk_TitleVersion.Text = " $($ScriptVersion)"

    # Defer the update check until the window has rendered and come to the foreground.
    $formCodeSigning.Dispatcher.InvokeAsync({
        Start-BackgroundUpdateCheck
      }, [System.Windows.Threading.DispatcherPriority]::ApplicationIdle) | Out-Null

    # Pre-fill from parameters. Cheap field updates happen now; the certificate store lookup and
    # per-file signature reads are deferred to Background priority so the window paints first.
    if (-not [string]::IsNullOrWhiteSpace($TimestampServer)) {
      $txt_TimestampServer.Text = $TimestampServer
    }

    if (-not [string]::IsNullOrWhiteSpace($Thumbprint)) {
      $txt_Thumbprint.Text = $Thumbprint
      # A SHA-1 thumbprint is 40 hex characters once separators/spaces are stripped.
      if ((($Thumbprint -replace '[^0-9A-Fa-f]', '').Length) -ne 40) {
        Set-StatusText -Target $txtblk_CertInfo -Message "Invalid thumbprint  |  must be 40 hexadecimal characters" -Type 'Danger'
      }
    }

    if ((-not [string]::IsNullOrWhiteSpace($Thumbprint)) -or $Path) {
      $formCodeSigning.Dispatcher.InvokeAsync({
          $cleanThumbprint = ($Thumbprint -replace '[^0-9A-Fa-f]', '').ToUpperInvariant()
          if ($cleanThumbprint.Length -eq 40) {
            $preCert = Get-SigningCertificateByThumbprint -Thumbprint $cleanThumbprint
            if ($null -ne $preCert) {
              & $Script:ApplyCertificate $preCert
            }
            else {
              Set-StatusText -Target $txtblk_CertInfo -Message "Certificate not found  |  not in CurrentUser or LocalMachine store" -Type 'Danger'
            }
          }
          if ($Path) {
            & $Script:AddFilesToList $Path
          }
        }, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
    }
  })

#### Button Handlers ####
$btn_Browse.add_Click({
    $selected = Show-CertificatePicker -Owner $formCodeSigning
    if ($null -ne $selected) {
      & $Script:ApplyCertificate $selected.Certificate
    }
  })

$btn_Create.add_Click({
    $created = Show-CertificateCreator -Owner $formCodeSigning
    if ($null -ne $created) {
      & $Script:ApplyCertificate $created
    }
  })

$btn_View.add_Click({
    if ($null -ne $Script:SelectedCertificate) {
      Show-CertificateInformation -Certificate $Script:SelectedCertificate -Owner $formCodeSigning | Out-Null
    }
  })

$btn_AddFiles.add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Multiselect = $true
    $dialog.Title = 'Select files to sign'
    $dialog.Filter = 'All files (*.*)|*.*'
    if ($dialog.ShowDialog() -eq $true) {
      & $Script:AddFilesToList $dialog.FileNames
    }
  })

$btn_RemoveFiles.add_Click({
    foreach ($item in @($dg_Files.SelectedItems)) {
      $Script:FilesCollection.Remove($item) | Out-Null
    }
    Set-StatusMessage -Message "$($Script:FilesCollection.Count) file(s) queued." -Type 'Muted'
  })

$btn_ClearFiles.add_Click({
    $Script:FilesCollection.Clear()
    Set-StatusMessage -Message 'File list cleared.' -Type 'Muted'
  })

# Enables the timestamp server field only when timestamping is turned on.
$chk_Timestamp.add_Checked({ $txt_TimestampServer.IsEnabled = $true })
$chk_Timestamp.add_Unchecked({ $txt_TimestampServer.IsEnabled = $false })

$dg_Files.add_PreviewDragOver({
    param($sender, $e)
    if ($e.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
      $e.Effects = [System.Windows.DragDropEffects]::Copy
    }
    else {
      $e.Effects = [System.Windows.DragDropEffects]::None
    }
    $e.Handled = $true
  })

$dg_Files.add_Drop({
    param($sender, $e)
    if ($e.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
      & $Script:AddFilesToList $e.Data.GetData([System.Windows.DataFormats]::FileDrop)
    }
  })

# Selection changes on mouse-down, so capture whether the clicked row was already the sole selection.
$dg_Files.add_PreviewMouseLeftButtonDown({
    param($sender, $e)
    $Script:RowWasSelectedOnDown = $false
    try {
      $dep = $e.OriginalSource -as [System.Windows.DependencyObject]
      while ($null -ne $dep -and $dep -isnot [System.Windows.Controls.DataGridCell]) {
        $dep = [System.Windows.Media.VisualTreeHelper]::GetParent($dep)
      }
      if ($null -eq $dep) { return }
      $item = $dep.DataContext
      if ($null -ne $item -and $dg_Files.SelectedItems.Count -eq 1 -and $dg_Files.SelectedItems.Contains($item)) {
        $Script:RowWasSelectedOnDown = $true
      }
    }
    catch { }
  })

# Clicking a Status cell shows the full detail that the column trims.
$dg_Files.add_PreviewMouseLeftButtonUp({
    param($sender, $e)
    try {
      $dep = $e.OriginalSource -as [System.Windows.DependencyObject]
      while ($null -ne $dep -and $dep -isnot [System.Windows.Controls.DataGridCell]) {
        $dep = [System.Windows.Media.VisualTreeHelper]::GetParent($dep)
      }
      # Clicking empty space (not a cell) clears the selection.
      if ($null -eq $dep) { $dg_Files.UnselectAll(); return }
      $header = "$($dep.Column.Header)"
      $item = $dep.DataContext
      if ($null -eq $item) { return }

      if ($header -eq 'Status') {
        if (-not [string]::IsNullOrWhiteSpace($item.StatusDetail)) {
          $statusValue = "$($item.Status)"
          $statusType = switch -Wildcard ($statusValue) {
            'Failed*' { 'Error'; break }
            '*untrusted*' { 'Warning'; break }
            'Signed*' { 'Success'; break }
            default { 'Info' }
          }
          Show-StatusWindow -Message $item.StatusDetail -Title "Status - $($item.FileName)" -Type $statusType -Owner $formCodeSigning | Out-Null
        }
      }
      elseif ($header -eq 'Signed') {
        $sig = Get-FileSignatureInfo -Path $item.FullPath
        if ($null -eq $sig -or $null -eq $sig.SignerCertificate) {
          Set-StatusMessage -Message "$($item.FileName) is not signed." -Type 'Muted'
          return
        }
        Show-CertificateInformation -Certificate $sig.SignerCertificate -Signature $sig -FileName $item.FileName -FilePath $item.FullPath -Owner $formCodeSigning | Out-Null
      }
      elseif ($Script:RowWasSelectedOnDown -and [System.Windows.Input.Keyboard]::Modifiers -eq [System.Windows.Input.ModifierKeys]::None) {
        # Clicking the already-selected row again clears the selection.
        $dg_Files.UnselectAll()
      }
    }
    catch { }
  })

$btn_Sign.add_Click({
    $problem = Get-CertificateStatus -Certificate $Script:SelectedCertificate
    if ($problem) {
      Set-StatusMessage -Message "Cannot sign: $problem" -Type 'Danger'
      return
    }
    if ($Script:FilesCollection.Count -eq 0) {
      Set-StatusMessage -Message 'Add one or more files to sign.' -Type 'Accent'
      return
    }

    $timestamp = if ($chk_Timestamp.IsChecked) { $txt_TimestampServer.Text.Trim() } else { '' }

    # Detect files that already carry a signature so the user can re-sign or skip them.
    $signedPaths = New-Object System.Collections.Generic.HashSet[string]
    foreach ($entry in $Script:FilesCollection) {
      $existing = Get-FileSignatureInfo -Path $entry.FullPath
      if ($null -ne $existing -and $null -ne $existing.SignerCertificate) { [void]$signedPaths.Add($entry.FullPath) }
    }

    $certName = Get-CertCommonName -DistinguishedName $Script:SelectedCertificate.Subject
    $fileCount = $Script:FilesCollection.Count
    $fileWord = "file$(if ($fileCount -ne 1) { 's' })"

    $skipSigned = $false
    if ($signedPaths.Count -gt 0) {
      # Some files are already signed - let the user choose how to handle them.
      $message = "$fileCount $fileWord will be signed with:`n$certName`n`n" +
      "$($signedPaths.Count) of them already have a signature.`n`n" +
      "Re-sign all - replace every signature`nSign unsigned only - leave signed files untouched"
      $answer = Show-ConfirmWindow -Message $message -Title 'Confirm Signing' -Type 'Warning' `
        -Buttons @('Re-sign all', 'Sign unsigned only', 'Cancel') -Owner $formCodeSigning
      if ($answer -ne 'Re-sign all' -and $answer -ne 'Sign unsigned only') { return }
      if ($answer -eq 'Sign unsigned only') { $skipSigned = $true }
    }
    else {
      # Plain confirmation before signing when nothing is already signed.
      $message = "Sign $fileCount $fileWord with:`n$certName"
      $answer = Show-ConfirmWindow -Message $message -Title 'Confirm Signing' -Type 'Question' `
        -Buttons @('Sign', 'Cancel') -Owner $formCodeSigning
      if ($answer -ne 'Sign') { return }
    }

    $signed = 0
    $failed = 0
    $skipped = 0
    foreach ($entry in $Script:FilesCollection) {
      if ($skipSigned -and $signedPaths.Contains($entry.FullPath)) {
        $entry.Status = 'Skipped'
        $entry.StatusDetail = 'Skipped - file already has a signature.'
        $skipped++
        continue
      }
      $result = Invoke-CodeSignature -Path $entry.FullPath -Certificate $Script:SelectedCertificate -TimestampServer $timestamp
      $message = "$($result.Message)".Trim()
      $status = "$($result.Status)"
      $detail = if ([string]::IsNullOrWhiteSpace($message)) { $status } else { "$status`n`n$message" }
      if ($result.Success) {
        # SignerCertificate is set, so a signature was written. Windows reports NotTrusted
        # (untrusted publisher) or UnknownError (generic invalid/unverifiable signature) when
        # it can't build a trusted chain here - common for self-signed certs. See SignatureStatus.
        if ($status -in 'UnknownError', 'NotTrusted') {
          $entry.Status = 'Signed (untrusted)'
          $entry.StatusDetail = "$detail`n`nThe signature was applied, but Windows could not verify the signing certificate as trusted on this machine."
        }
        else {
          $entry.Status = 'Signed'
          $entry.StatusDetail = $detail
        }
        $entry.Signed = 'Yes'
        $signed++
      }
      else {
        $entry.Status = 'Failed'
        $entry.StatusDetail = $detail
        $failed++
      }
    }
    $dg_Files.Items.Refresh()

    $parts = @("Signed $signed")
    if ($skipped -gt 0) { $parts += "skipped $skipped" }
    if ($failed -gt 0) { $parts += "failed $failed" }
    $summary = "$($parts -join ', ') of $($Script:FilesCollection.Count) file(s)."
    Set-StatusMessage -Message $summary -Type $(if ($failed -gt 0) { 'Danger' } else { 'Success' })
  })

#### Right Click Menu Handlers ####
$MenuItem_Install.add_Click({
    Write-Host "Menu Item Install Clicked"
    $thumb = if ($null -ne $Script:SelectedCertificate) { $Script:SelectedCertificate.Thumbprint } else { $null }
    Install-RightClickMenu -Thumbprint $thumb | Out-Null
    if ($thumb) {
      Set-StatusMessage -Message "Right-click menu installed with the selected certificate." -Type 'Success'
    }
    else {
      Set-StatusMessage -Message "Right-click menu installed." -Type 'Success'
    }
  })

$MenuItem_Uninstall.add_Click({
    Write-Host "Menu Item Uninstall Clicked"
    Uninstall-RightClickMenu
    Set-StatusMessage -Message "Right-click menu removed." -Type 'Danger'
  })

$MenuItem_Open_RCM.add_Click({
    if (-not (Test-Path $Script:RightClickMenuFolderPath)) {
      New-Item -ItemType Directory -Path $Script:RightClickMenuFolderPath -ErrorAction SilentlyContinue | Out-Null
    }
    Invoke-Item -Path $Script:RightClickMenuFolderPath
  })

#### About Menu Handlers ####
$MenuItem_CheckForUpdates.add_Click({
    Write-Host "Checking for updates: [$($Script:ReleasesApiUrl)]"
    Start-BackgroundUpdateCheck -Manual
  })

$MenuItem_UpdateAvailable.add_Click({
    switch ($Script:UpdateChannel) {
      'PSGallery' {
        # Let the Gallery replace the installed copy, then relaunch from its location.
        try {
          Write-Host "Updating via PowerShell Gallery: [Update-Script CodeSigningTool -Force]"
          Update-Script -Name 'CodeSigningTool' -Force -ErrorAction Stop
          $installed = Get-InstalledScript -Name 'CodeSigningTool' -ErrorAction SilentlyContinue
          $updatedPath = if ($installed) { Join-Path $installed.InstalledLocation $Script:ScriptName } else { $PSCommandPath }
          Restart-Script -ScriptPath $updatedPath
        }
        catch {
          Write-Host "PSGallery update failed: $($_.Exception.Message)"
          Open-ReleasePage
        }
      }
      'LooseFile' {
        # Replace the launched .ps1 in place, then relaunch; fall back to the releases page on failure.
        if ($Script:LatestReleaseTag -and (Update-ScriptFile -ScriptPath $PSCommandPath -Tag $Script:LatestReleaseTag)) {
          Restart-Script -ScriptPath $PSCommandPath
        }
        else {
          Open-ReleasePage
        }
      }
      'RightClick' {
        # Refresh the LOCALAPPDATA copy and menu entries in place, then relaunch from there.
        if ($Script:LatestReleaseTag -and (Update-ScriptFile -ScriptPath $PSCommandPath -Tag $Script:LatestReleaseTag)) {
          $thumb = if ($null -ne $Script:SelectedCertificate) { $Script:SelectedCertificate.Thumbprint } else { $null }
          $updatedPath = Install-RightClickMenu -Thumbprint $thumb
          Restart-Script -ScriptPath $updatedPath
        }
        else {
          Open-ReleasePage
        }
      }
      default {
        # Web (and any failure): open the releases page.
        Open-ReleasePage
      }
    }
  })

#### Title Bar Handlers ####
$titlebar.add_MouseLeftButtonDown({
    try { $formCodeSigning.DragMove() } catch { }
  })

$titlebar_Minimize.add_Click({
    $formCodeSigning.WindowState = [System.Windows.WindowState]::Minimized
  })

$titlebar_Close.add_Click({
    $formCodeSigning.Close()
  })

# Set the PowerShell Window Title
$Host.UI.RawUI.WindowTitle = "Code Signing Tool"

#Show the WPF Window
$formCodeSigning.Add_ContentRendered({
    $formCodeSigning.Activate()
    # Toggling Topmost raises the z-order without leaving the window pinned on top.
    $formCodeSigning.Topmost = $true
    $formCodeSigning.Topmost = $false
    $formCodeSigning.Focus() | Out-Null
  })
$formCodeSigning.WindowStartupLocation = "CenterScreen"
$formCodeSigning.ShowDialog() | Out-Null
