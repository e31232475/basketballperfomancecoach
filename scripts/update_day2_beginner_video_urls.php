<?php

$pdo = new PDO(
    'mysql:host=127.0.0.1;dbname=basketballperfomancecoach;charset=utf8mb4',
    'root',
    '',
    [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]
);

$baseUrl = 'http://127.0.0.1:8000/videos/beginner/day2';

// Day 2 Beginner order:
// 1. Foot Fires
// 2. Split Jump
// 3. Tuck Jump
// 4. Broad Jump
// 5. Alternating Foot Taps
$videoUrlsByExerciseId = [
    6 => $baseUrl.'/foot-fires.mp4',
    7 => $baseUrl.'/split-jump.mp4',
    4 => $baseUrl.'/tuck-jump.mp4',
    8 => $baseUrl.'/broad-jump.mp4',
    9 => $baseUrl.'/alternating-foot-taps.mp4',
];

$statement = $pdo->prepare(
    'UPDATE exercises SET video = ?, video_url = ? WHERE id = ?'
);

foreach ($videoUrlsByExerciseId as $exerciseId => $videoUrl) {
    $statement->execute([$videoUrl, $videoUrl, $exerciseId]);
}

echo 'Updated Day 2 Beginner video URLs: '.count($videoUrlsByExerciseId).PHP_EOL;
