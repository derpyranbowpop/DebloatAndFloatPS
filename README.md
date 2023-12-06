# Debloat And Float

[![made-with-powershell](https://img.shields.io/badge/PowerShell-1f425f?logo=Powershell)](https://microsoft.com/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## This is a fork of [Sycnex's Windows10Debloater](https://github.com/Sycnex/Windows10Debloater)

Debloat And Float is a Script/Utility/Application to debloat Windows 10 and 11, to remove Windows pre-installed unnecessary applications, stop some telemetry functions, disable unnecessary scheduled tasks, and more...

## Disclaimer

**WARNING:** I do **NOT** take responsibility for what may happen to your system! Run scripts at your own risk!
Also, other variants of this repo are not technically "new" versions of this, but they are different in their own respective ways. There are some sites saying that other projects are "new" versions of this, but that is inaccurate. 

## How To Run the Script

1) Download the .zip file from the releases page of the GitHub and extract the .zip file to your desired location
2) Double click the launch.bat file
3) Allow the Command Prompt to have admin privileges 

# Features

This script has a number of diffrent features below you can read what they do. 

## Installing Programs

This script has buttons to install programs the way they are downloaded and installed is with [WinGet]([https://chocolatey.org/](https://github.com/microsoft/winget-cli))

### Basic System Setup
Basic System Setup installs the following:
[Google Chrome](https://www.google.com/intl/en_au/chrome/), [Firefox](https://www.mozilla.org/en-US/firefox/new/), [Adobe Reader DC](https://get.adobe.com/uk/reader/), [Teamviewer](https://www.teamviewer.com/en-au/), [Unchecky](https://unchecky.com/), [VLC](https://www.videolan.org/). 

### Installed Software List

This uses the Installed Software List file thats created from a backup/transfer from [Fab's AutoBackup](https://www.fpnet.fr/?page=index&lang=en) to automatically download previously installed programs.

### Install Game Launchers 

This installs Steam and Epic Games Launcher

## The scheduled tasks that are disabled are

XblGameSaveTaskLogon,
XblGameSaveTask,
Consolidator,
UsbCeip,
DmClient

These scheduled tasks that are disabled have absolutely no impact on the function of the OS.

## Bloatware that is removed

[3DBuilder](https://www.microsoft.com/en-us/p/3d-builder/9wzdncrfj3t6),
[ActiproSoftware](https://www.microsoft.com/en-us/p/actipro-universal-windows-controls/9wzdncrdlvzp),
[Alarms](https://www.microsoft.com/en-us/p/windows-alarms-clock/9wzdncrfj3pr?activetab=pivot:overviewtab),
[Appconnector](https://www.microsoft.com/en-us/p/connector/9wzdncrdjmlj?activetab=pivot:overviewtab),
[Asphalt8](https://www.microsoft.com/en-us/p/asphalt-8-racing-game-drive-drift-at-real-speed/9wzdncrfj26j?activetab=pivot:overviewtab),
[Autodesk SketchBook](https://www.microsoft.com/en-us/p/autodesk-sketchbook/9nblggh4vzw5),
[MSN Money](https://www.microsoft.com/en-us/p/msn-money/9wzdncrfhv4v?activetab=pivot:overviewtab),
[Food And Drink](https://www.microsoft.com/en-us/p/food-and-drink/9nblggh0jhqg),
[Health And Fitness](https://www.microsoft.com/en-us/p/health-fitness-free/9wzdncrcwcdp),
[Microsoft News](https://www.microsoft.com/en-us/p/microsoft-news/9wzdncrfhvfw#activetab=pivot:overviewtab),
[MSN Sports](https://www.microsoft.com/en-us/p/msn-sports/9wzdncrfhvh4?activetab=pivot:overviewtab),
[MSN Travel](https://www.microsoft.com/en-us/p/msn-travel/9wzdncrfj3ft?activetab=pivot:overviewtab),
[MSN Weather](https://www.microsoft.com/en-us/p/msn-weather/9wzdncrfj3q2?activetab=pivot:overviewtab),
BioEnrollment,
[Windows Camera](https://www.microsoft.com/en-us/p/windows-camera/9wzdncrfjbbg#activetab=pivot:overviewtab),
CandyCrush,
CandyCrushSoda,
Caesars Slots Free Casino,
ContactSupport,
CyberLink MediaSuite Essentials,
DrawboardPDF,
Duolingo,
EclipseManager,
Facebook,
FarmVille 2 Country Escape,
Flipboard,
Fresh Paint,
Get started,
iHeartRadio,
King apps,
Maps,
March of Empires,
Messaging,
Microsoft Office Hub,
Microsoft Solitaire Collection,
Microsoft Sticky Notes,
Minecraft,
Netflix,
Network Speed Test,
NYT Crossword,
Office Sway,
OneNote,
OneConnect,
Pandora,
People,
Phone,
Phototastic Collage,
PicsArt-PhotoStudio,
PowerBI,
Royal Revolt 2,
Shazam,
Skype for Desktop,
SoundRecorder,
TuneInRadio,
Twitter,
Windows communications apps,
Windows Feedback,
Windows Feedback Hub,
Windows Reading List,
XboxApp,
Xbox Game CallableUI,
Xbox Identity Provider,
Zune Music,
Zune Video.

## Allowlist and Blocklist
There may be some confusion, but when using the Allowlist/Blocklist, the checkmark means it is on the blocklist, and that it will be removed.

## Credits
Thank you to [a60wattfish](https://github.com/a60wattfish), [abulgatz](abulgatz), [xsisbest](https://github.com/xsisbest), [Damian](https://github.com/Damian), [Vikingat-RAGE](https://github.com/Vikingat-RAGE), Reddit user [/u/GavinEke](https://github.com/GavinEke), and all of the contributors (https://github.com/Sycnex/Windows10Debloater/graphs/contributors) for the suggestions, code, changes, and fixes that you have all graciously worked hard on and shared! You all have done a fantastic job!
