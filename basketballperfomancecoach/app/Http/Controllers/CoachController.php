<?php

namespace App\Http\Controllers;

use App\Models\CoachReview;
use App\Models\User;
use App\Models\UserWorkoutLog;
use App\Models\Workout;
use App\Models\WorkoutRecording;
use App\Notifications\CoachReviewSubmitted;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class CoachController extends Controller
{
    public function dashboard(Request $request)
    {
        if ($denied = $this->denyUnlessCoach($request)) {
            return $denied;
        }

        $athletes = $this->athleteQuery()->get();
        $athletePayloads = $athletes
            ->map(fn (User $user) => $this->athletePayload($user))
            ->values();
        $totalAthletes = $athletePayloads->count();
        $activeSince = now()->subDays(7);
        $activeAthletes = $athletePayloads
            ->filter(function (array $athlete) use ($activeSince) {
                return $athlete['last_activity_at'] !== null
                    && Carbon::parse($athlete['last_activity_at'])->greaterThanOrEqualTo($activeSince);
            })
            ->count();
        $pendingReviews = $this->pendingReviewQuery()->count();
        $averageConsistency = $totalAthletes > 0
            ? (int) round($athletePayloads->avg('consistency_progress'))
            : 0;
        $athleteRankings = $this->athleteRankings($athletePayloads);

        return response()->json([
            'success' => true,
            'data' => [
                'total_athletes' => $totalAthletes,
                'active_athletes' => $activeAthletes,
                'pending_reviews' => $pendingReviews,
                'average_consistency' => $averageConsistency,
                'athlete_rankings' => $athleteRankings,
            ],
        ]);
    }

    public function athletes(Request $request)
    {
        if ($denied = $this->denyUnlessCoach($request)) {
            return $denied;
        }

        $athletes = $this->athleteQuery()
            ->orderBy('name')
            ->get()
            ->map(fn (User $user) => $this->athletePayload($user))
            ->values();

        return response()->json([
            'success' => true,
            'data' => $athletes,
        ]);
    }

    public function athlete(Request $request, $userId)
    {
        if ($denied = $this->denyUnlessCoach($request)) {
            return $denied;
        }

        $athlete = $this->athleteQuery()
            ->where('id', $userId)
            ->first();

        if (! $athlete) {
            return response()->json([
                'success' => false,
                'message' => 'Atlet tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'athlete' => $this->athletePayload($athlete),
                'recordings' => $this->recordingQuery()
                    ->where('workout_recordings.user_id', (int) $userId)
                    ->orderByDesc('workout_recordings.created_at')
                    ->get()
                    ->map(fn ($recording) => $this->recordingPayload($recording))
                    ->values(),
            ],
        ]);
    }

    public function recordings(Request $request)
    {
        if ($denied = $this->denyUnlessCoach($request)) {
            return $denied;
        }

        $status = $request->query('status', 'all');
        $query = $this->recordingQuery()
            ->orderByDesc('workout_recordings.created_at');

        if ($status !== 'all') {
            if ($status === 'pending') {
                $query->where(function ($inner) {
                    $inner->whereNull('coach_reviews.status')
                        ->orWhere('coach_reviews.status', 'pending');
                });
            } else {
                $query->where('coach_reviews.status', $status);
            }
        }

        return response()->json([
            'success' => true,
            'data' => $query
                ->get()
                ->map(fn ($recording) => $this->recordingPayload($recording))
                ->values(),
        ]);
    }

    public function review(Request $request, $recordingId)
    {
        if ($denied = $this->denyUnlessCoach($request)) {
            return $denied;
        }

        $validated = $request->validate([
            'status' => [
                'required',
                Rule::in(['approved', 'needs_revision', 'rejected']),
            ],
            'score' => ['required', 'integer', 'min:0', 'max:100'],
            'feedback' => ['required', 'string', 'max:2000'],
        ]);
        $recording = WorkoutRecording::find($recordingId);

        if (! $recording) {
            return response()->json([
                'success' => false,
                'message' => 'Recording tidak ditemukan',
            ], 404);
        }

        $status = $validated['status'] === 'rejected'
            ? 'needs_revision'
            : $validated['status'];
        $review = CoachReview::updateOrCreate(
            [
                'workout_recording_id' => (int) $recording->id,
            ],
            [
                'user_id' => (int) $recording->user_id,
                'workout_id' => (int) $recording->workout_id,
                'day_number' => (int) $recording->day_number,
                'coach_id' => $request->user()?->id,
                'status' => $status,
                'score' => (int) $validated['score'],
                'feedback' => trim($validated['feedback']),
                'reviewed_at' => now(),
            ]
        );
        $athlete = User::find($recording->user_id);
        $workoutTitle = Workout::find($recording->workout_id)?->title
            ?: 'Day '.$recording->day_number;

        if ($athlete) {
            $athlete->unreadNotifications
                ->where('type', CoachReviewSubmitted::class)
                ->filter(
                    fn ($notification) => (int) ($notification->data['review_id'] ?? 0)
                        === (int) $review->id
                )
                ->each->markAsRead();

            $athlete->notify(new CoachReviewSubmitted($review, $workoutTitle));
        }

        return response()->json([
            'success' => true,
            'message' => 'Review coach berhasil disimpan',
            'data' => [
                'review' => $review,
                'athlete' => $this->athletePayload($athlete),
                'recording' => $this->recordingPayload(
                    $this->recordingQuery()
                        ->where('workout_recordings.id', (int) $recording->id)
                        ->first()
                ),
            ],
        ]);
    }

    private function athleteQuery()
    {
        $query = User::query();

        if (Schema::hasColumn('users', 'role')) {
            $query->where(function ($inner) {
                $inner->whereNull('role')
                    ->orWhere('role', 'athlete');
            });
        }

        return $query;
    }

    private function denyUnlessCoach(Request $request)
    {
        $role = strtolower($request->user()?->role ?? '');

        if ($role === 'coach') {
            return null;
        }

        return response()->json([
            'success' => false,
            'message' => 'Akses hanya untuk coach',
        ], 403);
    }

    private function athletePayload(?User $user): array
    {
        if (! $user) {
            return [];
        }

        $pendingReviews = $this->pendingReviewQuery()
            ->where('workout_recordings.user_id', (int) $user->id)
            ->count();
        $performance = $this->performanceProgress((int) $user->id);
        $reviewCount = $this->coachReviewCount((int) $user->id);
        $programStats = $this->programStats($user);
        $rankingScore = $this->rankingScore($programStats['consistency_progress'], $performance);

        return [
            'id' => (int) $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'training_level' => $user->training_level,
            'height' => $user->height ? (float) $user->height : null,
            'weight' => $user->weight ? (float) $user->weight : null,
            'age' => $user->age ? (int) $user->age : null,
            'consistency_progress' => $programStats['consistency_progress'],
            'performance_progress' => $performance,
            'coach_score' => $performance,
            'coach_review_count' => $reviewCount,
            'ranking_score' => $rankingScore,
            'pending_reviews' => $pendingReviews,
            'completed_days' => $programStats['completed_days'],
            'recorded_days' => $programStats['recorded_days'],
            'total_program_days' => $programStats['total_program_days'],
            'program_days' => $programStats['program_days'],
            'last_activity_at' => optional($this->lastActivityAt((int) $user->id))->toISOString(),
            'status' => $pendingReviews > 0 || ($performance > 0 && $performance < 70)
                ? 'needs_attention'
                : 'active',
        ];
    }

    private function recordingQuery()
    {
        return DB::table('workout_recordings')
            ->leftJoin('users', 'users.id', '=', 'workout_recordings.user_id')
            ->leftJoin('workouts', 'workouts.id', '=', 'workout_recordings.workout_id')
            ->leftJoin(
                'coach_reviews',
                'coach_reviews.workout_recording_id',
                '=',
                'workout_recordings.id'
            )
            ->select([
                'workout_recordings.*',
                'users.name as athlete_name',
                'users.email as athlete_email',
                'users.training_level as athlete_training_level',
                'workouts.title as workout_title',
                'workouts.name as workout_name',
                'workouts.level as workout_level',
                'coach_reviews.status as review_status',
                'coach_reviews.score as review_score',
                'coach_reviews.feedback as review_feedback',
                'coach_reviews.reviewed_at as reviewed_at',
            ]);
    }

    private function recordingPayload($recording): array
    {
        return [
            'id' => (int) $recording->id,
            'user_id' => (int) $recording->user_id,
            'athlete_name' => $recording->athlete_name,
            'athlete_email' => $recording->athlete_email,
            'athlete_training_level' => $recording->athlete_training_level,
            'workout_id' => (int) $recording->workout_id,
            'day_number' => (int) $recording->day_number,
            'workout_title' => $recording->workout_title
                ?: ($recording->workout_name ?: 'Day '.$recording->day_number),
            'workout_level' => $recording->workout_level,
            'uploaded_at' => $this->isoDateTime($recording->created_at),
            'recorded_at' => $this->isoDateTime($recording->recorded_at),
            'status' => $recording->review_status ?: 'pending',
            'score' => $recording->review_score === null
                ? null
                : (int) $recording->review_score,
            'feedback' => $recording->review_feedback,
            'reviewed_at' => $this->isoDateTime($recording->reviewed_at),
            'duration_seconds' => $recording->duration_seconds === null
                ? null
                : (int) $recording->duration_seconds,
            'mime_type' => $recording->mime_type,
            'file_size' => $recording->file_size === null
                ? null
                : (int) $recording->file_size,
            'video_url' => $this->absoluteUrl($recording->file_url),
        ];
    }

    private function pendingReviewQuery()
    {
        return DB::table('workout_recordings')
            ->leftJoin(
                'coach_reviews',
                'coach_reviews.workout_recording_id',
                '=',
                'workout_recordings.id'
            )
            ->where(function ($query) {
                $query->whereNull('coach_reviews.status')
                    ->orWhere('coach_reviews.status', 'pending');
            });
    }

    private function consistencyProgress(int $userId): int
    {
        $user = User::find($userId);

        return $user ? $this->programStats($user)['consistency_progress'] : 0;
    }

    private function programStats(User $user): array
    {
        $workouts = $this->programWorkouts($user);
        $workoutIds = $workouts->pluck('id')->map(fn ($id) => (int) $id)->all();
        $programDays = $workouts
            ->pluck('day_number')
            ->map(fn ($day) => (int) $day)
            ->filter(fn ($day) => $day > 0)
            ->unique()
            ->values()
            ->all();
        $totalProgramDays = count($programDays);
        $completedDays = $totalProgramDays > 0
            ? UserWorkoutLog::where('user_id', (int) $user->id)
                ->where('status', 'completed')
                ->whereIn('day_number', $programDays)
                ->distinct('day_number')
                ->count('day_number')
            : 0;
        $recordedDays = $totalProgramDays > 0
            ? WorkoutRecording::where('user_id', (int) $user->id)
                ->whereIn('workout_id', $workoutIds)
                ->whereIn('day_number', $programDays)
                ->distinct('day_number')
                ->count('day_number')
            : 0;
        $consistency = $totalProgramDays > 0
            ? min(100, (int) round((max($completedDays, $recordedDays) / $totalProgramDays) * 100))
            : 0;

        return [
            'completed_days' => $completedDays,
            'recorded_days' => $recordedDays,
            'total_program_days' => $totalProgramDays,
            'consistency_progress' => $consistency,
            'program_days' => $workouts
                ->groupBy('day_number')
                ->map(function ($dayWorkouts, $dayNumber) {
                    $workout = $dayWorkouts->first();

                    return [
                        'workout_id' => (int) $workout->id,
                        'workout_ids' => $dayWorkouts
                            ->pluck('id')
                            ->map(fn ($id) => (int) $id)
                            ->values()
                            ->all(),
                        'day_number' => (int) $dayNumber,
                        'title' => $workout->title ?: ($workout->name ?: 'Day '.$workout->day_number),
                        'level' => $workout->level,
                    ];
                })
                ->values()
                ->all(),
        ];
    }

    private function programWorkouts(User $user)
    {
        $level = trim((string) ($user->training_level ?: 'Beginner'));
        $matchedLevel = Workout::whereRaw('LOWER(level) = ?', [strtolower($level)])
            ->value('level')
            ?: Workout::whereRaw('LOWER(level) = ?', ['beginner'])->value('level');
        $query = Workout::query();

        if ($matchedLevel) {
            $query->whereRaw('LOWER(level) = ?', [strtolower($matchedLevel)]);
        } else {
            $query->whereRaw('1 = 0');
        }

        return $query
            ->orderBy('day_number')
            ->get(['id', 'title', 'name', 'level', 'day_number']);
    }

    private function performanceProgress(int $userId): int
    {
        $averageScore = CoachReview::where('user_id', $userId)
            ->whereIn('status', ['approved', 'needs_revision'])
            ->whereNotNull('score')
            ->avg('score');

        return $averageScore === null ? 0 : (int) round($averageScore);
    }

    private function coachReviewCount(int $userId): int
    {
        return CoachReview::where('user_id', $userId)
            ->whereIn('status', ['approved', 'needs_revision'])
            ->whereNotNull('score')
            ->count();
    }

    private function rankingScore(int $consistency, int $coachScore): int
    {
        return min(100, max(0, (int) round(($consistency + $coachScore) / 2)));
    }

    private function athleteRankings($athletes)
    {
        return collect($athletes)
            ->map(fn (array $athlete) => [
                'id' => (int) $athlete['id'],
                'name' => $athlete['name'],
                'email' => $athlete['email'],
                'training_level' => $athlete['training_level'],
                'consistency_progress' => (int) $athlete['consistency_progress'],
                'coach_score' => (int) $athlete['coach_score'],
                'coach_review_count' => (int) $athlete['coach_review_count'],
                'completed_days' => (int) $athlete['completed_days'],
                'total_program_days' => (int) $athlete['total_program_days'],
                'ranking_score' => (int) $athlete['ranking_score'],
            ])
            ->sort(function (array $left, array $right) {
                $scoreCompare = $right['ranking_score'] <=> $left['ranking_score'];

                if ($scoreCompare !== 0) {
                    return $scoreCompare;
                }

                $consistencyCompare = $right['consistency_progress'] <=> $left['consistency_progress'];

                if ($consistencyCompare !== 0) {
                    return $consistencyCompare;
                }

                $coachScoreCompare = $right['coach_score'] <=> $left['coach_score'];

                if ($coachScoreCompare !== 0) {
                    return $coachScoreCompare;
                }

                return strcmp((string) $left['name'], (string) $right['name']);
            })
            ->values()
            ->map(function (array $athlete, int $index) {
                $athlete['rank'] = $index + 1;

                return $athlete;
            })
            ->all();
    }

    private function lastActivityAt(int $userId)
    {
        $lastRecording = WorkoutRecording::where('user_id', $userId)
            ->latest('created_at')
            ->value('created_at');
        $lastCompletion = UserWorkoutLog::where('user_id', $userId)
            ->where('status', 'completed')
            ->latest('completed_at')
            ->value('completed_at');

        return collect([$lastRecording, $lastCompletion])
            ->filter()
            ->map(fn ($value) => $value instanceof Carbon ? $value : Carbon::parse($value))
            ->sortDesc()
            ->first();
    }

    private function isoDateTime($value): ?string
    {
        if (! $value) {
            return null;
        }

        return ($value instanceof Carbon ? $value : Carbon::parse($value))->toISOString();
    }

    private function absoluteUrl(?string $url): ?string
    {
        if (! $url) {
            return null;
        }

        $path = parse_url($url, PHP_URL_PATH);

        if ($path && str_starts_with($path, '/storage/')) {
            return request()->getSchemeAndHttpHost().$path;
        }

        if (str_starts_with($url, '/storage/')) {
            return request()->getSchemeAndHttpHost().$url;
        }

        if (str_starts_with($url, 'http://') || str_starts_with($url, 'https://')) {
            return $url;
        }

        return request()->getSchemeAndHttpHost().'/'.ltrim($url, '/');
    }
}
