<#
.SYNOPSIS
Runs LabKit MATLAB build tasks from Windows PowerShell.

.DESCRIPTION
This is the Windows-native wrapper for the LabKit build task entry points.
With no task arguments it runs `buildtool test`. Positional arguments are passed
as build task names, for example `checkStyle` or `testUnit coverage`.
#>

$ErrorActionPreference = 'Stop'

$RootDir = Resolve-Path (Join-Path $PSScriptRoot '..')
$Tasks = @()

function Show-Usage {
    @'
Usage: .\scripts\run_matlab_tests.ps1 [TASK ...]

Runs LabKit MATLAB build tasks. With no TASK arguments, runs `buildtool test`.

Examples:
  .\scripts\run_matlab_tests.ps1
  .\scripts\run_matlab_tests.ps1 checkStyle
  .\scripts\run_matlab_tests.ps1 testUnit coverage
  .\scripts\run_matlab_tests.ps1 testGuiStructural
  .\scripts\run_matlab_tests.ps1 listTasks

Task catalog:
  See docs/testing.md or run `buildtool listTasks`.

Removed interface:
  --suite, --test, and --gui are no longer supported. Use build task names.

Environment:
  MATLAB_CMD      Optional path or command name for MATLAB.
  MATLAB_FLAGS    Optional MATLAB flags for every run.
  MATLAB_TEST_LOG Optional log path. Defaults to .\matlab_test.log.
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
    if ($arg -in @('-h', '--help')) {
        Show-Usage
        exit 0
    }
    if ($arg.StartsWith('-')) {
        Fail-Usage "Unsupported option: $arg. Use build task names such as checkStyle, test, or testGuiStructural."
    }
    if ($arg -notmatch '^[A-Za-z][A-Za-z0-9_]*$') {
        Fail-Usage "Invalid build task name: $arg"
    }
    $Tasks += $arg
}

if ($Tasks.Count -eq 0) {
    $Tasks = @('test')
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

$taskText = $Tasks -join ' '
$matlabCommand = "cd($(ConvertTo-MatlabStringLiteral $rootPath)); buildtool $taskText;"
$matlabArgs = @(Split-MatlabFlags $env:MATLAB_FLAGS)
$matlabArgs += @('-logfile', $logFile, '-batch', $matlabCommand)

Write-Host "Using MATLAB: $MatlabBin"
Write-Host "Project root: $rootPath"
Write-Host "Build tasks: $taskText"
Write-Host "MATLAB log: $logFile"

if (Test-Path -LiteralPath $logFile) {
    Remove-Item -LiteralPath $logFile -Force
}

& $MatlabBin @matlabArgs
$status = $LASTEXITCODE

if ($status -eq 0) {
    Write-Host "MATLAB build tasks completed successfully. Log: $logFile"
} elseif (Test-Path -LiteralPath $logFile) {
    Get-Content -LiteralPath $logFile -Raw
} else {
    Write-Host "MATLAB did not create log file: $logFile"
}

exit $status
