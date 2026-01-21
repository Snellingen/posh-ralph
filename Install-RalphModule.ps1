[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SourcePath = (Join-Path $PSScriptRoot 'src/PoshRalph'),

    [Parameter(Mandatory = $false)]
    [ValidateSet('CurrentUser','AllUsers')]
    [string]$Scope = 'CurrentUser',

    [Parameter(Mandatory = $false)]
    [string]$ModuleVersion,

    [switch]$Force
)

function Get-RalphModuleVersion {
    param([string]$ManifestPath)
    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Manifest not found at: $ManifestPath"
    }
    $data = Import-PowerShellDataFile -Path $ManifestPath
    if (-not $data.ModuleVersion) {
        throw "ModuleVersion missing in manifest: $ManifestPath"
    }
    return $data.ModuleVersion.ToString()
}

function Get-RalphTargetBasePath {
    param([string]$Scope)
    $isDesktop = $PSVersionTable.PSEdition -eq 'Desktop'

    if ($Scope -eq 'AllUsers') {
        if ($IsWindows) {
            # Windows PowerShell uses WindowsPowerShell/Modules; pwsh uses PowerShell/Modules
            $folder = if ($isDesktop) { 'WindowsPowerShell/Modules' } else { 'PowerShell/Modules' }
            return Join-Path $env:ProgramFiles $folder
        }
        return '/usr/local/share/powershell/Modules'
    }

    if ($IsWindows) {
        $documents = [Environment]::GetFolderPath('MyDocuments')
        $folder = if ($isDesktop) { 'WindowsPowerShell/Modules' } else { 'PowerShell/Modules' }
        return Join-Path $documents $folder
    }

    return Join-Path $HOME '.local/share/powershell/Modules'
}

if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
    throw "Source module path not found: $SourcePath"
}

$manifestPath = Join-Path $SourcePath 'PoshRalph.psd1'
if (-not $ModuleVersion) {
    $ModuleVersion = Get-RalphModuleVersion -ManifestPath $manifestPath
}

$targetBase = Get-RalphTargetBasePath -Scope $Scope
$targetPath = Join-Path $targetBase "PoshRalph/$ModuleVersion"

if (Test-Path -LiteralPath $targetPath) {
    if ($Force) {
        Remove-Item -LiteralPath $targetPath -Recurse -Force
    }
    else {
        throw "Module already exists at $targetPath. Use -Force to overwrite."
    }
}

New-Item -ItemType Directory -Force -Path $targetPath | Out-Null
Copy-Item -Path (Join-Path $SourcePath '*') -Destination $targetPath -Recurse -Force

$moduleManifest = Join-Path $targetPath 'PoshRalph.psd1'
if (-not (Test-Path -LiteralPath $moduleManifest -PathType Leaf)) {
    throw "Expected module manifest not found after copy: $moduleManifest"
}

Import-Module $moduleManifest -Force

Write-Host "Installed PoshRalph $ModuleVersion to $targetPath" -ForegroundColor Green
Write-Host "Verify: Get-Command -Module PoshRalph" -ForegroundColor Cyan
