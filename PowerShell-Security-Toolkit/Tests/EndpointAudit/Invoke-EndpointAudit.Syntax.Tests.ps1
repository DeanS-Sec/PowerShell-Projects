Describe 'Invoke-EndpointAudit syntax' {
    BeforeAll {
        $scriptPath = Join-Path `
            -Path $PSScriptRoot `
            -ChildPath '..\..\Scripts\EndpointAudit\Invoke-EndpointAudit.ps1'

        $scriptPath = (Resolve-Path -LiteralPath $scriptPath).Path
    }

    It 'finds the Endpoint Audit script' {
        Test-Path -LiteralPath $scriptPath |
            Should -BeTrue
    }

    It 'parses without syntax errors in PowerShell 7' {
        $tokens = $null
        $parseErrors = $null

        [System.Management.Automation.Language.Parser]::ParseFile(
            $scriptPath,
            [ref]$tokens,
            [ref]$parseErrors
        ) | Out-Null

        $parseErrors |
            Should -BeNullOrEmpty
    }

    It 'parses without syntax errors in Windows PowerShell 5.1' {
        $windowsPowerShell = Join-Path `
            -Path $env:WINDIR `
            -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'

        $escapedScriptPath = $scriptPath.Replace("'", "''")

        $parseCommand = @"
`$tokens = `$null
`$parseErrors = `$null

[System.Management.Automation.Language.Parser]::ParseFile(
    '$escapedScriptPath',
    [ref]`$tokens,
    [ref]`$parseErrors
) | Out-Null

if (`$parseErrors.Count -gt 0) {
    `$parseErrors |
        ForEach-Object {
            [Console]::Error.WriteLine(`$_.Message)
        }

    exit 1
}
"@

        $encodedCommand = [Convert]::ToBase64String(
            [Text.Encoding]::Unicode.GetBytes($parseCommand)
        )

        & $windowsPowerShell `
            -NoLogo `
            -NoProfile `
            -NonInteractive `
            -EncodedCommand $encodedCommand

        $LASTEXITCODE |
            Should -Be 0
    }
}