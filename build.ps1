[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [ValidateSet('clean', 'build')]
    [string]
    $Task
)

$publish = Join-Path $PSScriptRoot -ChildPath publish -AdditionalChildPath 'HttpUnitPS'
$src = Join-Path $PSScriptRoot -ChildPath src
$files = Join-Path $src -ChildPath *
$lib = Join-Path $src -ChildPath lib

function Clean {
    param ()

    if (Test-Path $publish) {
        Remove-Item -Path $publish -Recurse -Force
    }
}

function Build {
    param ()

    New-Item -Path $publish -ItemType Directory | Out-Null
    Copy-Item -Path $files -Destination $publish
    Copy-Item -Path $lib -Destination $publish -Force -Recurse
    Copy-Item -Path .\LICENSE -Destination $publish
    Copy-Item -Path .\README.md -Destination $publish
}

switch ($Task) {
    'clean' {
        Clean
    }
    'build' {
        Clean
        Build
    }
    Default {
        Clean
        Build
    }
}