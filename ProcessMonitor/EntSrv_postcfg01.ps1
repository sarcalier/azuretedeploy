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


Set-Service -Name SQLSERVERAGENT -StartupType Automatic

 # Installing SSRS
 choco install ssrs --params "/Edition=Eval" -y --ignore-checksums
