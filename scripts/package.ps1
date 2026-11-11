#Requires -Version 7.4

param(
    [Parameter(Mandatory)]
    [ValidateSet('win-x64', 'osx-x64', 'osx-arm64', 'linux-x64', 'linux-arm64')]
    [string] $Runtime
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$PSNativeCommandUseErrorActionPreference = $true

$projectRoot = Split-Path -Parent $PSScriptRoot
$project = Join-Path $projectRoot 'portable-ocr.csproj'
$dist = Join-Path $projectRoot 'dist'
$packageName = "portable-ocr-$Runtime"
$stage = Join-Path $dist $packageName
$publish = Join-Path $dist "publish/$Runtime"
$executableName = if ($Runtime.StartsWith('win-')) { 'portable-ocr.exe' } else { 'portable-ocr' }

$hostOs = if ($IsWindows) { 'win' } elseif ($IsMacOS) { 'osx' } else { 'linux' }
$hostArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString().ToLowerInvariant()
if ($Runtime -ne "$hostOs-$hostArchitecture") {
    throw "Run packaging on a native $Runtime host; current host is $hostOs-$hostArchitecture."
}

# Refuse to reuse a staging directory so old files cannot enter a release archive.
if (Test-Path -LiteralPath $stage) {
    throw "Package directory already exists: $stage. Move or remove it before packaging again."
}

Push-Location $projectRoot
try {
    dotnet restore $project --locked-mode
    dotnet publish $project -c Release -r $Runtime --no-restore -o $publish

    New-Item -ItemType Directory -Path $stage | Out-Null
    $executable = Join-Path $stage $executableName
    Copy-Item -LiteralPath (Join-Path $publish $executableName) -Destination $executable
    Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md'), (Join-Path $projectRoot 'THIRD-PARTY-NOTICES.md') -Destination $stage
    Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses') -Destination $stage -Recurse

    if ($IsWindows -eq $false) {
        chmod 755 $executable
    }
    & $executable --help

    if ($IsWindows) {
        $archive = Join-Path $dist "$packageName.zip"
        Compress-Archive -LiteralPath $stage -DestinationPath $archive
    } else {
        $archive = Join-Path $dist "$packageName.tar.gz"
        tar -czf $archive -C $dist $packageName
    }

    $hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $([System.IO.Path]::GetFileName($archive))" | Set-Content -LiteralPath "$archive.sha256" -Encoding utf8NoBOM
    Write-Host "Package: $archive"
} finally {
    Pop-Location
}
