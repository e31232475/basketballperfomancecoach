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

$tutorialVideo = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4';
$restSeconds = 30;

$plans = [
    1 => [
        ['Sprint 15 Meter', '15 meter', 4],
        ['Lateral Hurdle Jump', '10', 3],
        ['Single Leg Butt Kicks', '6', 3],
        ['Tuck Jump', '8', 3],
        ['Squat Jump', '8', 3],
    ],
    2 => [
        ['Foot Fires', '20 sec', 4, 20],
        ['Split Jump', '12', 4],
        ['Tuck Jump', '8', 3],
        ['Broad Jump', '6', 3],
        ['Alternating Foot Taps', '20', 3],
    ],
    3 => [
        ['Sprint 15 Meter', '15 meter', 4],
        ['Kneeling Jump', '6', 3],
        ['Broad Jump', '6', 3],
        ['Lateral Bounds', '6', 3],
        ['Foot Fire', '20 sec', 4, 20],
    ],
    4 => [
        ['Sprint 15 Meter', '15 meter', 4],
        ['Kneeling Jump', '6', 3],
        ['Broad Jump', '6', 3],
        ['Lateral Bounds', '6', 3],
        ['Foot Fire', '20 sec', 4, 20],
    ],
    5 => [
        ['Lateral Hurdle Jump', '10', 4],
        ['Kneeling Tuck Jump', '6', 3],
        ['Broad Jump', '6', 3],
        ['180 Degree Jump', '8', 3],
        ['Split Jump', '12', 3],
    ],
    6 => [
        ['Superset: 20 High Knee and 10 Lateral Hurdle', '20 high knee + 10 lateral hurdle', 4],
        ['Superset: 6 Kneeling Jumps and 6 Single Leg Butt Kicks', '6 kneeling jumps + 6 single leg butt kicks', 4],
        ['Broad Jump to Vertical Jump', '6', 4],
        ['Superset: 12 Split Jump and 20 Alternating Footsteps', '12 split jump + 20 alternating footsteps', 4],
    ],
    7 => [
        ['Superset: 20 High Knee and 10 Lateral Hurdle', '20 high knee + 10 lateral hurdle', 4],
        ['Superset: 6 Kneeling Jumps and 6 Single Leg Butt Kicks', '6 kneeling jumps + 6 single leg butt kicks', 4],
        ['Broad Jump to Vertical Jump', '6', 4],
        ['Superset: 12 Split Jump and 20 Alternating Footsteps', '12 split jump + 20 alternating footsteps', 4],
    ],
    8 => [
        ['Sprint 15 Meter', '15 meter', 4],
        ['Superset: 180 Degree Jump and Lateral Bounds', '8 jumps + 12 lateral bounds (6 each side)', 4],
        ['Kneeling Tuck Jump', '6', 4],
        ['Broad Jump and Alternated Foot Taps', '6 broad jumps + 20 alternated foot taps', 4],
        ['Foot Fire', '20 sec', 4, 20],
    ],
    9 => [
        ['Alternating Foot Taps and Squat Jumps', '20 foot taps + 10 squat jumps', 4],
        ['Lateral Bound to Broad Jump', '6', 4],
        ['Hurdle to Tuck Jump', '6', 4],
        ['Single Leg Butt Kick', '6', 4],
        ['Lateral Hurdles and Foot Fire', '10 lateral hurdles + 20 sec foot fire', 4],
    ],
    10 => [
        ['Alternating Foot Taps and Squat Jumps', '20 foot taps + 10 squat jumps', 4],
        ['Lateral Bound to Broad Jump', '6', 4],
        ['Hurdle to Tuck Jump', '6', 4],
        ['Single Leg Butt Kick', '6', 4],
        ['Lateral Hurdles and Foot Fire', '10 lateral hurdles + 20 sec foot fire', 4],
    ],
    11 => [
        ['Sprint 15 Meter', '15 meter', 4],
        ['Split Jump', '12', 4],
        ['Lateral Bound to Tuck Jump to Broad Jump', '6', 4],
        ['Kneeling Tuck Jump', '6', 4],
        ['Superset: Lateral Hurdles and Foot Fires', '10 lateral hurdles + 20 sec foot fires', 4],
    ],
    12 => [
        ['Alternating Foot Taps and Squat Jump', '20 foot taps + 10 squat jump', 4],
        ['Broad Jump to Tuck Jump', '6', 4],
        ['Kneeling Tuck Jump to Broad Jump', '6', 4],
        ['Lateral Bound', '6', 4],
        ['Kneeling Jump to Foot Fires', '6 kneeling jump + 20 foot fires', 4],
    ],
    13 => [
        ['Alternating Foot Taps and Squat Jump', '20 foot taps + 10 squat jump', 4],
        ['Broad Jump to Tuck Jump', '6', 4],
        ['Kneeling Tuck Jump to Broad Jump', '6', 4],
        ['Lateral Bound', '6', 4],
        ['Kneeling Jump to Foot Fires', '6 kneeling jump + 20 foot fires', 4],
    ],
    14 => [
        ['15 Meter Sprint', '15 meter', 4],
        ['Kneeling Broad Jump into Tuck Jump', '6', 4],
        ['Split Jump and Vertical Jump', '12 split jump + 6 vertical jump', 4],
        ['Lateral Hurdle into Single Leg Broad Jump', '6', 4],
        ['180 Degree Jump and Alternating Foot Taps', '8 jumps + 20 alternating foot taps', 4],
    ],
];

