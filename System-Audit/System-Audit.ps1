# ============================================================
# System Audit Script - Full Version
# Author: [Your Name]
#
# Description:
# This PowerShell script performs a system audit by collecting:
# - System and OS information
# - Local users and administrator group membership
# - Running processes
# - Listening network ports
#
# It also performs risk analysis by:
# - Identifying risky/open ports based on a custom-defined list
# - Flagging suspicious accounts and privilege issues
#
# Output:
# - Writes results to terminal for quick visibility
# - Generates a timestamped report file for auditing/history
#
# Notes:
# - Risk definitions (e.g., risky ports) are user-defined
# - Script is designed to be portable across Windows systems
# ============================================================

# Display script title in terminal
Write-Host "=== System Audit Script ==="
Write-Host ""

# Define output file path for report
# Uses timestamp so each run generates a unique report file
# This allows historical tracking and debugging over time
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputFile = "$env:USERPROFILE\Documents\System-Audit-Report-$timestamp.txt"

# Store current user for later comparison (used in risk checks)
$currentUser = $env:USERNAME

# Optional visual separator (for future formatting use)
$separator = "========================================"

# ------------------------------------------------------------
# Risky Ports Configuration
# ------------------------------------------------------------
# This is a custom-defined list of ports considered "risky"
# PowerShell does NOT determine risk — this list defines it
#
# Each entry includes:
# - Port: Port number to monitor
# - Service: Common service associated with the port
# - Reason: Why the port is considered risky
#
# This structure allows easy expansion and better reporting
# ------------------------------------------------------------
$riskyPorts = @(
    @{ Port = 21; Service = "FTP"; Reason = "Unencrypted file transfer protocol" }
    @{ Port = 23; Service = "Telnet"; Reason = "Unencrypted remote access protocol" }
    @{ Port = 135; Service = "RPC"; Reason = "Common lateral movement vector" }
    @{ Port = 139; Service = "NetBIOS"; Reason = "Legacy file sharing protocol" }
    @{ Port = 445; Service = "SMB"; Reason = "Common file sharing protocol with known vulnerabilities" }
    @{ Port = 3389; Service = "RDP"; Reason = "Remote desktop protocol with potential for abuse" }
    @{ Port = 5985; Service = "WinRM HTTP"; Reason = "Windows Remote Management over HTTP" }
)

# ------------------------------------------------------------
# Helper Function: Write-ReportLine
# ------------------------------------------------------------
# Purpose:
# Writes a single line to the report file
#
# Why this exists:
# - Avoids repeating Out-File commands
# - Keeps output formatting consistent
# - Simplifies future changes to file writing
# ------------------------------------------------------------
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
Write-ReportLine "=== Running Processes (Top 15 by Name) ==="

# ------------------------------------------------------------
# Running Processes
# ------------------------------------------------------------
# Terminal Output:
# - Shows only top 15 processes for readability
#
# Report Output:
# - Can be configured to show either top 15 or full list
# ------------------------------------------------------------

# Get and sort processes alphabetically
$processes = Get-Process | Sort-Object ProcessName

# Show only top 15 in terminal (readable output)
$processes | Select-Object -First 15 | ForEach-Object {
    Write-Host ("Process: {0} | Id: {1}" -f $_.ProcessName, $_.Id)
}

Write-Host ""

# Write processes to report (full list for auditing)
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

# Get only processes that have a readable path
$processesWithPath = Get-Process | Where-Object { $_.Path }

# --------------------------------------------
# Check for enabled non-primary user accounts
# --------------------------------------------
foreach ($user in $users) {
    if ($user.Enabled -eq $true -and $user.Name -ne $currentUser) {
        Write-Host "WARNING: Enabled non-primary account found:" $user.Name -ForegroundColor Red
        Write-ReportLine ("WARNING: Enabled non-primary account found: {0}" -f $user.Name)
    }
}

# --------------------------------------------
# Check for unexpected administrator accounts
# --------------------------------------------
foreach ($admin in $admins) {
    if ($admin.Name -notlike "*$currentUser*" -and $admin.Name -notlike "*Administrator*") {
        Write-Host "WARNING: Unexpected admin account:" $admin.Name -ForegroundColor Red
        Write-ReportLine ("WARNING: Unexpected admin account: {0}" -f $admin.Name)
    }
}

# ------------------------------------------------------------
# Check for High-Risk Listening Ports
# ------------------------------------------------------------
# Logic:
# 1. Extract unique listening ports from system
# 2. Compare each port against custom risky port list
# 3. Flag matches and provide context (service + reason)
# 4. Track total number of risky ports found
# ------------------------------------------------------------

# Extract unique port numbers from listening connections
$uniquePorts = $ports | Select-Object -ExpandProperty LocalPort -Unique

# Initialize counter for findings
$riskyPortCount = 0

# Start Port Risk Summary section in report
Write-Host ""
Write-Host "=== Port Risk Summary ==="
Write-ReportLine "=== Port Risk Summary ==="

# Analyze each port
foreach ($port in $uniquePorts) {
    $matchedPort = $riskyPorts | Where-Object { $_.Port -eq $port }

    if ($matchedPort) {
        Write-Host "WARNING: Risky port open: $($matchedPort.Port) ($($matchedPort.Service)) - $($matchedPort.Reason)" -ForegroundColor Red
        Write-ReportLine "WARNING: Risky port open: $($matchedPort.Port) ($($matchedPort.Service)) - $($matchedPort.Reason)"
        # Increment counter
        $riskyPortCount++
    }
}

if ($riskyPortCount -eq 0) {
    Write-ReportLine "No risky ports detected"
}

Write-ReportLine "Risky ports monitored: $($riskyPorts.Count)"
Write-ReportLine "Risky ports found: $riskyPortCount"


# --------------------------------------------
# Check for processes running from Temp folders
# --------------------------------------------
foreach ($process in $processesWithPath) {
    if ($process.Path -like "*Temp*") {
        Write-Host "WARNING: Process running from Temp folder:" $process.ProcessName -ForegroundColor Yellow
        Write-ReportLine ("WARNING: Process running from Temp folder: {0} | Path: {1}" -f $process.ProcessName, $process.Path)
    }
}

Write-Host ""
Write-ReportLine ""
Write-ReportLine ""
