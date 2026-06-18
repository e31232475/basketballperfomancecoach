$ErrorActionPreference = "Stop"

$ffmpeg = "C:\Users\DIMAS RAMDHAN\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$backendPublicBaseDir = "C:\laragon\www\basketballperfomancecoach\public\videos\beginner"
$day12Dir = Join-Path $backendPublicBaseDir "day12"
$day13Dir = Join-Path $backendPublicBaseDir "day13"

if (!(Test-Path -LiteralPath $ffmpeg)) {
    $ffmpeg = "ffmpeg"
}

New-Item -ItemType Directory -Force -Path $day12Dir | Out-Null
New-Item -ItemType Directory -Force -Path $day13Dir | Out-Null

$videos = @(
    @{
        Source = "C:\vidio combination\Alternating foot taps x squat jump.mp4"
        Output = "alternating-foot-taps-squat-jump.mp4"
    },
    @{
        Source = "C:\vidio combination\0605.mp4"
        Output = "broad-jump-tuck-jump.mp4"
    },
    @{
        Source = "C:\vidio combination\kneeling tuck jump to broad jump.mp4"
        Output = "kneeling-tuck-jump-broad-jump.mp4"
    },
    @{
        Source = "C:\video program\LATERAL BOUND JUMP.MOV"
        Output = "lateral-bound-jump.mp4"
        Start = "00:00:00.30"
        Duration = "00:00:07.00"
    },
    @{
        Source = "C:\vidio combination\kneeling jump x foot fires.mp4"
        Output = "kneeling-jump-foot-fires.mp4"
    }
)

foreach ($video in $videos) {
    $outputPath = Join-Path $day12Dir $video.Output
    $arguments = @("-y")

    if ($video.ContainsKey("Start")) {
        $arguments += @("-ss", $video.Start)
    }

    if ($video.ContainsKey("Duration")) {
        $arguments += @("-t", $video.Duration)
    }

    $arguments += @(
        "-i", $video.Source,
        "-an",
        "-vf", "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,format=yuv420p",
        "-c:v", "libx264",
        "-preset", "medium",
        "-crf", "23",
        "-movflags", "+faststart",
        $outputPath
    )

    & $ffmpeg @arguments
    Copy-Item -LiteralPath $outputPath -Destination $day13Dir -Force
}

Write-Host "Processed Day 12 and Day 13 Beginner videos into $backendPublicBaseDir"
