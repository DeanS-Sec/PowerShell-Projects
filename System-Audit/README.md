# System Audit Script

## Overview
This PowerShell script performs a system audit by collecting and analyzing key security-related information from a Windows machine. The script outputs results to both the terminal and a structured report file.

## Features

### System Information
- Computer name
- Current user
- Operating system details (name, version, build)

### User & Privilege Auditing
- Enumerates all local user accounts
- Displays account status (enabled/disabled)
- Lists members of the local Administrators group

### Process Monitoring
- Displays a summary of running processes in the terminal
- Writes the full process list to a report file

### Network Visibility
- Identifies all listening network ports
- Highlights high-risk ports (135, 139, 445)

### Risk Detection
- Flags enabled non-primary user accounts
- Identifies unexpected administrator accounts
- Detects high-risk open ports
- Flags processes running from Temp directories

### Reporting
- Outputs results to a text file for documentation and review
- Uses a helper function for clean and consistent file logging

---

## Technologies Used
- PowerShell
- Windows system cmdlets:
  - `Get-CimInstance`
  - `Get-LocalUser`
  - `Get-LocalGroupMember`
  - `Get-Process`
  - `Get-NetTCPConnection`

---

## Example Use Case
This script can be used for:
- System auditing
- Security baseline checks
- Incident response preparation
- Learning PowerShell and security concepts

---

## Future Improvements
- Export results to CSV or JSON
- Add timestamps to reports
- Expand risk detection rules
- Integrate Windows Defender scan results
- Convert checks into reusable functions/modules

- Security Relevance
This script can be used by SOC analysts or system administrators to:
- Identify suspicious processes consuming high CPU
- Detect abnormal system configurations
- Gather forensic baseline data during incident response

---

## Author
DeanS-Sec
