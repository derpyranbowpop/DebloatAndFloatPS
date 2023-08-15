#### START ELEVATE TO ADMIN #####
param(
    [Parameter(Mandatory=$false)]
    [switch]$shouldAssumeToBeElevated,

    [Parameter(Mandatory=$false)]
    [String]$workingDirOverride
)

# If parameter is not set, we are propably in non-admin execution. We set it to the current working directory so that
#  the working directory of the elevated execution of this script is the current working directory
if(-not($PSBoundParameters.ContainsKey('workingDirOverride')))
{
    $workingDirOverride = (Get-Location).Path
}

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# If we are in a non-admin execution. Execute this script as admin
if ((Test-Admin) -eq $false)  {
    if ($shouldAssumeToBeElevated) {
        Write-Output "Elevating did not work :("

    } else {
        #                                                         vvvvv add `-noexit` here for better debugging vvvvv 
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -shouldAssumeToBeElevated -workingDirOverride "{1}"' -f ($myinvocation.MyCommand.Definition, "$workingDirOverride"))
    }
    exit
}

Set-Location "$workingDirOverride"
##### END ELEVATE TO ADMIN #####

function Test-ChocolateyInstalled {
    # Check if the 'choco.exe' executable is in the system's PATH 
    $chocoExe = Get-Command -Name 'choco.exe' -ErrorAction SilentlyContinue
    if ($chocoExe -eq $null) {
        Write-Host "Chocolatey is not installed. Installing Chocolatey..."
        Set-ExecutionPolicy AllSigned
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        choco feature enable -n allowGlobalConfirmation

        # Check again if Chocolatey is installed
        $chocoExe = Get-Command -Name 'choco.exe' -ErrorAction SilentlyContinue
        if ($chocoExe -eq $null) {
            Write-Host "Chocolatey installation failed. Please install Chocolatey manually before continuing."
            return $false
        } else {
            Write-Host "Chocolatey is now installed. You can use Chocolatey commands."
            return $true
        }
    } else {
        return $true
    }
}

#Unnecessary Windows 10 AppX apps that will be removed by the blacklist.
$global:Bloatware = @(
    "Microsoft.BingNews"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.Messaging"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.NetworkSpeedTest"
    "Microsoft.News"                                    # Issue 77
    "Microsoft.Office.Lens"                             # Issue 77
    "Microsoft.Office.OneNote"
    "Microsoft.Office.Sway"
    "Microsoft.OneConnect"
    "Microsoft.People"
    "Microsoft.Print3D"
    "Microsoft.RemoteDesktop"                           # Issue 120
    "Microsoft.SkypeApp"
    "Microsoft.StorePurchaseApp"
    "Microsoft.Office.Todo.List"                        # Issue 77
    "Microsoft.Whiteboard"                              # Issue 77
    "Microsoft.WindowsAlarms"
    "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.MicrosoftJournal"
    "MicrosoftCorporationII.MicrosoftFamily"
    "C27EB4BA.DropboxOEM"
    "MixedRealityLearning"
    #Sponsored Windows 10 AppX Apps
    #Add sponsored/featured apps to remove in the "*AppName*" format
    "57540AMZNMobileLLC.AmazonAlexa"
    "26720RandomSaladGamesLLC.3899848563C1F"
    "26720RandomSaladGamesLLC.HeartsDeluxe"
    "26720RandomSaladGamesLLC.Spades"
    "Evernote.Evernote"
    "EclipseManager"
    "ActiproSoftwareLLC"
    "AdobeSystemsIncorporated.AdobePhotoshopExpress"
    "Duolingo-LearnLanguagesforFree"
    "PandoraMediaInc"
    "CandyCrush"
    "Wunderlist"
    "Flipboard"
    "Twitter"
    "Facebook"
    "Spotify"                                           # Issue 123
    "Minecraft"
    "Royal Revolt"
    "Sway"                                              # Issue 77
    "Dolby"                                             # Issue 78
    #Laptop Bloat
    "AD2F1837.myHP"
    "AD2F1837.HPQuickDrop"
    "AD2F1837.HPInc.EnergyStar"
    "AD2F1837.HPSystemEventUtility"
    "AD2F1837.OMENCommandCenter"
    "E046963F.LenovoCompanion"
    "E046963F.LenovoVoiceWorldWide"
    "AcerIncorporated.AcerRegistration"
    "AcerIncorporated.QuickAccess"
    "AcerIncorporated.UserExperienceImprovementProgramV"
    "AcerIncorporated.AcerPurifiedVoiceConsoleR"

    #Optional: Typically not removed but you can if you need to for some reason
    #"Microsoft.Advertising.Xaml_10.1712.5.0_x64__8wekyb3d8bbwe"
    #"Microsoft.Advertising.Xaml_10.1712.5.0_x86__8wekyb3d8bbwe"
    #"Microsoft.BingWeather"
)

#Valuable Windows 10 AppX apps that most people want to keep. Protected from DeBloat All.
#Credit to /u/GavinEke for a modified version of my whitelist code
$global:WhiteListedApps = @(
    "Microsoft.WindowsCalculator"               # Microsoft removed legacy calculator
    "Microsoft.WindowsStore"                    # Issue 1
    "Microsoft.Windows.Photos"                  # Microsoft disabled/hid legacy photo viewer
    "CanonicalGroupLimited.UbuntuonWindows"     # Issue 10
    "Microsoft.Xbox.TCUI"                       # Issue 25, 91  Many home users want to play games
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"               # Issue 25, 91  Many home users want to play games
    "Microsoft.XboxIdentityProvider"            # Issue 25, 91  Many home users want to play games
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.MicrosoftStickyNotes"            # Issue 33  New functionality.
    "Microsoft.MSPaint"                         # Issue 32  This is Paint3D, legacy paint still exists in Windows 10
    "Microsoft.WindowsCamera"                   # Issue 65  New functionality.
    "\.NET"
    "Microsoft.HEIFImageExtension"              # Issue 68
    "Microsoft.ScreenSketch"                    # Issue 55: Looks like Microsoft will be axing snipping tool and using Snip & Sketch going forward
    "Microsoft.StorePurchaseApp"                # Issue 68
    "Microsoft.VP9VideoExtensions"              # Issue 68
    "Microsoft.WebMediaExtensions"              # Issue 68
    "Microsoft.WebpImageExtension"              # Issue 68
    "Microsoft.DesktopAppInstaller"             # Issue 68
    "WindSynthBerry"                            # Issue 68
    "MIDIBerry"                                 # Issue 68
    "Slack"                                     # Issue 83
)

