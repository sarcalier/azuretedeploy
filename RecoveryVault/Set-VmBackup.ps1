<#
#### requires ps-version 3.0 ####
<#
.SYNOPSIS
<Overview of script>
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
   Creation Date:  Tuesday, February 11th 2020, 2:51:15 pm
   File: Set-VmBackup.ps1
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
#---------------------------------------------------------[Variables]--------------------------------------------------------
#Log File Info
#$sLogPath = 
#$sLogName = script_name.log
#$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#---------------------------------------------------------[Functions]--------------------------------------------------------

function Test-AzureConnected {

   #simple check true if Azure connection is in place, false if opposite
   try {[Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile}
   catch {return $false}
   return $true
}


#---------------------------------------------------------[Main]--------------------------------------------------------

#connecting Azure Accont if not yet happened
if(-not (Test-AzureConnected)) {Connect-AzAccount}

#displaying the list of availabel RSVs for given subscription
Write-Host "List of RSVs available:" -ForegroundColor Cyan
Get-AzRecoveryServicesVault | Format-Table Name,Location,ResourceGroupName -AutoSize

#input of the desired RSV
$TheChosenOneRSV =  Read-Host "Please paste in the NAME of target RSV"
$TheChosenOneRSVid = (Get-AzRecoveryServicesVault -Name $TheChosenOneRSV).id
$TheChosenOneRSVgroup = (Get-AzRecoveryServicesVault -Name $TheChosenOneRSV).ResourceGroupName
$TheChosenOneRSVlocation = (Get-AzRecoveryServicesVault -Name $TheChosenOneRSV).Location

#Recovery Policies Available
#Write-Host "Optet RSV contains the following Policies:"
#Get-AzRecoveryServicesBackupProtectionPolicy -VaultId $TheChosenOneRSVid | Where-Object {$_.WorkloadType -eq "AzureVM"} | Format-Table Name 

#input of desired policy
#$TheChosenOnePolicy = Read-Host "Please paste in the name of Backup Policy"

#getting the BackupPolicy for the RSV
$BkpPol = Get-AzRecoveryServicesBackupProtectionPolicy -VaultId $TheChosenOneRSVid | Where-Object {$_.WorkloadType -eq "AzureVM"} 
#$RSVResGroup = Get-AzRecoveryServicesVault -identity $TheChosenOneRSV

#listing VMs available
Write-Host "Please see below VMs available for chosen RSV location" -ForegroundColor Cyan
Get-AzVM -Location $TheChosenOneRSVlocation | Format-Table Name,ResourceGroupName,Location


#input the VM name
$TheChosenOneVMname = Read-Host "Please paste in the NAME of target VM"

Enable-AzRecoveryServicesBackupProtection -Name $TheChosenOneVMname -Policy $BkpPol  -VaultId $TheChosenOneRSVid -ResourceGroupName $TheChosenOneRSVgroup -whatif