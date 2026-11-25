<?php

namespace App\Http\Controllers;

use App\Models\ExerciseProgress;
use App\Models\CoachReview;
use App\Models\PerformanceLog;
use App\Models\UserWorkoutLog;
use App\Models\User;
use App\Models\Workout;
use App\Models\WorkoutRecording;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

class WorkoutController extends Controller
{
    private const TESTING_UNLOCK_ALL_DAYS_DATE = '2026-06-05';

    public function workoutList(Request $request, $user_id)
    {
        if ($denied = $this->denyUnlessAthleteUser($request, (int) $user_id)) {
            return $denied;
        }

        $user = User::find((int) $user_id);

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        $workouts = Workout::orderBy('day_number')->get();

        $result = [];
        $completedDaysByLevel = [];
        $previousDayByLevel = [];
        $testingUnlockAllDays = $this->testingUnlockAllDaysActive();

        foreach ($workouts as $workout) {
            $dayNumber = (int) $workout->day_number;
            $levelKey = strtolower($workout->level ?? 'Beginner');
            $exerciseIds = $this->exerciseIdsForWorkout((int) $workout->id);
            $completedExerciseCount = $this->completedExerciseCount(
                (int) $user_id,
                (int) $workout->id,
                $exerciseIds
            );
            $setStats = $this->workoutSetStats((int) $user_id, (int) $workout->id);
            $completed = $this->isWorkoutCompletedForUser(
                (int) $user_id,
                $workout,
                $exerciseIds,
                $completedExerciseCount
            );
            $access = $this->workoutAccess($user, $workout);
            $previousDay = $previousDayByLevel[$levelKey] ?? null;
            $completedDaysForLevel = $completedDaysByLevel[$levelKey] ?? [];
            $lockedBySequence = $previousDay !== null
                && ! in_array($previousDay, $completedDaysForLevel, true);
            $lockedBySequence = $testingUnlockAllDays ? false : $lockedBySequence;
            $locked = $access['locked'] || $lockedBySequence;
            $visibleCompleted = $completed && ! $access['locked'];

            if ($visibleCompleted) {
                $completedDaysByLevel[$levelKey][] = $dayNumber;
            }

            $previousDayByLevel[$levelKey] = $dayNumber;

            $progressPercentage = $this->progressPercentage(
                $setStats['logged_sets'],
                $setStats['expected_sets'],
                $completedExerciseCount,
                count($exerciseIds)
            );

            $result[] = [
                'id' => $workout->id,
                'title' => $this->workoutTitle($workout),
                'day_number' => $dayNumber,
                'level' => $workout->level ?? 'Beginner',
                'difficulty' => $workout->level ?? 'Beginner',
                'estimated_duration' => $this->estimatedDurationMinutes((int) $workout->id),
                'status' => $visibleCompleted ? 'completed' : ($locked ? 'locked' : 'unlocked'),
                'completed' => $visibleCompleted,
                'locked' => $locked,
                'locked_reason' => $access['locked']
                    ? $access['reason']
                    : ($lockedBySequence ? 'previous_day_required' : null),
                'lock_message' => $access['locked']
                    ? $access['message']
                    : ($lockedBySequence ? 'Selesaikan workout hari sebelumnya terlebih dahulu.' : null),
                'exercise_count' => count($exerciseIds),
                'completed_exercise_count' => $completedExerciseCount,
                'progress_percentage' => $progressPercentage,
                'total_sets' => $setStats['expected_sets'],
                'logged_sets' => $setStats['logged_sets'],
                'successful_sets' => $setStats['successful_sets'],
                'failed_sets' => $setStats['failed_sets'],
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $result,
        ]);
    }

    public function getWorkout(Request $request, $day)
    {
        $workout = Workout::where('day_number', $day)->first();

        if (! $workout) {
            return response()->json([
                'success' => false,
                'message' => 'Workout not found',
            ], 404);
        }

        $exercises = $this->exercisesForWorkout((int) $workout->id);
        $userId = $request->query('user_id');

        if ($userId !== null) {
            if ($denied = $this->denyUnlessAthleteUser($request, (int) $userId)) {
                return $denied;
            }

            if ($denied = $this->denyLockedWorkoutAccess((int) $userId, $workout)) {
                return $denied;
            }

            $completedIds = $this->completedExerciseIds(
                (int) $userId,
                (int) $workout->id,
                $exercises->pluck('id')->map(fn ($id) => (int) $id)->all()
            );

            $exercises = $exercises->map(function ($exercise) use ($completedIds, $userId, $workout) {
                $exercise->completed = in_array((int) $exercise->id, $completedIds, true);
                $exerciseLogs = PerformanceLog::where('user_id', (int) $userId)
                    ->where('workout_id', (int) $workout->id)
                    ->where('exercise_id', (int) $exercise->id)
                    ->orderBy('set_number')
                    ->get(['set_number', 'success', 'created_at']);
                $exercise->set_logs = $exerciseLogs->map(function ($log) {
                    return [
                        'set_number' => (int) $log->set_number,
                        'success' => (bool) $log->success,
                        'created_at' => optional($log->created_at)->toISOString(),
                    ];
                })->values();
                $exercise->logged_sets = $exerciseLogs->count();
                $exercise->successful_sets = $exerciseLogs
                    ->where('success', true)
                    ->count();
                $exercise->failed_sets = $exerciseLogs
                    ->where('success', false)
                    ->count();

                return $exercise;
            });
        }

        return response()->json([
            'success' => true,
            'data' => [
                'workout' => [
                    'id' => $workout->id,
                    'title' => $this->workoutTitle($workout),
                    'name' => $this->workoutTitle($workout),
                    'level' => $workout->level ?? 'Beginner',
                    'difficulty' => $workout->level ?? 'Beginner',
                    'day_number' => (int) $workout->day_number,
                    'estimated_duration' => $this->estimatedDurationMinutes((int) $workout->id),
                    'total_sets' => $this->expectedSetCount((int) $workout->id),
                ],
                'exercises' => $exercises,
            ],
        ]);
    }

