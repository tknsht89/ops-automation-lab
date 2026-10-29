#Requires -Version 5.1
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$logDir = Join-Path $env:LOCALAPPDATA 'WindowsMaintenance\Logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$log = Join-Path $logDir ((Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt')
function Invoke-Step($Name, [scriptblock]$Action) {
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    try { & $Action } catch { Write-Warning $_.Exception.Message }
}
function Wait-Manual {
    Read-Host 'Finish the task in the app, then press Enter here. Enter also allows skipping; completion is not verified' | Out-Null
}
function Open-Browser($Executable, $RelativePath, $Url) {
    $paths = @()
    $command = Get-Command $Executable -ErrorAction SilentlyContinue
    if ($command) { $paths += $command.Source }
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA)) {
        if ($root) { $paths += Join-Path $root $RelativePath }
    }
    $path = $paths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if (-not $path) { throw "Browser not found. Open manually: $Url" }
    Start-Process -FilePath $path -ArgumentList $Url
}
function Open-StartApp($Pattern) {
    $app = Get-StartApps | Where-Object { $_.Name -match $Pattern } | Select-Object -First 1
    if (-not $app) { throw "App not found: $Pattern. Open it from Start manually." }
    Start-Process explorer.exe -ArgumentList ('shell:AppsFolder\' + $app.AppID)
}
Start-Transcript -Path $log | Out-Null
try {
    Write-Host 'Windows Maintenance - semi-automated publication edition'
    Write-Host 'Save your work. This script does not force-close apps, restart Windows, or directly delete files.'
    Write-Host 'Updates can change software. Store, browser final checks, SupportAssist and PC Manager require user interaction.'
    if ((Read-Host 'Type Y to start') -ne 'Y') { return }
    Invoke-Step 'Windows Update' {
        Import-Module PSWindowsUpdate -ErrorAction Stop
        $updates = @(Get-WindowsUpdate -ErrorAction Stop)
        if ($updates.Count -eq 0) { Write-Host 'No updates returned by this search.' } else {
            $updates | Format-Table -AutoSize | Out-Host
            Write-Host 'Review candidates, including any drivers. A new search during installation may return different candidates.'
            if ((Read-Host 'Type Y to install all updates returned by the installation search') -eq 'Y') {
                Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -ErrorAction Stop | Format-Table -AutoSize | Out-Host
            } else { Write-Host 'Installation skipped.' }
        }
    }
    Invoke-Step 'WinGet application updates' {
        & winget upgrade --all
        Write-Host ('WinGet exit code: ' + $LASTEXITCODE)
        Write-Host 'Review individual results. Unknown versions and unsupported applications are not covered.'
    }
    Invoke-Step 'Defender definitions and quick scan' {
        Update-MpSignature -ErrorAction Stop
        Start-MpScan -ScanType QuickScan -ErrorAction Stop
        Get-MpComputerStatus | Select-Object AntivirusSignatureLastUpdated, QuickScanStartTime, QuickScanEndTime | Format-List | Out-Host
        Write-Host 'Check Windows Security / Protection history for findings and actions.'
    }
    Invoke-Step 'Edge update check' {
        Open-Browser 'msedge.exe' 'Microsoft\Edge\Application\msedge.exe' 'edge://settings/help'
        Write-Host 'Wait for the browser check. Save work and relaunch manually if requested.'
        Wait-Manual
    }
    Invoke-Step 'Chrome update check' {
        Open-Browser 'chrome.exe' 'Google\Chrome\Application\chrome.exe' 'chrome://settings/help'
        Write-Host 'Wait for the browser check. Save work and relaunch manually if requested.'
        Wait-Manual
    }
    Invoke-Step 'Optional Windows updates - manual' {
        Start-Process 'ms-settings:windowsupdate-optionalupdates'
        Wait-Manual
    }
    Invoke-Step 'Microsoft Store updates - manual' {
        Start-Process 'ms-windows-store://downloadsandupdates'
        Wait-Manual
    }
    Invoke-Step 'Dell SupportAssist - manual' {
        Open-StartApp '^Dell SupportAssist$'
        Write-Host 'Start the entire-PC scan and review results in the app.'
        Wait-Manual
    }
    Invoke-Step 'PC Manager - manual' {
        Open-StartApp 'PC Manager'
        Write-Host 'Run Boost, Health check and Deep cleanup. Review deletion targets and app-closing prompts yourself.'
        Wait-Manual
    }
    Write-Host "`nWorkflow ended. This does not certify success of every task or absence of threats."
    Write-Host 'Review output and app results. Save work and restart manually if required.'
    Write-Host ('Local transcript: ' + $log)
} finally {
    Stop-Transcript | Out-Null
}
