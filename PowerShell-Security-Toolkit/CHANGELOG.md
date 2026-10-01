# Changelog

All notable changes to the PowerShell Security Toolkit are documented in this
file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added this changelog to record notable changes beginning with version 1.0.0.
- Added Pester syntax tests for PowerShell 7 and Windows PowerShell 5.1.
- Added a Pester integration test that runs Endpoint Audit in temporary storage
  and verifies its run directory, core files, JSON validity, metadata, activity
  log, and separation from the Git repository.
- Added instructions for running the Endpoint Audit test suite.
- Added a GitHub Actions workflow that runs the Endpoint Audit test suite on a
  temporary Windows runner for pull requests and updates to `main`, with an
  option to run it manually.

## [1.0.1] - 2026-09-29

### Added

- Added `Export-AuditJson` to provide one consistent JSON-export path for all
  audit collectors.
- Added configurable JSON depth to the export helper, with validation from 1
  through 100 and a default depth of 3.

### Changed

- Replaced 18 repeated `ConvertTo-Json` and `Set-Content` blocks with calls to
  `Export-AuditJson`.
- Preserved a JSON depth of 6 for scheduled-task data because its actions and
  triggers contain nested objects.
- Refactored scheduled-task action and trigger property handling so the script
  parses correctly in both Windows PowerShell 5.1 and PowerShell 7.
- Updated the script version and runtime metadata from 1.0.0 to 1.0.1.
- Updated documentation to use the current script name, repository layout, and
  external log location.

### Fixed

- Fixed Windows PowerShell 5.1 parser compatibility in the scheduled-task
  collector.

## [1.0.0] - 2026-09-29

### Added

- Added the first complete version of `Invoke-EndpointAudit.ps1`.
- Added configurable output location and event-log lookback period.
- Added per-run metadata and activity logging.
- Added collectors for operating-system information, local administrators,
  local users, interactive sessions, processes, TCP connections, UDP
  endpoints, System events, services, scheduled tasks, startup commands,
  Microsoft Defender status, registered antivirus products, Windows Firewall
  profiles, network profiles, registered firewall products, and BitLocker
  status.
- Added separate structured JSON files for collected audit categories.
- Added per-collector error handling so one failed collector does not stop the
  remaining audit.
- Stored generated endpoint-audit logs outside the Git repository so collected
  system information is not included in commits or clones.
- Added documentation for usage, output files, privileges, privacy, and the
  planned project structure.

[Unreleased]: https://github.com/DeanS-Sec/PowerShell-Projects/compare/endpoint-audit-v1.0.1...HEAD
[1.0.1]: https://github.com/DeanS-Sec/PowerShell-Projects/compare/endpoint-audit-v1.0.0...endpoint-audit-v1.0.1
[1.0.0]: https://github.com/DeanS-Sec/PowerShell-Projects/releases/tag/endpoint-audit-v1.0.0