#NonRemovable Apps that where getting attempted and the system would reject the uninstall, speeds up debloat and prevents 'initalizing' overlay when removing apps
$NonRemovables = Get-AppxPackage -AllUsers | Where-Object { $_.NonRemovable -eq $true } | foreach { $_.Name }
$NonRemovables += Get-AppxPackage | Where-Object { $_.NonRemovable -eq $true } | foreach { $_.Name }
$NonRemovables += Get-AppxProvisionedPackage -Online | Where-Object { $_.NonRemovable -eq $true } | foreach { $_.DisplayName }
$NonRemovables = $NonRemovables | Sort-Object -unique

if ($NonRemovables -eq $null ) {
    # the .NonRemovable property doesn't exist until version 18xx. Use a hard-coded list instead.
    #WARNING: only use exact names here - no short names or wildcards
    $NonRemovables = @(
        "1527c705-839a-4832-9118-54d4Bd6a0c89"
        "c5e2524a-ea46-4f67-841f-6a9465d9d515"
        "E2A4F912-2574-4A75-9BB0-0D023378592B"
        "F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE"
        "InputApp"
        "Microsoft.AAD.BrokerPlugin"
        "Microsoft.AccountsControl"
        "Microsoft.BioEnrollment"
        "Microsoft.CredDialogHost"
        "Microsoft.ECApp"
        "Microsoft.LockApp"
        "Microsoft.MicrosoftEdgeDevToolsClient"
        "Microsoft.MicrosoftEdge"
        "Microsoft.PPIProjection"
        "Microsoft.Win32WebViewHost"
        "Microsoft.Windows.Apprep.ChxApp"
        "Microsoft.Windows.AssignedAccessLockApp"
        "Microsoft.Windows.CapturePicker"
        "Microsoft.Windows.CloudExperienceHost"
        "Microsoft.Windows.ContentDeliveryManager"
        "Microsoft.Windows.Cortana"
        "Microsoft.Windows.HolographicFirstRun"         # Added 1709
        "Microsoft.Windows.NarratorQuickStart"
        "Microsoft.Windows.OOBENetworkCaptivePortal"    # Added 1709
        "Microsoft.Windows.OOBENetworkConnectionFlow"   # Added 1709
        "Microsoft.Windows.ParentalControls"
        "Microsoft.Windows.PeopleExperienceHost"
        "Microsoft.Windows.PinningConfirmationDialog"
        "Microsoft.Windows.SecHealthUI"                 # Issue 117 Windows Defender
        "Microsoft.Windows.SecondaryTileExperience"     # Added 1709
        "Microsoft.Windows.SecureAssessmentBrowser"
        "Microsoft.Windows.ShellExperienceHost"
        "Microsoft.Windows.XGpuEjectDialog"
        "Microsoft.XboxGameCallableUI"                  # Issue 91
        "Windows.CBSPreview"
        "windows.immersivecontrolpanel"
        "Windows.PrintDialog"
        "Microsoft.VCLibs.140.00"
        "Microsoft.Services.Store.Engagement"
        "Microsoft.UI.Xaml.2.0"
    )
}

# import library code - located relative to this script
Function dotInclude() {
    Param(
        [Parameter(Mandatory)]
        [string]$includeFile
    )
    # Look for the file in the same directory as this script
    $scriptPath = $PSScriptRoot
    if ( $PSScriptRoot -eq $null -and $psISE) {
        $scriptPath = (Split-Path -Path $psISE.CurrentFile.FullPath)
    }
    if ( test-path $scriptPath\$includeFile ) {
        # import and immediately execute the requested file
        . $scriptPath\$includeFile
    }
}

# Override built-in blacklist/whitelist with user defined lists
dotInclude 'custom-lists.ps1'

#convert to regular expression to allow for the super-useful -match operator
$global:BloatwareRegex = $global:Bloatware -join '|'
$global:WhiteListedAppsRegex = $global:WhiteListedApps -join '|'

# This form was created using POSHGUI.com  a free online gui designer for PowerShell
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

#region begin GUI 
$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '600,500'
$Form.StartPosition = 'CenterScreen'
$Form.FormBorderStyle = 'FixedSingle'
$Form.MinimizeBox = $false
$Form.MaximizeBox = $false
$Form.ShowIcon = $false
$Form.text = "Debloat And Float"
$Form.TopMost = $false
$Form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#252525")

$Debloat = New-Object system.Windows.Forms.Label
$Debloat.text = "Debloat Options"
$Debloat.AutoSize = $true
$Debloat.width = 25
$Debloat.height = 10
$Debloat.location = New-Object System.Drawing.Point(10, 9)
$Debloat.Font = 'Microsoft Sans Serif,12,style=Bold,Underline'
$Debloat.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")


$CustomizeBlacklists = New-Object system.Windows.Forms.Button
$CustomizeBlacklists.text = "Customize Blacklist"
$CustomizeBlacklists.width = 140
$CustomizeBlacklists.height = 40
$CustomizeBlacklists.location = New-Object System.Drawing.Point(10, 32)
$CustomizeBlacklists.Font = 'Microsoft Sans Serif,10'
$CustomizeBlacklists.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$RemoveAllBloatware = New-Object system.Windows.Forms.Button
$RemoveAllBloatware.text = "Remove All Bloatware"
$RemoveAllBloatware.width = 140
$RemoveAllBloatware.height = 40
$RemoveAllBloatware.location = New-Object System.Drawing.Point(10, 80)
$RemoveAllBloatware.Font = 'Microsoft Sans Serif,10'
$RemoveAllBloatware.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$RemoveBlacklist = New-Object system.Windows.Forms.Button
$RemoveBlacklist.text = "Remove Bloatware With Customized Blacklist"
$RemoveBlacklist.width = 190
$RemoveBlacklist.height = 40
$RemoveBlacklist.location = New-Object System.Drawing.Point(10, 130)
$RemoveBlacklist.Font = 'Microsoft Sans Serif,10'
$RemoveBlacklist.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")


