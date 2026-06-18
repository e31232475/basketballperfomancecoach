$ErrorActionPreference = "Stop"

$ffmpeg = "C:\Users\DIMAS RAMDHAN\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$backendPublicDir = "C:\laragon\www\basketballperfomancecoach\public\videos\beginner\day1"

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
        Source = "C:\video program\LATERAL HURDLE JUMP.MOV"
        Output = "lateral-hurdle-jump.mp4"
        Start = "00:00:00.00"
        Duration = "00:00:06.70"
    },
    @{
        Source = "C:\video program\SINGLE LEG BUTT KICK.MOV"
        Output = "single-leg-butt-kicks.mp4"
        Start = "00:00:00.00"
        Duration = "00:00:09.20"
    },
    @{
        Source = "C:\video program\TUCK JUMP.MOV"
        Output = "tuck-jump.mp4"
        Start = "00:00:00.00"
        Duration = "00:00:06.20"
    },
    @{
        Source = "C:\video program\SQUAT JUMP.MOV"
        Output = "squat-jump.mp4"
        Start = "00:00:00.00"
        Duration = "00:00:06.70"
    }
)

foreach ($video in $videos) {
    $outputPath = Join-Path $backendPublicDir $video.Output

    & $ffmpeg `
        -y `
        -ss $video.Start `
        -t $video.Duration `
        -i $video.Source `
        -an `
        -vf "scale=1280:-2,format=yuv420p" `
        -c:v libx264 `
        -preset medium `
        -crf 23 `
        -movflags +faststart `
        $outputPath
}

Write-Host "Processed Day 1 Beginner videos into $backendPublicDir"
