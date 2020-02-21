<#
#### requires ps-version 5.0 ####
<#
.SYNOPSIS
Creates Recovery Volume with weekly backup schedule, basing on default MS ARM templates
.DESCRIPTION
<Brief description of script>
.PARAMETER <Parameter_Name>
<Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
<Inputs if any, otherwise state None>
.OUTPUTS
<Outputs if anything is generated>
.NOTES
   Version:        0.1
   Author:         Ruslan Gatiyatullin
   Creation Date:  Monday, February 10th 2020, 9:05:01 am
   File: Add-AzureRVaultWeeklyBkp.ps1
   Copyright (c) 2020 <<company>>
HISTORY:
Date      	          By	Comments
----------	          ---	----------------------------------------------------------

.LINK
   <<website>>

.COMPONENT
 Required Modules:
   Az.Accounts
   Az.RecoveryServices
   Az.Compute

.LICENSE
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the Software), to deal
in the Software without restriction, including without limitation the rights
to use copy, modify, merge, publish, distribute sublicense and /or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 
.EXAMPLE
<Example goes here. Repeat this attribute for more than one example>
#
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action 
#$ErrorActionPreference = 'SilentlyContinue'

#simple check for required PS modules
Install-Module Az.Accounts
Install-Module Az.RecoveryServices
#Install-Module Az.Compute

#---------------------------------------------------------[Variables]--------------------------------------------------------
#Log File Info
#$sLogPath = 
#$sLogName = script_name.log
#$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName


$ArmTemplateRSVweekly =  "https://raw.githubusercontent.com/sarcalier/azuretedeploy/master/RecoveryVault/ArmTemplates/azuredeploy.json"
$ArmTemplateRSVweeklyparams = "https://raw.githubusercontent.com/sarcalier/azuretedeploy/master/RecoveryVault/ArmTemplates/azuredeploy.parameters.json"
$ArmTemplateRSVdaily = "https://raw.githubusercontent.com/sarcalier/azuretedeploy/master/RecoveryVault/ArmTemplates/azuredeploy_daily.json"
$ArmTemplateRSVdailyparams = "https://raw.githubusercontent.com/sarcalier/azuretedeploy/master/RecoveryVault/ArmTemplates/azuredeploy_daily.parameters.json"
#---------------------------------------------------------[Functions]--------------------------------------------------------


function Get-AzAccessToken {
   <#
   .SYNOPSIS
   Retrieve the cached Azure AccessToken (Bearer) from the current Powershell session and its current Azure Context

   .NOTES
   Thanks to Stephane Lapointe (https://www.linkedin.com/in/stephanelapointe/) for this script to get the Bearer Token from an existing Powershell session (https://gallery.technet.microsoft.com/scriptcenter/Easily-obtain-AccessToken-3ba6e593/view/Reviews)
   #>

   [CmdletBinding()]
   param ()

   $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
   if (-not $azProfile.Accounts.Count) {
       Write-Error 'Could not find a valid AzProfile, please run Connect-AzAccount'
       return
   }

   $currentAzureContext = Get-AzContext
   $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
   $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
   $token.AccessToken
}

function Test-AzureConnected {

   #simple check true if Azure connection is in place, false if opposite
   try {[Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile}
   catch {return $false}
   return $true
}


#---------------------------------------------------------[Main]--------------------------------------------------------

#connecting Azure Accont if not yet happened
if(-not (Test-AzureConnected)) {Connect-AzAccount}

#getting the list of currently available resource groups
Write-Host "The list of resource groups present:" -ForegroundColor Cyan
Get-AzResourceGroup | Format-Table ResourceGroupName,Location

#getting group to deploy vault in
$GroupName = Read-Host "Type in Resource Group name to deploy the Recovery Service Vault to" 

#getting recovery plan schedule
$RsvBkpPlan = Read-Host "Type '1' for DAILY backup shedule, '2' for WEEKLY, '3' for CUSRTOMIZABLE"
switch ($RsvBkpPlan) {
   '1' {
      Write-Host "Creating RSV with DAILY backup schedule" -ForegroundColor Cyan
      $DeplOut = New-AzResourceGroupDeployment -ResourceGroupName $GroupName -TemplateUri $ArmTemplateRSVdaily -TemplateParameterUri $ArmTemplateRSVdailyparams #-WhatIf
   }
   '2' {
      Write-Host "Creating RSV with WEEKLY backup schedule" -ForegroundColor Cyan
      $DeplOut = New-AzResourceGroupDeployment -ResourceGroupName $GroupName -TemplateUri $ArmTemplateRSVweekly -TemplateParameterUri $ArmTemplateRSVweeklyparams #-WhatIf
   }
   '3' {
      Write-Host "Redirecting to customizable deployment" -ForegroundColor Cyan
      Start-Process "https://azuredeploy.net/?repository=https://github.com/sarcalier/azuretedeploy/tree/master"
   }
   Default {
      Write-Host "Incorrect value, exiting, bye" -ForegroundColor Red
      exit
   }
}

#getting the new RSV name
$NewRSVname = $DeplOut.Parameters.vaultName.Value

switch ($NewRSVname) {
   $null {
      Write-Host "Recovery Service Volume deployment failed" -ForegroundColor Red
      exit
   }
   Default {Write-Host "Recovery Service Volume name: $($NewRSVname)" -ForegroundColor Cyan}
}

#removing the default backup policy
Remove-AzRecoveryServicesBackupProtectionPolicy -VaultId (Get-AzRecoveryServicesVault -Name $NewRSVname).id -Name "DefaultPolicy" -Confirm: $false -Force
