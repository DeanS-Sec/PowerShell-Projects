<#
.SYNOPSIS
    Collects endpoint-triage information for further investigation.

.DESCRIPTION
    Creates a uniquely identified audit run, records execution metadata,
    and collects operating-system details, local administrator membership,
    local user accounts, interactive logon sessions, running processes,
    network activity, recent System events, Windows services, scheduled tasks,
    startup commands, and basic endpoint-security posture without performing
    remediation.

    Each run creates an audit log and separate JSON files containing the
    execution metadata and results from each successful collector. Collectors
    that cannot run are recorded in the audit log.

    Findings produced by this script indicate items that may require
    investigation; they do not prove that the endpoint is compromised.

.PARAMETER OutputPath
    Parent directory in which the unique audit-run directory is created.

.PARAMETER LookbackHours
    Number of hours of System event-log history to collect. The permitted
    range is 1 through 720 hours. The default is 24 hours.

.EXAMPLE
    ..\Invoke-EndpointAudit.ps1

    Runs the audit using the default output location and lookback period.

.EXAMPLE
    .\Invoke-EndpointAudit.ps1 -OutputPath 'C:\AuditLogs' -LookbackHours 48

    Runs the audit with a custom output location and 48-hour lookback period.

.NOTES
    Script version: 1.0.1
    Current collectors: operating system, local administrators, local users,
    interactive logon sessions, running processes, TCP and UDP network activity,
    recent System events, Windows services, scheduled tasks, startup commands,
    and basic endpoint-security posture.

        Requirements:
    - Windows PowerShell 5.1 or PowerShell 7 running on Windows.
    - A 64-bit PowerShell process is required for the LocalAccounts module
      on a 64-bit Windows installation.

    Limitations:
    - Some collectors may return incomplete results without elevation.
    - Collected findings require human analysis and do not independently
      prove that the endpoint is compromised.
    - BitLocker status collection requires administrator privileges and is
     skipped during a non-elevated run.
#>

[CmdletBinding()]
param (
    [string]$OutputPath = "$env:USERPROFILE\Documents\EndpointAuditLogs",

    [ValidateRange(1, 720)]
    [int]$LookbackHours = 24
)

# Runtime settings
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Helper functions
function Write-AuditLog {
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $eventTimestamp = (Get-Date).ToUniversalTime().ToString('o')
    $logLine = "$eventTimestamp [$runId] [$Level] $Message"

    Add-Content -LiteralPath $logPath -Value $logLine -Encoding utf8
}

function Export-AuditJson {
    param (
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$LiteralPath,

        [ValidateRange(1, 100)]
        [int]$Depth = 3
    )

    ConvertTo-Json `
        -InputObject $InputObject `
        -Depth $Depth |
        Set-Content `
            -LiteralPath $LiteralPath `
            -Encoding utf8
}

function Get-AuditOperatingSystem {
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem

    [PSCustomObject]@{
        Name         = $operatingSystem.Caption
        Version      = $operatingSystem.Version
        BuildNumber  = $operatingSystem.BuildNumber
        Architecture = $operatingSystem.OSArchitecture
        InstallDate  = $operatingSystem.InstallDate
        LastBootTime = $operatingSystem.LastBootUpTime
    }
}

function Get-AuditLocalAdministrators {
    $administratorsSid = [Security.Principal.SecurityIdentifier]::new(
        'S-1-5-32-544'
    )

    $members = Get-LocalGroupMember -SID $administratorsSid

    foreach ($member in $members) {
        [PSCustomObject]@{
            Name            = $member.Name
            ObjectClass     = $member.ObjectClass
            PrincipalSource = [string]$member.PrincipalSource
            SID             = $member.SID.Value
        }
    }
}

function Get-AuditLocalUsers {
    $users = Get-LocalUser

    foreach ($user in $users) {
        [PSCustomObject]@{
            Name                  = $user.Name
            FullName              = $user.FullName
            Enabled               = $user.Enabled
            Description           = $user.Description
            PrincipalSource       = [string]$user.PrincipalSource
            SID                   = $user.SID.Value
            LastLogon             = $user.LastLogon
            PasswordLastSet       = $user.PasswordLastSet
            PasswordExpires       = $user.PasswordExpires
            PasswordRequired      = $user.PasswordRequired
            UserMayChangePassword = $user.UserMayChangePassword
        }
    }
}

