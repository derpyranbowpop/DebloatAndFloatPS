# Load the HtmlAgilityPack assembly
$scriptPath = $MyInvocation.MyCommand.Path
$htmlAgilityPackDll = Join-Path (Split-Path $scriptPath) "HtmlAgilityPack.dll"
Add-Type -Path $htmlAgilityPackDll

# Function to install a program using Chocolatey with progress and output display
function Install-ChocoPackage {
    param (
        [string]$packageName
    )

    # Initialize message
    $progressMessage = "Installing $packageName..."

    # Start the installation process asynchronously
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "choco.exe"
    $processInfo.Arguments = "install $packageName -y --ignore-checksums"
    $processInfo.RedirectStandardOutput = $false  # Do not redirect output to file
    $processInfo.RedirectStandardError = $false   # Do not redirect error output to file
    $processInfo.UseShellExecute = $false         # Required to redirect output to terminal
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null

    # Wait for the process to finish and then show the output in the terminal
    $process.WaitForExit()
}

# Function to extract content from <strong> and Support URLs using HAP (Html Agility Pack)
function Extract-ContentUsingHAP {
    param (
        [string]$htmlContent
    )

    # Load the HTML content into HAP document
    $hapDoc = New-Object -TypeName HtmlAgilityPack.HtmlDocument
    $hapDoc.LoadHtml($htmlContent)

    $groupedResults = @()

    # Get all <tr> elements with <strong> tags
    $tableRows = $hapDoc.DocumentNode.SelectNodes("//tr[.//strong]")

    if ($null -ne $tableRows) {
        $currentProgram = $null
        foreach ($row in $tableRows) {
            $strongTagNode = $row.SelectSingleNode(".//strong")
            $strongTagContent = if ($null -ne $strongTagNode) { $strongTagNode.InnerText } else { "" }

            # Clean up the program name (Remove text enclosed between #### and #### and all surrounding # characters if it exists)
            $strongTagContent = $strongTagContent -replace "(?s) - #*?####.*?#####*", ""

            # Trim leading and trailing whitespaces
            $strongTagContent = $strongTagContent.Trim()

            # Check if the current row contains a program name
            if (![string]::IsNullOrWhiteSpace($strongTagContent)) {
                $currentProgram = $strongTagContent
            }

            # Find the <a> tags within the current <tr> element
            $aNodes = $row.SelectNodes(".//a[starts-with(@href, 'http')]")

            # Extract the first 5 Support URLs from the found <a> tags
            $supportUrls = @()
            if ($null -ne $aNodes) {
                $urlCount = 0
                foreach ($aNode in $aNodes) {
                    $url = $aNode.GetAttributeValue("href", "")
                    $supportUrls += $url
                    $urlCount++

                    if ($urlCount -eq 5) {
                        break
                    }
                }
            }

            # Check if any support URL contains the specified substring to exclude the program
            #$excludeProgram = $supportUrls -like "*https://help.steampowered.com/*"
            # Removed due to a bug with the first program using other support URLs 
            if ($currentProgram -and $supportUrls.Count -gt 0 -and !$excludeProgram) {
                # Output the program name and support URLs to the console in real-time
                Write-Host "Program Name: $currentProgram"
                Write-Host "Support URLs: $supportUrls"
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
$programDatabase = @{
    "Google Chrome" = "googlechrome"
    "Firefox" = "firefox"
    "Steam" = "steam"
    "VLC media player" = "vlc"
    "Teamviewer" = "teamviewer"
    "Google Drive" = "googledrive"
    "WinRAR" = "winrar"
    "CCleaner" = "ccleaner"
    "Skype" = "skype"
    "gimp" = "gimp"
    "Thunderbird" = "thunderbird"
    "Spotify" = "spotify"
    "Keypass" = "keypass"
    "Brave Browser" = "brave"
    "iTunes" = "itunes"
    "Google Earth" = "googleearthpro"
    "Blender" = "blender"
    "CrysalDiskInfo" = "Crystaldiskinfo"
    "CrysalDiskMark" = "crysaldiskmark"
    "Discord" = "discord"
    "OBS Studio" = "obs-studio"
    "Origin" = "origin"
    "GOG Galaxy" = "goggalaxy"
    "iCloud" = "icloud"
    "AVG Antivirus Free" = "avgantivirusfree"
    "Ubisoft Connect" = "ubisoft-connect"
    "VMware Workstation Player" = "vmware-workstation-player"
    "Macrium Reflect Free" = "reflect-free"
    "Plex" = "plex"
    "Authy Desktop" = "authy-desktop"
    "Kaspersky Internet Security" = "kis"
    "RetroArch" = "retroarch"
    "Opera GX" = "opera-gx"
    "QFinder Pro" = "qfinderpro"
    "EA Desktop Client" = "ea-app"
    "EaseUS Todo Backup" = "todobackup"
    "SideQuest" = "sidequest"
    "Nexus Mod Manager" = "nmm"
    "Rockstar Games Launcher" = "rockstar-launcher"
    "Fitbit Connect" = "fitbit.connect"
    "AOMEI Partition Assistant" = "partition-assistant-standard"
    "NextDNS" = "nextdns"
    "Visual Studio Code" = "vscode"
    "Adobe Acrobat DC" = "adobereader"
    # Add more entries as needed
}

# Explicitly load the Windows Forms assembly
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.Application]::EnableVisualStyles()

# Run the script and display output to the console in real-time
# Create and display the file dialog box
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Filter = "HTML Files (*.html;*.htm)|*.html;*.htm|All Files (*.*)|*.*"
$openFileDialog.Title = "Select an HTML file"

# Check if the user selected a file and proceed accordingly
if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $htmlFilePath = $openFileDialog.FileName

    # Read the content of the HTML file
    $htmlContent = Get-Content -Path $htmlFilePath -Raw

    # Extract content using HAP (Html Agility Pack) and log the results
    $groupedResults = Extract-ContentUsingHAP $htmlContent

    # Create the output file path with .txt extension
    $outputFilePath = [System.IO.Path]::ChangeExtension("C:\Temp\DebloatAndFloat\Logs\Autoinstaller", "txt")

    # Generate the output content and log the results
    $outputContent = $groupedResults | ForEach-Object {
        $programName = $_.StrongTagContent

        # Search for the corresponding Chocolatey package name based on partial matches
        $chocoPackage = $programDatabase.GetEnumerator() | Where-Object {
            $programName -like ("*{0}*" -f $_.Key)
        } | Select-Object -ExpandProperty Value

        if ($chocoPackage) {
            # If the program name exists in the database, install it using Chocolatey
            Install-ChocoPackage $chocoPackage
        }

        "Program Name: $programName"
        "Support URLs: $($_.SupportUrls -join ', ')"
        "------------------------"
    }

    # Save the results to the output file
    $outputContent -join "`r`n" | Out-File -FilePath $outputFilePath -Encoding UTF8

    # Log the completion and the output file path
    "Results saved to: $outputFilePath" | Write-Output
} else {
    "File selection canceled by the user." | Write-Output
}