$Label2 = New-Object system.Windows.Forms.Label
$Label2.text = "Optional Changes/Fixes"
$Label2.AutoSize = $true
$Label2.width = 25
$Label2.height = 10
$Label2.location = New-Object System.Drawing.Point(220, 9)
$Label2.Font = 'Microsoft Sans Serif,12,style=Bold,Underline'
$Label2.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$DisableTaskbarbloat = New-Object system.Windows.Forms.Button
$DisableTaskbarbloat.text = "Remove Taskbar Bloat"
$DisableTaskbarbloat.width = 140
$DisableTaskbarbloat.height = 40
$DisableTaskbarbloat.location = New-Object System.Drawing.Point(220, 32)
$DisableTaskbarbloat.Font = 'Microsoft Sans Serif,10'
$DisableTaskbarbloat.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$StopEdgePDFTakeover = New-Object system.Windows.Forms.Button
$StopEdgePDFTakeover.text = "Stop Edge PDF Takeover"
$StopEdgePDFTakeover.width = 140
$StopEdgePDFTakeover.height = 40
$StopEdgePDFTakeover.location = New-Object System.Drawing.Point(370, 32)
$StopEdgePDFTakeover.Font = 'Microsoft Sans Serif,10'
$StopEdgePDFTakeover.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$DisableTelemetry = New-Object system.Windows.Forms.Button
$DisableTelemetry.text = "Disable Telemetry/Tasks"
$DisableTelemetry.width = 140
$DisableTelemetry.height = 40
$DisableTelemetry.location = New-Object System.Drawing.Point(220, 80)
$DisableTelemetry.Font = 'Microsoft Sans Serif,10'
$DisableTelemetry.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$RemoveRegkeys = New-Object system.Windows.Forms.Button
$RemoveRegkeys.text = "Remove Bloatware Regkeys"
$RemoveRegkeys.width = 140
$RemoveRegkeys.height = 40
$RemoveRegkeys.location = New-Object System.Drawing.Point(370, 80)
$RemoveRegkeys.Font = 'Microsoft Sans Serif,10'
$RemoveRegkeys.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$LongSleep = New-Object system.Windows.Forms.Button
$LongSleep.text = "Longer Sleep"
$LongSleep.width = 140
$LongSleep.height = 40
$LongSleep.location = New-Object System.Drawing.Point(220, 125)
$LongSleep.Font = 'Microsoft Sans Serif,10'
$LongSleep.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")


$Label3 = New-Object system.Windows.Forms.Label
$Label3.text = "Install Programs"
$Label3.AutoSize = $true
$Label3.width = 25
$Label3.height = 10
$Label3.location = New-Object System.Drawing.Point(10, 190)
$Label3.Font = 'Microsoft Sans Serif,12,style=Bold,Underline'
$Label3.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$BasicSS = New-Object system.Windows.Forms.Button
$BasicSS.text = "Install Basic System Setup"
$BasicSS.width = 140
$BasicSS.height = 40
$BasicSS.location = New-Object System.Drawing.Point(10, 215)
$BasicSS.Font = 'Microsoft Sans Serif,10'
$BasicSS.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$UnBasicSS = New-Object system.Windows.Forms.Button
$UnBasicSS.text = "Uninstall Basic System Setup"
$UnBasicSS.width = 140
$UnBasicSS.height = 40
$UnBasicSS.location = New-Object System.Drawing.Point(10, 265)
$UnBasicSS.Font = 'Microsoft Sans Serif,10'
$UnBasicSS.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$ISFile = New-Object system.Windows.Forms.Button
$ISFile.text = "Install From Installed Software File"
$ISFile.width = 140
$ISFile.height = 40
$ISFile.location = New-Object System.Drawing.Point(160, 215)
$ISFile.Font = 'Microsoft Sans Serif,10'
$ISFile.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$ITDB = New-Object system.Windows.Forms.Button
$ITDB.text = "Install Todo Backup"
$ITDB.width = 140
$ITDB.height = 40
$ITDB.location = New-Object System.Drawing.Point(160, 265)
$ITDB.Font = 'Microsoft Sans Serif,10'
$ITDB.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$InsatllGames = New-Object system.Windows.Forms.Button
$InsatllGames.text = "Insatll Game Launchers"
$InsatllGames.width = 140
$InsatllGames.height = 40
$InsatllGames.location = New-Object System.Drawing.Point(310, 215)
$InsatllGames.Font = 'Microsoft Sans Serif,10'
$InsatllGames.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")


$Theme = New-Object system.Windows.Forms.Label
$Theme.text = "Windows Theme"
$Theme.AutoSize = $true
$Theme.width = 457
$Theme.height = 142
$Theme.Anchor = 'top,right,left'
$Theme.location = New-Object System.Drawing.Point(460,190)
$Theme.Font = 'Microsoft Sans Serif,12,style=Bold,Underline'
$Theme.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$EnableDarkMode = New-Object system.Windows.Forms.Button
$EnableDarkMode.text = "Dark"
$EnableDarkMode.width = 133
$EnableDarkMode.height = 40
$EnableDarkMode.Anchor = 'top,right,left'
$EnableDarkMode.location = New-Object System.Drawing.Point(460,215)
$EnableDarkMode.Font = 'Microsoft Sans Serif,10'
$EnableDarkMode.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")

$DisableDarkMode = New-Object system.Windows.Forms.Button
$DisableDarkMode.text = "Light"
$DisableDarkMode.width = 133
$DisableDarkMode.height = 40
$DisableDarkMode.Anchor = 'top,right,left'
$DisableDarkMode.location = New-Object System.Drawing.Point(460,260)
$DisableDarkMode.Font = 'Microsoft Sans Serif,10'
$DisableDarkMode.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#eeeeee")


$Form.controls.AddRange(@($Debloat, $ITDB, $ISFile, $InsatllGames, $LongSleep,$Theme, $DisableDarkMode, $EnableDarkMode, $CustomizeBlacklists, $RemoveAllBloatware, $RemoveBlacklist, $Label1, $BasicSS, $UnBasicSS, $Label2, $Label3, $DisableTaskbarbloat, $StopEdgePDFTakeover, $DisableTelemetry, $RemoveRegkeys, $FixWhitelist, $RemoveBloatNoBlacklist))

$DAFFolder = "C:\Temp\DebloatAndFloat\Logs"
If (Test-Path $DAFFolder) {
    Write-Host "$DAFFolder exists. Skipping."
}
Else {
    Write-Host "The folder "$DAFFolder" doesn't exist. This folder will be used for storing logs created after the script runs. Creating now."
    Start-Sleep 1
    New-Item -Path "$DAFFolder" -ItemType Directory
    Write-Host "The folder $DAFFolder was successfully created."
}

Start-Transcript -OutputDirectory "$DAFFolder"

