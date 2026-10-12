# First-boot configuration for Windows Server 2019 training VMs.
$ErrorActionPreference = 'Stop'

# These registry values disable Internet Explorer Enhanced Security Configuration
# for administrators and regular users, as required by the classroom notes.
$escKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}',
    'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}'
)
foreach ($key in $escKeys) {
    if (Test-Path $key) {
        Set-ItemProperty -Path $key -Name IsInstalled -Value 0
    }
}

# Ansible uses a local Windows account over HTTPS/NTLM. The GCP firewall rule
# accepts port 5986 only from IAP, and the local rule has the same source range.
Enable-PSRemoting -Force -SkipNetworkProfileCheck
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' `
    -Name LocalAccountTokenFilterPolicy -Value 1 -PropertyType DWord -Force | Out-Null
$httpsListener = Get-ChildItem WSMan:\localhost\Listener |
    Where-Object { $_.Keys -contains 'Transport=HTTPS' }
if (-not $httpsListener) {
    $certificate = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME `
        -CertStoreLocation 'Cert:\LocalMachine\My' -Type SSLServerAuthentication
    New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address '*' `
        -Port 5986 -Enabled $true -CertificateThumbPrint $certificate.Thumbprint -Force | Out-Null
}
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM
if (-not (Get-NetFirewallRule -Name 'ZabbixEduWinRMHTTPS' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'ZabbixEduWinRMHTTPS' -DisplayName 'Zabbix EDU WinRM HTTPS via IAP' `
        -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5986 `
        -RemoteAddress '35.235.240.0/20' | Out-Null
}
Write-Output 'Windows training bootstrap complete: IE ESC disabled; WinRM HTTPS ready.'
