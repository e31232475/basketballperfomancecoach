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

$baseUrl = 'http://127.0.0.1:8000/videos/beginner/day14';

$filenamesByName = [
    '15 Meter Sprint' => '15-meter-sprint.mp4',
    'Kneeling Broad Jump into Tuck Jump' => 'kneeling-broad-jump-tuck-jump.mp4',
    'Split Jump and Vertical Jump' => 'split-jump-vertical-jump.mp4',
    'Lateral Hurdle into Single Leg Broad Jump' => 'lateral-hurdle-single-leg-broad-jump.mp4',
    '180 Degree Jump and Alternating Foot Taps' => '180-degree-jump-alternating-foot-taps.mp4',
];

$selectStatement = $pdo->prepare(
    "SELECT we.id AS workout_exercise_id, e.name
     FROM workouts w
     JOIN workout_exercises we ON we.workout_id = w.id
     JOIN exercises e ON e.id = we.exercise_id
     WHERE LOWER(w.level) = 'beginner'
       AND w.day_number = 14
     ORDER BY we.id"
);

$updateStatement = $pdo->prepare(
    'UPDATE workout_exercises SET video_url = ? WHERE id = ?'
);

$selectStatement->execute();

$updated = 0;

foreach ($selectStatement as $row) {
    if (!isset($filenamesByName[$row['name']])) {
        continue;
    }

    $videoUrl = $baseUrl.'/'.$filenamesByName[$row['name']];
    $updateStatement->execute([$videoUrl, $row['workout_exercise_id']]);
    $updated++;
}

echo 'Updated Day 14 Beginner workout_exercises video URLs: '.$updated.PHP_EOL;