#region gui events {
$CustomizeBlacklists.Add_Click( {
        $CustomizeForm = New-Object system.Windows.Forms.Form
        $CustomizeForm.ClientSize = '600,400'
        $CustomizeForm.text = "Customize Whitelist and Blacklist"
        $CustomizeForm.TopMost = $false
        $CustomizeForm.AutoScroll = $true

        $SaveList = New-Object system.Windows.Forms.Button
        $SaveList.text = "Save custom Whitelist and Blacklist to custom-lists.ps1"
        $SaveList.AutoSize = $true
        $SaveList.location = New-Object System.Drawing.Point(200, 5)
        $CustomizeForm.controls.Add($SaveList)

        $SaveList.Add_Click( {
                $ErrorActionPreference = 'silentlycontinue'

                '$global:WhiteListedApps = @(' | Out-File -FilePath $PSScriptRoot\custom-lists.ps1 -Encoding utf8
                @($CustomizeForm.controls) | ForEach {
                    if ($_ -is [System.Windows.Forms.CheckBox] -and $_.Enabled -and !$_.Checked) {
                        "    ""$( $_.Text )""" | Out-File -FilePath $PSScriptRoot\custom-lists.ps1 -Append -Encoding utf8
                    }
                }
                ')' | Out-File -FilePath $PSScriptRoot\custom-lists.ps1 -Append -Encoding utf8

                '$global:Bloatware = @(' | Out-File -FilePath $PSScriptRoot\custom-lists.ps1 -Append -Encoding utf8
                @($CustomizeForm.controls) | ForEach {
                    if ($_ -is [System.Windows.Forms.CheckBox] -and $_.Enabled -and $_.Checked) {
                        "    ""$($_.Text)""" | Out-File -FilePath $PSScriptRoot\custom-lists.ps1 -Append -Encoding utf8
                    }
                }
                ')' | Out-File -FilePath $PSScriptRoot\custom-lists.ps1 -Append -Encoding utf8

                #Over-ride the white/blacklist with the newly saved custom list
                dotInclude custom-lists.ps1

                #convert to regular expression to allow for the super-useful -match operator
                $global:BloatwareRegex = $global:Bloatware -join '|'
                $global:WhiteListedAppsRegex = $global:WhiteListedApps -join '|'
            })

        Function AddAppToCustomizeForm() {
            Param(
                [Parameter(Mandatory)]
                [int] $position,
                [Parameter(Mandatory)]
                [string] $appName,
                [Parameter(Mandatory)]
                [bool] $enabled,
                [Parameter(Mandatory)]
                [bool] $checked,

                [string] $notes
            )

            $label = New-Object system.Windows.Forms.Label
            $label.Location = New-Object System.Drawing.Point(2, (30 + $position * 16))
            $label.Text = $notes
            $label.width = 300
            $label.height = 16
            $Label.TextAlign = [System.Drawing.ContentAlignment]::TopRight
            $CustomizeForm.controls.Add($label)

            $Checkbox = New-Object system.Windows.Forms.CheckBox
            $Checkbox.text = $appName
            $Checkbox.location = New-Object System.Drawing.Point(320, (30 + $position * 16))
            $Checkbox.Autosize = 1;
            $Checkbox.Checked = $checked
            $Checkbox.Enabled = $enabled
            $CustomizeForm.controls.Add($CheckBox)
        }


        $Installed = @( (Get-AppxPackage).Name )
        $Online = @( (Get-AppxProvisionedPackage -Online).DisplayName )
        $AllUsers = @( (Get-AppxPackage -AllUsers).Name )
        [int]$checkboxCounter = 0

        foreach ($item in $NonRemovables) {
            $string = ""
            if ( $null -notmatch $global:BloatwareRegex -and $item -cmatch $global:BloatwareRegex ) { $string += " ConflictBlacklist " }
            if ( $null -notmatch $global:WhiteListedAppsRegex -and $item -cmatch $global:WhiteListedAppsRegex ) { $string += " ConflictWhitelist" }
            if ( $null -notmatch $Installed -and $Installed -cmatch $item) { $string += "Installed" }
            if ( $null -notmatch $AllUsers -and $AllUsers -cmatch $item) { $string += " AllUsers" }
            if ( $null -notmatch $Online -and $Online -cmatch $item) { $string += " Online" }
            $string += "  NONREMOVABLE"
            AddAppToCustomizeForm $checkboxCounter $item $false $false $string
            ++$checkboxCounter
        }
        foreach ( $item in $global:WhiteListedApps ) {
            $string = ""
            if ( $null -notmatch $NonRemovables -and $NonRemovables -cmatch $item ) { $string += " Conflict NonRemovables " }
            if ( $null -notmatch $global:BloatwareRegex -and $item -cmatch $global:BloatwareRegex ) { $string += " ConflictBlacklist " }
            if ( $null -notmatch $Installed -and $Installed -cmatch $item) { $string += "Installed" }
            if ( $null -notmatch $AllUsers -and $AllUsers -cmatch $item) { $string += " AllUsers" }
            if ( $null -notmatch $Online -and $Online -cmatch $item) { $string += " Online" }
            AddAppToCustomizeForm $checkboxCounter $item $true $false $string
            ++$checkboxCounter
        }
        foreach ( $item in $global:Bloatware ) {
            $string = ""
            if ( $null -notmatch $NonRemovables -and $NonRemovables -cmatch $item ) { $string += " Conflict NonRemovables " }
            if ( $null -notmatch $global:WhiteListedAppsRegex -and $item -cmatch $global:WhiteListedAppsRegex ) { $string += " Conflict Whitelist " }
            if ( $null -notmatch $Installed -and $Installed -cmatch $item) { $string += "Installed" }
            if ( $null -notmatch $AllUsers -and $AllUsers -cmatch $item) { $string += " AllUsers" }
            if ( $null -notmatch $Online -and $Online -cmatch $item) { $string += " Online" }
            AddAppToCustomizeForm $checkboxCounter $item $true $true $string
            ++$checkboxCounter
        }
        foreach ( $item in $AllUsers ) {
            $string = "NEW   AllUsers"
            if ( $null -notmatch $NonRemovables -and $NonRemovables -cmatch $item ) { continue }
            if ( $null -notmatch $global:WhiteListedAppsRegex -and $item -cmatch $global:WhiteListedAppsRegex ) { continue }
            if ( $null -notmatch $global:BloatwareRegex -and $item -cmatch $global:BloatwareRegex ) { continue }
            if ( $null -notmatch $Installed -and $Installed -cmatch $item) { $string += " Installed" }
            if ( $null -notmatch $Online -and $Online -cmatch $item) { $string += " Online" }
            AddAppToCustomizeForm $checkboxCounter $item $true $true $string
            ++$checkboxCounter
        }
        foreach ( $item in $Installed ) {
            $string = "NEW   Installed"
            if ( $null -notmatch $NonRemovables -and $NonRemovables -cmatch $item ) { continue }
            if ( $null -notmatch $global:WhiteListedAppsRegex -and $item -cmatch $global:WhiteListedAppsRegex ) { continue }
            if ( $null -notmatch $global:BloatwareRegex -and $item -cmatch $global:BloatwareRegex ) { continue }
            if ( $null -notmatch $AllUsers -and $AllUsers -cmatch $item) { continue }
            if ( $null -notmatch $Online -and $Online -cmatch $item) { $string += " Online" }
            AddAppToCustomizeForm $checkboxCounter $item $true $true $string
            ++$checkboxCounter
        }
        foreach ( $item in $Online ) {
            $string = "NEW   Online "
            if ( $null -notmatch $NonRemovables -and $NonRemovables -cmatch $item ) { continue }
            if ( $null -notmatch $global:WhiteListedAppsRegex -and $item -cmatch $global:WhiteListedAppsRegex ) { continue }
            if ( $null -notmatch $global:BloatwareRegex -and $item -cmatch $global:BloatwareRegex ) { continue }
            if ( $null -notmatch $Installed -and $Installed -cmatch $item) { continue }
            if ( $null -notmatch $AllUsers -and $AllUsers -cmatch $item) { continue }
            AddAppToCustomizeForm $checkboxCounter $item $true $true $string
            ++$checkboxCounter
        }
        [void]$CustomizeForm.ShowDialog()

    })
