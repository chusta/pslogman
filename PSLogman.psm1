<#
    .Synopsis
    Powershell wrapper for logman.exe

    .Description
    Powershell wrapper for logman.exe. Implements PSObjects
    for easier lookup of ETW session properties.

    .Example
    Get-Logman
#>
function Get-Logman
{
    function Parse
    {
        Param(
            [parameter(Mandatory=$true)][String] $line
        )

        $null, $v = $line -split ": "
        $v = if ($v) { $v.Trim() } else { "" }
        return $v
    }

    $output = logman -ets
    $output = $output[3..($output.Length-2)] | % { $_.split()[0] } | ? { $_.Trim() -ne "" }

    $sessions = @()
    foreach ($o in $output)
    {
        $full = logman -ets $o
        $providers = $full | Select-String "Provider:" -Context 1,2

        $session = New-Object PSObject -Property @{
            SessionName = $o
            Properties = @()
            FullOutput = $full
        }

        for ($i = 0; $i -lt $providers.count; $i++)
        {
            $sections = $providers[$i] -split "`n"
            $sections = $sections | ? { $_ -match "Name|Guid" }
            $name = Parse $sections[0]
            $guid = Parse $sections[1]
            $property = New-Object PSObject -Property @{
                Name = $name
                Guid = $guid
            }
            $session.Properties += $property
        }
        $sessions += $session
    }
    return $sessions
}

<#
    .Synopsis
    Search all ETW sessions for matching provider names and guids.

    .Example
    Search-Sessions e2795
#>
function Search-Sessions
{
    Param(
        [parameter(Mandatory=$true)][String] $term
    )

    $sessions = Get-Logman
    $results = @()
    foreach ($session in $sessions)
    {
        $properties = $session.Properties | ? { ($_.Name, $_.Guid) -match "$term" }
        if ($properties)
        {
            $results += $session
        }
    }
    return $results
}
