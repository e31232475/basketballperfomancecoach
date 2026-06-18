$ErrorActionPreference = "Stop"

$ffmpeg = "C:\Users\DIMAS RAMDHAN\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$backendPublicDir = "C:\laragon\www\basketballperfomancecoach\public\videos\beginner\day8"

if (!(Test-Path -LiteralPath $ffmpeg)) {
    $ffmpeg = "ffmpeg"
}

New-Item -ItemType Directory -Force -Path $backendPublicDir | Out-Null

$videos = @(
    @{
        Source = "C:\video program\SPRINT.MOV"
        Output = "sprint-15-meter.mp4"
        Start = "00:00:02.40"
        Duration = "00:00:10.60"
    },
    @{
        Source = "C:\vidio combination\180 Degree Jump x Lateral Bound Jump.mp4"
        Output = "180-degree-jump-lateral-bounds.mp4"
    },
    @{
        Source = "C:\video program\KNEELING JUMP TO TUCK JUMP.MOV"
        Output = "kneeling-tuck-jump.mp4"
        Start = "00:00:00.30"
        Duration = "00:00:08.00"
    },
    @{
        Source = "C:\vidio combination\Broad Jump x Alternating Foot Taps.mp4"
        Output = "broad-jump-alternated-foot-taps.mp4"
    },
    @{
        Source = "C:\video program\FOOT FIRES.MOV"
        Output = "foot-fires.mp4"
        Start = "00:00:00.40"
        Duration = "00:00:09.00"
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

Write-Host "Processed Day 8 Beginner videos into $backendPublicDir"
