#!/usr/bin/env pwsh

param(
    [string]$Configuration = "Release",
    [string]$Platform = "Any CPU",
    [switch]$Pack,
    [switch]$PackOnly,
    [switch]$Publish,
    [switch]$ReadyToRun
)

$ErrorActionPreference = "Stop"

Write-Host "Building Schedule Editor..." -ForegroundColor Green

# Navigate to the source directory
Push-Location "Source"

try {
    # Build for all target platforms
    $platforms = @("win-x64")
    $names = @("Windows x64")

    if (-not $PackOnly) {
        # Clean previous builds
        Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
        dotnet clean ScheduleEditor.csproj -c $Configuration

        # Restore packages
        Write-Host "Restoring packages..." -ForegroundColor Yellow
        dotnet restore ScheduleEditor.csproj

        for ($i = 0; $i -lt $platforms.Length; $i++) {
            $rid = $platforms[$i]
            $name = $names[$i]

            Write-Host "Building for $name..." -ForegroundColor Cyan
            Write-Host "  RID: $rid" -ForegroundColor Gray

            # Build publish command with conditional ready-to-run
            $publishCmd = "dotnet publish ScheduleEditor.csproj -c $Configuration -r $rid --self-contained true -p:PublishSingleFile=true -p:PublishTrimmed=false -o `"bin/publish/$rid`""

            if ($ReadyToRun) {
                Write-Host "  Enabling Ready-to-Run compilation..." -ForegroundColor Yellow
                $publishCmd += " -p:PublishReadyToRun=true"
            }

            # Publish the application
            Write-Host "  Running: $publishCmd" -ForegroundColor Gray
            Invoke-Expression $publishCmd

            if ($LASTEXITCODE -ne 0) {
                throw "Build failed for $name"
            }
        }
    }

    if ($Pack -or $PackOnly) {
        Write-Host "Creating Velopack packages..." -ForegroundColor Green

        # Install vpk tool if not present
        if (!(Get-Command "vpk" -ErrorAction SilentlyContinue)) {
            Write-Host "Installing Velopack CLI..." -ForegroundColor Yellow
            dotnet tool install -g vpk
        }

        for ($j = 0; $j -lt $platforms.Length; $j++) {
            $rid = $platforms[$j]
            $name = $names[$j]

            Write-Host "Packaging for $name..." -ForegroundColor Cyan

            $publishDir = "bin/publish/$rid"
            $releaseDir = "bin/releases/$rid"

            # Create release directory
            New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

            # Create Velopack package
            vpk pack --packId ScheduleEditor --packVersion "1.0.3" --packDir $publishDir --outputDir $releaseDir --framework net8 --runtime $rid

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Packaging failed for $name"
            }
        }
    }

    Write-Host "Build completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Build failed: $_"
    exit 1
}
finally {
    Pop-Location
}