Write-Host "Script started at $(Get-Date)" # Initial Timestamp

# Log files

$logFile = "C:\Users\deanschauer\Documents\Powershell Scripts\Script Logs\launch-log.txt"

"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Launch-Chrome.ps1 ran" | Out-File -FilePath $logFile -Append

# Profile Variables & Modes (modes removed for simplicity, but can be added back in if needed)

$personalProfile = "Profile 1"
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

# Personal Sites (Array)
$personalSites = @(
    'https://news.google.com'
    'https://mail.google.com'
    'https://linkedin.com'
)

# Work Sites (Array)
$workSites = @(
    'https://mail.google.com'
    'https://calendar.google.com'
    'https://my.boisestate.edu'
    'https://boisestateproduction.service-now.com/'
    'https://middleware.boisestate.edu/faculty/courses'
)

# Launch Profiles
Open-ChromeProfile -Profile $personalProfile -Sites $personalSites

Start-Sleep -Seconds 2 # Ensure the first profile is complete before launching the secondary profile

Open-ChromeProfile -Profile $workProfile -Sites $workSites

# Application Setup
Start-Process "code.exe"


# End of script proof
Write-Host "End of Script"
Write-Host "Script ended at $(Get-Date)"