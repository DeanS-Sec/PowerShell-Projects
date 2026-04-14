# Define the path for the report file in the user's Documents folder
$reportFile = Join-Path $env:USERPROFILE "Documents\SystemInfoReport.txt"

# Clear the contents of the report file if it already exists
Set-Content -Path $reportFile -Value ""

# Create a helper function to write output to both the console and the report file
function Write-ReportLine {
    param(
        [string]$Text = ""  # Accepts a string input (defaults to blank line)
    )

    # Output text to console AND append it to the report file
    $Text | Tee-Object -FilePath $reportFile -Append
}

# Write report title
Write-ReportLine "System Information Report"

# Display script start time in the console
Write-Host "Script started at $(Get-Date)" # Initial Timestamp

# Log script start time in the report file
Write-ReportLine "Script started at $(Get-Date)" # Initial Timestamp

# Add spacing in report
Write-ReportLine

# Section header for system information
Write-ReportLine "=== System Information ==="
Write-ReportLine

# Retrieve system details and format output
Get-ComputerInfo | Select-Object `
    CsName,                # Computer name
    WindowsVersion,        # Windows version
    WindowsBuildLabEx,     # Detailed build info
    OsArchitecture |       # OS architecture (32-bit or 64-bit)
    Format-Table -AutoSize |  # Format output as a table
    Out-String |              # Convert table to string format
    Tee-Object -FilePath $reportFile -Append  # Output to console and file

# Add spacing in report
Write-ReportLine

# Section header for network information
Write-ReportLine "=== Network Information ==="
Write-ReportLine

# Retrieve IPv4 network addresses
Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" } | Select-Object `
    InterfaceAlias,  # Network adapter name
    IPAddress,       # Assigned IP address
    AddressFamily |  # Address type (IPv4)
    Format-Table -AutoSize |
    Out-String |
    Tee-Object -FilePath $reportFile -Append

# Add spacing in report
Write-ReportLine

# Section header for CPU usage
Write-ReportLine "=== Top CPU-Intensive Processes ==="
Write-ReportLine

# Get top 5 processes consuming the most CPU
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | Select-Object `
    ProcessName,  # Name of the process
    CPU,          # CPU time used
    Id |          # Process ID
    Format-Table -AutoSize |
    Out-String |
    Tee-Object -FilePath $reportFile -Append

# Indicate script completion in the console
Write-Host "End of Script"

# Display script end time
Write-Host "Script ended at $(Get-Date)"
