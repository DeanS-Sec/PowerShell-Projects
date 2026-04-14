# ============================================
# System Audit Script - Full Version
# ============================================

# Display script title in terminal
Write-Host "=== System Audit Script ==="
Write-Host ""

# Define output file path for report
$outputFile = "C:\Users\deanr\OneDrive\Documents\PowerShell\System-Audit-Report.txt"

# Store current user for later comparison (used in risk checks)
$currentUser = $env:USERNAME

# Optional visual separator (for future formatting use)
$separator = "========================================"

# ============================================
# Helper Function: Write to Report File
# ============================================
# This replaces repeated Out-File commands
function Write-ReportLine {
    param (
        [string]$text
    )

    # Append text to the report file
    $text | Out-File -FilePath $outputFile -Append
}

# Create / overwrite report file with title
"=== System Audit Script ===" | Out-File -FilePath $outputFile
"" | Out-File -FilePath $outputFile -Append

# ============================================
# Basic System Info
# ============================================
Write-Host "=== Basic System Info ==="
Write-Host "Computer Name:" $env:COMPUTERNAME
Write-Host "Current User:" $env:USERNAME
Write-Host ""

# Write to report file
Write-ReportLine "=== Basic System Info ==="
Write-ReportLine ("Computer Name: {0}" -f $env:COMPUTERNAME)
Write-ReportLine ("Current User: {0}" -f $currentUser)
Write-ReportLine ""

# ============================================
# Operating System Info
# ============================================
Write-Host "=== Operating System Info ==="

# Get OS details from system
$os = Get-CimInstance Win32_OperatingSystem

Write-Host "OS Name:" $os.Caption
Write-Host "Version:" $os.Version
Write-Host "Build Number:" $os.BuildNumber
Write-Host ""

# Write to report file
Write-ReportLine "=== Operating System Info ==="
Write-ReportLine ("OS Name: {0}" -f $os.Caption)
Write-ReportLine ("Version: {0}" -f $os.Version)
Write-ReportLine ("Build Number: {0}" -f $os.BuildNumber)
Write-ReportLine ""

# ============================================
# Local Users
# ============================================
Write-Host "=== Local Users ==="

# Get all local user accounts
$users = Get-LocalUser

# Display users in terminal
foreach ($user in $users) {
    Write-Host ("User: {0} | Enabled: {1}" -f $user.Name, $user.Enabled)
}

Write-Host ""

# Write users to report
Write-ReportLine "=== Local Users ==="
foreach ($user in $users) {
    Write-ReportLine ("User: {0} | Enabled: {1}" -f $user.Name, $user.Enabled)
}
Write-ReportLine ""

# ============================================
# Local Administrators
# ============================================
Write-Host "=== Local Administrators ==="

# Get members of Administrators group
$admins = Get-LocalGroupMember -Group "Administrators"

# Display admins in terminal
foreach ($admin in $admins) {
    Write-Host ("Admin Member: {0}" -f $admin.Name)
}

Write-Host ""

# Write admins to report
Write-ReportLine "=== Local Administrators ==="
foreach ($admin in $admins) {
    Write-ReportLine ("Admin Member: {0}" -f $admin.Name)
}
Write-ReportLine ""

# ============================================
# Running Processes
# ============================================
Write-Host "=== Running Processes (Top 15 by Name) ==="

# Get and sort processes
$processes = Get-Process | Sort-Object ProcessName

# Show only top 15 in terminal (readable output)
$processes | Select-Object -First 15 | ForEach-Object {
    Write-Host ("Process: {0} | Id: {1}" -f $_.ProcessName, $_.Id)
}

Write-Host ""

# Write FULL process list to report
Write-ReportLine "=== Running Processes ==="
foreach ($process in $processes) {
    Write-ReportLine ("Process: {0} | Id: {1}" -f $process.ProcessName, $process.Id)
}
Write-ReportLine ""

# ============================================
# Listening Network Ports
# ============================================
Write-Host "=== Listening Ports ==="

# Get ports that are actively listening
$ports = Get-NetTCPConnection |
         Where-Object { $_.State -eq "Listen" } |
         Sort-Object LocalPort

# Display ports in terminal
foreach ($port in $ports) {
    Write-Host ("Local Address: {0} | Port: {1}" -f $port.LocalAddress, $port.LocalPort)
}

Write-Host ""

# Write ports to report
Write-ReportLine "=== Listening Ports ==="
foreach ($port in $ports) {
    Write-ReportLine ("Local Address: {0} | Port: {1}" -f $port.LocalAddress, $port.LocalPort)
}
Write-ReportLine ""

# ============================================
# Risk Summary
# ============================================
Write-Host "=== Risk Summary ==="
Write-ReportLine "=== Risk Summary ==="

# Check for unexpected enabled user accounts
foreach ($user in $users) {
    if ($user.Enabled -eq $true -and $user.Name -ne $currentUser) {
        Write-Host "WARNING: Enabled non-primary account found:" $user.Name -ForegroundColor Red
        Write-ReportLine ("WARNING: Enabled non-primary account: {0}" -f $user.Name)
    }
}

Write-Host ""
Write-ReportLine ""