$hasWorkoutExerciseVideoUrl = (bool) $pdo
    ->query("SHOW COLUMNS FROM workout_exercises LIKE 'video_url'")
    ->fetch();
$videoUrlsByDayAndName = [];

if ($hasWorkoutExerciseVideoUrl) {
    $videoUrlRows = $pdo->query(
        "SELECT w.day_number, e.name, we.video_url
         FROM workouts w
         JOIN workout_exercises we ON we.workout_id = w.id
         JOIN exercises e ON e.id = we.exercise_id
         WHERE LOWER(w.level) = 'beginner'
           AND we.video_url IS NOT NULL
           AND we.video_url <> ''"
    );

    foreach ($videoUrlRows as $row) {
        $videoUrlsByDayAndName[(int) $row['day_number']][$row['name']] =
            $row['video_url'];
    }
}

$pdo->beginTransaction();

try {
    $selectWorkout = $pdo->prepare('SELECT id FROM workouts WHERE day_number = ? LIMIT 1');
    $insertWorkout = $pdo->prepare(
        'INSERT INTO workouts (day_number, title, level) VALUES (?, ?, ?)'
    );
    $updateWorkout = $pdo->prepare(
        'UPDATE workouts SET title = ?, level = ? WHERE id = ?'
    );
    $selectExercise = $pdo->prepare('SELECT id FROM exercises WHERE name = ? LIMIT 1');
    $insertExercise = $pdo->prepare(
        'INSERT INTO exercises (name, type, video, video_url) VALUES (?, ?, ?, ?)'
    );
    $updateExercise = $pdo->prepare(
        'UPDATE exercises SET name = ?, type = ?, video = COALESCE(video, ?), video_url = COALESCE(video_url, ?) WHERE id = ?'
    );
    $deletePlan = $pdo->prepare('DELETE FROM workout_exercises WHERE workout_id = ?');
    $insertPlan = $pdo->prepare(
        $hasWorkoutExerciseVideoUrl
            ? 'INSERT INTO workout_exercises (workout_id, exercise_id, sets, reps, duration, rest_seconds, video_url) VALUES (?, ?, ?, ?, ?, ?, ?)'
            : 'INSERT INTO workout_exercises (workout_id, exercise_id, sets, reps, duration, rest_seconds) VALUES (?, ?, ?, ?, ?, ?)'
    );

    foreach ($plans as $day => $items) {
        $selectWorkout->execute([$day]);
        $workoutId = $selectWorkout->fetchColumn();
        $title = 'Day '.$day;

        if (! $workoutId) {
            $insertWorkout->execute([$day, $title, 'Beginner']);
            $workoutId = (int) $pdo->lastInsertId();
        } else {
            $updateWorkout->execute([$title, 'Beginner', $workoutId]);
        }

        $deletePlan->execute([$workoutId]);

        foreach ($items as $item) {
            [$name, $reps, $sets] = $item;
            $duration = $item[3] ?? null;
            $type = $duration === null ? 'training' : 'time';

            $selectExercise->execute([$name]);
            $exerciseId = $selectExercise->fetchColumn();

            if (! $exerciseId) {
                $insertExercise->execute([$name, $type, $tutorialVideo, $tutorialVideo]);
                $exerciseId = (int) $pdo->lastInsertId();
            } else {
                $updateExercise->execute([$name, $type, $tutorialVideo, $tutorialVideo, $exerciseId]);
            }

            $planValues = [
                $workoutId,
                $exerciseId,
                $sets,
                $reps,
                $duration,
                $restSeconds,
            ];

            if ($hasWorkoutExerciseVideoUrl) {
                $planValues[] = $videoUrlsByDayAndName[$day][$name] ?? null;
            }

            $insertPlan->execute($planValues);
        }
    }

    $pdo->commit();
    echo 'Synced Beginner workouts: '.count($plans).' days'.PHP_EOL;
} catch (Throwable $error) {
    $pdo->rollBack();
    throw $error;
}
