#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Removes Windows Security (SecHealthUI) and related inbox apps for every user.

.DESCRIPTION
    For each pattern, the script deprovisions the package (so new users do not
    get it) and removes it from every existing user. It marks the package as
    "deprovisioned" and "end of life" in the AppxAllUserStore, clears the
    non-removable policy via DISM, then removes the provisioned and installed
    packages.

.PARAMETER PackagePattern
    One or more substrings to match against package names. Defaults to
    'SecHealthUI'.

.PARAMETER Skip
    Substrings of packages to leave untouched even if they match a pattern.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File RemoveSecHealthApp.ps1
#>
[CmdletBinding()]
param(
    [string[]] $PackagePattern = @('SecHealthUI'),
    [string[]] $Skip = @()
)

$ErrorActionPreference = 'Continue'
$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'

# SIDs to mark end-of-life for: SYSTEM plus every real (S-1-5-21-*) account.
$users = @('S-1-5-18')
if (Test-Path $store) {
    $users += (Get-ChildItem $store -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -like '*S-1-5-21*' }).PSChildName
}

$provisioned = Get-AppxProvisionedPackage -Online
$installed   = Get-AppxPackage -AllUsers

function Test-Skip {
    param([string] $Name)
    foreach ($pattern in $Skip) {
        if ($Name -like "*$pattern*") { return $true }
    }
    return $false
}

foreach ($choice in $PackagePattern) {
    if ([string]::IsNullOrWhiteSpace($choice)) { continue }

    # --- Provisioned packages (the image / future users) ---
    foreach ($appx in @($provisioned | Where-Object { $_.PackageName -like "*$choice*" })) {
        if (Test-Skip $appx.PackageName) { continue }

        $packageName = $appx.PackageName
        $familyName  = ($installed | Where-Object { $_.Name -eq $appx.DisplayName }).PackageFamilyName
        Write-Verbose "Deprovisioning $packageName (family '$familyName')"

        if ($familyName) {
            New-Item "$store\Deprovisioned\$familyName" -Force | Out-Null
            foreach ($sid in $users) {
                New-Item "$store\EndOfLife\$sid\$packageName" -Force | Out-Null
            }
            & dism.exe /online /set-nonremovableapppolicy /packagefamily:$familyName /nonremovable:0 | Out-Null
        }
        Remove-AppxProvisionedPackage -PackageName $packageName -Online -AllUsers -ErrorAction SilentlyContinue | Out-Null
    }

    # --- Installed packages (existing users) ---
    foreach ($appx in @($installed | Where-Object { $_.PackageFullName -like "*$choice*" })) {
        if (Test-Skip $appx.PackageFullName) { continue }

        $fullName   = $appx.PackageFullName
        $familyName = $appx.PackageFamilyName
        Write-Verbose "Removing $fullName (family '$familyName')"

        New-Item "$store\Deprovisioned\$familyName" -Force | Out-Null
        foreach ($sid in $users) {
            New-Item "$store\EndOfLife\$sid\$fullName" -Force | Out-Null
        }
        & dism.exe /online /set-nonremovableapppolicy /packagefamily:$familyName /nonremovable:0 | Out-Null
        Remove-AppxPackage -Package $fullName -AllUsers -ErrorAction SilentlyContinue | Out-Null
    }
}
