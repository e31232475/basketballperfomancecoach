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

$baseUrl = 'http://127.0.0.1:8000/videos/beginner';

$urlsByName = [
    'Sprint 15 Meter' => 'sprint-15-meter.mp4',
    'Kneeling Jump' => 'kneeling-jump.mp4',
    'Broad Jump' => 'broad-jump.mp4',
    'Lateral Bounds' => 'lateral-bound-jump.mp4',
    'Foot Fire' => 'foot-fires.mp4',
];

$selectStatement = $pdo->prepare(
    "SELECT we.id AS workout_exercise_id, w.day_number, e.name
     FROM workouts w
     JOIN workout_exercises we ON we.workout_id = w.id
     JOIN exercises e ON e.id = we.exercise_id
     WHERE LOWER(w.level) = 'beginner'
       AND w.day_number IN (3, 4)
     ORDER BY w.day_number, we.id"
);

$updateStatement = $pdo->prepare(
    'UPDATE workout_exercises SET video_url = ? WHERE id = ?'
);

$selectStatement->execute();

$updated = 0;

foreach ($selectStatement as $row) {
    if (!isset($urlsByName[$row['name']])) {
        continue;
    }

    $videoUrl = $baseUrl.'/day'.$row['day_number'].'/'.$urlsByName[$row['name']];
    $updateStatement->execute([$videoUrl, $row['workout_exercise_id']]);
    $updated++;
}

echo 'Updated Day 3/4 Beginner workout_exercises video URLs: '.$updated.PHP_EOL;
