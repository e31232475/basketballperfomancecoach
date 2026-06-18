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

$baseUrl = 'http://127.0.0.1:8000/videos/beginner/day1';

$videoUrls = [
    'Sprint 15 Meter' => $baseUrl.'/sprint-15-meter.mp4',
    'Lateral Hurdle Jump' => $baseUrl.'/lateral-hurdle-jump.mp4',
    'Single Leg Butt Kicks' => $baseUrl.'/single-leg-butt-kicks.mp4',
    'Tuck Jump' => $baseUrl.'/tuck-jump.mp4',
    'Squat Jump' => $baseUrl.'/squat-jump.mp4',
];

$statement = $pdo->prepare(
    'UPDATE exercises SET video = ?, video_url = ? WHERE name = ?'
);

foreach ($videoUrls as $exerciseName => $videoUrl) {
    $statement->execute([$videoUrl, $videoUrl, $exerciseName]);
}

echo 'Updated Day 1 Beginner video URLs: '.count($videoUrls).PHP_EOL;
