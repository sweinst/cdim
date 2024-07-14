# all we need to know about a bookmark
Add-Type -Language CSharp @"
public class Bookmark {
    public string          Name;
    public string          Path;
    public System.DateTime TimeStamp;
}
"@;

# the location of our settings
$cdim_path = Join-Path (Split-Path $PROFILE -Parent) .cdim

# the last version, we've read
$cdim_last_update = Get-Date 1970-01-01

# the stack of directories
[Collections.Generic.List[String]] $cdim_history = @()
 
# the dictionary of bookmarks
[System.Collections.Generic.SortedDictionary[String, Bookmark]]$cdim_bookmarks = @{}

# maximum size of history
$cdim_max_history = 15
 
 <#
.SYNOPSIS
   Improved cd command with history and bookmarks.
.DESCRIPTION
   Add to cd command:
   - history (only for the current session)
   - bookmarks (persisted)

.PARAMETER Path
If any of the other options have been provided, this the path to set the location to.
If it starts with a '%', this is:
- the ith item in the history, if a number follows the '%'
- the name of a bookmark otherwise

If the bookmark option has been set, this is the location to use for setting the bookmark

if empty, the location will be set to the current directory

.PARAMETER List
This list the location history and available history

.PARAMETER Bookmark
This is the name of the bookmark to create or change

.PARAMETER Delete
This is the name of the bookmark to delete

.PARAMETER Fuzzy
Will cd to the most recent directory in history match the regex (case-insensitive)

.NOTES
It can be aliased to 'CD': Set-Alias cd cdim -Option AllScope

.EXAMPLE
cdim C:\windows
CD to a directory
.EXAMPLE
cdim %2
CD to the 2nd most recent directory
.EXAMPLE
cdim %d1
CD to the bookmark 'd1'
.EXAMPLE
cdim first-dir
cdim second-dir
cdim first-dir2
cdim -f econd
will cd to the directory second-dir
cdim -f irst.*d
will cd to the directory first-dir
.EXAMPLE
cdim -b d1
Bookmark the current directory to 'd1'
.EXAMPLE
cdim c:\windows -b d1
Bookmark the c:\windows directory to 'd1'
.EXAMPLE
cdim -d d1
Delete the bookmark 'd1'
#>
function cdim
{
	param(
	[Parameter(Position=0, ValueFromPipeline=$true)]
	[string]${Path},
	[string]${Bookmark},
	[string]${Delete},
    [switch]${List},
    [string]${Fuzzy}
    )
 
    # get any "external" change
    load-settings
    # the path
    # add a new bookmark ?
    if (-not [System.String]::IsNullOrWhiteSpace($Bookmark))
    {
        if ([System.String]::IsNullOrWhiteSpace($Path)) 
        {
            $Path = $PWD
        }
        $b = New-Object Bookmark -Property @{ Name=$Bookmark.Trim(); Path=$Path; TimeStamp = Get-Date }
        $cdim_bookmarks[$b.Name] = $b
        Write-Host "Added bookmark '$($b.Name)' for path '$($b.Path)'"
        save-settings
    }
    elseif (-not [System.String]::IsNullOrWhiteSpace($Delete))
    {
        $cdim_bookmarks.Remove($Delete.Trim())
        save-settings
    }
    elseif ($List)
    {
        Write-Host "----------"
        Write-Host "Bookmarks:"
        Write-Host "----------"
        # NB: foreach iterates with one null value if the collection is empty
        if ($cdim_bookmarks.Count -ne 0) { $cdim_bookmarks.Values | ForEach-Object { Write-Host "$($_.Name): $($_.Path)" } }
        Write-Host "----------"
        Write-Host "History:"
        Write-Host "----------"
        $i = 1
        if ($cdim_history.Count -ne 0) { $cdim_history | ForEach-Object { Write-Host "${i}: $_"; $i += 1 } }
    }
    else
    {
        # fuzzy search
        if (-not [System.String]::IsNullOrWhiteSpace($Fuzzy)) 
        {
            if ($cdim_history.Count -eq 0) { Throw "no directory in history" }
            foreach($h_path in $cdim_history)
            {
                # matches only on the directory name
                $dir_name = (Split-Path $h_path -Leaf)
                if (${dir_name} -imatch $Fuzzy)
                {
                    $Path = $h_path
                    break
                }
            }
            if ([System.String]::IsNullOrWhiteSpace($Path)) { Throw "no match for '$Fuzzy'" }
        }
        # cd home
        elseif ([System.String]::IsNullOrWhiteSpace($Path)) 
        {
            $Path = [Environment]::GetFolderPath("UserProfile")
        }
        # support for "cd -""
        elseif ($Path.Trim().equals("-")) 
        {
            if ($cdim_history.Count -ge 2) 
            {
                $Path = $cdim_history[1]
            }
            else
            {
                $Path = (Get-Location).Path
            }
        }
        if ($Path.StartsWith('%'))
        {
            $Path = $Path.Substring(1)
            $i = $Path -as [int]
            if ($i -eq $null)
            {
                if (-not $cdim_bookmarks.ContainsKey($Path))
                {
                    Throw "unknown bookmark %$Path"
                }
                $Path = $cdim_bookmarks[$Path].Path
            }
            else
            {
                if ($cdim_history.Count -lt $i)
                {
                    Throw "Only $($cdim_history.Count) item(s) in history"
                }
                $Path = $cdim_history[$i - 1]
            }
        }
        Set-Location $Path
        $np = $PWD.Path
        $cdim_history.Insert(0, $np)
        # remove any previous instance
        for ($i=$cdim_history.Count - 1; $i -gt 0; $i--)
        {
            if ($cdim_history[$i] -ieq $np) { $cdim_history.RemoveAt($i) }
        }
        # avoid too large history
        while ($cdim_max_history -lt $cdim_history.Count) { $cdim_history.RemoveAt($cdim_history.Count - 1) }
    }

}

