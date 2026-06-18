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

$baseUrl = 'http://127.0.0.1:8000/videos/beginner/day5';

// Day 5 Beginner order:
// 1. Lateral Hurdle Jump
// 2. Kneeling Tuck Jump
// 3. Broad Jump
// 4. 180 Degree Jump
// 5. Split Jump
$videoUrlsByWorkoutExerciseId = [
    504 => $baseUrl.'/lateral-hurdle-jump.mp4',
    505 => $baseUrl.'/kneeling-tuck-jump.mp4',
    506 => $baseUrl.'/broad-jump.mp4',
    507 => $baseUrl.'/180-degree-jump.mp4',
    508 => $baseUrl.'/split-jump.mp4',
];

$statement = $pdo->prepare(
    'UPDATE workout_exercises SET video_url = ? WHERE id = ?'
);

foreach ($videoUrlsByWorkoutExerciseId as $workoutExerciseId => $videoUrl) {
    $statement->execute([$videoUrl, $workoutExerciseId]);
}

echo 'Updated Day 5 Beginner workout_exercises video URLs: '.count($videoUrlsByWorkoutExerciseId).PHP_EOL;
