[CmdletBinding()]
param(
    [string]$BaseHref = "/tornado_gallery_website/",
    [string]$CommitMessage = "",
    [switch]$NoPush
)

$ErrorActionPreference = "Stop"

function Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Ensure-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found in PATH."
    }
}

try {
    Step "Checking required commands"
    Ensure-Command "flutter"
    Ensure-Command "git"

    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
    Set-Location $repoRoot

    Step "Building Flutter web release"
    flutter build web --release --base-href $BaseHref
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter build failed with exit code $LASTEXITCODE."
    }

    $buildWeb = Join-Path $repoRoot "build/web"
    $docsDir = Join-Path $repoRoot "docs"

    if (-not (Test-Path $buildWeb)) {
        throw "Expected build output not found: $buildWeb"
    }

    Step "Replacing docs with build/web"
    if (Test-Path $docsDir) {
        Remove-Item $docsDir -Recurse -Force
    }
    Move-Item $buildWeb $docsDir

    Step "Preparing git commit"
    git add --all docs
    if ($LASTEXITCODE -ne 0) {
        throw "git add failed."
    }

    $hasStagedChanges = git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "No changes detected in docs. Nothing to commit." -ForegroundColor Yellow
    }
    else {
        if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $CommitMessage = "Deploy web to GitHub Pages ($timestamp)"
        }

        git commit -m $CommitMessage
        if ($LASTEXITCODE -ne 0) {
            throw "git commit failed."
        }

        if (-not $NoPush) {
            Step "Pushing to remote"
            git push
            if ($LASTEXITCODE -ne 0) {
                throw "git push failed."
            }
        }
        else {
            Write-Host "Push skipped because -NoPush was specified." -ForegroundColor Yellow
        }
    }

    Write-Host "`nDone." -ForegroundColor Green
}
catch {
    Write-Error $_
    exit 1
}
