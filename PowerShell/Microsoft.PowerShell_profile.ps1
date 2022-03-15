
# This profile script performs the following
# * Attempts to set the execution policy based on the $ExecutionPolicy variable
# * Sets environment variables for user olders
#       e.g. Downloads is set as FolderDownloads so you can Set-Location $FolderDownloads
# * Adds function 'Install-WinGetPackage' which tries to install packages to a specific location
#       Most packages I've tested don't seem to be able follow - and many either don't use msi installers or the msi doesn't accept supported flags
# * Adds a function 'Set-MyFolder' which uses the created $FolderX variables.
#       e.g. instead of Set-Location $FolderDownloads you can run 'Set-MyFolder Downloads'
# * Adds some aliases for Linux users who spend too much time in the terminal
#   * You can run:
#       * 'ip addr' & 'ifconfig' -> ipconfig /all
# 
# How to install:
# Use VSCode -
# In a powershell window run
# * 'code $PROFILE'
# * Paste contents into VSCode and save
#
# As you always do- review the script before installing to check for errors or security issues


$ExecutionPolicy = Get-ExecutionPolicy
$DesiredPolicies = @('Bypass', 'Unrestricted')
$Global:InstallDir = "F:\PackageManagerInstalls\WinGet\"

$ShellFolders = (Get-Item 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\')




$FolderMapping = @{
    "{7D1D3A04-DEBB-4115-95CF-2F29DA2920DA}" = 'Searches'
    "{374DE290-123F-4565-9164-39C4925E467B}" = 'Downloads'
    "{A520A1A4-1780-4FF6-BD18-167343C5AF16}" = 'AppDataLocalLow'
    "{4C5C32FF-BB9D-43B0-B5B4-2D72E54EAAA4}" = "SavedGames"
    "{1B3EA5DC-B587-4786-B4EF-BD1DC332AEAE}" = 'Libraries'
    "{56784854-C6CB-462B-8169-88E350ACB882}" = 'Contacts'
    "{BFB9D5E0-C6A9-404C-B2B2-AE6DB6AF4968}" = 'Links'
}

ForEach ($ShellFolder in $ShellFolders.Property) {

    if ($ShellFolder -in $FolderMapping.Keys) {
        $FolderPathValue =  Get-ItemPropertyValue -Path 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name $ShellFolder

        $VariableName = "Folder$($FolderMapping[$ShellFolder])".Replace(' ', '')

        Set-Variable -Scope Global -Name $VariableName -Value $FolderPathValue
        # Write-Output "Folder$($FolderMapping[$ShellFolder])"
    } elseif ($ShellFolder -notmatch '^(!|{)') {
        $FolderPathValue =  Get-ItemPropertyValue -Path 'HKCU:\software\microsoft\windows\currentversion\explorer\shell folders\' -Name $ShellFolder
        $VariableName = "Folder$($ShellFolder)".Replace(' ', '')
        if ($ShellFolder -eq 'Personal') {
            Set-Variable -Scope Global -Name 'FolderDocuments' -Value $FolderPathValue
        }
        Set-Variable -Scope Global -Name $VariableName -Value $FolderPathValue
    }
        
}

Function Set-MyFolder {
    [CmdletBinding()]
    param (
        [Parameter()]
        $Folder
    )
    $PathValue = (Get-Variable -Name "Folder$($Folder)").Value
    Set-Location -Path $PathValue

}

# ----------------------------

# Becase I always accidently type ip addr on Windows.
function ip { 
    if ($args[0] -eq 'addr') { 
        ipconfig /all  
    }
}

# Because somtimes I ifconfig do this instead
Set-Alias -Name ifconfig -Value ipconfig



if ($ExecutionPolicy -notin $DesiredPolicies) {
    try {
        $(Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Scope CurrentUser) 2> $null
    }
    catch {
        
        Write-Host -ForegroundColor 'Yellow' "Failed to set permissive execution policy. Current policy is $ExecutionPolicy."
        Write-Host -ForegroundColor 'Yellow' "Desired policies were:"
        $DesiredPolicies | ForEach-Object {Write-Host -ForegroundColor 'Yellow' "    • $_"}
        
    }

}


$InfoString = @'
    This profile script performs the following:
    * Attempts to set the execution policy based on $ExecutionPolicy variable
    * Sets environment variables for user olders
        e.g. Downloads is set as $FolderDownloads so you can Set-Location$FolderDownloads
    * Adds function "Install-WinGetPackage" which tries to install packages to a specific
    location. Most packages I'+"'"+'ve tested don"t seem to be able follow -l and many
    don'+"'"+'t use msi installers or the msi doesn'+"'"+'t accept any location flags
    * Adds a function "Set-MyFolder" which uses the created $FolderX variables.
        e.g. instead of Set-Location $FolderDow you can run "Set-MyFolder Downloads"
    * Adds some aliases for Linux users who spend too much time in the terminal
        * "ip addr" & "ifconfig" -> ipconfig /all
    * Adds function "Set-LnkLocation"  which allows you to change directory to
    a location in a .lnk file. Aliased to cdl.
'@






# Set-PSReadLineOption -AddToHistoryHandler $TestSaveHistory -MaximumHistoryCount 10000 -BellStyle None -HistorySaveStyle SaveIncrementally -HistorySavePath $home\.ps_history

function Write-InfoBox {
    param (
        $BoxString,
        $VerticalDelimiter = '+',
        $HorizontalDelimiter  = '=',
        $TitlelDelimiter = $HorizontalDelimiter,
        $TitlelDelimiterLeft = $TitlelDelimiter,
        $TitlelDelimiterRight = $TitlelDelimiter,
        $Title = "INFO"
    )
    # if (-not $TitlelDelimiter) {
    #     $TitlelDelimiter = $HorizontalDelimiter
    # }
    $ExistingBackgroundColour = $Host.UI.RawUI.BackgroundColor
    $ExistingForegroundColour = $Host.UI.RawUI.ForegroundColor
    $InfoStringArray = ($BoxString -split "\n" ) -split "`n" | % { $_.trim() }
    $TitleString = "  " + $Title + "  "
    $MaxLineLength = ($InfoStringArray |  Measure-Object -Maximum -Property Length).Maximum
    $PadLength = $MaxLineLength + 10 + 2
    $InfoDelimiter = $VerticalDelimiter + $HorizontalDelimiter * ($PadLength) + $VerticalDelimiter
    $InfoTitle = ($VerticalDelimiter + $TitlelDelimiterLeft * [int]($PadLength / 2 - ($TitleString.Length / 2)) + $TitleString).PadRight($PadLength + 1, $TitlelDelimiterRight) + $VerticalDelimiter
    # $InfoString = $InfoString
    Write-Host -BackgroundColor $ExistingBackgroundColour -ForegroundColor $ExistingForegroundColour ' '
    Write-Host -NoNewline -BackgroundColor DarkBlue -ForegroundColor White $InfoDelimiter
    Write-Host -BackgroundColor $ExistingBackgroundColour -ForegroundColor $ExistingForegroundColour ' '
    Write-Host -NoNewline  -BackgroundColor DarkBlue -ForegroundColor White $InfoTitle
    Write-Host -BackgroundColor $ExistingBackgroundColour -ForegroundColor $ExistingForegroundColour ' '
    Write-Host -NoNewline -BackgroundColor DarkBlue -ForegroundColor White $InfoDelimiter
    Write-Host -BackgroundColor $ExistingBackgroundColour -ForegroundColor $ExistingForegroundColour ' '
    ForEach($TextLine in $InfoStringArray) {
        [int]$PadLineLength = $PadLength -2

        Write-Host -NoNewline -BackgroundColor DarkBlue -ForegroundColor White $($VerticalDelimiter) $($TextLine.PadRight($PadLineLength)) $($VerticalDelimiter)
        Write-Host -BackgroundColor $ExistingBackgroundColour -ForegroundColor $ExistingForegroundColour ' '
    }
    Write-Host -BackgroundColor DarkBlue -ForegroundColor White $InfoDelimiter.PadRight($PadLineLength)
    Write-Host -BackgroundColor $ExistingBackgroundColour -ForegroundColor $ExistingForegroundColour ' '
}





Write-InfoBox -BoxString $InfoString -TitlelDelimiter '|'


Set-Alias python3 python
Set-Alias pip3 pip

# $HistoryFilePath = Join-Path ([Environment]::GetFolderPath('UserProfile')) .ps_history_state
# Register-EngineEvent PowerShell.Exiting -Action { Get-History | Export-Clixml $HistoryFilePath } | out-null
# if (Test-path $HistoryFilePath) { 
#     Import-Clixml $HistoryFilePath | Add-History 
# }

Function Install-WinGetPackage {
    param (
        [string]$Program,
        [string]$InstallDir = $Global:InstallDir,
        [string]$WingetExtraOptions = ''
    )

    $BaseInstallDir = (Get-ItemProperty -Path $InstallDir).FullName.TrimEnd('\')
    $TargetInstallDir = "$($BaseInstallDir)\$($Program)"

    function Write-WithColor {
        param (
            $BGColor = 'White',
            $FGColor = 'Black',
            $Message
        )
        $ConsolePreviousBGColour = (Get-Host).UI.RawUI.BackgroundColor
        $ConsolePreviousFGColour = (Get-Host).UI.RawUI.ForegroundColor
        $WindowWidth = (Get-Host).UI.RawUI.WindowSize.Width


        (Get-Host).UI.RawUI.BackgroundColor=$BGColor
        (Get-Host).UI.RawUI.ForegroundColor=$FGColor


        Write-Host $message.PadRight($WindowWidth)


        (Get-Host).UI.RawUI.BackgroundColor=$ConsolePreviousBGColour
        (Get-Host).UI.RawUI.ForegroundColor=$ConsolePreviousFGColour
    }


    function Exit-ReturnError {
        param (
            [int]$code = 5,
            [string]$message
        )
        Write-WithColor -FGColor 'White' -BGColor 'Red' -Message "An error has occurred."
        Write-WithColor -FGColor 'White' -BGColor 'DarkRed' -Message $message

        exit $code
    }





    if (!$program) {

        Exit-ReturnError -Message 'A program to install must be provided in -Program ' -Code 5
    }

    $OverrideString = "MSI_TARGETDIR=$($TargetInstallDir) INSTALLDIR=$($TargetInstallDir) INSTALLPATH=$($TargetInstallDir) INSTALLFOLDER=$($TargetInstallDir) INSTALLLOCATION=$($TargetInstallDir) APPDIR=$($TargetInstallDir) APPLICATIONFOLDER=$($TargetInstallDir) TARGETDIR=$($TargetInstallDir)"
    winget install $($Program) -l $TargetInstallDir --override $OverrideString $WingetExtraOptions
}

function Set-LnkLocation {
    
    param (
        [Parameter(Mandatory=$true)]
        [string]$LinkFile
    )
    $WscriptShell = new-object -com wscript.shell
    if ($LinkFile -inotmatch '.*\.lnk$') {
        $LinkFile = $LinkFile + '.lnk'

    }
    $ResolvedLnkPath = Resolve-Path $LinkFile
    if (Test-Path -Type Leaf $ResolvedLnkPath) {
        
        $TargetPath = $WscriptShell.CreateShortcut($ResolvedLnkPath).TargetPath
        Set-Location $TargetPath
    } else {
        throw "$($LinkFile) was not found."
    }
    
}

Set-Alias -Name cdl -Value Set-LnkLocation
Set-Alias -Name cdm -Value Set-MyFolder
