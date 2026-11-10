<#
.SYNOPSIS
  Registers org-protocol:// links with Emacs for the current Windows user.

.DESCRIPTION
  Writes HKCU\Software\Classes\org-protocol so the browser hands
  org-protocol:// links to emacsclientw.exe, which passes them to the running
  Emacs. No administrator rights are needed. Emacs must be running and have
  called (server-start). Safe to re-run; run with -Uninstall to remove it.

.PARAMETER EmacsBin
  The Emacs bin directory containing emacsclientw.exe. Found on PATH or under
  Program Files / AppData\Local\Programs if omitted.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install-org-protocol.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install-org-protocol.ps1 -EmacsBin "C:\Program Files\Emacs\emacs-30.2\bin"
#>
param(
  [string]$EmacsBin,
  [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$key = 'HKCU:\Software\Classes\org-protocol'

if ($Uninstall) {
  if (Test-Path $key) { Remove-Item -Path $key -Recurse }
  Write-Host 'Removed the org-protocol:// handler.'
  return
}

function Find-EmacsBin {
  $onPath = Get-Command emacsclientw.exe -ErrorAction SilentlyContinue
  if ($onPath) { return Split-Path $onPath.Source }
  $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, (Join-Path $env:LOCALAPPDATA 'Programs')) |
    Where-Object { $_ -and (Test-Path (Join-Path $_ 'Emacs')) }
  foreach ($root in $roots) {
    # Newest version first, e.g. Emacs\emacs-30.2\bin before Emacs\emacs-29.4\bin.
    $hit = Get-ChildItem -Path (Join-Path $root 'Emacs') -Filter emacsclientw.exe -Recurse -ErrorAction SilentlyContinue |
      Sort-Object FullName -Descending | Select-Object -First 1
    if ($hit) { return $hit.DirectoryName }
  }
  return $null
}

if (-not $EmacsBin) { $EmacsBin = Find-EmacsBin }
if (-not $EmacsBin -or -not (Test-Path (Join-Path $EmacsBin 'emacsclientw.exe'))) {
  throw "emacsclientw.exe not found; pass -EmacsBin 'C:\path\to\emacs\bin'"
}
$client = Join-Path $EmacsBin 'emacsclientw.exe'
$command = '"{0}" -n "%1"' -f $client

# New-Item -Force recreates the key, so a re-run replaces an older registration.
New-Item -Path $key -Value 'URL:Org Protocol' -Force | Out-Null
New-ItemProperty -Path $key -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
New-Item -Path "$key\shell\open\command" -Value $command -Force | Out-Null
Write-Host "Registered org-protocol:// -> $command"
