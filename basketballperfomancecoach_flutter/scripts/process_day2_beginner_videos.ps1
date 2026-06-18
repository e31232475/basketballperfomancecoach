$ErrorActionPreference = "Stop"

$ffmpeg = "C:\Users\DIMAS RAMDHAN\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$backendPublicDir = "C:\laragon\www\basketballperfomancecoach\public\videos\beginner\day2"

if (!(Test-Path -LiteralPath $ffmpeg)) {
    $ffmpeg = "ffmpeg"
}

New-Item -ItemType Directory -Force -Path $backendPublicDir | Out-Null

$videos = @(
    @{
        Source = "C:\video program\FOOT FIRES.MOV"
        Output = "foot-fires.mp4"
        Start = "00:00:00.40"
        Duration = "00:00:09.00"
    },
    @{
        Source = "C:\video program\SPLIT JUMP.MOV"
        Output = "split-jump.mp4"
        Start = "00:00:00.50"
        Duration = "00:00:14.00"
    },
    @{
        Source = "C:\video program\TUCK JUMP.MOV"
        Output = "tuck-jump.mp4"
        Start = "00:00:00.00"
        Duration = "00:00:06.20"
    },
    @{
        Source = "C:\video program\BROAD JUMP.MOV"
        Output = "broad-jump.mp4"
        Start = "00:00:00.50"
        Duration = "00:00:15.00"
    },
    @{
        Source = "C:\video program\ALTERNATING FOOT TAPS.MOV"
        Output = "alternating-foot-taps.mp4"
        Start = "00:00:00.30"
        Duration = "00:00:08.50"
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

Write-Host "Processed Day 2 Beginner videos into $backendPublicDir"
