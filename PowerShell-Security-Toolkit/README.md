# PowerShell Security Toolkit

This repository is a long-term PowerShell learning project centered on a Windows endpoint-audit script. The project began as a way to apply concepts from *Learn PowerShell in a Month of Lunches* and is being developed gradually so that every function, object, pipeline, and error-handling decision is understood before the next capability is added.

The current milestone is `Invoke-EndpointAudit.ps1` version **1.0.1**.

## Project goals

- Learn PowerShell by building something practical.
- Collect useful Windows endpoint-triage information in a consistent format.
- Practice functions, pipelines, CIM, custom objects, parameters, validation, JSON, logging, and error handling.
- Keep collection separate from interpretation and remediation.
- Grow toward a small identity- and incident-response-oriented toolset over time.

## Non-goals

This project is not currently intended to:

- Determine conclusively that a computer is compromised.
- Automatically remediate or change the endpoint.
- Replace an EDR, antivirus, SIEM, vulnerability scanner, or enterprise-management platform.
- Perform formal forensic acquisition or maintain evidentiary chain of custody.
- Support fleet-wide or mass deployment.

## Current capabilities

Each run creates a uniquely named output directory and records execution metadata in addition to the following information:

- Operating-system details
- Local administrator membership
- Local user accounts
- Interactive logon sessions visible to the current user
- Running processes
- TCP connections
- UDP endpoints
- Recent Critical, Error, and Warning events from the System log
- Windows services
- Scheduled tasks, including nested actions and triggers
- Startup commands
- Microsoft Defender status
- Antivirus products registered with Windows Security Center
- Effective Windows Firewall profiles
- Current network profiles
- Firewall products registered with Windows Security Center
- BitLocker status when the script is run with sufficient privileges

The script does not label findings as safe or malicious. It records observations for human review.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7 running on Windows
- A 64-bit PowerShell host on a 64-bit Windows installation for the `LocalAccounts` module
- Access to the Windows CIM, networking, scheduled-task, Defender, and event-log providers used by individual collectors
- Administrator privileges only for collectors that require them, such as BitLocker status

The script is designed to continue when an individual collector fails. Failures and expected skips are recorded in `Audit.log`.

## Usage

From PowerShell, change to the `Scripts\EndpointAudit` directory and run:

```powershell
.\Invoke-EndpointAudit.ps1
```

Specify a different output directory or event-log lookback period when needed:

```powershell
.\Invoke-EndpointAudit.ps1 `
    -OutputPath 'C:\AuditLogs' `
    -LookbackHours 48
```

View the script's comment-based help:

```powershell
Get-Help .\Invoke-EndpointAudit.ps1 -Full
```

## Output

By default, runs are written beneath:

```text
%USERPROFILE%\Documents\EndpointAuditLogs
```

Each run uses a unique directory similar to:

```text
Endpoint-Audit-COMPUTERNAME-20260928T162534Z-1d99730b
```

Depending on permissions and available Windows components, a run can contain:

```text
Audit.log
Metadata.json
OperatingSystem.json
LocalAdministrators.json
LocalUsers.json
InteractiveSessions.json
Processes.json
TcpConnections.json
UdpEndpoints.json
SystemEvents.json
Services.json
ScheduledTasks.json
StartupCommands.json
DefenderStatus.json
AntivirusProducts.json
FirewallProfiles.json
NetworkProfiles.json
FirewallProducts.json
BitLockerStatus.json        # Only when collection is permitted
```

`Audit.log` is the authoritative record of collector successes, failures, expected skips, and completion. The absence of a particular JSON file should be interpreted together with this log.

## Data sensitivity

Generated audit output can contain sensitive endpoint information, including:

- Usernames and security identifiers
- Local group membership
- Executable paths and process command lines
- IP addresses, ports, and connection state
- Service identities
- Scheduled-task commands and arguments
- Installed security-product names
- Event-log messages

Do not commit generated logs or JSON output to a public repository. Review and redact any sample output before sharing it.

The source script does not contain credentials and does not transmit its results. It operates on the computer where it is executed.

## Recommended long-term structure

The repository can grow toward the following structure without moving everything immediately:

```text
PowerShell-Security-Toolkit/
├── README.md
├── CHANGELOG.md                       # Future release history
├── LICENSE                            # Choose before wider public use
├── Scripts/
│   ├── EndpointAudit/
│   │   ├── README.md
│   │   └── Invoke-EndpointAudit.ps1   # Current 1.0.1 entry point
│   ├── Comparison/
│   │   └── Compare-EndpointAudit.ps1
│   ├── IdentityTriage/
│   │   └── Invoke-IdentityTriage.ps1
│   └── Utilities/
├── Modules/
│   └── EndpointAudit/
│       ├── EndpointAudit.psd1
│       ├── EndpointAudit.psm1
│       ├── Public/
│       └── Private/
├── Tests/
│   ├── Unit/
│   └── Integration/
├── Docs/
│   ├── Architecture.md
│   ├── Collectors.md
│   ├── OutputSchema.md
│   └── LearningNotes/
└── Examples/
    └── RedactedOutput/
```

The directories marked as future work should be created only when the project needs them. The existing single-script design remains appropriate while the fundamentals are being learned.

## Development roadmap

### 1.x — Stabilize and enrich

- Add a concise run summary with collector status and item counts.
- Correlate TCP and UDP owning-process IDs with process names and paths.
- Introduce a reusable JSON-export helper after its behavior is fully understood.
- Improve documentation for every collector and output schema.
- Add Pester tests for functions that can be tested safely.

### 2.x — Compare audit runs

- Build `Compare-EndpointAudit.ps1` as a separate script.
- Compare local administrators, users, services, scheduled tasks, startup commands, and security providers between two runs.
- Produce structured change objects rather than relying only on formatted text.
- Distinguish additions, removals, and modified properties.

### 3.x — Identity-focused triage

- Collect relevant identity and authentication events when permissions allow.
- Explore successful and failed logons, explicit credential use, privileged logons, account changes, and local-group membership changes.
- Keep identity collection separate from conclusions about malicious activity.
- Develop and test permission-sensitive features in an appropriately authorized environment or personal lab.

### 4.x — Module architecture

- Move reusable collector and export functions into `EndpointAudit.psm1`.
- Create a module manifest (`EndpointAudit.psd1`).
- Separate public commands from private helpers.
- Preserve a small, readable entry-point script that orchestrates collection.

### Longer-term possibilities

- Baseline policy files and approved-difference lists
- Redacted sample datasets for testing
- Application and PowerShell operational event collectors
- Installed-software and Windows-update inventory
- Network adapter and DNS configuration
- File hashing for specifically selected executables
- Signed release artifacts
- Additional Pester coverage and continuous validation

## Versioning approach

The project uses semantic-style versions:

- Major version: a stable milestone or significant design change
- Minor version: a backward-compatible capability or collector
- Patch version: a correction or internal refinement that does not materially change usage

Version numbers are recorded in both the comment-based help and runtime metadata.

## Development principles

- Add one capability at a time.
- Test the underlying Windows command before wrapping it in a function.
- Return structured objects from collector functions.
- Keep formatting, JSON export, and logging in the orchestration section.
- Preserve useful partial results when one collector fails.
- Treat a lack of access as information, not as permission to bypass a security boundary.
- Prefer neutral observations over unsupported security conclusions.
- Keep environment-specific output out of source control.

## Current status

Version `1.0.0` is the first complete learning milestone. Future work should begin from this known-good baseline and remain incremental so that each change can be understood and tested independently.

Version `1.0.1` centralizes JSON export behavior and restores Windows PowerShell 5.1 parser compatibility without changing the collected data.