function Get-AuditProcesses {
    $cimProcesses = Get-CimInstance `
        -ClassName Win32_Process `
        -Property Name,
            ProcessId,
            ParentProcessId,
            ExecutablePath,
            CommandLine,
            CreationDate,
            SessionId

    foreach ($process in $cimProcesses) {
        [PSCustomObject]@{
            Name            = $process.Name
            ProcessId       = $process.ProcessId
            ParentProcessId = $process.ParentProcessId
            ExecutablePath  = $process.ExecutablePath
            CommandLine     = $process.CommandLine
            CreationDate    = $process.CreationDate
            SessionId       = $process.SessionId
        }
    }
}

function Get-AuditTcpConnections {
    $connections = Get-NetTCPConnection

    foreach ($connection in $connections) {
        [PSCustomObject]@{
            LocalAddress  = $connection.LocalAddress
            LocalPort     = $connection.LocalPort
            RemoteAddress = $connection.RemoteAddress
            RemotePort    = $connection.RemotePort
            State         = [string]$connection.State
            OwningProcess = $connection.OwningProcess
            CreationTime  = $connection.CreationTime
        }
    }
}

function Get-AuditUdpEndpoints {
    $endpoints = Get-NetUDPEndpoint

    foreach ($endpoint in $endpoints) {
        [PSCustomObject]@{
            LocalAddress  = $endpoint.LocalAddress
            LocalPort     = $endpoint.LocalPort
            OwningProcess = $endpoint.OwningProcess
            CreationTime  = $endpoint.CreationTime
        }
    }
}

function Get-AuditSystemEvents {
    param (
        [Parameter(Mandatory)]
        [datetime]$StartTime
    )

        try {
        $events = @(
            Get-WinEvent -FilterHashtable @{
                LogName   = 'System'
                Level     = 1, 2, 3
                StartTime = $StartTime
            } -ErrorAction Stop
        )
    }
    catch {
        if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') {
            $events = @()
        }
        else {
            throw
        }
    }

    foreach ($event in $events) {
        [PSCustomObject]@{
            TimeCreated     = $event.TimeCreated
            RecordId       = $event.RecordId
            Id             = $event.Id
            Level           = $event.Level
            LevelDisplayName = $event.LevelDisplayName
            ProviderName    = $event.ProviderName
            Message         = $event.Message
        }
    }
}

function Get-AuditServices {
    $services = Get-CimInstance -ClassName Win32_Service

    foreach ($service in $services) {
        [PSCustomObject]@{
            Name        = $service.Name
            DisplayName = $service.DisplayName
            Description = $service.Description
            State       = $service.State
            StartMode   = $service.StartMode
            StartName   = $service.StartName
            ProcessId   = $service.ProcessId
            PathName    = $service.PathName
        }
    }
}

function Get-AuditScheduledTasks {
    $tasks = Get-ScheduledTask

    foreach ($task in $tasks) {
        $actions = @(
            foreach ($action in $task.Actions) {
                $executeProperty =
                    $action.PSObject.Properties['Execute']

                $argumentsProperty =
                    $action.PSObject.Properties['Arguments']

                $workingDirectoryProperty =
                    $action.PSObject.Properties['WorkingDirectory']

                $execute = if ($null -ne $executeProperty) {
                    $executeProperty.Value
                }
                else {
                    $null
                }

                $actionArguments = if ($null -ne $argumentsProperty) {
                    $argumentsProperty.Value
                }
                else {
                    $null
                }

                $workingDirectory = if (
                    $null -ne $workingDirectoryProperty
                ) {
                    $workingDirectoryProperty.Value
                }
                else {
                    $null
                }

                [PSCustomObject]@{
                    ActionType       = $action.CimClass.CimClassName
                    Execute          = $execute
                    Arguments        = $actionArguments
                    WorkingDirectory = $workingDirectory
                }
            }
        )

        $triggers = @(
            foreach ($trigger in $task.Triggers) {
                $delayProperty =
                    $trigger.PSObject.Properties['Delay']

                $randomDelayProperty =
                    $trigger.PSObject.Properties['RandomDelay']

                $delay = if ($null -ne $delayProperty) {
                    $delayProperty.Value
                }
                else {
                    $null
                }

                $randomDelay = if ($null -ne $randomDelayProperty) {
                    $randomDelayProperty.Value
                }
                else {
                    $null
                }

                [PSCustomObject]@{
                    TriggerType       = $trigger.CimClass.CimClassName
                    Enabled           = $trigger.Enabled
                    StartBoundary     = $trigger.StartBoundary
                    EndBoundary       = $trigger.EndBoundary
                    ExecutionTimeLimit = $trigger.ExecutionTimeLimit
                    Delay             = $delay
                    RandomDelay       = $randomDelay
                }
            }
        )

        [PSCustomObject]@{
            TaskName    = $task.TaskName
            TaskPath    = $task.TaskPath
            State       = [string]$task.State
            Author      = $task.Author
            Description = $task.Description
            RunAsUser   = $task.Principal.UserId
            RunAsGroup  = $task.Principal.GroupId
            LogonType   = [string]$task.Principal.LogonType
            RunLevel    = [string]$task.Principal.RunLevel
            Enabled     = $task.Settings.Enabled
            Hidden      = $task.Settings.Hidden
            Actions     = $actions
            Triggers    = $triggers
        }
    }
}

