Write-Host "Script started at $(Get-Date)" # Initial Timestamp

# Log files

$logFile = "C:\Users\dean.schauer\Documents\PowershellLearning\Logs\launch-log.txt"

"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Launch-Chrome.ps1 ran" | Out-File -FilePath $logFile -Append

# Profile Variables & Modes (modes removed for simplicity, but can be added back in if needed)


$workProfile = "Default"

# Function to open multiple chrome browsers
function Open-ChromeProfile {
    param(
        [string]$Profile,
        [string[]]$Sites
    )

    Write-Host "Launching Chrome with profile: $Profile"

    $args = @(
        '--new-window'
        "--profile-directory=`"$Profile`""
    ) + $Sites

    Start-Process "chrome.exe" -ArgumentList $args
}

# Work Sites (Array)
$workSites = @(
    #Sites redacted for security purposes
)

# Launch Profiles

Open-ChromeProfile -Profile $workProfile -Sites $workSites

# Application Setup
Start-Process "code.exe"


# End of script proof
Write-Host "End of Script"
Write-Host "Script ended at $(Get-Date)"