    public function saveExerciseProgress(Request $request)
    {
        $validated = $request->validate([
            'user_id' => ['required', 'integer'],
            'workout_id' => ['required', 'integer'],
            'exercise_id' => ['required', 'integer'],
            'status' => ['nullable', 'string'],
            'set_number' => ['nullable', 'integer'],
        ]);

        if ($denied = $this->denyUnlessAthleteUser($request, (int) $validated['user_id'])) {
            return $denied;
        }

        $exerciseExists = DB::table('workout_exercises')
            ->where('workout_id', $validated['workout_id'])
            ->where('exercise_id', $validated['exercise_id'])
            ->exists();

        if (! $exerciseExists) {
            return response()->json([
                'success' => false,
                'message' => 'Exercise tidak ada di workout ini',
            ], 422);
        }

        $workout = Workout::find((int) $validated['workout_id']);

        if (! $workout) {
            return response()->json([
                'success' => false,
                'message' => 'Workout tidak ditemukan',
            ], 404);
        }

        if ($denied = $this->denyLockedWorkoutAccess((int) $validated['user_id'], $workout)) {
            return $denied;
        }

        $progress = ExerciseProgress::updateOrCreate(
            [
                'user_id' => $validated['user_id'],
                'workout_id' => $validated['workout_id'],
                'exercise_id' => $validated['exercise_id'],
            ],
            [
                'status' => $validated['status'] ?? 'completed',
                'set_number' => $validated['set_number'] ?? 1,
            ]
        );
        $exerciseIds = $this->exerciseIdsForWorkout((int) $validated['workout_id']);
        $completedExerciseCount = $this->completedExerciseCount(
            (int) $validated['user_id'],
            (int) $validated['workout_id'],
            $exerciseIds
        );

        return response()->json([
            'success' => true,
            'message' => 'Exercise progress saved',
            'data' => [
                'progress' => $progress,
                'total_exercises' => count($exerciseIds),
                'completed_exercise_count' => $completedExerciseCount,
                'all_exercises_completed' => count($exerciseIds) > 0
                    && $completedExerciseCount === count($exerciseIds),
                'workout_progress' => $this->workoutSetStats(
                    (int) $validated['user_id'],
                    (int) $validated['workout_id']
                ),
            ],
        ]);
    }

    public function getExerciseProgress(Request $request, $user_id, $workout_id)
    {
        if ($denied = $this->denyUnlessAthleteUser($request, (int) $user_id)) {
            return $denied;
        }

        $progress = ExerciseProgress::where('user_id', $user_id)
            ->where('workout_id', $workout_id)
            ->get(['exercise_id', 'status', 'set_number']);
        $exerciseIds = $this->exerciseIdsForWorkout((int) $workout_id);

        return response()->json([
            'success' => true,
            'data' => $progress,
            'meta' => [
                'total_exercises' => count($exerciseIds),
                'completed_exercise_count' => $this->completedExerciseCount(
                    (int) $user_id,
                    (int) $workout_id,
                    $exerciseIds
                ),
                'workout_progress' => $this->workoutSetStats((int) $user_id, (int) $workout_id),
            ],
        ]);
    }

