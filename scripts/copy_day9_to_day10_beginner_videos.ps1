$ErrorActionPreference = "Stop"

$sourceDir = "C:\laragon\www\basketballperfomancecoach\public\videos\beginner\day9"
$targetDir = "C:\laragon\www\basketballperfomancecoach\public\videos\beginner\day10"

if (!(Test-Path -LiteralPath $sourceDir)) {
    throw "Source directory not found: $sourceDir"
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$filenames = @(
    "alternating-foot-taps-squat-jumps.mp4",
    "lateral-bound-broad-jump.mp4",
    "lateral-hurdle-tuck-jump.mp4",
    "single-leg-butt-kick.mp4",
    "lateral-hurdle-foot-fires.mp4"
)

foreach ($filename in $filenames) {
    $sourcePath = Join-Path $sourceDir $filename

    if (!(Test-Path -LiteralPath $sourcePath)) {
        throw "Source video not found: $sourcePath"
    }

    Copy-Item -LiteralPath $sourcePath -Destination $targetDir -Force
}

Write-Host "Copied Day 9 Beginner videos into $targetDir"
