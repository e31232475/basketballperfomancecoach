<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        DB::table('users')->updateOrInsert(
            ['email' => 'test@example.com'],
            $this->onlyExistingColumns('users', $this->withTimestamps('users', [
                'name' => 'Test User',
                'password' => Hash::make('password'),
                'height' => 185,
                'weight' => 82,
                'age' => 21,
                'training_level' => 'Beginner',
            ]))
        );

        $workouts = [
            ['day_number' => 1, 'title' => 'Day 1', 'level' => 'Beginner'],
            ['day_number' => 2, 'title' => 'Day 2', 'level' => 'Beginner'],
            ['day_number' => 3, 'title' => 'Day 3', 'level' => 'Beginner'],
            ['day_number' => 4, 'title' => 'Day 4', 'level' => 'Beginner'],
            ['day_number' => 5, 'title' => 'Day 5', 'level' => 'Beginner'],
            ['day_number' => 6, 'title' => 'Day 6', 'level' => 'Beginner'],
            ['day_number' => 7, 'title' => 'Day 7', 'level' => 'Beginner'],
            ['day_number' => 8, 'title' => 'Day 8', 'level' => 'Beginner'],
            ['day_number' => 9, 'title' => 'Day 9', 'level' => 'Beginner'],
            ['day_number' => 10, 'title' => 'Day 10', 'level' => 'Beginner'],
            ['day_number' => 11, 'title' => 'Day 11', 'level' => 'Beginner'],
            ['day_number' => 12, 'title' => 'Day 12', 'level' => 'Beginner'],
            ['day_number' => 13, 'title' => 'Day 13', 'level' => 'Beginner'],
            ['day_number' => 14, 'title' => 'Day 14', 'level' => 'Beginner'],
            ['day_number' => 15, 'title' => 'Intermediate Lower Power', 'level' => 'Intermediate'],
            ['day_number' => 16, 'title' => 'Intermediate Core Control', 'level' => 'Intermediate'],
            ['day_number' => 17, 'title' => 'Intermediate Upper Strength', 'level' => 'Intermediate'],
            ['day_number' => 18, 'title' => 'Intermediate Plyometric Power', 'level' => 'Intermediate'],
            ['day_number' => 19, 'title' => 'Intermediate Agility Flow', 'level' => 'Intermediate'],
            ['day_number' => 20, 'title' => 'Intermediate Explosive Strength', 'level' => 'Intermediate'],
            ['day_number' => 21, 'title' => 'Intermediate Recovery Mobility', 'level' => 'Intermediate'],
            ['day_number' => 22, 'title' => 'Intermediate Jump Mechanics', 'level' => 'Intermediate'],
            ['day_number' => 23, 'title' => 'Intermediate Landing Control', 'level' => 'Intermediate'],
            ['day_number' => 24, 'title' => 'Intermediate Single Leg Strength', 'level' => 'Intermediate'],
            ['day_number' => 25, 'title' => 'Intermediate Reactive Plyometrics', 'level' => 'Intermediate'],
            ['day_number' => 26, 'title' => 'Intermediate Court Conditioning', 'level' => 'Intermediate'],
            ['day_number' => 27, 'title' => 'Intermediate Vertical Jump Builder', 'level' => 'Intermediate'],
            ['day_number' => 28, 'title' => 'Intermediate Performance Test', 'level' => 'Intermediate'],
        ];

        foreach ($workouts as $workout) {
            DB::table('workouts')->updateOrInsert(
                ['day_number' => $workout['day_number']],
                $this->withTimestamps('workouts', [
                    'title' => $workout['title'],
                    'level' => $workout['level'],
                ])
            );
        }

        $tutorialVideo = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4';
        $exercises = [
            ['name' => 'Bodyweight Squat', 'type' => 'strength'],
            ['name' => 'Reverse Lunge', 'type' => 'strength'],
            ['name' => 'Calf Raise', 'type' => 'strength'],
            ['name' => 'Plank Hold', 'type' => 'core'],
            ['name' => 'Dead Bug', 'type' => 'core'],
            ['name' => 'Push Up', 'type' => 'strength'],
            ['name' => 'Band Row', 'type' => 'strength'],
            ['name' => 'Pogo Jump', 'type' => 'plyometric'],
            ['name' => 'Squat Jump', 'type' => 'plyometric'],
            ['name' => 'Defensive Slide', 'type' => 'agility'],
            ['name' => 'Sprint Start', 'type' => 'speed'],
            ['name' => 'Hip Mobility Flow', 'type' => 'mobility'],
            ['name' => 'Glute Bridge', 'type' => 'strength'],
            ['name' => 'Snap Down Landing', 'type' => 'plyometric'],
            ['name' => 'Lateral Bound', 'type' => 'plyometric'],
            ['name' => 'Wall Sit', 'type' => 'strength'],
            ['name' => 'Mountain Climber', 'type' => 'conditioning'],
        ];

        foreach ($exercises as $exercise) {
            $exercise['video'] = $tutorialVideo;
            $exercise['video_url'] = $tutorialVideo;

            DB::table('exercises')->updateOrInsert(
                ['name' => $exercise['name']],
                $this->onlyExistingColumns(
                    'exercises',
                    $this->withTimestamps('exercises', $exercise)
                )
            );
        }

        $plans = [
            1 => [
                ['Sprint 15 Meter', 4, '15 meter', null, 30],
                ['Lateral Hurdle Jump', 3, '10', null, 30],
                ['Single Leg Butt Kicks', 3, '6', null, 30],
                ['Tuck Jump', 3, '8', null, 30],
                ['Squat Jump', 3, '8', null, 30],
            ],
            2 => [
                ['Foot Fires', 4, '20 sec', 20, 30],
                ['Split Jump', 4, '12', null, 30],
                ['Tuck Jump', 3, '8', null, 30],
                ['Broad Jump', 3, '6', null, 30],
                ['Alternating Foot Taps', 3, '20', null, 30],
            ],
            3 => [
                ['Sprint 15 Meter', 4, '15 meter', null, 30],
                ['Kneeling Jump', 3, '6', null, 30],
                ['Broad Jump', 3, '6', null, 30],
                ['Lateral Bounds', 3, '6', null, 30],
                ['Foot Fire', 4, '20 sec', 20, 30],
            ],
            4 => [
                ['Sprint 15 Meter', 4, '15 meter', null, 30],
                ['Kneeling Jump', 3, '6', null, 30],
                ['Broad Jump', 3, '6', null, 30],
                ['Lateral Bounds', 3, '6', null, 30],
                ['Foot Fire', 4, '20 sec', 20, 30],
            ],
            5 => [
                ['Lateral Hurdle Jump', 4, '10', null, 30],
                ['Kneeling Tuck Jump', 3, '6', null, 30],
                ['Broad Jump', 3, '6', null, 30],
                ['180 Degree Jump', 3, '8', null, 30],
                ['Split Jump', 3, '12', null, 30],
            ],
            6 => [
                ['Superset: 20 High Knee and 10 Lateral Hurdle', 4, '20 high knee + 10 lateral hurdle', null, 30],
                ['Superset: 6 Kneeling Jumps and 6 Single Leg Butt Kicks', 4, '6 kneeling jumps + 6 single leg butt kicks', null, 30],
                ['Broad Jump to Vertical Jump', 4, '6', null, 30],
                ['Superset: 12 Split Jump and 20 Alternating Footsteps', 4, '12 split jump + 20 alternating footsteps', null, 30],
            ],
            7 => [
                ['Superset: 20 High Knee and 10 Lateral Hurdle', 4, '20 high knee + 10 lateral hurdle', null, 30],
                ['Superset: 6 Kneeling Jumps and 6 Single Leg Butt Kicks', 4, '6 kneeling jumps + 6 single leg butt kicks', null, 30],
                ['Broad Jump to Vertical Jump', 4, '6', null, 30],
                ['Superset: 12 Split Jump and 20 Alternating Footsteps', 4, '12 split jump + 20 alternating footsteps', null, 30],
            ],
            8 => [
                ['Sprint 15 Meter', 4, '15 meter', null, 30],
                ['Superset: 180 Degree Jump and Lateral Bounds', 4, '8 jumps + 12 lateral bounds (6 each side)', null, 30],
                ['Kneeling Tuck Jump', 4, '6', null, 30],
                ['Broad Jump and Alternated Foot Taps', 4, '6 broad jumps + 20 alternated foot taps', null, 30],
                ['Foot Fire', 4, '20 sec', 20, 30],
            ],
            9 => [
                ['Alternating Foot Taps and Squat Jumps', 4, '20 foot taps + 10 squat jumps', null, 30],
                ['Lateral Bound to Broad Jump', 4, '6', null, 30],
                ['Hurdle to Tuck Jump', 4, '6', null, 30],
                ['Single Leg Butt Kick', 4, '6', null, 30],
                ['Lateral Hurdles and Foot Fire', 4, '10 lateral hurdles + 20 sec foot fire', null, 30],
            ],
            10 => [
                ['Alternating Foot Taps and Squat Jumps', 4, '20 foot taps + 10 squat jumps', null, 30],
                ['Lateral Bound to Broad Jump', 4, '6', null, 30],
                ['Hurdle to Tuck Jump', 4, '6', null, 30],
                ['Single Leg Butt Kick', 4, '6', null, 30],
                ['Lateral Hurdles and Foot Fire', 4, '10 lateral hurdles + 20 sec foot fire', null, 30],
            ],
            11 => [
                ['Sprint 15 Meter', 4, '15 meter', null, 30],
                ['Split Jump', 4, '12', null, 30],
                ['Lateral Bound to Tuck Jump to Broad Jump', 4, '6', null, 30],
                ['Kneeling Tuck Jump', 4, '6', null, 30],
                ['Superset: Lateral Hurdles and Foot Fires', 4, '10 lateral hurdles + 20 sec foot fires', null, 30],
            ],
            12 => [
                ['Alternating Foot Taps and Squat Jump', 4, '20 foot taps + 10 squat jump', null, 30],
                ['Broad Jump to Tuck Jump', 4, '6', null, 30],
                ['Kneeling Tuck Jump to Broad Jump', 4, '6', null, 30],
                ['Lateral Bound', 4, '6', null, 30],
                ['Kneeling Jump to Foot Fires', 4, '6 kneeling jump + 20 foot fires', null, 30],
            ],
            13 => [
                ['Alternating Foot Taps and Squat Jump', 4, '20 foot taps + 10 squat jump', null, 30],
                ['Broad Jump to Tuck Jump', 4, '6', null, 30],
                ['Kneeling Tuck Jump to Broad Jump', 4, '6', null, 30],
                ['Lateral Bound', 4, '6', null, 30],
                ['Kneeling Jump to Foot Fires', 4, '6 kneeling jump + 20 foot fires', null, 30],
            ],
            14 => [
                ['15 Meter Sprint', 4, '15 meter', null, 30],
                ['Kneeling Broad Jump into Tuck Jump', 4, '6', null, 30],
                ['Split Jump and Vertical Jump', 4, '12 split jump + 6 vertical jump', null, 30],
                ['Lateral Hurdle into Single Leg Broad Jump', 4, '6', null, 30],
                ['180 Degree Jump and Alternating Foot Taps', 4, '8 jumps + 20 alternating foot taps', null, 30],
            ],
            15 => [
                ['Bodyweight Squat', 4, '15', null, 60],
                ['Reverse Lunge', 4, '12/side', null, 60],
                ['Calf Raise', 4, '20', null, 45],
            ],
            16 => [
                ['Plank Hold', 4, '45 sec', 45, 45],
                ['Dead Bug', 4, '12/side', null, 45],
                ['Hip Mobility Flow', 3, '60 sec', 60, 30],
            ],
            17 => [
                ['Push Up', 4, '14', null, 60],
                ['Band Row', 4, '15', null, 60],
                ['Plank Hold', 4, '45 sec', 45, 45],
            ],
            18 => [
                ['Pogo Jump', 5, '25', null, 45],
                ['Squat Jump', 5, '10', null, 75],
                ['Calf Raise', 4, '22', null, 45],
            ],
            19 => [
                ['Defensive Slide', 5, '25 sec', 25, 45],
                ['Sprint Start', 6, '15 m', null, 60],
                ['Dead Bug', 4, '14/side', null, 45],
            ],
            20 => [
                ['Squat Jump', 6, '8', null, 90],
                ['Push Up', 5, '14', null, 60],
                ['Sprint Start', 6, '20 m', null, 75],
            ],
            21 => [
                ['Hip Mobility Flow', 4, '60 sec', 60, 30],
                ['Plank Hold', 3, '45 sec', 45, 45],
                ['Calf Raise', 3, '20', null, 30],
            ],
            22 => [
                ['Snap Down Landing', 5, '8', null, 60],
                ['Bodyweight Squat', 4, '16', null, 60],
                ['Pogo Jump', 4, '25', null, 45],
            ],
            23 => [
                ['Snap Down Landing', 5, '10', null, 60],
                ['Reverse Lunge', 4, '12/side', null, 60],
                ['Dead Bug', 4, '14/side', null, 45],
            ],
            24 => [
                ['Glute Bridge', 5, '15', null, 60],
                ['Reverse Lunge', 5, '12/side', null, 60],
                ['Wall Sit', 4, '45 sec', 45, 60],
            ],
            25 => [
                ['Lateral Bound', 5, '10/side', null, 75],
                ['Squat Jump', 5, '10', null, 75],
                ['Pogo Jump', 5, '30', null, 45],
            ],
            26 => [
                ['Mountain Climber', 5, '40 sec', 40, 45],
                ['Defensive Slide', 5, '30 sec', 30, 45],
                ['Sprint Start', 6, '20 m', null, 60],
            ],
            27 => [
                ['Squat Jump', 6, '10', null, 90],
                ['Calf Raise', 5, '24', null, 45],
                ['Glute Bridge', 5, '16', null, 60],
            ],
            28 => [
                ['Pogo Jump', 5, '35', null, 45],
                ['Squat Jump', 6, '8', null, 90],
                ['Sprint Start', 7, '20 m', null, 75],
                ['Hip Mobility Flow', 3, '60 sec', 60, 30],
            ],
        ];

        foreach ($plans as $dayNumber => $items) {
            $workoutId = DB::table('workouts')
                ->where('day_number', $dayNumber)
                ->value('id');

            if ($workoutId) {
                DB::table('workout_exercises')->where('workout_id', $workoutId)->delete();
            }

            foreach ($items as [$exerciseName, $sets, $reps, $duration, $restSeconds]) {
                if (! $workoutId) {
                    continue;
                }

                $exerciseId = DB::table('exercises')
                    ->where('name', $exerciseName)
                    ->value('id');

                if (! $exerciseId) {
                    DB::table('exercises')->insert(
                        $this->onlyExistingColumns(
                            'exercises',
                            $this->withTimestamps('exercises', [
                                'name' => $exerciseName,
                                'type' => $duration === null ? 'training' : 'time',
                                'video' => $tutorialVideo,
                                'video_url' => $tutorialVideo,
                            ])
                        )
                    );

                    $exerciseId = DB::table('exercises')
                        ->where('name', $exerciseName)
                        ->value('id');
                }

                if (! $exerciseId) {
                    continue;
                }

                DB::table('workout_exercises')->updateOrInsert(
                    [
                        'workout_id' => $workoutId,
                        'exercise_id' => $exerciseId,
                    ],
                    [
                        'sets' => $sets,
                        'reps' => $reps,
                        'duration' => $duration,
                        'rest_seconds' => $restSeconds,
                    ]
                );
            }
        }
    }

    private function withTimestamps(string $table, array $values): array
    {
        $now = now();

        if (Schema::hasColumn($table, 'created_at')) {
            $values['created_at'] = $values['created_at'] ?? $now;
        }

        if (Schema::hasColumn($table, 'updated_at')) {
            $values['updated_at'] = $now;
        }

        return $values;
    }

    private function onlyExistingColumns(string $table, array $values): array
    {
        $columns = Schema::getColumnListing($table);

        return array_filter(
            $values,
            fn ($key) => in_array($key, $columns, true),
            ARRAY_FILTER_USE_KEY
        );
    }
}
