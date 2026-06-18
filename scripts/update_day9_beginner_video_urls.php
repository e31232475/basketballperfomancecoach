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

$baseUrl = 'http://127.0.0.1:8000/videos/beginner/day9';

$filenamesByName = [
    'Alternating Foot Taps and Squat Jumps' => 'alternating-foot-taps-squat-jumps.mp4',
    'Lateral Bound to Broad Jump' => 'lateral-bound-broad-jump.mp4',
    'Hurdle to Tuck Jump' => 'lateral-hurdle-tuck-jump.mp4',
    'Single Leg Butt Kick' => 'single-leg-butt-kick.mp4',
    'Lateral Hurdles and Foot Fire' => 'lateral-hurdle-foot-fires.mp4',
];

$selectStatement = $pdo->prepare(
    "SELECT we.id AS workout_exercise_id, e.name
     FROM workouts w
     JOIN workout_exercises we ON we.workout_id = w.id
     JOIN exercises e ON e.id = we.exercise_id
     WHERE LOWER(w.level) = 'beginner'
       AND w.day_number = 9
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

echo 'Updated Day 9 Beginner workout_exercises video URLs: '.$updated.PHP_EOL;
