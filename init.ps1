$ErrorActionPreference = "Stop"
if (-not $env:TOKEN) { Write-Error "TOKEN is required"; exit 1 }
$macKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtWNNsQaEzch6vGUsyY4mnQCjsKyDfqW01e6RCUs6Gi fleet-mesh-mac"
function Add-KeyLine($Path, $Line) {
  if (-not (Test-Path $Path)) { New-Item -ItemType File -Path $Path -Force | Out-Null }
  $existing = Get-Content $Path -ErrorAction SilentlyContinue
  if ($existing -notcontains $Line) { Add-Content -Path $Path -Value $Line }
}
$ts = Get-Command tailscale -ErrorAction SilentlyContinue
if (-not $ts) {
  $installer = Join-Path $env:TEMP "tailscale-setup.exe"
  $urls = @("https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe", "https://ghfast.top/https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe")
  $installed = $false
  foreach ($url in $urls) {
    try {
      Invoke-WebRequest -Uri $url -OutFile $installer -TimeoutSec 30 -UseBasicParsing
      if ((Test-Path $installer) -and ((Get-Item $installer).Length -gt 1000000)) {
        Start-Process -FilePath $installer -ArgumentList "/quiet" -Wait
        $installed = $true
        break
      }
    } catch { }
  }
  if (-not $installed) {
    try { winget install --id Tailscale.Tailscale -e --silent --accept-package-agreements --accept-source-agreements } catch { }
  }
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
  $ts = Get-Command tailscale -ErrorAction SilentlyContinue
}
if (-not $ts) { $ts = Get-Command "C:\Program Files\Tailscale\tailscale.exe" -ErrorAction SilentlyContinue }
if (-not $ts) { Write-Error "tailscale install failed"; exit 1 }
& $ts.Source up --authkey=$env:TOKEN
$cap = Get-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0" -ErrorAction SilentlyContinue
if ($cap -and $cap.State -ne "Installed") { Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0" | Out-Null }
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service sshd -StartupType Automatic -ErrorAction SilentlyContinue
if (-not (Get-NetFirewallRule -Name "sshd" -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -Name "sshd" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}
$adminDir = "C:\ProgramData\ssh"
New-Item -ItemType Directory -Path $adminDir -Force | Out-Null
$adminKeys = Join-Path $adminDir "administrators_authorized_keys"
Add-KeyLine $adminKeys $macKey
if ($env:KEY) { Add-KeyLine $adminKeys $env:KEY }
& icacls $adminKeys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F" | Out-Null
Write-Output "done"
