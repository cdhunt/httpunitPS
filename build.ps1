[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [ValidateSet('clean', 'build', 'changes', 'publish')]
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

function Changes {
    param ()

    git log -n 3 --pretty='format:%h %s'
}

function Publish {
    param ()

    $repo = if ($env:PSPublishRepo) { $env:PSPublishRepo } else { 'PSGallery' }

    $notes = Changes
    $manifest = Join-Path $publish -ChildPath 'HttpUnitPS.psd1'
    Update-ModuleManifest -Path $manifest -ReleaseNotes $notes
    Publish-Module -Path $publish -Repository $repo -NuGetApiKey $env:PSPublishApiKey
}

switch ($Task) {
    'clean' {
        Clean
    }
    'build' {
        Clean
        Build
    }
    'changes' {
        Changes
    }
    'publish' {
        Clean
        Build
        Publish
    }
    Default {
        Clean
        Build
    }
}