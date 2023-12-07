# Load the HtmlAgilityPack assembly
$scriptPath = $MyInvocation.MyCommand.Path
$htmlAgilityPackDll = Join-Path (Split-Path $scriptPath) "HtmlAgilityPack.dll"
Add-Type -Path $htmlAgilityPackDll

# Set the path for the output file
$outputFilePath = "C:\Temp\DebloatAndFloat\Logs\Autoinstaller.txt"
$IDoutputFilePath = "C:\Temp\DebloatAndFloat\Logs\IDOutPut.txt"

# Redirect the output to the Autoinstaller.txt file
Start-Transcript -Path $outputFilePath -Append

Function TimedPrompt($prompt,$secondsToWait){   
    Write-Host -NoNewline $prompt
    $secondsCounter = 0
    $subCounter = 0
    While ( $secondsCounter -lt $secondsToWait ){
        if ([Console]::KeyAvailable){break}
        start-sleep -m 10
        $subCounter = $subCounter + 10
        if($subCounter -eq 1000)
        {
            $secondsCounter++
            $subCounter = 0
            Write-Host -NoNewline "."
        }       
        If ($secondsCounter -eq $secondsToWait) { 
            Write-Host "`r`n"
            return $false;
        }
    }
    Write-Host "`r`n"
    return $true;
}

function Install-ChocoPackage {
    param (
        [string]$packageName
    )

    Write-Host "Installing $packageName..."

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "choco.exe"
    $processInfo.Arguments = "install $packageName -y --ignore-checksums"
    $processInfo.RedirectStandardOutput = $false
    $processInfo.RedirectStandardError = $false
    $processInfo.UseShellExecute = $false
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null
    $process.WaitForExit()
}

