$ErrorActionPreference = "Stop"

$ffmpeg = "C:\Users\DIMAS RAMDHAN\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$backendPublicDir = "C:\laragon\www\basketballperfomancecoach\public\videos\beginner\day5"

if (!(Test-Path -LiteralPath $ffmpeg)) {
    $ffmpeg = "ffmpeg"
}

New-Item -ItemType Directory -Force -Path $backendPublicDir | Out-Null

$videos = @(
    @{
        Source = "C:\video program\LATERAL HURDLE JUMP.MOV"
        Output = "lateral-hurdle-jump.mp4"
        Start = "00:00:00.00"
        Duration = "00:00:06.70"
    },
    @{
        Source = "C:\video program\KNEELING JUMP TO TUCK JUMP.MOV"
        Output = "kneeling-tuck-jump.mp4"
        Start = "00:00:00.30"
        Duration = "00:00:08.00"
    },
    @{
        Source = "C:\video program\BROAD JUMP.MOV"
        Output = "broad-jump.mp4"
        Start = "00:00:00.50"
        Duration = "00:00:15.00"
    },
    @{
        Source = "C:\video program\180 DEGREE JUMP.MOV"
        Output = "180-degree-jump.mp4"
        Start = "00:00:00.60"
        Duration = "00:00:13.00"
    },
    @{
        Source = "C:\video program\SPLIT JUMP.MOV"
        Output = "split-jump.mp4"
        Start = "00:00:00.50"
        Duration = "00:00:14.00"
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
        -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,format=yuv420p" `
        -c:v libx264 `
        -preset medium `
        -crf 23 `
        -movflags +faststart `
        $outputPath
}

Write-Host "Processed Day 5 Beginner videos into $backendPublicDir"
