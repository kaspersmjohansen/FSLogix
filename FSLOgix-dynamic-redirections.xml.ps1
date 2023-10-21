function buildlist($b, $p)
{
	if ($b -eq "Chrome")
	{
		$folders = "Cache", "Cached Theme Image", "JumpListIcons", "JumpListIconsOld", "Storage", "Local Storage", "Session Storage", "Storage", "GPUCache", "Sync Data", "blob_storage", "IndexedDB", "Application Cache", "Code Cache"
		foreach ($folder in $folders)
		{
			if (test-path (Join-Path $p $folder))
			{
				((join-path $p $folder) -split "$env:username\\")[1]
			}
		}
	}
	else
	{
		$folders = "cache2", "jumpListCache", "OfflineCache", "startupCache", "thumbnails"
		foreach ($folder in $folders)
		{
			if (test-path (Join-Path $p $folder))
			{
				((join-path $p $folder) -split "$env:username\\")[1]
			}
		}
	}
	
}

$redirection = "$env:localappdata\FSLogix\Redirections.xml"
$firefoxprofiles = (gci "$env:localappdata\mozilla\firefox\Profiles" | ?{ $_.psiscontainer }).fullname
$firefoxexcludes = @()
$chromeexcludes = @()
foreach ($fprof in $firefoxprofiles)
{
	$firefoxexcludes += buildlist -b firefox -p $fprof
}
$googleprofiles = (gci "$env:localappdata\Google\Chrome\User Data" | ?{ $_.psiscontainer -and ($_.name -eq "default" -or $_.name -like "profile*") }).fullname
foreach ($gprof in $googleprofiles)
{
	$chromeexcludes = buildlist -b chrome -p $gprof
}
$template = "<?xml version=`"1.0`"?>
<FrxProfileFolderRedirection ExcludeCommonFolders=`"128`">
	<Includes>
		<Include>AppData\Roaming\Microsoft\Excel\XLSTART\</Include>
        <Include>AppData\Roaming\Microsoft\Word\STARTUP</Include>
	</Includes>
	<Excludes>
		<Exclude Copy=`"0`">AppData\Roaming\Microsoft\Excel\</Exclude>
        <Exclude Copy=`"0`">AppData\Roaming\Microsoft\Word\</Exclude>"
$end = "`r`n</Excludes>
</FrxProfileFolderRedirection>"
if ($firefoxexcludes)
{
	foreach ($f in $firefoxexcludes)
	{
		$template += "`r`n<Exclude Copy=`"0`">" + $f + "</Exclude>"
	}
}
if ($chromeexcludes)
{
	foreach ($c in $chromeexcludes)
	{
		$template += "`r`n<Exclude Copy=`"0`">" + $c + "</Exclude>"
	}
}
$template += $end
$template | out-file $redirection -force