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


# Adding System account to SA
#$query2 = @"
#    ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM]
#"@
#      
#Invoke-Sqlcmd -ServerInstance "localhost" -Query $query2 -QueryTimeout 0 -Username "supausr" -Password $SqlSaPass -Verbose


# Adding system account once again?
#$query3 = @"
#    IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NT AUTHORITY\SYSTEM' AND IS_SRVROLEMEMBER ('sysadmin', name) = 1)
#    EXEC sp_addsrvrolemember @loginame = N'NT AUTHORITY\SYSTEM', @rolename = N'sysadmin'
#"@
#Invoke-Sqlcmd -ServerInstance "localhost" -Query $query3 -Username "supausr" -Password $SqlSaPass -Verbose


Set-Service -Name SQLSERVERAGENT -StartupType Automatic

# no idea, maybe service restart would help here
#Restart-Service -Name 'MSSQLSERVER' -Force

 # Installing SSRS
 choco install ssrs --params "/Edition=Eval" -y --ignore-checksums


# Wait for some time just in case
Start-Sleep -Seconds 10


 # Configure the SSRS
 
function Get-ConfigSet()
{
	return Get-WmiObject –namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14\Admin" -class MSReportServer_ConfigurationSetting -ComputerName localhost
}


# Retrieve the current configuration
$configset = Get-ConfigSet

#$configset

If (! $configset.IsInitialized)
{
	# Get the ReportServer and ReportServerTempDB creation script
	[string]$dbscript = $configset.GenerateDatabaseCreationScript("ReportServer", 1033, $false).Script

	# Import the SQL Server PowerShell module
	Import-Module sqlps -DisableNameChecking | Out-Null

	# Establish a connection to the database server (localhost)
	$conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList $env:ComputerName
	$conn.ApplicationName = "SSRS Configuration Script"
	$conn.StatementTimeout = 0
	$conn.Connect()
	$smo = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $conn

	# Create the ReportServer and ReportServerTempDB databases
	$db = $smo.Databases["master"]
	$db.ExecuteNonQuery($dbscript)

	# Set permissions for the databases
	$dbscript = $configset.GenerateDatabaseRightsScript($configset.WindowsServiceIdentityConfigured, "ReportServer", $false, $true).Script
	$db.ExecuteNonQuery($dbscript)

	# Set the database connection info
	$configset.SetDatabaseConnection("(local)", "ReportServer", 2, "", "")

	$configset.SetVirtualDirectory("ReportServerWebService", "ReportServer", 1033)
	$configset.ReserveURL("ReportServerWebService", "http://+:80", 1033)

	# For SSRS 2016-2017 only, older versions have a different name
	$configset.SetVirtualDirectory("ReportServerWebApp", "Reports", 1033)
	$configset.ReserveURL("ReportServerWebApp", "http://+:80", 1033)

	$configset.InitializeReportServer($configset.InstallationID)

	# Re-start services?
	$configset.SetServiceState($false, $false, $false)
	Restart-Service $configset.ServiceName
	$configset.SetServiceState($true, $true, $true)

	# Update the current configuration
	$configset = Get-ConfigSet

	# Output to screen
	$configset.IsReportManagerEnabled
	$configset.IsInitialized
	$configset.IsWebServiceEnabled
	$configset.IsWindowsServiceEnabled
	$configset.ListReportServersInDatabase()
	$configset.ListReservedUrls();

	$inst = Get-WmiObject –namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14" `
		-class MSReportServer_Instance -ComputerName localhost

	$inst.GetReportServerUrls()
}
