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

$day1BaseUrl = 'http://127.0.0.1:8000/videos/beginner/day1';
$baseUrl = 'http://127.0.0.1:8000/videos/exercises';

$videoUrlsByName = [
    '15 Meter Sprint' => $day1BaseUrl.'/sprint-15-meter.mp4',
    'Sprint 15 Meter' => $day1BaseUrl.'/sprint-15-meter.mp4',
    'Sprint 15 meter / Sprint ditempat' => $day1BaseUrl.'/sprint-15-meter.mp4',
    'Sprint Start' => $day1BaseUrl.'/sprint-15-meter.mp4',

    'Lateral Hurdle Jump' => $day1BaseUrl.'/lateral-hurdle-jump.mp4',
    'Lateral Hurdles and Foot Fire' => $day1BaseUrl.'/lateral-hurdle-jump.mp4',
    'Superset: Lateral Hurdles and Foot Fires' => $day1BaseUrl.'/lateral-hurdle-jump.mp4',
    'Hurdle to Tuck Jump' => $day1BaseUrl.'/lateral-hurdle-jump.mp4',

    'Single Leg Butt Kick' => $day1BaseUrl.'/single-leg-butt-kicks.mp4',
    'Single Leg Butt Kicks' => $day1BaseUrl.'/single-leg-butt-kicks.mp4',
    'Superset: 6 Kneeling Jumps and 6 Single Leg Butt Kicks' => $baseUrl.'/kneeling-jump.mp4',

    'Tuck Jump' => $day1BaseUrl.'/tuck-jump.mp4',
    'Squat Jump' => $day1BaseUrl.'/squat-jump.mp4',

    '180 Degree Jump' => $baseUrl.'/180-degree-jump.mp4',
    '180 Degree Jump and Alternating Foot Taps' => $baseUrl.'/180-degree-jump.mp4',
    'Superset: 180 Degree Jump and Lateral Bounds' => $baseUrl.'/180-degree-jump.mp4',

    'Alternating Foot Taps' => $baseUrl.'/alternating-foot-taps.mp4',
    'Alternating Foot Taps and Squat Jump' => $baseUrl.'/alternating-foot-taps.mp4',
    'Alternating Foot Taps and Squat Jumps' => $baseUrl.'/alternating-foot-taps.mp4',
    'Broad Jump and Alternated Foot Taps' => $baseUrl.'/alternating-foot-taps.mp4',

    'Broad Jump' => $baseUrl.'/broad-jump.mp4',
    'Broad Jump to Tuck Jump' => $baseUrl.'/broad-jump.mp4',
    'Broad Jump to Vertical Jump' => $baseUrl.'/broad-jump.mp4',

    'Foot Fire' => $baseUrl.'/foot-fires.mp4',
    'Foot Fires' => $baseUrl.'/foot-fires.mp4',
    'Kneeling Jump to Foot Fires' => $baseUrl.'/foot-fires.mp4',

    'High Knees' => $baseUrl.'/high-knee.mp4',
    'Superset: 20 High Knee and 10 Lateral Hurdle' => $baseUrl.'/high-knee.mp4',

    'Kneeling Jump' => $baseUrl.'/kneeling-jump.mp4',
    'Kneeling Tuck Jump' => $baseUrl.'/kneeling-jump-to-tuck-jump.mp4',
    'Kneeling Broad Jump into Tuck Jump' => $baseUrl.'/kneeling-jump-to-tuck-jump.mp4',
    'Kneeling Broad Jump to Tuck Jump' => $baseUrl.'/kneeling-jump-to-tuck-jump.mp4',
    'Kneeling Tuck Jump to Broad Jump' => $baseUrl.'/kneeling-jump-to-tuck-jump.mp4',

    'Lateral Bound' => $baseUrl.'/lateral-bound-jump.mp4',
    'Lateral Bounds' => $baseUrl.'/lateral-bound-jump.mp4',
    'Lateral Bound to Broad Jump' => $baseUrl.'/lateral-bound-jump.mp4',
    'Lateral Bound to Tuck Jump to Broad Jump' => $baseUrl.'/lateral-bound-jump.mp4',

    'Lateral Hurdle into Single Leg Broad Jump' => $baseUrl.'/single-leg-broad-jump.mp4',
    'Lateral Hurdle to Single Leg Broad Jump' => $baseUrl.'/single-leg-broad-jump.mp4',

    'Split Jump' => $baseUrl.'/split-jump.mp4',
    'Split Jump and Vertical Jump' => $baseUrl.'/split-jump.mp4',
    'Superset: 12 Split Jump and 20 Alternating Footsteps' => $baseUrl.'/split-jump.mp4',

    'Vertical Jump' => $baseUrl.'/vertical-jump.mp4',
];

$statement = $pdo->prepare(
    'UPDATE exercises SET video = ?, video_url = ? WHERE name = ?'
);

$updatedNames = [];

foreach ($videoUrlsByName as $exerciseName => $videoUrl) {
    $statement->execute([$videoUrl, $videoUrl, $exerciseName]);

    if ($statement->rowCount() > 0) {
        $updatedNames[] = $exerciseName;
    }
}

echo 'Updated exercise video URLs: '.count($updatedNames).PHP_EOL;
foreach ($updatedNames as $name) {
    echo '- '.$name.PHP_EOL;
}