function Install-WinGetPackage {
    param (
        [string]$packageName
    )

    Write-Host "Installing $packageName..."

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "powershell.exe"
    $processInfo.Arguments = "winget install --id `"$packageName`" -h --accept-package-agreements --accept-source-agreements"
    $processInfo.RedirectStandardOutput = $false
    $processInfo.RedirectStandardError = $false
    $processInfo.UseShellExecute = $false
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null
    $process.WaitForExit()
}

function Extract-ContentUsingHAP {
    param (
        [string]$htmlContent
    )

    $hapDoc = New-Object -TypeName HtmlAgilityPack.HtmlDocument
    $hapDoc.LoadHtml($htmlContent)

    $groupedResults = @()

    # Get all <tr> elements with <strong> tags
    $tableRows = $hapDoc.DocumentNode.SelectNodes("//tr[.//strong]")

    if ($null -ne $tableRows) {
        $currentProgram = $null
        $supportUrls = @()
        foreach ($row in $tableRows) {
            $strongTagNode = $row.SelectSingleNode(".//strong")
            $strongTagContent = if ($null -ne $strongTagNode) { $strongTagNode.InnerText } else { "" }

            # Clean up the program name (Remove text enclosed between #### and #### and all surrounding # characters if it exists)
            $strongTagContent = $strongTagContent -replace "(?s) - #*?####.*?#####*", ""

            # Trim leading and trailing whitespaces
            $strongTagContent = $strongTagContent.Trim()

            # Check if the current row contains a program name
            if (![string]::IsNullOrWhiteSpace($strongTagContent) -and $strongTagContent -notlike "*User name*") {
                $skipProgram = $strongTagContent -match "SQL|SDK|Driver|Redistributable|Runtime|PhysX|Bonjour|Acer|Asus|Canon|Brother|Toshiba"
                if ($skipProgram) {
                    continue
                }

            # Check if the current row contains a program name
            if (![string]::IsNullOrWhiteSpace($strongTagContent) -and $strongTagContent -notlike "*User name*") {
                if ($currentProgram -and $supportUrls.Count -le 6) {
                    if ($supportUrls.Count -gt 0) {
                        $hasSteamUrl = $supportUrls -like "*https://help.steampowered.com/*"
                        if (!$hasSteamUrl) {
                            # Output the program name and support URLs to the console in real-time
                            Write-Host "Program Name: $currentProgram"
                            Write-Host "Support URLs: $($supportUrls -join ', ')"
                            Write-Host "------------------------"

                            # Add the data to $groupedResults array
                            $groupedResults += [PSCustomObject]@{
                                StrongTagContent = $currentProgram
                                SupportUrls = $supportUrls
                            }
                        }
                    } else {
                        # Output the program name without support URLs
                        Write-Host "Program Name: $currentProgram"
                        Write-Host "No support URLs available."
                        Write-Host "------------------------"

                        # Add the data to $groupedResults array
                        $groupedResults += [PSCustomObject]@{
                            StrongTagContent = $currentProgram
                            SupportUrls = $supportUrls
                        }
                    }
                }

                $currentProgram = $strongTagContent
                $supportUrls = @()  # Clear the support URLs for the new program
            }

            # Find the <a> tags within the current <tr> element
            $aNodes = $row.SelectNodes(".//a[starts-with(@href, 'http')]")

            if ($aNodes -ne $null) {
                foreach ($aNode in $aNodes) {
                    $url = $aNode.GetAttributeValue("href", "")
                    $supportUrls += $url
                }
            }
        }
    }
        # Add the last program if it's not excluded and has valid support URLs
        if ($currentProgram -and $supportUrls.Count -le 6) {
            if ($supportUrls.Count -gt 0) {
                $hasSteamUrl = $supportUrls -like "*https://help.steampowered.com/*"
                if (!$hasSteamUrl) {
                    # Output the program name and support URLs to the console in real-time
                    Write-Host "Program Name: $currentProgram"
                    Write-Host "Support URLs: $($supportUrls -join ', ')"
                    Write-Host "------------------------"

                    # Add the data to $groupedResults array
                    $groupedResults += [PSCustomObject]@{
                        StrongTagContent = $currentProgram
                        SupportUrls = $supportUrls
                    }
                }
            } else {
                # Output the program name without support URLs
                Write-Host "Program Name: $currentProgram"
                Write-Host "No support URLs available."
                Write-Host "------------------------"

                # Add the data to $groupedResults array
                $groupedResults += [PSCustomObject]@{
                    StrongTagContent = $currentProgram
                    SupportUrls = $supportUrls
                }
            }
        }
    }
    return $groupedResults
}

# Database of program names and their corresponding Chocolatey package names
$chocoProgramDatabase = @{
    "CrystalDiskInfo" = "Crystaldiskinfo"
    "CrystalDiskMark" = "Crystaldiskmark"
    "Kaspersky Internet Security" = "kis"
    "Keypass" = "keepass"
    "Macrium Reflect Free" = "reflect-free"
    "Nexus Mod Manager" = "nmm"
    "Rockstar Games Launcher" = "rockstar-launcher"
    "Fitbit Connect" = "fitbit.connect"
    "VLC media player" = "vlc"
    "AOMEI Partition Assistant" = "partition-assistant-standard"
}

# Database of program names and their corresponding winget package names
$wingetProgramDatabase = @{
    "Google Chrome" = "Google.Chrome"
    "Firefox" = "Mozilla.Firefox"
    "Steam" = "Valve.Steam"
    "Teamviewer" = "TeamViewer.TeamViewer"
    "Google Drive" = "Google.GoogleDrive"
    "WinRAR" = "RARLab.WinRAR"
    "CCleaner" = "Piriform.CCleaner"
    "Skype" = "Microsoft.Skype"
    "gimp" = "GIMP.GIMP"
    "Thunderbird" = "Mozilla.Thunderbird"
    "Spotify" = "Spotify.Spotify"
    "Brave Browser" = "XP8C9QZMS2PC1T"
    "iTunes" = "Apple.iTunes"
    "Google Earth" = "Google.EarthPro"
    "Blender" = "BlenderFoundation.Blender"
    "Discord" = "Discord.Discord"
    "OBS Studio" = "OBSProject.OBSStudio"
    "Origin" = "ElectronicArts.EADesktop"
    "GOG Galaxy" = "GOG.Galaxy"
    "iCloud" = "9PKTQ5699M62"
    "AVG Antivirus Free" = "XP8BX2DWV7TF50"
    "Ubisoft Connect" = "Ubisoft.Connect"
    "VMware Workstation Player" = "VMware.WorkstationPlayer"
    "Plex" = "Plex.Plex"
    "Authy Desktop" = "Twilio.Authy"
    "RetroArch" = "libretro.RetroArch"
    "Opera GX" = "Opera.OperaGX"
    "QFinder Pro" = "QNAP.QfinderPro"
    "EA Desktop Client" = "ElectronicArts.EADesktop"
    "EaseUS Todo Backup" = "EaseUS.TodoBackup"
    "SideQuest" = "SideQuestVR.SideQuest"
    "NextDNS" = "NextDNS.NextDNS.Desktop"
    "Visual Studio Code" = "Microsoft.VisualStudioCode"
    "Adobe Acrobat DC" = "Adobe.Acrobat.Reader.64-bit"
    "Unchecky" = "Unchecky.Unchecky"
}

if (Get-Command "winget" -ErrorAction SilentlyContinue) {
    Write-Host "Winget is installed."
} else {
    Write-Host "Winget is not installed."
    $progressPreference = 'silentlyContinue'
Invoke-WebRequest `
    -URI https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3 `
    -OutFile xaml.zip -UseBasicParsing
New-Item -ItemType Directory -Path xaml
Expand-Archive -Path xaml.zip -DestinationPath xaml
Add-AppxPackage -Path "xaml\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx"
Remove-Item xaml.zip
Remove-Item xaml -Recurse
$latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
$latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]
Write-Information "Downloading winget to artifacts directory..."
Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "./$latestWingetMsixBundle"
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx
Add-AppxPackage $latestWingetMsixBundle
}

# Explicitly load the Windows Forms assembly
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.Application]::EnableVisualStyles()

# Create and display the file dialog box
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.InitialDirectory = 'C:\Users\Public\Desktop'
$openFileDialog.Filter = "HTML Files (*.html;*.htm)|*.html;*.htm|All Files (*.*)|*.*"
$openFileDialog.Title = "Select an HTML file"


# Check if the user selected a file and proceed accordingly
if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $htmlFilePath = $openFileDialog.FileName

    $htmlContent = Get-Content -Path $htmlFilePath -Raw

    $groupedResults = Extract-ContentUsingHAP $htmlContent

    $outputContent = @()

    # Prompt for mode selection
    Write-Host "Set and forget disables all prompts required to install programs and skips them"
    $setAndForget = TimedPrompt "Press any button in 15 seconds to disable set and forget." 15

    # Initialize an array to store program names that couldn't be found or installed
    $unavailablePrograms = @()

    foreach ($result in $groupedResults) {
        $programName = $result.StrongTagContent

    # Search for the corresponding Chocolatey package name based on partial matches
    $chocoPackage = $chocoProgramDatabase.GetEnumerator() | Where-Object {
        $programName -like "*$($_.Key)*"
    } | Select-Object -ExpandProperty Value

    if ($chocoPackage) {
        Install-ChocoPackage $chocoPackage
    }

    # Search for the corresponding WinGet package name based on partial matches
    $winGetPackage = $wingetProgramDatabase.GetEnumerator() | Where-Object {
        $programName -like "*$($_.Key)*"
    } | Select-Object -ExpandProperty Value

    if ($winGetPackage) {
        Install-WinGetPackage $winGetPackage
    }

    # If it's not a Choco or WinGet package, attempt to search with winget
    if (-not ($chocoPackage -or $winGetPackage)) {
        # Define regex patterns for refinement
        $refinementPatterns = @(
            '\s+\(.*?\)',
            '\s+(release|version|update)\s+.*',
            '\b(x64|x86)\b',
            '\d+(\.\d+)*',
            '(\d+)\s*-\s*(\d+)'
        )
    
        # Refine the program name using regex patterns
        $refinedProgramName = $programName
        foreach ($pattern in $refinementPatterns) {
            $refinedProgramName = $refinedProgramName -replace $pattern, ''
        }
        $refinedProgramName = $refinedProgramName.Trim()
    
        # Search for packages using refined program name
        $packageAvailable = winget show $refinedProgramName --accept-source-agreements
    
        if ($packageAvailable) {
            $noPackageFound = $packageAvailable -contains "No package found matching input criteria."
            $ExactMatch = $packageAvailable -match ("Found $([regex]::Escape($refinedProgramName))")
            $OneResult = $packageAvailable -match ("^Found\s+.*$([regex]::Escape($refinedProgramName))")
    
        if ($noPackageFound) {
            Write-Host "Unable to find '$programName' also searched for '$refinedProgramName'."
            $unavailablePrograms += "Unable to find $programName"
        } else {
            if ($ExactMatch) {
                Write-Host "Exact match found for '$refinedProgramName'."
                Write-Host "Exact match package name: $ExactMatch"
                winget install `"$refinedProgramName`" -h --accept-package-agreements --accept-source-agreements
            }
        } 

        if ($ExactMatch) {
            continue
        } else {
        if ($OneResult) {
            Write-Host "Partial match found for '$refinedProgramName'."
            Write-Host "Partial match package name: $OneResult"
            if ($setAndForget -eq $false) {
                Write-Host "Skiping due to set and forget being active"
                $unavailablePrograms += "Skiped due to set and forget being active $programName"
                continue
            } else {
                $installChoice = Read-Host "Do you want to install '$refinedProgramName'? (Y/N)"
                if ($installChoice -eq "Y") {
                    Install-WinGetPackage $refinedProgramName
                } else {
                    Write-Host "Installation of '$refinedProgramName' cancelled."
                }
            }
        }
    }
    
        if (-not ($oneresult -and $Exactmatch)) {

            if ($line -contains "\s*Multiple packages found\s*") {
        
            if ($setAndForget -eq $false) {
                Write-Host "Packages matching '$refinedProgramName' are available:"
                Write-Host "Skiping due to set and forget being active"
                $unavailablePrograms += "Skiped due to set and forget being active $programName"
                continue
            } else {
                Write-Host "Packages matching '$refinedProgramName' are available:"
                $packageLines = $packageAvailable -split '\r?\n'
                $packageInfo = @()
                $packageCount = 0
                $packageIds = @()
        
                foreach ($line in $packageLines) {
                    # Skip lines that match the "packages (found)" pattern or the "Multiple packages found" pattern
                    if ($line -match "^\s*packages\s*(\(found\))?\s*$" -or $line -match "^\s*Multiple packages found\s*") {
                        continue
                    }
        
                    $packageParts = $line -split '\s+'
                    if ($packageParts.Length -ge 4) {
                        $packageCount++
                        $packageName = $packageParts[0..($packageParts.Length - 3)] -join ' '  # Combine multiple words in the program name
                        $packageId = $packageParts[($packageParts.Length - 2)]
        
                        Write-Host "$packageCount. $packageName ($packageId)"
                        $packageInfo += [PSCustomObject]@{
                            PackageName = $packageName
                            PackageId = $packageId
                        }
                    }
                }
            }
        }
    }
    
            if ($packageCount -le 1) {  # Use $packageCount instead of $packageInfo.Count
        } else {
            $selection = Read-Host "`nEnter the line number of the package you want to install"
    
            if ([int]::TryParse($selection, [ref]$null)) {
                $selection = [int]$selection
                if ($selection -ge 1 -and $selection -le $packageInfo.Count) {
                    # Get the selected package ID
                    $selectedPackageId = $packageInfo[$selection - 1].PackageId
    
                    Write-Host "Installing package with ID '$selectedPackageId'..."
                    Install-WinGetPackage $selectedPackageId
                    Write-Host "'$refinedProgramName' with Package ID '$selectedPackageId' has been installed."
                } else {
                    Write-Host "Invalid selection. No package will be installed."
                }
            } else {
                Write-Host "Invalid input."
                $unavailablePrograms += "Couldn't install $refinedProgramName"
            }
        }
    }
}
# Output content
$outputContent += "Program Name: $refinedProgramName"
$outputContent += "Support URLs: $($result.SupportUrls -join ', ')"
$outputContent += "------------------------"
}
# Save the list of unavailable programs to a text file on the desktop
if ($unavailablePrograms.Count -gt 0) {
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $unavailableFilePath = Join-Path $desktopPath "UnavailablePrograms.txt"
    $unavailablePrograms | Out-File -FilePath $unavailableFilePath
    Write-Host "List of unavailable programs saved to: $unavailableFilePath"
}
        #$outputContent | Out-File -FilePath $outputFilePath -Encoding UTF8

        "Results saved to: $outputFilePath" | Write-Host
    } else {
        "File selection canceled by the user." | Write-Host
    }
    Stop-Transcript
