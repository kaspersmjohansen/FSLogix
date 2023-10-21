*****************’

function ConvertFrom-Hexa($hexstring)
{
    ($hexstring.Split(",",[System.StringSplitOptions]::RemoveEmptyEntries) | ?{$_ -gt '0'} | ForEach{[char][int]"$($_)"}) -join ''
}

Function ConvertTo-Hexa($str)
{
    $ans = ''
    [System.Text.Encoding]::Unicode.GetBytes($str + "`0")
}

$newBasePath = "$env:LOCALAPPDATA\Microsoft\Outlook"
$username = [Environment]::UserName

#find key that has the 001f6610 property that holds the OST file path - one key per outlook profile.
$name = '001f6610'
$keys = @( (Get-ChildItem "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\" -Recurse | Where-Object {$_.Property -eq $name}).name )
$keys
foreach($key in $keys)
{
write-host $key -foregroundcolor green
$key = $key.Replace("HKEY_CURRENT_USER\","HKCU:\")
write-host $key -foregroundcolor green

$value = (get-itemproperty -path $key -name $name).$name
$value2 = (Get-ItemProperty -path $key | Select -ExpandProperty $name) -join ','

$oldValue = ConvertFrom-Hexa $value2
write-host "Old Value for OST File was:  $oldValue" -foregroundcolor Yellow
#make sure it is an OST in this field
if($oldValue.substring($oldValue.length - 4,4) -eq ".ost")
{

$oldFilenameParts = $oldValue.split("\")
$oldFilename = $oldFilenameParts[$oldFilenameParts.Count - 1]

$new = "$newBasePath\$oldFilename"
$newBin = ConvertTo-Hexa($new)
$newBin2 = $newBin -join ','
$newBin2Str = ConvertFrom-Hexa $newBin2
write-host "New Value for OST file (encoded and decoded) is: $newBin2Str" -foregroundcolor Yellow

if ($oldValue -ne $newBin2Str){
    write-host "About to change value in registry..." -foregroundcolor RED
    set-ItemProperty -path $key -name $name -value $newBin
} else {
    Write-Host "Nothing has been done"
}
}
}  
*****************’