$RemoveBlacklist.Add_Click( { 
        $ErrorActionPreference = 'silentlycontinue'
        Function DebloatBlacklist {
            Write-Host "Requesting removal of $global:BloatwareRegex"
            Write-Host "--- This may take a while - please be patient ---"
            Get-AppxPackage | Where-Object Name -cmatch $global:BloatwareRegex | Remove-AppxPackage
            Write-Host "...now starting the silent ProvisionedPackage bloatware removal..."
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -cmatch $global:BloatwareRegex | Remove-AppxProvisionedPackage -Online
            Write-Host "...and the final cleanup..."
            Get-AppxPackage -AllUsers | Where-Object Name -cmatch $global:BloatwareRegex | Remove-AppxPackage
        }
        Write-Host "Removing blacklisted Bloatware."
        DebloatBlacklist
        Write-Host "Bloatware removed!"
    })
$RemoveAllBloatware.Add_Click( { 
        $ErrorActionPreference = 'silentlycontinue'
        #This function finds any AppX/AppXProvisioned package and uninstalls it, except for Freshpaint, Windows Calculator, Windows Store, and Windows Photos.
        #Also, to note - This does NOT remove essential system services/software/etc such as .NET framework installations, Cortana, Edge, etc.

        #This is the switch parameter for running this script as a 'silent' script, for use in MDT images or any type of mass deployment without user interaction.

        Function Begin-SysPrep {

            Write-Host "Starting Sysprep Fixes"
   
            # Disable Windows Store Automatic Updates
            Write-Host "Adding Registry key to Disable Windows Store Automatic Updates"
            $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
            If (!(Test-Path $registryPath)) {
                Mkdir $registryPath
                New-ItemProperty $registryPath AutoDownload -Value 2 
            }
            Set-ItemProperty $registryPath AutoDownload -Value 2

            #Stop WindowsStore Installer Service and set to Disabled
            Write-Host "Stopping InstallService"
            Stop-Service InstallService
            Write-Host "Setting InstallService Startup to Disabled"
            Set-Service InstallService -StartupType Disabled
        }
        
        Function CheckDMWService {

            Param([switch]$Debloat)
  
            If (Get-Service dmwappushservice | Where-Object { $_.StartType -eq "Disabled" }) {
                Set-Service dmwappushservice -StartupType Automatic
            }

            If (Get-Service dmwappushservice | Where-Object { $_.Status -eq "Stopped" }) {
                Start-Service dmwappushservice
            } 
        }

        Function DebloatAll {
            #Removes AppxPackages
            Get-AppxPackage | Where { !($_.Name -cmatch $global:WhiteListedAppsRegex) -and !($NonRemovables -cmatch $_.Name) } | Remove-AppxPackage
            Get-AppxProvisionedPackage -Online | Where { !($_.DisplayName -cmatch $global:WhiteListedAppsRegex) -and !($NonRemovables -cmatch $_.DisplayName) } | Remove-AppxProvisionedPackage -Online
            Get-AppxPackage -AllUsers | Where { !($_.Name -cmatch $global:WhiteListedAppsRegex) -and !($NonRemovables -cmatch $_.Name) } | Remove-AppxPackage
        }
  
        #Creates a PSDrive to be able to access the 'HKCR' tree
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
  
        Function Remove-Keys {         
            #These are the registry keys that it will delete.
          
            $Keys = @(
          
                #Remove Background Tasks
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
          
                #Windows File
                "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
          
                #Registry keys to delete if they aren't uninstalled by RemoveAppXPackage/RemoveAppXProvisionedPackage
                "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
                "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
                "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
          
                #Scheduled Tasks to delete
                "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
          
                #Windows Protocol Keys
                "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
                "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
             
                #Windows Share Target
                "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            )
      
            #This writes the output of each key it is removing and also removes the keys listed above.
            ForEach ($Key in $Keys) {
                Write-Host "Removing $Key from registry"
                Remove-Item $Key -Recurse
            }
        }
          
        Function Protect-Privacy { 
  
            #Creates a PSDrive to be able to access the 'HKCR' tree
            New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
          
            #Disables Windows Feedback Experience
            Write-Host "Disabling Windows Feedback Experience program"
            $Advertising = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
            If (Test-Path $Advertising) {
                Set-ItemProperty $Advertising Enabled -Value 0
            }
          
            #Stops Cortana from being used as part of your Windows Search Function
            Write-Host "Stopping Cortana from being used as part of your Windows Search Function"
            $Search = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
            If (Test-Path $Search) {
                Set-ItemProperty $Search AllowCortana -Value 0
            }
          
            #Stops the Windows Feedback Experience from sending anonymous data
            Write-Host "Stopping the Windows Feedback Experience program"
            $Period1 = 'HKCU:\Software\Microsoft\Siuf'
            $Period2 = 'HKCU:\Software\Microsoft\Siuf\Rules'
            $Period3 = 'HKCU:\Software\Microsoft\Siuf\Rules\PeriodInNanoSeconds'
            If (!(Test-Path $Period3)) { 
                mkdir $Period1
                mkdir $Period2
                mkdir $Period3
                New-ItemProperty $Period3 PeriodInNanoSeconds -Value 0
            }
                 
            Write-Host "Adding Registry key to prevent bloatware apps from returning"
            #Prevents bloatware applications from returning
            $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
            If (!(Test-Path $registryPath)) {
                Mkdir $registryPath
                New-ItemProperty $registryPath DisableWindowsConsumerFeatures -Value 1 
            }          
      
            Write-Host "Setting Mixed Reality Portal value to 0 so that you can uninstall it in Settings"
            $Holo = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic'    
            If (Test-Path $Holo) {
                Set-ItemProperty $Holo FirstRunSucceeded -Value 0
            }
      
            #Disables live tiles
            Write-Host "Disabling live tiles"
            $Live = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'    
            If (!(Test-Path $Live)) {
                mkdir $Live  
                New-ItemProperty $Live NoTileApplicationNotification -Value 1
            }
      
            #Turns off Data Collection via the AllowTelemtry key by changing it to 0
            Write-Host "Turning off Data Collection"
            $DataCollection = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'    
            If (Test-Path $DataCollection) {
                Set-ItemProperty $DataCollection AllowTelemetry -Value 0
            }
      
            #Disables People icon on Taskbar
            Write-Host "Disabling People icon on Taskbar"
            $People = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
            If (Test-Path $People) {
                Set-ItemProperty $People PeopleBand -Value 0
            }
  
            #Disables suggestions on start menu
            Write-Host "Disabling suggestions on the Start Menu"
            $Suggestions = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'    
            If (Test-Path $Suggestions) {
                Set-ItemProperty $Suggestions SystemPaneSuggestionsEnabled -Value 0
            }
            
            
            Write-Host "Removing CloudStore from registry if it exists"
            $CloudStore = 'HKCUSoftware\Microsoft\Windows\CurrentVersion\CloudStore'
            If (Test-Path $CloudStore) {
                Stop-Process Explorer.exe -Force
                Remove-Item $CloudStore
                Start-Process Explorer.exe -Wait
            }
  
            #Loads the registry keys/values below into the NTUSER.DAT file which prevents the apps from redownloading. Credit to a60wattfish
            reg load HKU\Default_User C:\Users\Default\NTUSER.DAT
            Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name SystemPaneSuggestionsEnabled -Value 0
            Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name PreInstalledAppsEnabled -Value 0
            Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name OemPreInstalledAppsEnabled -Value 0
            reg unload HKU\Default_User
      
            #Disables scheduled tasks that are considered unnecessary 
            Write-Host "Disabling scheduled tasks"
            #Get-ScheduledTask -TaskName XblGameSaveTaskLogon | Disable-ScheduledTask
            Get-ScheduledTask -TaskName XblGameSaveTask | Disable-ScheduledTask
            Get-ScheduledTask -TaskName Consolidator | Disable-ScheduledTask
            Get-ScheduledTask -TaskName UsbCeip | Disable-ScheduledTask
            Get-ScheduledTask -TaskName DmClient | Disable-ScheduledTask
            Get-ScheduledTask -TaskName DmClientOnScenarioDownload | Disable-ScheduledTask
        }

        Function UnpinStart {
            #Credit to Vikingat-Rage
            #https://superuser.com/questions/1068382/how-to-remove-all-the-tiles-in-the-windows-10-start-menu
            #Unpins all tiles from the Start Menu
            Write-Host "Unpinning all tiles from the start menu"
            (New-Object -Com Shell.Application).
            NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').
            Items() |
            % { $_.Verbs() } |
            ? { $_.Name -match 'Un.*pin from Start' } |
            % { $_.DoIt() }
        }

        Function Remove3dObjects {
            #Removes 3D Objects from the 'My Computer' submenu in explorer
            Write-Output "Removing 3D Objects from explorer 'My Computer' submenu"
            $Objects32 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
            $Objects64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
            If (Test-Path $Objects32) {
                Remove-Item $Objects32 -Recurse 
            }
            If (Test-Path $Objects64) {
                Remove-Item $Objects64 -Recurse 
            }
        }

  
        Function CheckDMWService {

            Param([switch]$Debloat)
  
            If (Get-Service dmwappushservice | Where-Object { $_.StartType -eq "Disabled" }) {
                Set-Service dmwappushservice -StartupType Automatic
            }

            If (Get-Service dmwappushservice | Where-Object { $_.Status -eq "Stopped" }) {
                Start-Service dmwappushservice
            } 
        }
        
        Function CheckInstallService {
  
            If (Get-Service InstallService | Where-Object { $_.Status -eq "Stopped" }) {  
                Start-Service InstallService
                Set-Service InstallService -StartupType Automatic 
            }
        }
  
        Write-Host "Initiating Sysprep"
        Begin-SysPrep
        Write-Host "Removing bloatware apps."
        DebloatAll
        Write-Host "Removing leftover bloatware registry keys."
        Remove-Keys
        Write-Host "Checking to see if any Whitelisted Apps were removed, and if so re-adding them."
        FixWhitelistedApps
        Write-Host "Stopping telemetry, disabling unneccessary scheduled tasks, and preventing bloatware from returning."
        Protect-Privacy
        Write-Host "Unpinning tiles from the Start Menu."
        UnpinStart
        Write-Host "Setting the 'InstallService' Windows service back to 'Started' and the Startup Type 'Automatic'."
        CheckDMWService
        CheckInstallService
        Write-Host "Finished all tasks. `n"
  
    } )
$DisableTaskbarbloat.Add_Click( { 
        $ErrorActionPreference = 'silentlycontinue'
        Write-Host "Disabling Cortana"
        $Cortana1 = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"
        $Cortana2 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
        $Cortana3 = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
        $TaskbarButtons = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $SearchHighlights = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        $meetnow1 = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"

        If (!(Test-Path $Cortana1)) {
            New-Item $Cortana1
        }
        Set-ItemProperty $Cortana1 AcceptedPrivacyPolicy -Value 0 
        If (!(Test-Path $Cortana2)) {
            New-Item $Cortana2
        }
        Set-ItemProperty $Cortana2 RestrictImplicitTextCollection -Value 1 
        Set-ItemProperty $Cortana2 RestrictImplicitInkCollection -Value 1 
        If (!(Test-Path $Cortana3)) {
            New-Item $Cortana3
        }
        Set-ItemProperty $Cortana3 HarvestContacts -Value 0
        Set-ItemProperty $TaskbarButtons ShowCortanaButton -Value 0
        Set-ItemProperty $TaskbarButtons ShowTaskViewButton -Value 0 
        Set-ItemProperty $TaskbarButtons TaskbarMn -Value 0 
        Set-ItemProperty $TaskbarButtons HideSCAMeetNow -Value 0 
        New-Item $SearchHighlights -Force
        New-ItemProperty $SearchHighlights -Name "EnableDynamicContentInWSB" -PropertyType DWORD -Value 0
        If (!(Test-Path $meetnow1)) {
            New-Item $meetnow1
        }
        Set-ItemProperty $meetnow1 HideSCAMeetNow -Value 1 
        taskkill /f /im explorer.exe
        Start-Process explorer.exe
        Write-Host "Taskbar Bloat Has Been Removed."
    })
$LongSleep.Add_Click( { 
        $ErrorActionPreference = 'silentlycontinue'
        Write-Host "Changing Sleep Settings"
        Powercfg /Change monitor-timeout-ac 60
        Powercfg /Change monitor-timeout-dc 20
        Powercfg /Change standby-timeout-ac 120
        Powercfg /Change standby-timeout-dc 50
        Write-Host "Sleep Settings Changed."
    })
$StopEdgePDFTakeover.Add_Click( { 
        $ErrorActionPreference = 'silentlycontinue'
        #Stops edge from taking over as the default .PDF viewer    
        Write-Host "Stopping Edge from taking over as the default .PDF viewer"
        $NoPDF = "HKCR:\.pdf"
        $NoProgids = "HKCR:\.pdf\OpenWithProgids"
        $NoWithList = "HKCR:\.pdf\OpenWithList" 
        If (!(Get-ItemProperty $NoPDF  NoOpenWith)) {
            New-ItemProperty $NoPDF NoOpenWith 
        }        
        If (!(Get-ItemProperty $NoPDF  NoStaticDefaultVerb)) {
            New-ItemProperty $NoPDF  NoStaticDefaultVerb 
        }        
        If (!(Get-ItemProperty $NoProgids  NoOpenWith)) {
            New-ItemProperty $NoProgids  NoOpenWith 
        }        
        If (!(Get-ItemProperty $NoProgids  NoStaticDefaultVerb)) {
            New-ItemProperty $NoProgids  NoStaticDefaultVerb 
        }        
        If (!(Get-ItemProperty $NoWithList  NoOpenWith)) {
            New-ItemProperty $NoWithList  NoOpenWith
        }        
        If (!(Get-ItemProperty $NoWithList  NoStaticDefaultVerb)) {
            New-ItemProperty $NoWithList  NoStaticDefaultVerb 
        }
            
        #Appends an underscore '_' to the Registry key for Edge
        $Edge = "HKCR:\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_"
        If (Test-Path $Edge) {
            Set-Item $Edge AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_ 
        }
        Write-Host "Edge should no longer take over as the default .PDF."
    })
$DisableTelemetry.Add_Click( { 
        $ErrorActionPreference = 'silentlycontinue'
        #Disables Windows Feedback Experience
        Write-Host "Disabling Windows Feedback Experience program"
        $Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        If (Test-Path $Advertising) {
            Set-ItemProperty $Advertising Enabled -Value 0 
        }
            
        #Stops Cortana from being used as part of your Windows Search Function
        Write-Host "Stopping Cortana from being used as part of your Windows Search Function"
        $Search = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        If (Test-Path $Search) {
            Set-ItemProperty $Search AllowCortana -Value 0 
        }

        #Disables Web Search in Start Menu
        Write-Host "Disabling Bing Search in Start Menu"
        $WebSearch = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled -Value 0 
        If (!(Test-Path $WebSearch)) {
            New-Item $WebSearch
        }
        Set-ItemProperty $WebSearch DisableWebSearch -Value 1 
            
        #Stops the Windows Feedback Experience from sending anonymous data
        Write-Host "Stopping the Windows Feedback Experience program"
        $Period = "HKCU:\Software\Microsoft\Siuf\Rules"
        If (!(Test-Path $Period)) { 
            New-Item $Period
        }
        Set-ItemProperty $Period PeriodInNanoSeconds -Value 0 

        #Prevents bloatware applications from returning and removes Start Menu suggestions               
        Write-Host "Adding Registry key to prevent bloatware apps from returning"
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        $registryOEM = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        If (!(Test-Path $registryPath)) { 
            New-Item $registryPath
        }
        Set-ItemProperty $registryPath DisableWindowsConsumerFeatures -Value 1 

        If (!(Test-Path $registryOEM)) {
            New-Item $registryOEM
        }
        Set-ItemProperty $registryOEM  ContentDeliveryAllowed -Value 0 
        Set-ItemProperty $registryOEM  OemPreInstalledAppsEnabled -Value 0 
        Set-ItemProperty $registryOEM  PreInstalledAppsEnabled -Value 0 
        Set-ItemProperty $registryOEM  PreInstalledAppsEverEnabled -Value 0 
        Set-ItemProperty $registryOEM  SilentInstalledAppsEnabled -Value 0 
        Set-ItemProperty $registryOEM  SystemPaneSuggestionsEnabled -Value 0          
    
        #Preping mixed Reality Portal for removal    
        Write-Host "Setting Mixed Reality Portal value to 0 so that you can uninstall it in Settings"
        $Holo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic"    
        If (Test-Path $Holo) {
            Set-ItemProperty $Holo  FirstRunSucceeded -Value 0 
        }

        #Disables Wi-fi Sense
        Write-Host "Disabling Wi-Fi Sense"
        $WifiSense1 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
        $WifiSense2 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
        $WifiSense3 = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
        If (!(Test-Path $WifiSense1)) {
            New-Item $WifiSense1
        }
        Set-ItemProperty $WifiSense1  Value -Value 0 
        If (!(Test-Path $WifiSense2)) {
            New-Item $WifiSense2
        }
        Set-ItemProperty $WifiSense2  Value -Value 0 
        Set-ItemProperty $WifiSense3  AutoConnectAllowedOEM -Value 0 
        
        #Disables live tiles
        Write-Host "Disabling live tiles"
        $Live = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"    
        If (!(Test-Path $Live)) {      
            New-Item $Live
        }
        Set-ItemProperty $Live  NoTileApplicationNotification -Value 1 
        
        #Turns off Data Collection via the AllowTelemtry key by changing it to 0
        Write-Host "Turning off Data Collection"
        $DataCollection1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        $DataCollection2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        $DataCollection3 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection"    
        If (Test-Path $DataCollection1) {
            Set-ItemProperty $DataCollection1  AllowTelemetry -Value 0 
        }
        If (Test-Path $DataCollection2) {
            Set-ItemProperty $DataCollection2  AllowTelemetry -Value 0 
        }
        If (Test-Path $DataCollection3) {
            Set-ItemProperty $DataCollection3  AllowTelemetry -Value 0 
        }
    
        #Disabling Location Tracking
        Write-Host "Disabling Location Tracking"
        $SensorState = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
        $LocationConfig = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
        If (!(Test-Path $SensorState)) {
            New-Item $SensorState
        }
        Set-ItemProperty $SensorState SensorPermissionState -Value 0 
        If (!(Test-Path $LocationConfig)) {
            New-Item $LocationConfig
        }
        Set-ItemProperty $LocationConfig Status -Value 0 
        
        #Disables People icon on Taskbar
        Write-Host "Disabling People icon on Taskbar"
        $People = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
        If (Test-Path $People) {
            Set-ItemProperty $People -Name PeopleBand -Value 0
        } 
        
        #Disables scheduled tasks that are considered unnecessary 
        Write-Host "Disabling scheduled tasks"
        #Get-ScheduledTask  XblGameSaveTaskLogon | Disable-ScheduledTask
        Get-ScheduledTask  XblGameSaveTask | Disable-ScheduledTask
        Get-ScheduledTask  Consolidator | Disable-ScheduledTask
        Get-ScheduledTask  UsbCeip | Disable-ScheduledTask
        Get-ScheduledTask  DmClient | Disable-ScheduledTask
        Get-ScheduledTask  DmClientOnScenarioDownload | Disable-ScheduledTask

        #Write-Host "Uninstalling Telemetry Windows Updates"
        #Uninstalls Some Windows Updates considered to be Telemetry. !WIP!
        #Wusa /Uninstall /KB:3022345 /norestart /quiet
        #Wusa /Uninstall /KB:3068708 /norestart /quiet
        #Wusa /Uninstall /KB:3075249 /norestart /quiet
        #Wusa /Uninstall /KB:3080149 /norestart /quiet        

        Write-Host "Stopping and disabling WAP Push Service"
        #Stop and disable WAP Push Service
        Stop-Service "dmwappushservice"
        Set-Service "dmwappushservice" -StartupType Disabled

        Write-Host "Stopping and disabling Diagnostics Tracking Service"
        #Disabling the Diagnostics Tracking Service
        Stop-Service "DiagTrack"
        Set-Service "DiagTrack" -StartupType Disabled
        Write-Host "Telemetry has been disabled!"
    })
$RemoveRegkeys.Add_Click( { 
        $ErrorActionPreference = 'silentlycontinue'
        $Keys = @(
            
            New-PSDrive  HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
            #Remove Background Tasks
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
            
            #Windows File
            "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            
            #Registry keys to delete if they aren't uninstalled by RemoveAppXPackage/RemoveAppXProvisionedPackage
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
            
            #Scheduled Tasks to delete
            "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
            
            #Windows Protocol Keys
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
               
            #Windows Share Target
            "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
        )
        
        #This writes the output of each key it is removing and also removes the keys listed above.
        ForEach ($Key in $Keys) {
            Write-Host "Removing $Key from registry"
            Remove-Item $Key -Recurse
        }
        Write-Host "Additional bloatware keys have been removed!"
    })
$EnableDarkMode.Add_Click( {
        Write-Host "Enabling Dark Mode"
        $Theme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Set-ItemProperty $Theme AppsUseLightTheme -Value 0
        Set-ItemProperty $Theme SystemUsesLightTheme -Value 0
        Start-Sleep 1
        Write-Host "Enabled"
    }
)
$DisableDarkMode.Add_Click( {
        Write-Host "Disabling Dark Mode"
        $Theme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Set-ItemProperty $Theme AppsUseLightTheme -Value 1
        Set-ItemProperty $Theme SystemUsesLightTheme -Value 1
        Start-Sleep 1
        Write-Host "Disabled"
    }
)
$BasicSS.Add_Click( {
    if (Test-ChocolateyInstalled) {
        Write-Host "Chocolatey is installed."
    Write-Host "Installing Google Chrome"
    choco install googlechrome
    Write-Host "Installed Google Chrome"

    Write-Host "Installing Firefox"
    choco install firefox
    Write-Host "Installed Firefox"
    
    Write-Host "Installing Adobe Reader DC"
    choco install adobereader
    Write-Host "Installed Adobe Reader DC"
    
    Write-Host "Installing Teamviewer"
    choco install teamviewer
    Write-Host "Installed Teamviewer"
    
    Write-Host "Installing Unchecky"
    choco install unchecky
    Write-Host "Installed Unchecky"
    
    Write-Host "Installing VLC"
    choco install vlc
    Write-Host "Installed VLC"
} else {
    Write-Host "Chocolatey is not installed. Please install Chocolatey before continuing."
}
})
$UnBasicSS.Add_Click( {
    if (Test-ChocolateyInstalled) {
        Write-Host "Chocolatey is installed."
    Write-Host "Uninstalling Google Chrome"
    choco uninstall googlechrome
    Write-Host "Uninstalled Google Chrome"

    Write-Host "Uninstalling Firefox"
    choco uninstall firefox
    Write-Host "Uninstalled Firefox"
    
    Write-Host "Uninstalling Adobe Reader DC"
    choco uninstall adobereader
    Write-Host "Uninstalled Adobe Reader DC"
    
    Write-Host "Uninstalling Teamviewer"
    choco uninstall teamviewer
    Write-Host "Uninstalled Teamviewer"
    
    Write-Host "Uninstalling Unchecky"
    choco uninstall unchecky
    Write-Host "Uninstalled Unchecky"
    
    Write-Host "Uninstalling VLC"
    choco uninstall vlc
    Write-Host "Uninstalled VLC"
} else {
    Write-Host "Chocolatey is not installed. Please install Chocolatey before continuing."
}
})
$ISFile.Add_Click( {
    if (Test-ChocolateyInstalled) {
        Write-Host "Chocolatey is installed."
        Write-Host "Launching Auto Installer"
        Write-Host "This will take some time..."
        . .\Autoinstaller.ps1
        Write-Host "Auto Intaller Finished."
    } else {
        Write-Host "Chocolatey is not installed. Please install Chocolatey before continuing."
    }
    })
$ITDB.Add_Click( {
if (Test-ChocolateyInstalled) {
        Write-Host "Chocolatey is installed."
        Write-Host "Installing Todo Backup"
        choco install todobackup
        Write-Host "Installed Todo Backup"
    } else {
    Write-Host "Chocolatey is not installed. Please install Chocolatey before continuing."
}
})
$InsatllGames.Add_Click( {
    if (Test-ChocolateyInstalled) {
        Write-Host "Chocolatey is installed."
        Write-Host "Installing Game Launchers"
        Write-Host "Installing Steam"
        Choco install steam
        Write-Host "Installed Steam"

        Write-Host "Installing Epic Games"
        Choco install epicgameslauncher
        Write-Host "Installed Epic Games"

        Write-Host "Finished Installing Game Launchers."
    } else {
        Write-Host "Chocolatey is not installed. Please install Chocolatey before continuing."
    }
    })

    [void]$Form.ShowDialog()
