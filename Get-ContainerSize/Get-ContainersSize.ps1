﻿#Requires -RunAsAdministrator
<#
*************************************************************************************************************************************
Name:               Get-ContainerSize
Author:             Kasper Johansen
Website:            https://virtualwarlock.net
Version:            1.0            
Last modified Date: 20-01-2020

*************************************************************************************************************************************

.SYNOPSIS
    This script expands VHD/VHDX files. It is created specifically for FSLogix Containers.

.DESCRIPTION
    This script can expand any existing FSLogix Containers (VHD/VHDX), retaining data but increaing the size of the VHD/VHDX
    and the volume/partion inside the VHD/VHDX.
    
    Running this script with a UNC path has not been tested, but it should be possible.
    
    The script has been tested on a Windows Server 2016/2019 file server only, 
    it's not guarenteed to work on older operating systems. 
    
    The script will obviously only be able to do it's thing while the FSLogix Container is not in use, 
    and the script requires administrative permissions.

    !!DISCLAIMER!!
    Run this script a your own risk. I cannot be held responsible if anything goes wrong like corrupt or damaged containers.
    Like anything else TEST, TEST and TEST some more, before releasing to production!

.PARAMETER $ContainerDir
    The local path to the share where any FSLogix Containers are stored.

.PARAMETER $ContainerSize
    The new size of the VHD/VHDX container in gigabytes.

.PARAMETER $ContainerType
    The FSLogix Container type, either Profile or O365.

.EXAMPLES
    Expand an existing FSLogix Profile Container to a total size of 40GB:
            Expand-Container -ContainerDir "E:\FSLogix\Profiles" -ContainerSize 40 -ContainerType Profile

*************************************************************************************************************************************
#>

param(
     [Parameter(Mandatory = $true)]
     [string]$ContainerDir,
     [Parameter(Mandatory = $true)][ValidateSet("Profile","O365")]
     [string]$ContainerType
     )

# Test if specified VHD/VHDX directory exists.
function Get-Container
    {
    $Dir = $ContainerDir
    
    If (!(Test-Path -Path $Dir))
    {
        Write-Host "$Dir does not exist"
        Break
    }
        else
        {
            Get-ChildItem -Path $Dir -Recurse -Include "*.VHD","*.VHDX"
        }    
    }

# Get the Profile Container or Office 365 Container volume
function Get-ContainerVolume
    {
        Get-Volume | where {($_.FileSystemLabel -like "$ContainerType-*")}
    }

# Get container size and amount of data within the container
function Get-ContainerSize
    {
        If (Get-Container -gt 0)
        {
            ForEach ($VHD in Get-Container)
            {

            [string][math]::Round(($VHD | Measure-Object -Property length -Sum).Sum / 1GB,2) + "GB"
            #$ContainerSize = [math]::Round(($VHD | Measure-Object -Property length -Sum).Sum / 1GB,2)
            #[string]$ContainerSize + "GB"

            # [math]::Round((get-item C:\windows\explorer.exe).Length/1Mb,2)
            #$DirSizeGB = "{0:N2}" -f (($DirArray | Measure-Object -property length -sum).sum / 1GB)
            #Mount-DiskImage -ImagePath $Container -NoDriveLetter -Verbose
            }
        }
    }

Get-ContainerSize $ContainerDir

# Mounts and expands the container
function Expand-ContainerPartition
    {
    param(
         $Container
         )
            Mount-DiskImage -ImagePath $Container -NoDriveLetter -Verbose
            ForEach ($Volume in Get-ContainerVolume)
                 {
                    $DiskNumber = Get-Disk | where {$_.Location -eq $VHDContainer} | select -ExpandProperty DiskNumber
                    $PartitionNumber = Get-Partition -DiskNumber $DiskNumber | select -ExpandProperty PartitionNumber
                    $MaxPartitionSize = (Get-PartitionSupportedSize -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber)
                    Resize-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -Size $MaxPartitionSize.SizeMax -Verbose
                 }
                        Dismount-DiskImage -ImagePath $Container -Verbose    
    }

function Expand-Container
    {
        Start-Transcript -Path "$PSScriptRoot\transcript.log"
        If (Get-Container -gt 0)
        {
            # Optimizes and defrags any VHD/VHDX files found
            ForEach ($VHD in Get-Container)
            {
                $VHDName = $VHD.Name                
                $VHDParentDir = $VHD.Directory | select -Unique
                $VHDContainer = $VHD.fullname
                                               
                # Break if differerencing disk is found
                If (Test-Path -Path "$VHDParentDir\RW.*")
                {
                    Write-Host "Differencing disk in use, compacting aborted"
                    Break
                }
                
                else
                    {
                        # Create diskpart configuration file for each VHD/VHDX
                        $DiskpartConfig = $VHD.Name+"-ExpandConfig.txt"
                        $DiskpartLog = $VHD.Name+"-diskpart.log"
                        Create-DiskpartConfig -DiskpartConfig $DiskpartConfig -DiskpartVHD $VHDContainer

                            try
                            {
                            Write-Host "Optimizing $VHD, please wait..." -Verbose
                            Defrag-Container -Container $VHDContainer
                
                                Write-Host "Expanding $VHD, please wait..." -Verbose
                                Start-Process -Wait "$env:windir\system32\diskpart.exe" -ArgumentList "/s $DiskpartConfig" -NoNewWindow -RedirectStandardOutput $DiskpartLog -Verbose
                                    
                                    Remove-Item -Path $DiskpartConfig -Verbose

                                        Write-Host "Expanding $VHD partition, please wait..." -Verbose
                                        Expand-ContainerPartition -Container $VHD

                            }
                            catch
                            {
                                Write-Output "$Error[0].Exception.GetType().FullName"
                                Write-Host "$VHD is currently in use"
                            }
                    }                
            }
        }
            else
            {
                Write-Host "No VHD or VHDX files exists in the specified location"
                Break
            }
        Stop-Transcript
    }

Expand-Container $ContainerDir $ContainerSize $ContainerType