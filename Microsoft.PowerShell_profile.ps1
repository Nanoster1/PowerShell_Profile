# Functions
function CheckAndInstallModule {
   param (
      [string] $ModuleName
   )
   
   if (-not (Get-Module -Name $ModuleName -ListAvailable)) {
      Write-Host "Installing $ModuleName..." -ForegroundColor Green
      Install-Module -Name $ModuleName -Scope CurrentUser
      Write-Host "Installed $ModuleName." -ForegroundColor Green
   }
}

function Connect-VPN {
   param (
      [string] $VpnName
   )
   
   if ($VpnName -eq [string]::Empty -or $null -eq $VpnName) {
      Write-Error "VPN name cannot be empty"
      return
   }

   [string] $passwdFile = "$VpnFolder/$VpnName.passwd-file"
   Write-Host "Passwd File: $passwdFile" -ForegroundColor Green
   Write-Host "Connecting to $VpnName..." -ForegroundColor Green
   Invoke-Command -ScriptBlock { nmcli connection up $VpnName passwd-file $passwdFile } | Write-Output
   if ($LASTEXITCODE -ne 0) {
      Write-Error "Failed to connect to $VpnName"
   }
   else {
      Write-Host "Connected to $VpnName" -ForegroundColor Green
   }
}

function Disconnect-VPN {
   param (
      [string] $VpnName
   )
      
   if ($VpnName -eq [string]::Empty -or $null -eq $VpnName) {
      $nmcliOutput = nmcli connection show --active | Select-String -Pattern "vpn"
      $connections = $null -eq $nmcliOutput ? $null : $nmcliOutput.ToString().Split(" ")
      if ($connections.Count -eq 0) {
         Write-Host "No active VPN connections found." -ForegroundColor Red
         return
      }
      $VpnName = $connections[0]
   }

   Write-Host "Disconnecting from $VpnName..." -ForegroundColor Green
   Invoke-Command -ScriptBlock { nmcli connection down $VpnName } | Write-Output
   if ($LASTEXITCODE -ne 0) {
      Write-Error "Failed to disconnect from $VpnName"
   }
   else {
      Write-Host "Disconnected from $VpnName" -ForegroundColor Green
   }
}

# Aliases
Set-Alias -Name cvpn -Value Connect-VPN
Set-Alias -Name dvpn -Value Disconnect-VPN

# Filters
filter Skip-Null { $_ | Where-Object { $_ } }

#Check Modules
CheckAndInstallModule -ModuleName "Microsoft.PowerShell.UnixTabCompletion"
CheckAndInstallModule -ModuleName "IPv4Toolbox"

# Import Modules
Import-PSUnixTabCompletion
Import-Module -Name "IPv4Toolbox"

# Base Variables
Set-Variable PROFILE -Option ReadOnly -Value $PSCommandPath -ErrorAction Ignore

#! PSReadline configuration
# Set shortcuts
Set-PSReadLineOption -EditMode Windows
# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key Alt+Enter -Function AddLine

# Encoding
[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding("utf-8")

# Autocompletion for arrow keys
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
   param($commandName, $wordToComplete, $cursorPosition)
   dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
   }
}

#Oh-my-posh configuration
Set-Variable OhMyPoshFolder -Option ReadOnly -Value "$HOME/.oh-my-posh" -ErrorAction Ignore
Set-Variable OhMyPoshThemes -Option ReadOnly -Value "$OhMyPoshFolder/themes" -ErrorAction Ignore
oh-my-posh init pwsh --config "$OhMyPoshThemes/default.json" | Invoke-Expression 

# vs-code configuration 
if ($env:TERM_PROGRAM -eq "vscode") { . "$(code --locate-shell-integration-path pwsh)" }

# Network-Manager configuration
Set-Variable VpnFolder -Option ReadOnly -Value "$HOME/.vpn" -ErrorAction Ignore