$ErrorActionPreference = "Stop"

$ffmpeg = "C:\Users\DIMAS RAMDHAN\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$backendPublicBaseDir = "C:\laragon\www\basketballperfomancecoach\public\videos\beginner"

if (!(Test-Path -LiteralPath $ffmpeg)) {
    $ffmpeg = "ffmpeg"
}

$videos = @(
    @{
        Source = "C:\video program\SPRINT.MOV"
        Output = "sprint-15-meter.mp4"
        Start = "00:00:02.40"
        Duration = "00:00:10.60"
    },
    @{
        Source = "C:\video program\KNEELING JUMP.MOV"
        Output = "kneeling-jump.mp4"
        Start = "00:00:00.30"
        Duration = "00:00:10.00"
    },
    @{
        Source = "C:\video program\BROAD JUMP.MOV"
        Output = "broad-jump.mp4"
        Start = "00:00:00.50"
        Duration = "00:00:15.00"
    },
    @{
        Source = "C:\video program\LATERAL BOUND JUMP.MOV"
        Output = "lateral-bound-jump.mp4"
        Start = "00:00:00.30"
        Duration = "00:00:07.00"
    },
    @{
        Source = "C:\video program\FOOT FIRES.MOV"
        Output = "foot-fires.mp4"
        Start = "00:00:00.40"
        Duration = "00:00:09.00"
    }
)

foreach ($day in @("day3", "day4")) {
    $backendPublicDir = Join-Path $backendPublicBaseDir $day
    New-Item -ItemType Directory -Force -Path $backendPublicDir | Out-Null

    foreach ($video in $videos) {
        $outputPath = Join-Path $backendPublicDir $video.Output

        & $ffmpeg `
            -y `
            -ss $video.Start `
            -t $video.Duration `
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

Write-Host "Processed Day 3 and Day 4 Beginner videos into $backendPublicBaseDir"
