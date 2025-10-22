# ==============================================================================
# Fizzlebee's Treasure Tracker - Release Script
# Copyright (c) 2025 Vivian Voss (Fizzlebee) <Boulder Dash Heroes>
# Licensed under the BSD 3-Clause License (see LICENSE file)
# ==============================================================================
# This script automates the release process for FTT:
# 1. Generates a new patch level (YYmmDD.HHMM) from current date/time
# 2. Updates the TOC file with new version
# 3. Creates a ZIP export in the parent directory (AddOns folder)
# 4. Excludes .claude/ folder and all development files
# ==============================================================================

param(
    [string]$Version = "1.0",  # Major.Minor version (default: 1.0)
    [switch]$DryRun = $false   # If set, only shows what would be done
)

# ==============================================================================
# CONFIGURATION
# ==============================================================================

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ProjectName = "FizzlebeesTreasureTracker"
$TOCFile = Join-Path $ProjectRoot "$ProjectName.toc"
$ParentDir = Split-Path -Parent $ProjectRoot

# Files/folders to exclude from ZIP
$Exclusions = @(
    ".claude",
    ".git",
    ".gitignore"
)

# ==============================================================================
# FUNCTIONS
# ==============================================================================

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Get-PatchLevel {
    # Generate patch level: YYmmDD.HHMM
    $now = Get-Date
    $patchLevel = $now.ToString("yyMMdd.HHmm")
    return $patchLevel
}

function Get-CurrentDate {
    # Get current date in YYYY-MM-DD format
    return (Get-Date).ToString("yyyy-MM-dd")
}

function Update-TOCFile {
    param(
        [string]$TOCPath,
        [string]$FullVersion,
        [string]$CurrentDate
    )

    if (-not (Test-Path $TOCPath)) {
        Write-Error-Custom "TOC file not found: $TOCPath"
        return $false
    }

    Write-Info "Updating TOC file: $TOCPath"

    # Read TOC file
    $content = Get-Content $TOCPath -Raw

    # Update version line
    $content = $content -replace '(?m)^## Version:.*$', "## Version: $FullVersion"

    # Update X-Date line
    $content = $content -replace '(?m)^## X-Date:.*$', "## X-Date: $CurrentDate"

    if ($DryRun) {
        Write-Info "[DRY-RUN] Would update TOC to version: $FullVersion"
        Write-Info "[DRY-RUN] Would update X-Date to: $CurrentDate"
        return $true
    }

    # Write back to file
    Set-Content -Path $TOCPath -Value $content -NoNewline

    Write-Success "TOC file updated successfully"
    return $true
}

function Create-ReleaseZIP {
    param(
        [string]$SourcePath,
        [string]$DestinationDir,
        [string]$ZipName,
        [string[]]$Exclude
    )

    $zipPath = Join-Path $DestinationDir $ZipName

    Write-Info "Creating release ZIP: $ZipName"
    Write-Info "Source: $SourcePath"
    Write-Info "Destination: $zipPath"
    Write-Info "Exclusions: $($Exclude -join ', ')"

    if ($DryRun) {
        Write-Info "[DRY-RUN] Would create ZIP at: $zipPath"
        return $true
    }

    # Create temporary directory for filtered copy
    $tempDir = Join-Path $env:TEMP "FTT_Release_$(Get-Random)"
    $tempProjectDir = Join-Path $tempDir $ProjectName

    try {
        Write-Info "Creating temporary directory: $tempDir"
        New-Item -ItemType Directory -Path $tempProjectDir -Force | Out-Null

        # Copy project files, excluding specified items
        Write-Info "Copying project files (excluding development files)..."
        Get-ChildItem -Path $SourcePath -Recurse | ForEach-Object {
            $relativePath = $_.FullName.Substring($SourcePath.Length + 1)
            $shouldExclude = $false

            foreach ($exclusion in $Exclude) {
                if ($relativePath -like "$exclusion*") {
                    $shouldExclude = $true
                    break
                }
            }

            if (-not $shouldExclude) {
                $targetPath = Join-Path $tempProjectDir $relativePath
                if ($_.PSIsContainer) {
                    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
                } else {
                    $targetDir = Split-Path -Parent $targetPath
                    if (-not (Test-Path $targetDir)) {
                        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                    }
                    Copy-Item -Path $_.FullName -Destination $targetPath -Force
                }
            }
        }

        # Remove existing ZIP if present
        if (Test-Path $zipPath) {
            Write-Info "Removing existing ZIP file..."
            Remove-Item $zipPath -Force
        }

        # Create ZIP archive
        Write-Info "Compressing files to ZIP..."
        Compress-Archive -Path $tempProjectDir -DestinationPath $zipPath -Force

        Write-Success "Release ZIP created successfully: $zipPath"
        return $true

    } catch {
        Write-Error-Custom "Failed to create ZIP: $_"
        return $false

    } finally {
        # Clean up temporary directory
        if (Test-Path $tempDir) {
            Write-Info "Cleaning up temporary files..."
            Remove-Item -Path $tempDir -Recurse -Force
        }
    }
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Yellow
Write-Host " Fizzlebee's Treasure Tracker - Release Script" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Yellow
Write-Host ""

# Validate project directory
if (-not (Test-Path $ProjectRoot)) {
    Write-Error-Custom "Project directory not found: $ProjectRoot"
    exit 1
}

if (-not (Test-Path $TOCFile)) {
    Write-Error-Custom "TOC file not found: $TOCFile"
    exit 1
}

# Generate patch level
$patchLevel = Get-PatchLevel
$fullVersion = "$Version.$patchLevel"
$currentDate = Get-CurrentDate
$zipName = "${ProjectName}_${fullVersion}.zip"

Write-Info "Version Configuration:"
Write-Info "  Major.Minor: $Version"
Write-Info "  Patch Level: $patchLevel"
Write-Info "  Full Version: $fullVersion"
Write-Info "  Release Date: $currentDate"
Write-Info "  ZIP Filename: $zipName"
Write-Host ""

if ($DryRun) {
    Write-Host "=== DRY-RUN MODE ===" -ForegroundColor Magenta
    Write-Host "No files will be modified or created." -ForegroundColor Magenta
    Write-Host ""
}

# Step 1: Update TOC file
Write-Host "Step 1: Updating TOC file..." -ForegroundColor Yellow
if (-not (Update-TOCFile -TOCPath $TOCFile -FullVersion $fullVersion -CurrentDate $currentDate)) {
    Write-Error-Custom "Failed to update TOC file"
    exit 1
}
Write-Host ""

# Step 2: Create ZIP
Write-Host "Step 2: Creating release ZIP..." -ForegroundColor Yellow
if (-not (Create-ReleaseZIP -SourcePath $ProjectRoot -DestinationDir $ParentDir -ZipName $zipName -Exclude $Exclusions)) {
    Write-Error-Custom "Failed to create release ZIP"
    exit 1
}
Write-Host ""

# Success
Write-Host "================================================================================" -ForegroundColor Green
Write-Host " Release completed successfully!" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""
Write-Success "Version: $fullVersion"
Write-Success "ZIP Location: $(Join-Path $ParentDir $zipName)"
Write-Host ""

if (-not $DryRun) {
    Write-Info "Next steps:"
    Write-Info "  1. Update PATCHNOTES.md with release information"
    Write-Info "  2. Test the ZIP file by extracting and loading in WoW"
    Write-Info "  3. Commit changes to git (if applicable)"
    Write-Host ""
}