function Get-AuditStartupCommands {
    $startupCommands = Get-CimInstance `
        -ClassName Win32_StartupCommand

    foreach ($startupCommand in $startupCommands) {
        [PSCustomObject]@{
            Name     = $startupCommand.Name
            Command  = $startupCommand.Command
            Location = $startupCommand.Location
            User     = $startupCommand.User
        }
    }
}

function Get-AuditInteractiveSessions {
    $logonSessions = Get-CimInstance `
        -ClassName Win32_LogonSession

    $interactiveSessions = @(
        $logonSessions |
            Where-Object { $_.LogonType -in 2, 10, 11 }
    )

    foreach ($session in $interactiveSessions) {
        $logonTypeName = switch ([int]$session.LogonType) {
            2  { 'Interactive' }
            10 { 'RemoteInteractive' }
            11 { 'CachedInteractive' }
        }

        $accounts = @(
            Get-CimAssociatedInstance `
                -InputObject $session `
                -Association Win32_LoggedOnUser
        )

        if ($accounts.Count -eq 0) {
            [PSCustomObject]@{
                Domain                = $null
                UserName              = $null
                SID                   = $null
                LogonId               = $session.LogonId
                LogonType             = $session.LogonType
                LogonTypeName         = $logonTypeName
                StartTime             = $session.StartTime
                AuthenticationPackage = $session.AuthenticationPackage
            }

            continue
        }

        foreach ($account in $accounts) {
            [PSCustomObject]@{
                Domain                = $account.Domain
                UserName              = $account.Name
                SID                   = $account.SID
                LogonId               = $session.LogonId
                LogonType             = $session.LogonType
                LogonTypeName         = $logonTypeName
                StartTime             = $session.StartTime
                AuthenticationPackage = $session.AuthenticationPackage
            }
        }
    }
}

function Get-AuditDefenderStatus {
    $defenderStatus = Get-MpComputerStatus

    [PSCustomObject]@{
        RunningMode                  = [string]$defenderStatus.AMRunningMode
        ServiceEnabled               = $defenderStatus.AMServiceEnabled
        AntivirusEnabled             = $defenderStatus.AntivirusEnabled
        AntispywareEnabled           = $defenderStatus.AntispywareEnabled
        BehaviorMonitorEnabled       = $defenderStatus.BehaviorMonitorEnabled
        RealTimeProtectionEnabled    = $defenderStatus.RealTimeProtectionEnabled
        IoavProtectionEnabled        = $defenderStatus.IoavProtectionEnabled
        NetworkInspectionEnabled     = $defenderStatus.NISEnabled
        AntivirusSignatureVersion    = $defenderStatus.AntivirusSignatureVersion
        AntivirusSignatureLastUpdate = $defenderStatus.AntivirusSignatureLastUpdated
        QuickScanAge                 = $defenderStatus.QuickScanAge
        FullScanAge                  = $defenderStatus.FullScanAge
    }
}

function Get-AuditAntivirusProducts {
    $antivirusProducts = Get-CimInstance `
        -Namespace 'root/SecurityCenter2' `
        -ClassName AntivirusProduct

    foreach ($antivirusProduct in $antivirusProducts) {
        [PSCustomObject]@{
            DisplayName               = $antivirusProduct.displayName
            InstanceGuid              = $antivirusProduct.instanceGuid
            PathToSignedProductExe    = $antivirusProduct.pathToSignedProductExe
            PathToSignedReportingExe  = $antivirusProduct.pathToSignedReportingExe
            ProductState              = $antivirusProduct.productState
            ProductStateHex           = '0x{0:X6}' -f
                [int]$antivirusProduct.productState
            Timestamp                 = $antivirusProduct.timestamp
        }
    }
}

