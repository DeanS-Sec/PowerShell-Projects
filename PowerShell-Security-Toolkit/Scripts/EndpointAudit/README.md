# Endpoint Audit

`Invoke-EndpointAudit.ps1` is a read-only PowerShell endpoint-triage script for collecting information from a Windows computer. It creates structured JSON files that can be reviewed during troubleshooting, security investigations, and incident-response learning.

Current version: **1.0.1**

## Collected Information

The script currently collects:

- Operating-system information
- Local administrator membership
- Local user accounts
- Interactive logon sessions
- Running processes
- TCP connections
- UDP endpoints
- Recent System event-log entries
- Windows services
- Scheduled tasks
- Startup commands
- Microsoft Defender status
- Registered antivirus products
- Windows Firewall profiles
- Network connection profiles
- Registered firewall products
- BitLocker status when run with administrator privileges

## Requirements

- Windows PowerShell 5.1 or PowerShell 7 on Windows
- A 64-bit PowerShell process on a 64-bit Windows installation
- Administrator privileges for BitLocker collection

Most collectors can run without administrator privileges. Collectors that cannot run are skipped and recorded in `Audit.log`.

## Usage

Run with the default 24-hour event-log lookback:

```powershell
.\Invoke-EndpointAudit.ps1
