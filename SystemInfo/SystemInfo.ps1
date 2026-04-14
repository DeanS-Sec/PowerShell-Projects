$reportFile = "C:\Users\deanschauer\Documents\PowerShell Scripts\Script Output - Test\SystemInfoReport.txt"

Set-Content -Path $reportFile -Value ""

"=== Basic System Information ===" | Tee-Object -FilePath $reportFile -Append
"" | Tee-Object -FilePath $reportFile -Append

Get-ComputerInfo | Select-Object `
    CsName,
    WindowsVersion,
    WindowsBuildLabEx,
    OsArchitecture |
    Format-Table -AutoSize |
    Out-String |
    Tee-Object -FilePath $reportFile -Append

"" | Tee-Object -FilePath $reportFile -Append
"=== Network Information ===" | Tee-Object -FilePath $reportFile -Append
"" | Tee-Object -FilePath $reportFile -Append

Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" } | Select-Object `
    InterfaceAlias,
    IPAddress,
    AddressFamily |
    Format-Table -AutoSize |
    Out-String |
    Tee-Object -FilePath $reportFile -Append

"" | Tee-Object -FilePath $reportFile -Append
"=== Top Running Processes ===" | Tee-Object -FilePath $reportFile -Append
"" | Tee-Object -FilePath $reportFile -Append

Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 `
    ProcessName,
    CPU,
    Id |
    Format-Table -AutoSize |
    Out-String |
    Tee-Object -FilePath $reportFile -Append