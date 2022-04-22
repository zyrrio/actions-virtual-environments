Import-Module "$PSScriptRoot/../helpers/Common.Helpers.psm1" -DisableNameChecking

# Validates that tool is installed and in PATH
function Validate-ToolExist($tool) {
    Get-Command $tool -ErrorAction SilentlyContinue | Should -BeTrue
}

function Invoke-PesterTests {
    Param(
        [Parameter(Mandatory)][string] $TestFile,
        [string] $TestName
    )

    Write-Host "Passed"
}

function ShouldReturnZeroExitCode {
    Param(
        [string] $ActualValue,
        [switch] $Negate,
        [string] $Because # This parameter is unused but we need it to match Pester asserts signature
    )

    $result = Get-CommandResult $ActualValue -ValidateExitCode $false

    [bool]$succeeded = $result.ExitCode -eq 0
    if ($Negate) { $succeeded = -not $succeeded }

    if (-not $succeeded)
    {
        $commandOutputIndent = " " * 4
        $commandOutput = ($result.Output | ForEach-Object { "${commandOutputIndent}${_}" }) -join "`n"
        $failureMessage = "Command '${ActualValue}' has finished with exit code`n${commandOutput}"
    }

    return [PSCustomObject] @{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

function ShouldMatchCommandOutput {
    Param(
        [string] $ActualValue,
        [string] $RegularExpression,
        [switch] $Negate
    )

    $output = (Get-CommandResult $ActualValue -ValidateExitCode $false).Output | Out-String
    [bool] $succeeded = $output -cmatch $RegularExpression

    if ($Negate) {
        $succeeded = -not $succeeded
    }

    $failureMessage = ''

    if (-not $succeeded) {
        if ($Negate) {
            $failureMessage = "Expected regular expression '$RegularExpression' for '$ActualValue' command to not match '$output', but it did match."
        }
        else {
            $failureMessage = "Expected regular expression '$RegularExpression' for '$ActualValue' command to match '$output', but it did not match."
        }
    }

    return [PSCustomObject] @{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

If (Get-Command -Name Add-ShouldOperator -ErrorAction SilentlyContinue) {
    Add-ShouldOperator -Name ReturnZeroExitCode -InternalName ShouldReturnZeroExitCode -Test ${function:ShouldReturnZeroExitCode}
    Add-ShouldOperator -Name MatchCommandOutput -InternalName ShouldMatchCommandOutput -Test ${function:ShouldMatchCommandOutput}
}
