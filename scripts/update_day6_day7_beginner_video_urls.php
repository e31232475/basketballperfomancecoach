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

$filenamesByName = [
    'Superset: 20 High Knee and 10 Lateral Hurdle' => 'high-knee-lateral-hurdle.mp4',
    'Superset: 6 Kneeling Jumps and 6 Single Leg Butt Kicks' => 'kneeling-jump-single-leg-butt-kick.mp4',
    'Broad Jump to Vertical Jump' => 'broad-jump-to-vertical-jump.mp4',
    'Superset: 12 Split Jump and 20 Alternating Footsteps' => 'split-jump-alternating-footsteps.mp4',
];

$selectStatement = $pdo->prepare(
    "SELECT we.id AS workout_exercise_id, w.day_number, e.name
     FROM workouts w
     JOIN workout_exercises we ON we.workout_id = w.id
     JOIN exercises e ON e.id = we.exercise_id
     WHERE LOWER(w.level) = 'beginner'
       AND w.day_number IN (6, 7)
     ORDER BY w.day_number, we.id"
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

    $videoUrl = $baseUrl.'/day'.$row['day_number'].'/'.$filenamesByName[$row['name']];
    $updateStatement->execute([$videoUrl, $row['workout_exercise_id']]);
    $updated++;
}

echo 'Updated Day 6/7 Beginner workout_exercises video URLs: '.$updated.PHP_EOL;