    public function performanceLog(Request $request)
    {
        $validated = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'workout_id' => ['required', 'integer', 'exists:workouts,id'],
            'exercise_id' => ['required', 'integer', 'exists:exercises,id'],
            'set_number' => ['required', 'integer', 'min:1'],
            'success' => ['required', 'boolean'],
        ]);

        if ($denied = $this->denyUnlessAthleteUser($request, (int) $validated['user_id'])) {
            return $denied;
        }

        $workoutExercise = DB::table('workout_exercises')
            ->where('workout_id', $validated['workout_id'])
            ->where('exercise_id', $validated['exercise_id'])
            ->first();

        if (! $workoutExercise) {
            return response()->json([
                'success' => false,
                'message' => 'Exercise tidak ada di workout ini',
            ], 422);
        }

        $workout = Workout::find((int) $validated['workout_id']);

        if (! $workout) {
            return response()->json([
                'success' => false,
                'message' => 'Workout tidak ditemukan',
            ], 404);
        }

        if ($denied = $this->denyLockedWorkoutAccess((int) $validated['user_id'], $workout)) {
            return $denied;
        }

        if ((int) $validated['set_number'] > (int) $workoutExercise->sets) {
            return response()->json([
                'success' => false,
                'message' => 'Set number melebihi jumlah set exercise',
            ], 422);
        }

        $log = PerformanceLog::updateOrCreate(
            [
                'user_id' => $validated['user_id'],
                'workout_id' => $validated['workout_id'],
                'exercise_id' => $validated['exercise_id'],
                'set_number' => $validated['set_number'],
            ],
            [
                'success' => $validated['success'],
                'created_at' => now(),
            ]
        );

        $exerciseLoggedSets = PerformanceLog::where('user_id', $validated['user_id'])
            ->where('workout_id', $validated['workout_id'])
            ->where('exercise_id', $validated['exercise_id'])
            ->count();

        if ($exerciseLoggedSets >= (int) $workoutExercise->sets) {
            ExerciseProgress::updateOrCreate(
                [
                    'user_id' => $validated['user_id'],
                    'workout_id' => $validated['workout_id'],
                    'exercise_id' => $validated['exercise_id'],
                ],
                [
                    'status' => 'completed',
                    'set_number' => (int) $workoutExercise->sets,
                ]
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Performance log saved',
            'data' => [
                'log' => $log,
                'workout_progress' => $this->workoutSetStats(
                    (int) $validated['user_id'],
                    (int) $validated['workout_id']
                ),
            ],
        ]);
    }

    public function performanceSummary(Request $request, $user_id)
    {
        if ($denied = $this->denyUnlessAthleteUser($request, (int) $user_id)) {
            return $denied;
        }

        return response()->json([
            'success' => true,
            'data' => $this->performanceSummaryData((int) $user_id),
        ]);
    }

    public function storeWorkoutRecording(Request $request)
    {
        $validated = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'workout_id' => ['required', 'integer', 'exists:workouts,id'],
            'day_number' => ['required', 'integer', 'min:1'],
            'mime_type' => ['nullable', 'string', 'max:120'],
            'duration_seconds' => ['nullable', 'integer', 'min:0'],
            'video' => ['required', 'file', 'max:512000'],
        ]);

        if ($denied = $this->denyUnlessAthleteUser($request, (int) $validated['user_id'])) {
            return $denied;
        }

        $workout = Workout::where('id', $validated['workout_id'])
            ->where('day_number', $validated['day_number'])
            ->first();

        if (! $workout) {
            return response()->json([
                'success' => false,
                'message' => 'Workout tidak sesuai dengan day number',
            ], 422);
        }

        if ($denied = $this->denyLockedWorkoutAccess((int) $validated['user_id'], $workout)) {
            return $denied;
        }

        $file = $request->file('video');
        $extension = $file->guessExtension() ?: 'webm';
        $path = $file->storeAs(
            'workout-recordings/user-'.$validated['user_id'].'/day-'.$validated['day_number'],
            'workout-'.$validated['workout_id'].'-'.now()->format('YmdHis').'.'.$extension,
            'public'
        );

        $recording = WorkoutRecording::create([
            'user_id' => $validated['user_id'],
            'workout_id' => $validated['workout_id'],
            'day_number' => $validated['day_number'],
            'file_path' => $path,
            'file_url' => Storage::url($path),
            'mime_type' => $validated['mime_type'] ?? $file->getClientMimeType(),
            'file_size' => $file->getSize() ?: 0,
            'duration_seconds' => $validated['duration_seconds'] ?? null,
            'recorded_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Workout recording uploaded',
            'data' => [
                'recording' => $recording,
            ],
        ]);
    }

    public function progress(Request $request, $user_id)
    {
        if ($denied = $this->denyUnlessAthleteUser($request, (int) $user_id)) {
            return $denied;
        }

        return response()->json([
            'success' => true,
            'data' => $this->progressData((int) $user_id),
        ]);
    }

    public function completeWorkout(Request $request, $user_id, $day_number = null)
    {
        if ($denied = $this->denyUnlessAthleteUser($request, (int) $user_id)) {
            return $denied;
        }

        if ($day_number === null) {
            return response()->json([
                'success' => false,
                'message' => 'Day number wajib diisi',
            ], 422);
        }

        $workout = Workout::where('day_number', $day_number)->first();

        if (! $workout) {
            return response()->json([
                'success' => false,
                'message' => 'Workout not found',
            ], 404);
        }

        if ($denied = $this->denyLockedWorkoutAccess((int) $user_id, $workout)) {
            return $denied;
        }

        if (! $this->testingUnlockAllDaysActive()
            && ! $this->isPreviousDayCompleted((int) $user_id, (int) $day_number)
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Selesaikan workout hari sebelumnya terlebih dahulu',
            ], 422);
        }

        $exerciseIds = $this->exerciseIdsForWorkout((int) $workout->id);
        $completedExerciseCount = $this->completedExerciseCount(
            (int) $user_id,
            (int) $workout->id,
            $exerciseIds
        );
        $setStats = $this->workoutSetStats((int) $user_id, (int) $workout->id);

        if (count($exerciseIds) === 0) {
            return response()->json([
                'success' => false,
                'message' => 'Workout belum memiliki exercise',
            ], 422);
        }

        $allExercisesCompleted = $completedExerciseCount === count($exerciseIds);
        $allSetsLogged = $setStats['expected_sets'] > 0
            && $setStats['logged_sets'] >= $setStats['expected_sets'];

        if (! $allExercisesCompleted && ! $allSetsLogged) {
            return response()->json([
                'success' => false,
                'message' => 'Selesaikan semua set latihan terlebih dahulu',
                'data' => [
                    'total_exercises' => count($exerciseIds),
                    'completed_exercise_count' => $completedExerciseCount,
                    'expected_sets' => $setStats['expected_sets'],
                    'logged_sets' => $setStats['logged_sets'],
                ],
            ], 422);
        }

        if (! $this->hasWorkoutRecording((int) $user_id, (int) $workout->id, (int) $day_number)) {
            return response()->json([
                'success' => false,
                'message' => 'Upload video recording exercise terlebih dahulu',
            ], 422);
        }

        UserWorkoutLog::updateOrCreate(
            [
                'user_id' => $user_id,
                'day_number' => $day_number,
            ],
            [
                'status' => 'completed',
                'completed_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Workout completed',
            'data' => [
                'day_number' => (int) $day_number,
                'next_day_unlocked' => Workout::where(
                    'day_number',
                    (int) $day_number + 1
                )->exists(),
                'score' => $this->workoutScoreData((int) $user_id, (int) $workout->id),
                'progress' => $this->progressData((int) $user_id),
            ],
        ]);
    }

    public function nextDay(Request $request, $user_id)
    {
        if ($denied = $this->denyUnlessAthleteUser($request, (int) $user_id)) {
            return $denied;
        }

        $user = User::find((int) $user_id);

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        $nextWorkout = Workout::orderBy('day_number')
            ->get()
            ->first(function ($workout) use ($user_id, $user) {
                return ! $this->workoutAccess($user, $workout)['locked']
                    && ! $this->isWorkoutCompletedForUser((int) $user_id, $workout);
            });

        return response()->json([
            'success' => true,
            'data' => $nextWorkout,
        ]);
    }

    public function resetDay(Request $request, $user_id)
    {
        if ($denied = $this->denyUnlessAthleteUser($request, (int) $user_id)) {
            return $denied;
        }

        UserWorkoutLog::where('user_id', $user_id)->delete();
        ExerciseProgress::where('user_id', $user_id)->delete();
        PerformanceLog::where('user_id', $user_id)->delete();
        WorkoutRecording::where('user_id', $user_id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Progress reset',
        ]);
    }

    public function history(Request $request, $user_id)
    {
        if ($denied = $this->denyUnlessAthleteUser($request, (int) $user_id)) {
            return $denied;
        }

        $history = UserWorkoutLog::where('user_id', $user_id)
            ->orderBy('day_number')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $history,
        ]);
    }

    public function saveProgress()
    {
        return response()->json([
            'success' => true,
            'message' => 'Gunakan endpoint POST /exercise-progress atau POST /performance-log untuk menyimpan progress',
        ]);
    }

    private function exercisesForWorkout(int $workoutId)
    {
        if (Schema::hasTable('workout_exercises')) {
            $selects = [
                'exercises.id',
                DB::raw('workout_exercises.id as workout_exercise_id'),
                'workout_exercises.exercise_id',
                'exercises.name',
                'exercises.type',
                'workout_exercises.sets',
                'workout_exercises.reps',
                'workout_exercises.duration',
                'workout_exercises.rest_seconds',
            ];

            $this->appendVideoSelect($selects);
            $this->appendExerciseDetailSelects($selects, 'exercises');

            return DB::table('workout_exercises')
                ->join(
                    'exercises',
                    'workout_exercises.exercise_id',
                    '=',
                    'exercises.id'
                )
                ->where(
                    'workout_exercises.workout_id',
                    $workoutId
                )
                ->select($selects)
                ->orderBy('workout_exercises.id')
                ->get();
        }

        $selects = [
            'id',
            DB::raw('null as workout_exercise_id'),
            DB::raw('id as exercise_id'),
            'name',
            DB::raw('null as type'),
            'sets',
            'reps',
            DB::raw('null as duration'),
            'rest_seconds',
        ];

        $this->appendFallbackVideoSelect($selects);
        $this->appendExerciseDetailSelects($selects, 'exercises');

        return DB::table('exercises')
            ->where('workout_id', $workoutId)
            ->select($selects)
            ->orderBy('id')
            ->get();
    }

    private function denyUnlessAthleteUser(Request $request, int $userId)
    {
        $authenticatedUser = $request->user('sanctum');

        if (! $authenticatedUser) {
            return response()->json([
                'success' => false,
                'message' => 'Token login wajib untuk mengakses data atlet',
            ], 401);
        }

        if ((int) $authenticatedUser->id !== $userId) {
            return response()->json([
                'success' => false,
                'message' => 'Token login tidak cocok dengan user atlet',
            ], 403);
        }

        $user = User::find($userId);

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        if (! $this->isAthleteRole($user->role)) {
            return response()->json([
                'success' => false,
                'message' => 'Akun coach/admin tidak bisa mengakses app atlet. Silakan register akun athlete terlebih dahulu.',
            ], 403);
        }

        return null;
    }

    private function isAthleteRole(?string $role): bool
    {
        $normalized = strtolower(trim((string) ($role ?? 'athlete')));

        return $normalized === '' || $normalized === 'athlete';
    }

    private function appendVideoSelect(array &$selects): void
    {
        $hasVideo = Schema::hasColumn('exercises', 'video');
        $hasVideoUrl = Schema::hasColumn('exercises', 'video_url');
        $hasWorkoutExerciseVideoUrl = Schema::hasColumn('workout_exercises', 'video_url');

        if ($hasWorkoutExerciseVideoUrl && $hasVideo && $hasVideoUrl) {
            $selects[] = DB::raw('COALESCE(workout_exercises.video_url, exercises.video_url, exercises.video) as video_url');

            return;
        }

        if ($hasWorkoutExerciseVideoUrl && $hasVideoUrl) {
            $selects[] = DB::raw('COALESCE(workout_exercises.video_url, exercises.video_url) as video_url');

            return;
        }

        if ($hasWorkoutExerciseVideoUrl && $hasVideo) {
            $selects[] = DB::raw('COALESCE(workout_exercises.video_url, exercises.video) as video_url');

            return;
        }

        if ($hasVideo && $hasVideoUrl) {
            $selects[] = DB::raw('COALESCE(exercises.video_url, exercises.video) as video_url');

            return;
        }

        if ($hasVideoUrl) {
            $selects[] = 'exercises.video_url';

            return;
        }

        if ($hasVideo) {
            $selects[] = DB::raw('exercises.video as video_url');

            return;
        }

        $selects[] = DB::raw('null as video_url');
    }

    private function appendExerciseDetailSelects(array &$selects, string $table): void
    {
        foreach ([
            'description',
            'instructions',
            'equipment',
            'muscle_group',
            'target_area',
        ] as $column) {
            if (Schema::hasColumn($table, $column)) {
                $selects[] = "{$table}.{$column}";

                continue;
            }

            $selects[] = DB::raw("null as {$column}");
        }
    }

    private function appendFallbackVideoSelect(array &$selects): void
    {
        $hasVideo = Schema::hasColumn('exercises', 'video');
        $hasVideoUrl = Schema::hasColumn('exercises', 'video_url');

        if ($hasVideo && $hasVideoUrl) {
            $selects[] = DB::raw('COALESCE(video_url, video) as video_url');

            return;
        }

        if ($hasVideoUrl) {
            $selects[] = 'video_url';

            return;
        }

        if ($hasVideo) {
            $selects[] = DB::raw('video as video_url');

            return;
        }

        $selects[] = DB::raw('null as video_url');
    }

    private function exerciseIdsForWorkout(int $workoutId): array
    {
        return $this->exercisesForWorkout($workoutId)
            ->pluck('id')
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values()
            ->all();
    }

    private function completedExerciseIds(
        int $userId,
        int $workoutId,
        array $exerciseIds
    ): array {
        if (count($exerciseIds) === 0) {
            return [];
        }

        return ExerciseProgress::where('user_id', $userId)
            ->where('workout_id', $workoutId)
            ->whereIn('exercise_id', $exerciseIds)
            ->whereIn('status', ['completed', 'complete', '1', 'true'])
            ->pluck('exercise_id')
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values()
            ->all();
    }

    private function completedExerciseCount(
        int $userId,
        int $workoutId,
        array $exerciseIds
    ): int {
        return count($this->completedExerciseIds(
            $userId,
            $workoutId,
            $exerciseIds
        ));
    }

    private function isWorkoutCompletedForUser(
        int $userId,
        Workout $workout,
        ?array $exerciseIds = null,
        ?int $completedExerciseCount = null
    ): bool {
        $hasCompletedLog = UserWorkoutLog::where('user_id', $userId)
            ->where('day_number', $workout->day_number)
            ->where('status', 'completed')
            ->exists();

        if (! $hasCompletedLog) {
            return false;
        }

        $exerciseIds ??= $this->exerciseIdsForWorkout((int) $workout->id);
        $completedExerciseCount ??= $this->completedExerciseCount(
            $userId,
            (int) $workout->id,
            $exerciseIds
        );

        $allExercisesCompleted = count($exerciseIds) > 0
            && $completedExerciseCount === count($exerciseIds);
        $setStats = $this->workoutSetStats($userId, (int) $workout->id);
        $allSetsLogged = $setStats['expected_sets'] > 0
            && $setStats['logged_sets'] >= $setStats['expected_sets'];

        return $allExercisesCompleted || $allSetsLogged;
    }

    private function isPreviousDayCompleted(int $userId, int $dayNumber): bool
    {
        $currentWorkout = Workout::where('day_number', $dayNumber)->first();

        if (! $currentWorkout) {
            return false;
        }

        $previousWorkout = Workout::where('level', $currentWorkout->level)
            ->where('day_number', '<', $dayNumber)
            ->orderByDesc('day_number')
            ->first();

        if (! $previousWorkout) {
            return true;
        }

        return $this->isWorkoutCompletedForUser($userId, $previousWorkout);
    }

    private function testingUnlockAllDaysActive(): bool
    {
        return now('Asia/Jakarta')->toDateString() === self::TESTING_UNLOCK_ALL_DAYS_DATE;
    }

    private function hasWorkoutRecording(int $userId, int $workoutId, int $dayNumber): bool
    {
        if (! Schema::hasTable('workout_recordings')) {
            return false;
        }

        return WorkoutRecording::where('user_id', $userId)
            ->where('workout_id', $workoutId)
            ->where('day_number', $dayNumber)
            ->exists();
    }

    private function expectedSetCount(int $workoutId): int
    {
        return (int) DB::table('workout_exercises')
            ->where('workout_id', $workoutId)
            ->sum('sets');
    }

    private function workoutSetStats(int $userId, int $workoutId): array
    {
        $expectedSets = $this->expectedSetCount($workoutId);
        $baseQuery = PerformanceLog::where('user_id', $userId)
            ->where('workout_id', $workoutId);
        $loggedSets = (clone $baseQuery)->count();
        $successfulSets = (clone $baseQuery)->where('success', true)->count();
        $failedSets = (clone $baseQuery)->where('success', false)->count();
        $successPercentage = $loggedSets > 0
            ? round(($successfulSets / $loggedSets) * 100)
            : 0;

        return [
            'expected_sets' => $expectedSets,
            'logged_sets' => $loggedSets,
            'successful_sets' => $successfulSets,
            'failed_sets' => $failedSets,
            'success_percentage' => $successPercentage,
            'performance_score' => $this->performanceScore($successPercentage, $loggedSets, $expectedSets),
            'feedback' => $this->feedbackForScore($successPercentage),
        ];
    }

    private function workoutScoreData(int $userId, int $workoutId): array
    {
        $stats = $this->workoutSetStats($userId, $workoutId);

        return [
            'success_percentage' => $stats['success_percentage'],
            'total_successful_sets' => $stats['successful_sets'],
            'failed_sets' => $stats['failed_sets'],
            'performance_score' => $stats['performance_score'],
            'workout_consistency' => $stats['expected_sets'] > 0
                ? round(($stats['logged_sets'] / $stats['expected_sets']) * 100)
                : 0,
            'motivational_feedback' => $stats['feedback'],
        ];
    }

    private function performanceSummaryData(int $userId): array
    {
        $coachReviewQuery = CoachReview::where('user_id', $userId)
            ->whereIn('status', ['approved', 'needs_revision'])
            ->whereNotNull('score');
        $reviewCount = (clone $coachReviewQuery)->count();
        $averageCoachScore = $reviewCount > 0
            ? (int) round((clone $coachReviewQuery)->avg('score'))
            : 0;
        $latestReview = CoachReview::where('user_id', $userId)
            ->latest('reviewed_at')
            ->latest('updated_at')
            ->first();
        $baseQuery = PerformanceLog::where('user_id', $userId);
        $totalSets = (clone $baseQuery)->count();
        $successfulSets = (clone $baseQuery)->where('success', true)->count();
        $failedSets = (clone $baseQuery)->where('success', false)->count();
        $successPercentage = $totalSets > 0
            ? round(($successfulSets / $totalSets) * 100)
            : 0;

        return [
            'total_sets' => $totalSets,
            'successful_sets' => $successfulSets,
            'failed_sets' => $failedSets,
            'success_percentage' => $successPercentage,
            'successful_sets_ratio' => $totalSets > 0 ? round($successfulSets / $totalSets, 2) : 0,
            'failed_sets_ratio' => $totalSets > 0 ? round($failedSets / $totalSets, 2) : 0,
            'performance_score' => $averageCoachScore,
            'performance_based_progress' => $averageCoachScore,
            'coach_review_count' => $reviewCount,
            'coach_feedback' => $latestReview?->feedback,
            'coach_review_status' => $latestReview?->status,
            'coach_reviewed_at' => optional($latestReview?->reviewed_at)->toISOString(),
            'coach_reviews_by_day' => $this->coachReviewsByDay($userId),
            'feedback' => $latestReview?->feedback
                ?? ($reviewCount > 0
                    ? $this->coachFeedbackForScore($averageCoachScore)
                    : 'Menunggu validasi coach'),
        ];
    }

    private function progressData(int $userId): array
    {
        $user = User::find($userId);
        $programWorkouts = $user ? $this->programWorkouts($user) : collect();
        $workoutIds = $programWorkouts->pluck('id')->map(fn ($id) => (int) $id)->all();
        $programDays = $programWorkouts
            ->pluck('day_number')
            ->map(fn ($day) => (int) $day)
            ->filter(fn ($day) => $day > 0)
            ->unique()
            ->values()
            ->all();
        $totalProgramDays = count($programDays);
        $completedDays = $totalProgramDays === 0
            ? []
            : UserWorkoutLog::where('user_id', $userId)
                ->where('status', 'completed')
                ->whereIn('day_number', $programDays)
                ->orderBy('day_number')
                ->pluck('day_number')
                ->map(fn ($day) => (int) $day)
                ->unique()
                ->values()
                ->all();
        $completedTotal = count($completedDays);
        $summary = $this->performanceSummaryData($userId);
        $weeklyChart = $this->weeklyChart($userId);
        $weeklyActiveDays = collect($weeklyChart)
            ->filter(fn (array $item) => (int) $item['activity_count'] > 0)
            ->count();
        $recordedDays = $workoutIds === [] || $programDays === []
            ? 0
            : WorkoutRecording::where('user_id', $userId)
                ->whereIn('workout_id', $workoutIds)
                ->whereIn('day_number', $programDays)
                ->distinct('day_number')
                ->count('day_number');
        $consistencyProgress = $totalProgramDays > 0
            ? round((max($completedTotal, $recordedDays) / $totalProgramDays) * 100)
            : 0;

        return [
            'consistency_progress' => min(100, $consistencyProgress),
            'performance_based_progress' => $summary['performance_based_progress'],
            'coach_review_count' => $summary['coach_review_count'],
            'coach_feedback' => $summary['coach_feedback'],
            'coach_review_status' => $summary['coach_review_status'],
            'coach_reviewed_at' => $summary['coach_reviewed_at'],
            'coach_reviews_by_day' => $summary['coach_reviews_by_day'],
            'workout_completion_percentage' => min(100, $consistencyProgress),
            'performance_trend' => $this->performanceTrend($userId),
            'successful_sets_ratio' => $summary['successful_sets_ratio'],
            'failed_sets_ratio' => $summary['failed_sets_ratio'],
            'weekly_consistency' => round(($weeklyActiveDays / 7) * 100),
            'completed_workout_total' => $completedTotal,
            'current_streak' => $this->currentStreak($completedDays),
            'total_workouts' => $totalProgramDays,
            'total_program_days' => $totalProgramDays,
            'training_level' => $user ? $this->trainingLevel($user) : null,
            'program_days' => $programWorkouts
                ->groupBy('day_number')
                ->map(function ($workouts, $dayNumber) {
                    $workout = $workouts->first();

                    return [
                        'workout_id' => (int) $workout->id,
                        'workout_ids' => $workouts
                            ->pluck('id')
                            ->map(fn ($id) => (int) $id)
                            ->values()
                            ->all(),
                        'day_number' => (int) $dayNumber,
                        'title' => $this->workoutTitle($workout),
                        'level' => $workout->level,
                    ];
                })
                ->values()
                ->all(),
            'total_sets' => $summary['total_sets'],
            'successful_sets' => $summary['successful_sets'],
            'failed_sets' => $summary['failed_sets'],
            'success_percentage' => $summary['success_percentage'],
            'performance_score' => $summary['performance_score'],
            'feedback' => $summary['feedback'],
            'chart' => $weeklyChart,
        ];
    }

    private function programWorkouts(User $user)
    {
        return $this->programWorkoutsForLevel($this->trainingLevel($user));
    }

    private function programWorkoutsForLevel(string $level)
    {
        $matchedLevel = Workout::whereRaw('LOWER(level) = ?', [strtolower($level)])
            ->value('level')
            ?: Workout::whereRaw('LOWER(level) = ?', ['beginner'])->value('level');
        $query = Workout::query();

        if ($matchedLevel) {
            $query->whereRaw('LOWER(level) = ?', [strtolower($matchedLevel)]);
        } else {
            $query->whereRaw('1 = 0');
        }

        return $query->orderBy('day_number')->get();
    }

    private function denyLockedWorkoutAccess(int $userId, Workout $workout)
    {
        $user = User::find($userId);

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        $access = $this->workoutAccess($user, $workout);

        if (! $access['locked']) {
            return null;
        }

        return response()->json([
            'success' => false,
            'message' => $access['message'],
            'data' => [
                'locked_reason' => $access['reason'],
            ],
        ], 403);
    }

    private function workoutAccess(User $user, Workout $workout): array
    {
        $workoutLevel = $this->normalizeTrainingLevel($workout->level ?? 'Beginner');
        $athleteLevel = $this->trainingLevel($user);

        if ($workoutLevel === 'Intermediate' && $athleteLevel !== 'Intermediate') {
            $beginnerCompleted = $this->isLevelCompleted((int) $user->id, 'Beginner');

            return [
                'locked' => true,
                'reason' => $beginnerCompleted
                    ? 'coach_approval_required'
                    : 'beginner_required',
                'message' => $beginnerCompleted
                    ? 'Program Intermediate terkunci. Tunggu approval pelatih untuk naik level.'
                    : 'Program Intermediate terkunci. Selesaikan program Beginner terlebih dahulu.',
            ];
        }

        return [
            'locked' => false,
            'reason' => null,
            'message' => null,
        ];
    }

    private function isLevelCompleted(int $userId, string $level): bool
    {
        $workouts = $this->programWorkoutsForLevel($level);

        if ($workouts->isEmpty()) {
            return false;
        }

        foreach ($workouts as $workout) {
            if (! $this->isWorkoutCompletedForUser($userId, $workout)) {
                return false;
            }
        }

        return true;
    }

    private function trainingLevel(User $user): string
    {
        return $this->normalizeTrainingLevel($user->training_level ?: 'Beginner');
    }

    private function normalizeTrainingLevel(?string $level): string
    {
        return strtolower(trim((string) $level)) === 'intermediate'
            ? 'Intermediate'
            : 'Beginner';
    }

    private function coachReviewsByDay(int $userId): array
    {
        return CoachReview::where('user_id', $userId)
            ->whereIn('status', ['approved', 'needs_revision', 'rejected'])
            ->orderBy('day_number')
            ->orderByDesc('reviewed_at')
            ->orderByDesc('updated_at')
            ->get()
            ->map(fn (CoachReview $review) => [
                'id' => (int) $review->id,
                'day_number' => (int) $review->day_number,
                'workout_id' => (int) $review->workout_id,
                'recording_id' => (int) $review->workout_recording_id,
                'status' => $review->status,
                'score' => $review->score === null ? null : (int) $review->score,
                'feedback' => $review->feedback,
                'reviewed_at' => optional($review->reviewed_at)->toISOString(),
            ])
            ->values()
            ->all();
    }

    private function coachFeedbackForScore(int $score): string
    {
        return match (true) {
            $score >= 90 => 'Excellent Performance',
            $score >= 75 => 'Great Effort',
            $score > 0 => 'Keep Improving',
            default => 'Menunggu validasi coach',
        };
    }

    private function weeklyChart(int $userId): array
    {
        $items = [];

        for ($i = 6; $i >= 0; $i--) {
            $date = now()->subDays($i);
            $dateString = $date->toDateString();
            $completedWorkouts = UserWorkoutLog::where('user_id', $userId)
                ->where('status', 'completed')
                ->whereDate('completed_at', $dateString)
                ->count();
            $recordedSessions = WorkoutRecording::where('user_id', $userId)
                ->where(function ($query) use ($dateString) {
                    $query->whereDate('recorded_at', $dateString)
                        ->orWhere(function ($fallbackQuery) use ($dateString) {
                            $fallbackQuery->whereNull('recorded_at')
                                ->whereDate('created_at', $dateString);
                        });
                })
                ->count();
            $activityCount = $completedWorkouts + $recordedSessions;

            $items[] = [
                'date' => $dateString,
                'label' => $date->format('D'),
                'completed_workouts' => $completedWorkouts,
                'recorded_sessions' => $recordedSessions,
                'activity_count' => $activityCount,
                'consistency_percentage' => $activityCount > 0 ? 100 : 0,
            ];
        }

        return $items;
    }

    private function currentStreak(array $completedDays): int
    {
        if (count($completedDays) === 0) {
            return 0;
        }

        rsort($completedDays);
        $streak = 1;
        $previous = $completedDays[0];

        foreach (array_slice($completedDays, 1) as $day) {
            if ($day === $previous - 1) {
                $streak++;
                $previous = $day;

                continue;
            }

            break;
        }

        return $streak;
    }

    private function performanceTrend(int $userId): string
    {
        $recent = $this->successPercentageBetween(
            $userId,
            now()->subDays(6)->startOfDay(),
            now()->endOfDay()
        );
        $previous = $this->successPercentageBetween(
            $userId,
            now()->subDays(13)->startOfDay(),
            now()->subDays(7)->endOfDay()
        );

        if ($recent === 0 && $previous === 0) {
            return 'No data yet';
        }

        if ($recent > $previous) {
            return 'Improving';
        }

        if ($recent < $previous) {
            return 'Needs focus';
        }

        return 'Stable';
    }

    private function successPercentageBetween(int $userId, $start, $end): int
    {
        $baseQuery = PerformanceLog::where('user_id', $userId)
            ->whereBetween('created_at', [$start, $end]);
        $total = (clone $baseQuery)->count();
        $success = (clone $baseQuery)->where('success', true)->count();

        return $total > 0 ? round(($success / $total) * 100) : 0;
    }

    private function progressPercentage(
        int $loggedSets,
        int $expectedSets,
        int $completedExercises,
        int $totalExercises
    ): int {
        if ($expectedSets > 0) {
            return min(100, round(($loggedSets / $expectedSets) * 100));
        }

        if ($totalExercises > 0) {
            return min(100, round(($completedExercises / $totalExercises) * 100));
        }

        return 0;
    }

    private function performanceScore(int $successPercentage, int $loggedSets, int $expectedSets): int
    {
        $completionWeight = $expectedSets > 0 ? min(1, $loggedSets / $expectedSets) : 0;

        return (int) round(($successPercentage * 0.75) + ($completionWeight * 25));
    }

    private function feedbackForScore(int $successPercentage): string
    {
        return match (true) {
            $successPercentage >= 90 => 'Excellent Performance',
            $successPercentage >= 75 => 'Great Effort',
            $successPercentage > 0 => 'Keep Improving',
            default => 'Start logging your sets',
        };
    }

    private function estimatedDurationMinutes(int $workoutId): int
    {
        $items = DB::table('workout_exercises')
            ->where('workout_id', $workoutId)
            ->get(['sets', 'duration', 'rest_seconds']);
        $seconds = 0;

        foreach ($items as $item) {
            $workSeconds = $item->duration ? (int) $item->duration : 40;
            $seconds += ((int) $item->sets * $workSeconds)
                + (max((int) $item->sets - 1, 0) * (int) $item->rest_seconds);
        }

        return max(5, (int) ceil($seconds / 60));
    }

    private function workoutTitle(Workout $workout): string
    {
        return $workout->title
            ?? $workout->name
            ?? 'Workout Day '.$workout->day_number;
    }
}