function save-settings()
{
    # first merge with any new definitions
    load-settings
    # then save them
    Export-Clixml -InputObject $cdim_bookmarks -Path $cdim_path
    $script:cdim_last_update = (Get-Item $cdim_path -Force).LastWriteTime
}

function load-settings()
{
    # only load if newer
    if (Test-Path $cdim_path)
    {
        $nts = (Get-Item $cdim_path -Force).LastWriteTime
        #NB: we must specify the scope for a DateTime as they are used by value
        if ($nts -gt $script:cdim_last_update)
        {
            #Write-Host "reloading settings"
            $import = Import-Clixml -Path $cdim_path
            $script:cdim_last_update = $nts
            # merge
            $import.Values | ForEach-Object {
                if ((-not $cdim_bookmarks.ContainsKey($_.Name)) -or ($_.TimeStamp -gt $cdim_bookmarks[$_.Name].TimeStamp))
                {
                    # NB: Import-Clixml does not recreate the original object but objects with the same public properties
                    # so we need to re-create the object
                    $cdim_bookmarks[$_.Name] = New-Object Bookmark -Property @{ Name=$_.Name; Path=$_.Path; TimeStamp = $_.TimeStamp }
                }}
        }
    }
}

function cdim_complete()
{
    param($wordToComplete)
    # get any "external" change
    load-settings
    if ($wordToComplete.StartsWith('%'))
    {
        $key,$sep,$rest = $wordToComplete.SubString(1) -split "([/\\])",2
        # %key/ + a/b -> dir_key/a/b
        if ($sep -and $cdim_bookmarks.ContainsKey($key)) {
            $res = (Join-Path $cdim_bookmarks[$key].Path "$rest")
            [System.Management.Automation.CompletionResult]::new($res, $res, 'ParameterValue', 'Directory')
        }
        else {
            # bookmark name completion
            $cdim_bookmarks.Keys | ? { $_.StartsWith($key) } |
                % { [System.Management.Automation.CompletionResult]::new('%' + $_, '%' + $_, 'ParameterValue', 'Bookmark') }
        }
    }
    else 
    {
        # directory name completion
        $key=$wordToComplete
        Get-ChildItem -Directory -Path . | ? { $_.Name.StartsWith($key) } |
            % { [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', 'Directory') }
    }
}

Set-Alias cd cdim -Option AllScope -scope Global
# PsReadline keeps a cache of the cd alias, we need to reset it
# see https://jamesone111.wordpress.com/2019/11/24/redefining-cd-in-powershell/
# warning, all PsReadline personalisation will be lost. So it's better to load this module BEFORE chaning any PSReadLine settings!
if (Get-Module PSReadLine) {
    Remove-Module -Force PsReadline
    Import-Module -Force PSReadLine
}

Register-ArgumentCompleter -CommandName 'cdim' -ParameterName 'Path' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    cdim_complete $wordToComplete
}

