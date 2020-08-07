#creating local users and sql logins

param (
    [string]$WinUsrPass,
    [string]$SqlSaPass
)

New-LocalUser -Name "mpinstaller" -Password (ConvertTo-SecureString -String $WinUsrPass -AsPlainText -Force) -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword -Verbose -ErrorAction SilentlyContinue 
Add-LocalGroupMember -Group "Administrators" -Member "mpinstaller" -Verbose -ErrorAction SilentlyContinue 



# Create SQL Server login for deployed user
$query = @"
    IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'$(hostname)\mpinstaller')
    BEGIN
        CREATE LOGIN [$(hostname)\mpinstaller] FROM WINDOWS WITH DEFAULT_DATABASE = [master], DEFAULT_LANGUAGE=[us_english]
    END     EXEC sp_addsrvrolemember @loginame = N'$(hostname)\mpinstaller', @rolename = N'sysadmin'
"@
      
Invoke-Sqlcmd -ServerInstance "localhost" -Query $query -QueryTimeout 0 -Username "supausr" -Password $SqlSaPass -Verbose



New-LocalUser -Name "mpreplication" -Password (ConvertTo-SecureString -String $WinUsrPass -AsPlainText -Force) -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword -Verbose -ErrorAction SilentlyContinue 
Add-LocalGroupMember -Group "Administrators" -Member "mpreplication" -Verbose -ErrorAction SilentlyContinue 
$query2 = @"
    IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'$(hostname)\mpreplication')
    BEGIN
        CREATE LOGIN [$(hostname)\mpreplication] FROM WINDOWS WITH DEFAULT_DATABASE = [master], DEFAULT_LANGUAGE=[us_english]
    END
"@
      
Invoke-Sqlcmd -ServerInstance "localhost" -Query $query2 -QueryTimeout 0 -Username "supausr" -Password $SqlSaPass -Verbose

 # Something to be done with the service
Grant-CPrivilege -Identity mpreplication -Privilege "SeServiceLogonRight" 
$service = Get-WmiObject -Class "Win32_Service" -ComputerName "localhost" -Filter "Name='SQLSERVERAGENT'"
$service.Change($null, $null, $null, $null, $null, $null, ".\mpreplication", $WinUsrPass)
Set-Service -Name SQLSERVERAGENT -StartupType Automatic
Restart-Service -ServiceName "SQLSERVERAGENT" -Force
