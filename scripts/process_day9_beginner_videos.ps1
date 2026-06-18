$ErrorActionPreference = "Stop"

$ffmpeg = "C:\Users\DIMAS RAMDHAN\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$backendPublicDir = "C:\laragon\www\basketballperfomancecoach\public\videos\beginner\day9"

if (!(Test-Path -LiteralPath $ffmpeg)) {
    $ffmpeg = "ffmpeg"
}

New-Item -ItemType Directory -Force -Path $backendPublicDir | Out-Null

$videos = @(
    @{
        Source = "C:\vidio combination\Alternating foot taps x squat jump.mp4"
        Output = "alternating-foot-taps-squat-jumps.mp4"
    },
    @{
        Source = "C:\vidio combination\lateral bound x broad jump.mp4"
        Output = "lateral-bound-broad-jump.mp4"
    },
    @{
        Source = "C:\vidio combination\Lateral Hurdle x Tuck Jump.mp4"
        Output = "lateral-hurdle-tuck-jump.mp4"
    },
    @{
        Source = "C:\video program\SINGLE LEG BUTT KICK.MOV"
        Output = "single-leg-butt-kick.mp4"
        Start = "00:00:00.00"
        Duration = "00:00:09.20"
    },
    @{
        Source = "C:\vidio combination\Lateral Hurdle x Foot Fires.mp4"
        Output = "lateral-hurdle-foot-fires.mp4"
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

Write-Host "Processed Day 9 Beginner videos into $backendPublicDir"
