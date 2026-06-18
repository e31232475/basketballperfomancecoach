$ErrorActionPreference = "Stop"

$ffmpeg = "C:\Users\DIMAS RAMDHAN\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$backendPublicBaseDir = "C:\laragon\www\basketballperfomancecoach\public\videos\beginner"

if (!(Test-Path -LiteralPath $ffmpeg)) {
    $ffmpeg = "ffmpeg"
}

$videos = @(
    @{
        Source = "C:\vidio combination\high knee x lateral bound.mp4"
        Output = "high-knee-lateral-hurdle.mp4"
    },
    @{
        Source = "C:\vidio combination\kneeling x leg butt kick.mp4"
        Output = "kneeling-jump-single-leg-butt-kick.mp4"
    },
    @{
        Source = "C:\vidio combination\Broad Jump to Vertical Jump.mp4"
        Output = "broad-jump-to-vertical-jump.mp4"
    },
    @{
        Source = "C:\vidio combination\12 Split Jump and 20 Alternating Footsteps.mp4"
        Output = "split-jump-alternating-footsteps.mp4"
    }
)

foreach ($day in @("day6", "day7")) {
    $backendPublicDir = Join-Path $backendPublicBaseDir $day
    New-Item -ItemType Directory -Force -Path $backendPublicDir | Out-Null

    foreach ($video in $videos) {
        $outputPath = Join-Path $backendPublicDir $video.Output

        & $ffmpeg `
            -y `
            -i $video.Source `
            -an `
            -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,format=yuv420p" `
            -c:v libx264 `
            -preset medium `
            -crf 23 `
            -movflags +faststart `
            $outputPath
    }
}

Write-Host "Processed Day 6 and Day 7 Beginner videos into $backendPublicBaseDir"
