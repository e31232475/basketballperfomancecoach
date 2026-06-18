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

$filenamesByName = [
    'Alternating Foot Taps and Squat Jump' => 'alternating-foot-taps-squat-jump.mp4',
    'Broad Jump to Tuck Jump' => 'broad-jump-tuck-jump.mp4',
    'Kneeling Tuck Jump to Broad Jump' => 'kneeling-tuck-jump-broad-jump.mp4',
    'Lateral Bound' => 'lateral-bound-jump.mp4',
    'Kneeling Jump to Foot Fires' => 'kneeling-jump-foot-fires.mp4',
];

$selectStatement = $pdo->prepare(
    "SELECT w.day_number, we.id AS workout_exercise_id, e.name
     FROM workouts w
     JOIN workout_exercises we ON we.workout_id = w.id
     JOIN exercises e ON e.id = we.exercise_id
     WHERE LOWER(w.level) = 'beginner'
       AND w.day_number IN (12, 13)
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

    $baseUrl = 'http://127.0.0.1:8000/videos/beginner/day'.$row['day_number'];
    $videoUrl = $baseUrl.'/'.$filenamesByName[$row['name']];
    $updateStatement->execute([$videoUrl, $row['workout_exercise_id']]);
    $updated++;
}

echo 'Updated Day 12 and Day 13 Beginner workout_exercises video URLs: '.$updated.PHP_EOL;
