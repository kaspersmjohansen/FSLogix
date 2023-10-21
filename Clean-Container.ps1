param(
      [Parameter(Mandatory = $true)]
      [ValidateScript( { If (Test-Path -Path $_ -PathType 'Leaf') { $True } Else { Throw "Cannot find log file directory: $_." } })]
      [string]$FsLogixRedirFile,
      [string]$LogPath = $env:USERPROFILE,
      [switch]$WhatIf
     )

function Clean-Container
    {
        # Start logging
        $LogPS = $LogPath + "\FSLogix Profile Cleanup.log"
        Start-Transcript -Path $LogPS

        # Get FSLogix Redirection.xml file content
        [xml]$RedirXML = Get-Content -Path $FsLogixRedirFile
        $ExcludedFolders = $RedirXML.FrxProfileFolderRedirection.Excludes.Exclude."#text"

        # Match content of FSLogix Redirection.xml file, and delete folders recursively
        If ($WhatIf)
        {
            $WhatIfPreference = $true
        }
                ForEach ($folder in $ExcludedFolders)
                {
                    If (Test-Path -Path "$env:USERPROFILE\$folder")
                    {
                        Remove-Item -Path "$env:USERPROFILE\$folder" -Recurse -Force -Verbose -ErrorAction SilentlyContinue
                    }
                }

        # Stop logging
        Stop-Transcript
    }

Clean-Container $FsLogixRedirFile $LogPath $WhatIf

[void][System.Console]::ReadKey($FALSE)