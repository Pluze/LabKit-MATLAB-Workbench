<#
.SYNOPSIS
Runs the LabKit MATLAB test suite from Windows PowerShell.

.DESCRIPTION
This is the Windows-native wrapper for tests/run_all_tests.m. It mirrors the
options accepted by scripts/run_matlab_tests.sh while avoiding a dependency on
Bash or Unix-only MATLAB startup flags.
#>

$ErrorActionPreference = 'Stop'

$RootDir = Resolve-Path (Join-Path $PSScriptRoot '..')
$IncludeGui = $false
$Suites = @()
$Tests = @()

function Show-Usage {
    @'
Usage: .\scripts\run_matlab_tests.ps1 [--gui] [--suite NAME] [--test NAME]

Runs the default non-GUI MATLAB tests.

Options:
  --gui         Also include optional noninteractive GUI launch/layout tests.
                This mode requires MATLAB graphics/uifigure support.
  --suite NAME  Run only a suite target, for example labkit/dta or apps/electrochem.
                Repeatable. The special gui target selects all GUI tests.
  --test NAME   Run only a test function, for example test_gui_layout_ui_helpers.
                Repeatable. test_gui_* automatically uses GUI MATLAB flags.
  -h, --help    Show this help text.

Environment:
  MATLAB_CMD       Optional path or command name for MATLAB.
  MATLAB_FLAGS     Optional flags for non-GUI runs. Defaults to no extra flags on Windows.
  MATLAB_GUI_FLAGS Optional flags for GUI runs. Defaults to no extra flags.
  MATLAB_TEST_LOG  Optional log path. Defaults to .\matlab_test.log.
'@
}

function Fail-Usage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    Write-Host $Message
    Show-Usage
    exit 2
}

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = [string] $args[$i]
    switch ($arg) {
        { $_ -in @('--gui', '-gui') } {
            $IncludeGui = $true
            continue
        }
        { $_ -in @('--suite', '-suite') } {
            if ($i + 1 -ge $args.Count) {
                Fail-Usage '--suite requires a value.'
            }
            $i++
            $suite = [string] $args[$i]
            $Suites += $suite
            if ($suite.ToLowerInvariant() -eq 'gui') {
                $IncludeGui = $true
            }
            continue
        }
        { $_ -in @('--test', '-test') } {
            if ($i + 1 -ge $args.Count) {
                Fail-Usage '--test requires a value.'
            }
            $i++
            $testName = [string] $args[$i]
            $Tests += $testName
            if ($testName.ToLowerInvariant().StartsWith('test_gui_')) {
                $IncludeGui = $true
            }
            continue
        }
        { $_ -in @('-h', '--help') } {
            Show-Usage
            exit 0
        }
        default {
            Fail-Usage "Unknown option: $arg"
        }
    }
}

function Find-Matlab {
    if (-not [string]::IsNullOrWhiteSpace($env:MATLAB_CMD)) {
        return $env:MATLAB_CMD
    }

    $cmd = Get-Command matlab.exe -ErrorAction SilentlyContinue
    if ($null -ne $cmd -and -not [string]::IsNullOrWhiteSpace($cmd.Source)) {
        return $cmd.Source
    }

    $cmd = Get-Command matlab -ErrorAction SilentlyContinue
    if ($null -ne $cmd -and -not [string]::IsNullOrWhiteSpace($cmd.Source)) {
        return $cmd.Source
    }

    $programFiles = $env:ProgramFiles
    if ([string]::IsNullOrWhiteSpace($programFiles)) {
        return $null
    }

    $matlabRoot = Join-Path $programFiles 'MATLAB'
    if (-not (Test-Path -LiteralPath $matlabRoot)) {
        return $null
    }

    $candidates = Get-ChildItem -LiteralPath $matlabRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'R*' } |
        Sort-Object -Property Name -Descending

    foreach ($candidate in $candidates) {
        $exe = Join-Path $candidate.FullName 'bin\matlab.exe'
        if (Test-Path -LiteralPath $exe) {
            return $exe
        }
    }

    return $null
}

function ConvertTo-MatlabStringLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function ConvertTo-MatlabCell {
    param(
        [string[]] $Values
    )

    if ($null -eq $Values -or $Values.Count -eq 0) {
        return '{}'
    }

    $quoted = @()
    foreach ($value in $Values) {
        $quoted += ConvertTo-MatlabStringLiteral $value
    }
    return '{' + ($quoted -join ',') + '}'
}

function Split-MatlabFlags {
    param(
        [string] $Flags
    )

    if ([string]::IsNullOrWhiteSpace($Flags)) {
        return @()
    }

    return @($Flags -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

$MatlabBin = Find-Matlab
if ([string]::IsNullOrWhiteSpace($MatlabBin)) {
    Write-Host 'MATLAB executable not found. Set MATLAB_CMD to matlab.exe and retry.'
    exit 127
}

$rootPath = [string] $RootDir
$logFile = if (-not [string]::IsNullOrWhiteSpace($env:MATLAB_TEST_LOG)) {
    $env:MATLAB_TEST_LOG
} else {
    Join-Path $rootPath 'matlab_test.log'
}

$suiteCell = ConvertTo-MatlabCell $Suites
$testCell = ConvertTo-MatlabCell $Tests
$includeGuiText = if ($IncludeGui) { 'true' } else { 'false' }
$selectionExpr = "struct('suites', {$suiteCell}, 'tests', {$testCell})"
$testExpr = "run_all_tests($includeGuiText, $selectionExpr);"
$matlabCommand = "cd($(ConvertTo-MatlabStringLiteral $rootPath)); addpath(fullfile(pwd, 'tests')); $testExpr"

$flagSource = if ($IncludeGui) { $env:MATLAB_GUI_FLAGS } else { $env:MATLAB_FLAGS }
$matlabArgs = @(Split-MatlabFlags $flagSource)
$matlabArgs += @('-logfile', $logFile, '-batch', $matlabCommand)

Write-Host "Using MATLAB: $MatlabBin"
Write-Host "Project root: $rootPath"
Write-Host "MATLAB log: $logFile"

if (Test-Path -LiteralPath $logFile) {
    Remove-Item -LiteralPath $logFile -Force
}

& $MatlabBin @matlabArgs
$status = $LASTEXITCODE

if ($status -eq 0) {
    Write-Host "MATLAB tests completed successfully. Log: $logFile"
} elseif (Test-Path -LiteralPath $logFile) {
    Get-Content -LiteralPath $logFile -Raw
} else {
    Write-Host "MATLAB did not create log file: $logFile"
}

exit $status
