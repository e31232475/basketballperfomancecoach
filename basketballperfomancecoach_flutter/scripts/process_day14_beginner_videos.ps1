$ErrorActionPreference = "Stop"

$ffmpeg = "C:\Users\DIMAS RAMDHAN\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$backendPublicDir = "C:\laragon\www\basketballperfomancecoach\public\videos\beginner\day14"

if (!(Test-Path -LiteralPath $ffmpeg)) {
    $ffmpeg = "ffmpeg"
}

New-Item -ItemType Directory -Force -Path $backendPublicDir | Out-Null

$videos = @(
    @{
        Source = "C:\video program\SPRINT.MOV"
        Output = "15-meter-sprint.mp4"
        Start = "00:00:02.40"
        Duration = "00:00:10.60"
    },
    @{
        Source = "C:\vidio combination\0605.mp4"
        Output = "kneeling-broad-jump-tuck-jump.mp4"
    },
    @{
        Source = "C:\vidio combination\split jump x vertical jump.mp4"
        Output = "split-jump-vertical-jump.mp4"
    },
    @{
        Source = "C:\vidio combination\LH X SLBJ.mp4"
        Output = "lateral-hurdle-single-leg-broad-jump.mp4"
    },
    @{
        Source = "C:\vidio combination\180 x alternating ft.mp4"
        Output = "180-degree-jump-alternating-foot-taps.mp4"
    }
)

foreach ($video in $videos) {
    $outputPath = Join-Path $backendPublicDir $video.Output
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
}

Write-Host "Processed Day 14 Beginner videos into $backendPublicDir"
