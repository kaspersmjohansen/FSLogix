﻿<#
***************************************************************************************************************************************
Name:               Create-ProfileShare
Author:             Kasper Johansen
Website:            https://virtualwarlock.net
Last modified by:   Kasper Johansen
Last modified Date: 07-02-2021

Change notes:
07-02-2021 - Implemented the recommended FSLogix share permissions. Change is on line 98. 
             The original configuration is commented out on line 97 - it will be removed at some point.


***************************************************************************************************************************************

.SYNOPSIS
    Create windows profile share with recommended permissions.

.DESCRIPTION
    This script creates a windows profile share with the recommended permission for security locked down profiles as per Microsoft
    See more here: https://technet.microsoft.com/en-us/library/jj649079(v=ws.11).aspx

    The script can also create an FSLogix profile/office container share with the recommended NTFS security permissions.

    The script should be executed on the file server where the profile share is to be created. 
    If the specified profile folder does not exist, the script creates it.
    
    This script requires administrative privileges and has been tested on Windows Server 2016 and Windows Server 2019.

.PARAMETER SharePath
    The full path to the profile folder on the file server - eg. E:\Profiles

.PARAMETER ShareGroup
    The local or Active Directory group to grant share permission. 
    If not specified, the default group, which is "Everyone" is configured.

.PARAMETER NTFSGroup
    The local or Active Directory group to grant NTFS permission. 
    If not specified, the default local group, which is "Users" is configured.

.SWITCH FSLogix
    If specified the recommended FSLogix share permissions are configured:
    https://docs.microsoft.com/en-us/fslogix/fslogix-storage-config-ht

.EXAMPLES
    Create a profile share on E:\ in the folder Profiles with a share name Profiles$:
            Create-ProfileShare -SharePath E:\Profiles -ShareName Profiles$

    Create a profile share on E:\ in the folder Profiles with a share name Profiles$ with a share name Profiles$ 
    and the Active Directy group CitrixUsers is granted share access
                Create-ProfileShare -SharePath E:\Profiles -ShareName Profiles$ -ShareGroup CitrixUsers

    Create a profile share on E:\ in the folder Profiles with a share name Profiles$ with a share name Profiles$ 
    and the Active Directy group CitrixUsers is granted share access and NTFS security permissions
                Create-ProfileShare -SharePath E:\Profiles -ShareName Profiles$ -ShareGroup CitrixUsers -NTFSGroup CitrixUsers

    Create a profile share on E:\ in the folder Profiles with a share name Profiles$ 
    and the NTFS security permissions for FSLogix is added:
            Create-ProfileShare -SharePath E:\Profiles -ShareName Profiles$ -FSLogix

***************************************************************************************************************************************
#>

#Requires -Version 3.0
#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory = $true)]
    [string]$SharePath,
    [Parameter(Mandatory = $true)]
    [string]$ShareName,
    [string]$ShareGroup = "Everyone",
    [string]$NTFSGroup = "Users",
    [switch]$FSLogix
    )

function Create-ProfileShare ($SharePath, $ShareName, $ShareGroup, $NTFSGroup, $FSLogix)
{
    # Test if share path exists
    If (!(Test-Path -Path $SharePath))
    {
        New-Item -Path $SharePath -ItemType Directory
    }
        # Create new share
        New-SmbShare -Path $SharePath -Name $ShareName -CachingMode None -FullAccess $ShareGroup

            # Configure NTFS security permissions for FSLogix container share
            If ($FSLogix)
            {
                Get-Acl $SharePath
                $acl = Get-Acl $SharePath
                $acl.SetAccessRuleProtection($True, $False)
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                $acl.AddAccessRule($rule)
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("System","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                $acl.AddAccessRule($rule)
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Creator OWner","FullControl", "ContainerInherit, ObjectInherit", "InheritOnly", "Allow")
                $acl.AddAccessRule($rule)
                #$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$NTFSGroup","ReadData, CreateFiles, AppendData, Synchronize", "None", "None", "Allow")
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$NTFSGroup","Modify", "None", "None", "Allow")
                $acl.AddAccessRule($rule)
                Set-Acl $SharePath $acl
            }
                # Configure NTFS security permissions for the profile share
                else
                {
                        Get-Acl $SharePath
                        $acl = Get-Acl $SharePath
                        $acl.SetAccessRuleProtection($True, $False)
                        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                        $acl.AddAccessRule($rule)
                        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("System","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                        $acl.AddAccessRule($rule)
                        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Creator OWner","FullControl", "ContainerInherit, ObjectInherit", "InheritOnly", "Allow")
                        $acl.AddAccessRule($rule)
                        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$NTFSGroup","ReadData, AppendData, Synchronize", "None", "None", "Allow")
                        $acl.AddAccessRule($rule)
                        Set-Acl $SharePath $acl
                }
}

Create-ProfileShare $SharePath $ShareName $ShareGroup $NTFSGroup $FSLogix