$ErrorActionPreference = "Stop"

$ffmpeg = "C:\Users\DIMAS RAMDHAN\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$backendPublicDir = "C:\laragon\www\basketballperfomancecoach\public\videos\exercises"

if (!(Test-Path -LiteralPath $ffmpeg)) {
    $ffmpeg = "ffmpeg"
}

New-Item -ItemType Directory -Force -Path $backendPublicDir | Out-Null

$videos = @(
    @{ Source = "C:\video program\180 DEGREE JUMP.MOV"; Output = "180-degree-jump.mp4"; Start = "00:00:00.60"; Duration = "00:00:13.00" },
    @{ Source = "C:\video program\ALTERNATING FOOT TAPS.MOV"; Output = "alternating-foot-taps.mp4"; Start = "00:00:00.30"; Duration = "00:00:08.50" },
    @{ Source = "C:\video program\BROAD JUMP.MOV"; Output = "broad-jump.mp4"; Start = "00:00:00.50"; Duration = "00:00:15.00" },
    @{ Source = "C:\video program\FOOT FIRES.MOV"; Output = "foot-fires.mp4"; Start = "00:00:00.40"; Duration = "00:00:09.00" },
    @{ Source = "C:\video program\HIGH KNEE.MOV"; Output = "high-knee.mp4"; Start = "00:00:00.20"; Duration = "00:00:05.00" },
    @{ Source = "C:\video program\KNEELING JUMP TO TUCK JUMP.MOV"; Output = "kneeling-jump-to-tuck-jump.mp4"; Start = "00:00:00.30"; Duration = "00:00:08.00" },
    @{ Source = "C:\video program\KNEELING JUMP.MOV"; Output = "kneeling-jump.mp4"; Start = "00:00:00.30"; Duration = "00:00:10.00" },
    @{ Source = "C:\video program\LATERAL BOUND JUMP.MOV"; Output = "lateral-bound-jump.mp4"; Start = "00:00:00.30"; Duration = "00:00:07.00" },
    @{ Source = "C:\video program\SINGLE LEG BROAD JUMP.MOV"; Output = "single-leg-broad-jump.mp4"; Start = "00:00:00.50"; Duration = "00:00:12.00" },
    @{ Source = "C:\video program\SPLIT JUMP.MOV"; Output = "split-jump.mp4"; Start = "00:00:00.50"; Duration = "00:00:14.00" },
    @{ Source = "C:\video program\VERTICAL JUMP.MOV"; Output = "vertical-jump.mp4"; Start = "00:00:00.20"; Duration = "00:00:06.50" }
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

Write-Host "Processed backend exercise videos into $backendPublicDir"
