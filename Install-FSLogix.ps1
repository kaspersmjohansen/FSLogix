#Requires -RunAsAdministrator
<#
*************************************************************************************************************************************
Name:               Install-FsLogix
Author:             Kasper Johansen
Company:            edgemo
Contact:            kjo@edgemo.com
Last modified by:   Kasper Johansen
Last modified Date: 15-10-2018


*************************************************************************************************************************************

.SYNOPSIS
    Install FSLogix Apps Suite

.DESCRIPTION
    IInstall FSLogix Apps Suite with either the builtin trial key or an actual product key.

.PARAMETER Agent
    Installs the FSLogix Apps Services Agent

.PARAMETER RuleEditor
    Installs the FSLogix Rule Editor

.PARAMETER JavaRuleEditor
    Installs the FSLogix Java Rule Editor

.PARAMETER ProductKey
    Applies a product key. If not specified, the builtin trial key is applied. 
    This switch only applies to the FSLogix Apps Service Agent, not the consoles.

.PARAMETER LogDir
    Configures a directory for the PowerShell transcription log files. The default folder for the log files is C:\Windows\temp

.EXAMPLES
    Install FSLogix Apps Service Agent:
            Install-FSLogix -Agent

    Install FSLogix RuleEditor:
            Install-FSLogix -RuleEditor

    Install FSLogix Java RuleEditor:
            Install-FSLogix -JavaRuleEditor

    Install FSLogix Apps Service Agent with alternate setup log directory:
            Install-FSLogix -Agent -LogDir C:\LogFiles

    Install FSLogix Apps Service Agent with a product key:
            Install-FSLogix -Agent -ProductKey "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"

#************************************************************************************************************************************
#>

# Script parameters
Param(
    [switch]$Agent,
    [switch]$RuleEditor,
    [switch]$JavaRuleEditor,
    [string]$ProductKey,
    [string]$LogDir = "$env:SystemRoot\Temp" 
    )

function Install-FSLogix ($Agent,$RuleEditor,$JavaRuleEditor,$ProductKey,$LogDir)
    {
        # Installer executable file names
        $AgentInstaller = "FSLogixAppsSetup.exe"
        $RuleEditorInstaller = "FSLogixAppsRuleEditorSetup.exe"
        $JavaRuleEditorInstaller = "FSLogixAppsJavaRuleEditorSetup.exe"

            # Install switches
            $Switches = "/install /quiet /norestart"
            
                # Get script execution directory
                $InstallDir = (Get-Location).Path
                Push-Location $InstallDir
                cd..
                cls
        
        If ($Agent)
        {
        # Get OS variable
        $OS = (Get-WmiObject Win32_OperatingSystem).Caption
        
        # Start time measuring and transcription
        $LogPS = $LogDir + "\Install-FSLogix-Agent.log"
        $startDTM = (Get-Date)
        Start-Transcript $LogPS

            # Install FSLogix Agent
            Write-Output "Installing FSLogix Agent" -Verbose
                            
                # Install FSLogix Agent with product key
                If (!([string]::IsNullOrWhiteSpace($ProductKey)))
                {
                    $Switches = $Switches+" "+"ProductKey=$ProductKey"
                    Start-Process -Wait ".\Source\x64\Release\$AgentInstaller" -ArgumentList $Switches -PassThru
                                        
                }
                else
                {
                    Start-Process -Wait ".\Source\x64\Release\$AgentInstaller" -ArgumentList $Switches -PassThru
                }

                # Windows Search Roaming registry fix
                If (!(Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows Search" -Name "CoreCount" -ErrorAction SilentlyContinue))
                {
                    Write-Output "Windows Search registry fix" -Verbose
                    New-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows Search" -Name "CoreCount" -Value "1" -Type DWORD -Verbose
                }
                else
                {
                    Write-Output "Windows Search registry fix exists" -Verbose
                }

                # Activate Windows Search Roaming in FSLogix Agent
                If (!(Get-ItemProperty -Path "HKLM:SOFTWARE\FSLogix\Apps" -Name "RoamSearch" -ErrorAction SilentlyContinue))
                {
                    Write-Output "Enabling FSLogix Search Roaming" -Verbose
                    If ($OS -Like "*Windows Server 2008 R2*" -or $OS -Like "*Windows Server 2012*" -or $OS -Like "*Windows Server 2016*" -or $OS -Like "*Windows Server 2019*")
                    {
                        New-ItemProperty -Path "HKLM:SOFTWARE\FSLogix\Apps" -Name "RoamSearch" -Value "2" -Type DWORD -Verbose
                    }
                        If ($OS -Like "*Windows 7*" -or $OS -Like "*Windows 8*" -or $OS -Like "*Windows 10*")
                        {
                            New-ItemProperty -Path "HKLM:SOFTWARE\FSLogix\Apps" -Name "RoamSearch" -Value "1" -Type DWORD -Verbose
                        }
                }
                else
                {
                    Write-Output "FSLogix Search Roaming enabled" -Verbose
                }

        $EndDTM = (Get-Date)
        Write-Output "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
        Stop-Transcript
        }

            If ($RuleEditor)
            {
            # Start time measuring and transcripting
            $LogPS = $LogDir + "\Install-FSLogix-RuleEditor.log"
            $startDTM = (Get-Date)
            Start-Transcript $LogPS

                # Install FSLogix Rule Editor
                Write-Output "Installing FSLogix RuleEditor" -Verbose
                Start-Process -Wait ".\Source\x64\Release\$RuleEditorInstaller" -ArgumentList $Switches -PassThru

            $EndDTM = (Get-Date)
            Write-Output "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
            Stop-Transcript
            }

                If ($JavaRuleEditor)
                {
                # Start time measuring and transcripting
                $LogPS = $LogDir + "\Install-FSLogix-JavaRuleEditor.log"
                $startDTM = (Get-Date)
                Start-Transcript $LogPS

                    # Install FSLogix Java RuleEditor
                    Write-Output "Installing FSLogix Java RuleEditor" -Verbose
                    Start-Process -Wait ".\Source\x64\Release\$JavaRuleEditorInstaller" -ArgumentList $Switches -PassThru
                    
                $EndDTM = (Get-Date)
                Write-Output "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
                Stop-Transcript
                }
    }

Install-FSLogix $Agent $RuleEditor $JavaRuleEditor $ProductKey $LogDir