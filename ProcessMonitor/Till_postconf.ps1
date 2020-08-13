param (
    [string]$WinAdmNm,
    [string]$WinAdmPass,
    [string]$WinUsrPass
)

New-LocalUser -Name "mpinstaller" -Password (ConvertTo-SecureString -String $WinUsrPass -AsPlainText -Force) -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword -Verbose -ErrorAction SilentlyContinue 
Add-LocalGroupMember -Group "Administrators" -Member "mpinstaller" -Verbose -ErrorAction SilentlyContinue 

#installing some missing component
Enable-WindowsOptionalFeature -Online -FeatureName WAS-NetFxEnvironment -All


#Installing the Sql Express
#choco install sql-server-express --version=14.1801.3958.1 -y


 # enable winrm
Enable-PSRemoting -SkipNetworkProfileCheck -Force
Start-Sleep 5

Enable-WSManCredSSP -Role Server -Force
Enable-WSManCredSSP -Role Client -DelegateComputer * -Force
New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation -Name AllowFreshCredentialsWhenNTLMOnly -Force
New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly -Name 1 -Value * -PropertyType String

$securePassword = ConvertTo-SecureString $WinAdmPass -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ".\$WinAdmNm", $securePassword
Invoke-Command -Authentication CredSSP -ScriptBlock {choco install sql-server-express --version=14.1801.3958.1 -y} -ComputerName $env:COMPUTERNAME -Credential $credential