function Get-AuditFirewallProfiles {
    $firewallProfiles = Get-NetFirewallProfile `
        -PolicyStore ActiveStore

    foreach ($firewallProfile in $firewallProfiles) {
        [PSCustomObject]@{
            Name                    = [string]$firewallProfile.Name
            Enabled                 = $firewallProfile.Enabled
            DefaultInboundAction    = [string]$firewallProfile.DefaultInboundAction
            DefaultOutboundAction   = [string]$firewallProfile.DefaultOutboundAction
            AllowInboundRules       = $firewallProfile.AllowInboundRules
            AllowLocalFirewallRules = $firewallProfile.AllowLocalFirewallRules
            NotifyOnListen          = $firewallProfile.NotifyOnListen
            LogAllowed              = $firewallProfile.LogAllowed
            LogBlocked              = $firewallProfile.LogBlocked
            LogFileName             = $firewallProfile.LogFileName
            LogMaxSizeKilobytes     = $firewallProfile.LogMaxSizeKilobytes
        }
    }
}

function Get-AuditNetworkProfiles {
    $networkProfiles = Get-NetConnectionProfile

    foreach ($networkProfile in $networkProfiles) {
        [PSCustomObject]@{
            Name             = $networkProfile.Name
            InterfaceAlias   = $networkProfile.InterfaceAlias
            InterfaceIndex   = $networkProfile.InterfaceIndex
            NetworkCategory  = [string]$networkProfile.NetworkCategory
            IPv4Connectivity = [string]$networkProfile.IPv4Connectivity
            IPv6Connectivity = [string]$networkProfile.IPv6Connectivity
        }
    }
}

function Get-AuditFirewallProducts {
    $firewallProducts = Get-CimInstance `
        -Namespace 'root/SecurityCenter2' `
        -ClassName FirewallProduct

    foreach ($firewallProduct in $firewallProducts) {
        [PSCustomObject]@{
            DisplayName              = $firewallProduct.displayName
            InstanceGuid             = $firewallProduct.instanceGuid
            PathToSignedProductExe   = $firewallProduct.pathToSignedProductExe
            PathToSignedReportingExe = $firewallProduct.pathToSignedReportingExe
            ProductState             = $firewallProduct.productState
            ProductStateHex          = '0x{0:X6}' -f
                [int]$firewallProduct.productState
            Timestamp                = $firewallProduct.timestamp
        }
    }
}

function Get-AuditBitLockerVolumes {
    $bitLockerVolumes = Get-BitLockerVolume

    foreach ($bitLockerVolume in $bitLockerVolumes) {
        [PSCustomObject]@{
            MountPoint          = $bitLockerVolume.MountPoint
            VolumeType         = [string]$bitLockerVolume.VolumeType
            CapacityGB         = $bitLockerVolume.CapacityGB
            VolumeStatus       = [string]$bitLockerVolume.VolumeStatus
            EncryptionPercentage =
                $bitLockerVolume.EncryptionPercentage
            ProtectionStatus   = [string]$bitLockerVolume.ProtectionStatus
            EncryptionMethod   = [string]$bitLockerVolume.EncryptionMethod
            LockStatus         = [string]$bitLockerVolume.LockStatus
            AutoUnlockEnabled  = $bitLockerVolume.AutoUnlockEnabled
        }
    }
}

# Initialize the audit run
Write-Host "=== Endpoint Audit ==="

Write-Host "Output parent directory: $OutputPath"
Write-Host "Event log lookback period: $LookbackHours hours"

$startTimeLocal = Get-Date
$startTimeUtc   = $startTimeLocal.ToUniversalTime()
$runId          = [guid]::NewGuid()
$computerName = $env:COMPUTERNAME
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$executingUser = $currentIdentity.Name
$timeZone = [TimeZoneInfo]::Local.Id
$powerShellVersion = $PSVersionTable.PSVersion.ToString()
$scriptVersion = '1.0.1'

# Determine whether this PowerShell process is running with administrator privileges.
$currentPrincipal = [Security.Principal.WindowsPrincipal]::new(
    $currentIdentity
)

$isAdministrator = $currentPrincipal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

$runTimestamp = $startTimeUtc.ToString("yyyyMMdd'T'HHmmss'Z'")
$shortRunId    = $runId.ToString().Substring(0, 8)

$runFolderName = "Endpoint-Audit-$computerName-$runTimestamp-$shortRunId"

try {
    $runFolderPath = Join-Path -Path $OutputPath -ChildPath $runFolderName

    # Create the parent output directory if it does not already exist.
    if (-not (Test-Path -LiteralPath $OutputPath -PathType Container)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    # Refuse to reuse an existing audit directory.
    if (Test-Path -LiteralPath $runFolderPath) {
        throw "The audit run directory already exists: $runFolderPath"
    }

    New-Item -ItemType Directory -Path $runFolderPath | Out-Null
}
catch {
    Write-Host "ERROR: Unable to initialize the audit output directory." `
        -ForegroundColor Red

    Write-Host "Reason: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

$logPath = Join-Path -Path $runFolderPath -ChildPath 'Audit.log'
Write-AuditLog -Message 'Audit started'

Write-Host "Run folder: $runFolderPath"

Write-Host "Local start time: $startTimeLocal"
Write-Host "UTC start time: $startTimeUtc"
Write-Host "Run ID: $runId"

# Build and export run metadata
$runContext = [PSCustomObject]@{
    RunId          = $runId
    StartTimeLocal = $startTimeLocal
    StartTimeUtc   = $startTimeUtc
    ComputerName = $computerName
    ExecutingUser = $executingUser
    TimeZone = $timeZone
    PowerShellVersion = $powerShellVersion
    ScriptVersion = $scriptVersion
    LookbackHours = $LookbackHours
    IsAdministrator = $isAdministrator
    OutputDirectory = $runFolderPath
}

$metadataPath = Join-Path -Path $runFolderPath -ChildPath 'Metadata.json'

try {
    Export-AuditJson `
        -InputObject $runContext `
        -LiteralPath $metadataPath

    Write-Host "Metadata saved: $metadataPath"
    Write-AuditLog -Message "Metadata saved: $metadataPath"
}
catch {
    $failureMessage = "Unable to save audit metadata: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage

    throw
}

# Collect and export operating-system information
Write-Host ""
Write-Host "=== Operating System ==="

$operatingSystemPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'OperatingSystem.json'

try {
    $osInfo = Get-AuditOperatingSystem

    Export-AuditJson `
        -InputObject $osInfo `
        -LiteralPath $operatingSystemPath

    $osInfo | Format-List

    Write-AuditLog -Message "Operating-system information saved: $operatingSystemPath"
}
catch {
    $failureMessage = "Unable to collect operating-system information: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export local administrator membership
Write-Host ""
Write-Host "=== Local Administrators ==="

$localAdministratorsPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'LocalAdministrators.json'

try {
    $localAdministrators = @(Get-AuditLocalAdministrators)

    Export-AuditJson `
        -InputObject $localAdministrators `
        -LiteralPath $localAdministratorsPath

    $localAdministrators |
        Format-Table Name, ObjectClass, PrincipalSource, SID -AutoSize

    Write-AuditLog -Message (
        "Local administrator membership saved: {0} ({1} members)" -f
        $localAdministratorsPath,
        $localAdministrators.Count
    )
}
catch {
    $failureMessage = "Unable to collect local administrator membership: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export local users
Write-Host ""
Write-Host "=== Local Users ==="

$localUsersPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'LocalUsers.json'

try {
    $localUsers = @(Get-AuditLocalUsers)

    Export-AuditJson `
        -InputObject $localUsers `
        -LiteralPath $localUsersPath

    $localUsers |
        Format-Table Name, Enabled, PrincipalSource, LastLogon, SID -AutoSize

    Write-AuditLog -Message (
        "Local user accounts saved: {0} ({1} accounts)" -f
        $localUsersPath,
        $localUsers.Count
    )
}
catch {
    $failureMessage = "Unable to collect local user accounts: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export running processes
Write-Host ""
Write-Host "=== Running Processes (First 15 by Name) ==="

$processesPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'Processes.json'

try {
    $processInfo = @(
        Get-AuditProcesses |
            Sort-Object Name, ProcessId
    )

    Export-AuditJson `
        -InputObject $processInfo `
        -LiteralPath $processesPath

    $processInfo |
        Select-Object -First 15 |
        Format-Table `
            Name,
            ProcessId,
            ParentProcessId,
            SessionId,
            CreationDate `
            -AutoSize

    Write-AuditLog -Message (
        "Process information saved: {0} ({1} processes)" -f
        $processesPath,
        $processInfo.Count
    )
}
catch {
    $failureMessage = "Unable to collect running processes: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export TCP connections
Write-Host ""
Write-Host "=== TCP Connection Summary ==="

$tcpConnectionsPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'TcpConnections.json'

try {
    $tcpConnectionInfo = @(
        Get-AuditTcpConnections |
            Sort-Object State, LocalAddress, LocalPort
    )

    Export-AuditJson `
        -InputObject $tcpConnectionInfo `
        -LiteralPath $tcpConnectionsPath

    $tcpConnectionInfo |
        Group-Object State |
        Sort-Object Count -Descending |
        Format-Table Name, Count -AutoSize

    Write-Host ""
    Write-Host "=== Established TCP Connections (First 15) ==="

    $tcpConnectionInfo |
        Where-Object { $_.State -eq 'Established' } |
        Sort-Object CreationTime -Descending |
        Select-Object -First 15 |
        Format-Table `
            LocalAddress,
            LocalPort,
            RemoteAddress,
            RemotePort,
            OwningProcess,
            CreationTime `
            -AutoSize

    Write-AuditLog -Message (
        "TCP connection information saved: {0} ({1} connections)" -f
        $tcpConnectionsPath,
        $tcpConnectionInfo.Count
    )
}
catch {
    $failureMessage = "Unable to collect TCP connections: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export UDP endpoints
Write-Host ""
Write-Host "=== UDP Endpoints (First 30 by Port) ==="

$udpEndpointsPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'UdpEndpoints.json'

try {
    $udpEndpointInfo = @(
        Get-AuditUdpEndpoints |
            Sort-Object LocalPort, LocalAddress
    )

    Export-AuditJson `
        -InputObject $udpEndpointInfo `
        -LiteralPath $udpEndpointsPath

    $udpEndpointInfo |
        Select-Object -First 30 |
        Format-Table `
            LocalAddress,
            LocalPort,
            OwningProcess,
            CreationTime `
            -AutoSize

    Write-AuditLog -Message (
        "UDP endpoint information saved: {0} ({1} endpoints)" -f
        $udpEndpointsPath,
        $udpEndpointInfo.Count
    )
}
catch {
    $failureMessage = "Unable to collect UDP endpoints: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export recent System event-log entries
Write-Host ""
Write-Host "=== Recent System Events (First 15) ==="

$systemEventsPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'SystemEvents.json'

$systemEventStartTime = $startTimeLocal.AddHours(-$LookbackHours)

try {
    $systemEvents = @(
        Get-AuditSystemEvents -StartTime $systemEventStartTime |
            Sort-Object TimeCreated -Descending
    )

    if ($systemEvents.Count -eq 0) {
        Set-Content `
            -LiteralPath $systemEventsPath `
            -Value '[]' `
            -Encoding utf8
    }
    else {
        Export-AuditJson `
            -InputObject $systemEvents `
            -LiteralPath $systemEventsPath
    }

    if ($systemEvents.Count -eq 0) {
        Write-Host (
            "No Critical, Error, or Warning events were found " +
            "during the selected lookback period."
        )
    }
    else {
        $systemEvents |
            Select-Object -First 15 |
            Format-Table `
                TimeCreated,
                LevelDisplayName,
                Id,
                ProviderName `
                -AutoSize
    }

    Write-AuditLog -Message (
        "System events saved: {0} ({1} events from the previous {2} hours)" -f
        $systemEventsPath,
        $systemEvents.Count,
        $LookbackHours
    )
}
catch {
    $failureMessage = "Unable to collect System events: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export Windows services
Write-Host ""
Write-Host "=== Windows Services Summary ==="

$servicesPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'Services.json'

try {
    $serviceInfo = @(
        Get-AuditServices |
            Sort-Object Name
    )

    Export-AuditJson `
        -InputObject $serviceInfo `
        -LiteralPath $servicesPath

    $serviceInfo |
        Group-Object State |
        Sort-Object Count -Descending |
        Format-Table Name, Count -AutoSize

    Write-Host ""
    Write-Host "=== Automatic Services (First 15 by Name) ==="

    $serviceInfo |
        Where-Object { $_.StartMode -eq 'Auto' } |
        Select-Object -First 15 |
        Format-Table `
            Name,
            State,
            StartName,
            ProcessId `
            -AutoSize

    Write-AuditLog -Message (
        "Windows service information saved: {0} ({1} services)" -f
        $servicesPath,
        $serviceInfo.Count
    )
}
catch {
    $failureMessage = "Unable to collect Windows services: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export scheduled tasks
Write-Host ""
Write-Host "=== Scheduled Tasks (First 20) ==="

$scheduledTasksPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'ScheduledTasks.json'

try {
    $scheduledTaskInfo = @(
        Get-AuditScheduledTasks |
            Sort-Object TaskPath, TaskName
    )

    Export-AuditJson `
        -InputObject $scheduledTaskInfo `
        -LiteralPath $scheduledTasksPath `
        -Depth 6

    $scheduledTaskInfo |
        Select-Object -First 20 `
            TaskPath,
            TaskName,
            State,
            RunLevel,
            @{
                Name = 'ActionCount'
                Expression = { $_.Actions.Count }
            },
            @{
                Name = 'TriggerCount'
                Expression = { $_.Triggers.Count }
            } |
        Format-Table -AutoSize

    Write-AuditLog -Message (
        "Scheduled task information saved: {0} ({1} tasks)" -f
        $scheduledTasksPath,
        $scheduledTaskInfo.Count
    )
}
catch {
    $failureMessage = "Unable to collect scheduled tasks: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export startup commands
Write-Host ""
Write-Host "=== Startup Commands ==="

$startupCommandsPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'StartupCommands.json'

try {
    $startupCommandInfo = @(
        Get-AuditStartupCommands |
            Sort-Object Name
    )

    Export-AuditJson `
        -InputObject $startupCommandInfo `
        -LiteralPath $startupCommandsPath

    $startupCommandInfo |
        Select-Object -First 20 `
            Name,
            Location,
            User |
        Format-Table -AutoSize

    Write-AuditLog -Message (
        "Startup command information saved: {0} ({1} entries)" -f
        $startupCommandsPath,
        $startupCommandInfo.Count
    )
}
catch {
    $failureMessage = "Unable to collect startup commands: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export interactive logon sessions
Write-Host ""
Write-Host "=== Interactive Logon Sessions ==="

$interactiveSessionsPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'InteractiveSessions.json'

try {
    $interactiveSessionInfo = @(
        Get-AuditInteractiveSessions |
            Sort-Object StartTime -Descending
    )

    Export-AuditJson `
        -InputObject $interactiveSessionInfo `
        -LiteralPath $interactiveSessionsPath

    $interactiveSessionInfo |
        Format-Table `
            Domain,
            UserName,
            LogonTypeName,
            StartTime,
            AuthenticationPackage `
            -AutoSize

    Write-AuditLog -Message (
        "Interactive logon session information saved: {0} ({1} sessions)" -f
        $interactiveSessionsPath,
        $interactiveSessionInfo.Count
    )
}
catch {
    $failureMessage = "Unable to collect interactive logon sessions: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export Microsoft Defender status
Write-Host ""
Write-Host "=== Microsoft Defender Status ==="

$defenderStatusPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'DefenderStatus.json'

try {
    $defenderStatusInfo = Get-AuditDefenderStatus

    Export-AuditJson `
        -InputObject $defenderStatusInfo `
        -LiteralPath $defenderStatusPath

    $defenderStatusInfo |
        Format-List `
            RunningMode,
            ServiceEnabled,
            AntivirusEnabled,
            RealTimeProtectionEnabled,
            NetworkInspectionEnabled

    Write-AuditLog -Message (
        "Microsoft Defender status saved: {0}" -f
        $defenderStatusPath
    )
}
catch {
    $failureMessage = "Unable to collect Microsoft Defender status: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export registered antivirus products
Write-Host ""
Write-Host "=== Registered Antivirus Products ==="

$antivirusProductsPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'AntivirusProducts.json'

try {
    $antivirusProductInfo = @(
        Get-AuditAntivirusProducts |
            Sort-Object DisplayName
    )

    Export-AuditJson `
        -InputObject $antivirusProductInfo `
        -LiteralPath $antivirusProductsPath

    $antivirusProductInfo |
        Format-Table `
            DisplayName,
            ProductState,
            ProductStateHex `
            -AutoSize

    Write-AuditLog -Message (
        "Registered antivirus products saved: {0} ({1} products)" -f
        $antivirusProductsPath,
        $antivirusProductInfo.Count
    )
}
catch {
    $failureMessage = "Unable to collect registered antivirus products: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export effective Windows Firewall profiles
Write-Host ""
Write-Host "=== Windows Firewall Profiles ==="

$firewallProfilesPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'FirewallProfiles.json'

try {
    $firewallProfileInfo = @(
        Get-AuditFirewallProfiles |
            Sort-Object Name
    )

    Export-AuditJson `
        -InputObject $firewallProfileInfo `
        -LiteralPath $firewallProfilesPath

    $firewallProfileInfo |
        Format-Table `
            Name,
            Enabled,
            DefaultInboundAction,
            DefaultOutboundAction `
            -AutoSize

    Write-AuditLog -Message (
        "Windows Firewall profiles saved: {0} ({1} profiles)" -f
        $firewallProfilesPath,
        $firewallProfileInfo.Count
    )
}
catch {
    $failureMessage = "Unable to collect Windows Firewall profiles: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export current network profiles
Write-Host ""
Write-Host "=== Current Network Profiles ==="

$networkProfilesPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'NetworkProfiles.json'

try {
    $networkProfileInfo = @(
        Get-AuditNetworkProfiles |
            Sort-Object InterfaceIndex
    )

    Export-AuditJson `
        -InputObject $networkProfileInfo `
        -LiteralPath $networkProfilesPath

    $networkProfileInfo |
        Format-Table `
            Name,
            InterfaceAlias,
            NetworkCategory,
            IPv4Connectivity,
            IPv6Connectivity `
            -AutoSize

    Write-AuditLog -Message (
        "Current network profiles saved: {0} ({1} profiles)" -f
        $networkProfilesPath,
        $networkProfileInfo.Count
    )
}
catch {
    $failureMessage = "Unable to collect current network profiles: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export registered firewall products
Write-Host ""
Write-Host "=== Registered Firewall Products ==="

$firewallProductsPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'FirewallProducts.json'

try {
    $firewallProductInfo = @(
        Get-AuditFirewallProducts |
            Sort-Object DisplayName
    )

    Export-AuditJson `
        -InputObject $firewallProductInfo `
        -LiteralPath $firewallProductsPath

    $firewallProductInfo |
        Format-Table `
            DisplayName,
            ProductState,
            ProductStateHex `
            -AutoSize

    Write-AuditLog -Message (
        "Registered firewall products saved: {0} ({1} products)" -f
        $firewallProductsPath,
        $firewallProductInfo.Count
    )
}
catch {
    $failureMessage = "Unable to collect registered firewall products: $($_.Exception.Message)"

    Write-Host "ERROR: $failureMessage" -ForegroundColor Red
    Write-AuditLog -Level 'ERROR' -Message $failureMessage
}

# Collect and export BitLocker volume status when permitted
Write-Host ""
Write-Host "=== BitLocker Volume Status ==="

$bitLockerStatusPath = Join-Path `
    -Path $runFolderPath `
    -ChildPath 'BitLockerStatus.json'

if (-not $isAdministrator) {
    $skipMessage = (
        "BitLocker status collection skipped because the current " +
        "PowerShell process is not running with administrator privileges."
    )

    Write-Host "WARNING: $skipMessage" -ForegroundColor Yellow
    Write-AuditLog -Level 'WARNING' -Message $skipMessage
}
else {
    try {
        $bitLockerVolumeInfo = @(
            Get-AuditBitLockerVolumes |
                Sort-Object MountPoint
        )

        Export-AuditJson `
            -InputObject $bitLockerVolumeInfo `
            -LiteralPath $bitLockerStatusPath

        $bitLockerVolumeInfo |
            Format-Table `
                MountPoint,
                VolumeType,
                VolumeStatus,
                EncryptionPercentage,
                ProtectionStatus,
                EncryptionMethod `
                -AutoSize

        Write-AuditLog -Message (
            "BitLocker volume status saved: {0} ({1} volumes)" -f
            $bitLockerStatusPath,
            $bitLockerVolumeInfo.Count
        )
    }
    catch {
        $failureMessage = "Unable to collect BitLocker volume status: $($_.Exception.Message)"

        Write-Host "ERROR: $failureMessage" -ForegroundColor Red
        Write-AuditLog -Level 'ERROR' -Message $failureMessage
    }
}

Write-Host ""
Write-Host "=== Run Context ==="
$runContext | Format-List

$endTimeLocal = Get-Date
$endTimeUtc = $endTimeLocal.ToUniversalTime()
$durationSeconds = ($endTimeUtc - $startTimeUtc).TotalSeconds

Write-AuditLog -Message (
    "Audit execution finished in {0:N2} seconds. " +
    "Review Audit.log for warnings and errors." -f
    $durationSeconds
)

Write-Host ""
Write-Host "=== Audit Finished ==="
Write-Host "Local end time: $endTimeLocal"
Write-Host "UTC end time: $endTimeUtc"
Write-Host ("Duration: {0:N2} seconds" -f $durationSeconds)
Write-Host "Review Audit.log for warnings and errors."
Write-Host "Output directory: $runFolderPath"