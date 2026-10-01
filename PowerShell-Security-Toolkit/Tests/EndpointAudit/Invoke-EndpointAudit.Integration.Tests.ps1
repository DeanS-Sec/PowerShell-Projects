Describe 'Invoke-EndpointAudit integration' -Tag 'Integration' {
    BeforeAll {
        $scriptPath = Join-Path `
            -Path $PSScriptRoot `
            -ChildPath '..\..\Scripts\EndpointAudit\Invoke-EndpointAudit.ps1'

        $scriptPath = (Resolve-Path -LiteralPath $scriptPath).Path

        $repositoryPath = Join-Path `
            -Path $PSScriptRoot `
            -ChildPath '..\..\..'

        $repositoryPath = (Resolve-Path -LiteralPath $repositoryPath).Path

        $outputRoot = Join-Path `
            -Path $TestDrive `
            -ChildPath 'EndpointAuditOutput'

        $consoleOutputPath = Join-Path `
            -Path $TestDrive `
            -ChildPath 'EndpointAuditConsoleOutput.txt'

        & $scriptPath `
            -OutputPath $outputRoot `
            -LookbackHours 1 `
            *> $consoleOutputPath

        $runFolders = @(
            Get-ChildItem `
                -LiteralPath $outputRoot `
                -Directory
        )

        $runFolder = $runFolders |
            Select-Object -First 1
    }

    It 'creates exactly one audit-run directory' {
        $runFolders.Count |
            Should -Be 1
    }

    It 'creates the core audit files' {
        $requiredFiles = @(
            'Audit.log'
            'Metadata.json'
            'OperatingSystem.json'
        )

        foreach ($requiredFile in $requiredFiles) {
            $requiredPath = Join-Path `
                -Path $runFolder.FullName `
                -ChildPath $requiredFile

            Test-Path -LiteralPath $requiredPath -PathType Leaf |
                Should -BeTrue `
                    -Because "$requiredFile should be created"
        }
    }

    It 'writes valid JSON to every generated JSON file' {
        $jsonFiles = @(
            Get-ChildItem `
                -LiteralPath $runFolder.FullName `
                -Filter '*.json' `
                -File
        )

        $jsonFiles.Count |
            Should -BeGreaterThan 0

        foreach ($jsonFile in $jsonFiles) {
            $jsonContent = Get-Content `
                -LiteralPath $jsonFile.FullName `
                -Raw

            $jsonContent |
                Should -Not -BeNullOrEmpty

            $jsonContent |
                Test-Json |
                Should -BeTrue `
                    -Because "$($jsonFile.Name) should contain valid JSON"
        }
    }

    It 'records the expected run metadata' {
        $metadataPath = Join-Path `
            -Path $runFolder.FullName `
            -ChildPath 'Metadata.json'

        $metadata = Get-Content `
            -LiteralPath $metadataPath `
            -Raw |
            ConvertFrom-Json

        $metadata.ScriptVersion |
            Should -Be '1.0.1'

        $metadata.LookbackHours |
            Should -Be 1

        $metadata.OutputDirectory |
            Should -Be $runFolder.FullName

        {
            [guid]::Parse($metadata.RunId)
        } |
            Should -Not -Throw
    }

    It 'records audit start and completion in the log' {
        $logPath = Join-Path `
            -Path $runFolder.FullName `
            -ChildPath 'Audit.log'

        $logContent = Get-Content `
            -LiteralPath $logPath `
            -Raw

        $logContent |
            Should -Match 'Audit started'

        $logContent |
            Should -Match 'Audit execution finished'
    }

    It 'keeps generated output outside the Git repository' {
        $repositoryFullPath =
            [IO.Path]::GetFullPath($repositoryPath).
                TrimEnd([IO.Path]::DirectorySeparatorChar) +
                [IO.Path]::DirectorySeparatorChar

        $outputFullPath =
            [IO.Path]::GetFullPath($runFolder.FullName)

        $outputFullPath.StartsWith(
            $repositoryFullPath,
            [StringComparison]::OrdinalIgnoreCase
        ) |
            Should -BeFalse
    }
}