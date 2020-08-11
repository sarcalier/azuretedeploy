param (
    [string]$WinAdmNm,
    [string]$WinAdmPass
)

#installing some missing component
Enable-WindowsOptionalFeature -Online -FeatureName WAS-NetFxEnvironment -All


#Installing the Sql Express
#choco install sql-server-express --version=14.1801.3958.1 -y


Enable-WSManCredSSP -Role Server -Force
Enable-WSManCredSSP -Role Client -DelegateComputer * -Force
New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation -Name AllowFreshCredentialsWhenNTLMOnly -Force
New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly -Name 1 -Value * -PropertyType String

$securePassword = ConvertTo-SecureString $WinAdmPass -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ".\$WinAdmNm", $securePassword
Invoke-Command -Authentication CredSSP -ScriptBlock {choco install sql-server-express --version=14.1801.3958.1 -y} -ComputerName . -Credential $credential