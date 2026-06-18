<?php

namespace App\Http\Controllers;

use App\Models\CoachReview;
use App\Models\User;
use App\Models\UserWorkoutLog;
use App\Models\Workout;
use App\Models\WorkoutRecording;
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

        $athleteIds = $this->athleteQuery()->pluck('id');
        $totalAthletes = $athleteIds->count();
        $activeAthletes = $athleteIds
            ->filter(fn ($id) => $this->lastActivityAt((int) $id) !== null)
            ->count();
        $pendingReviews = $this->pendingReviewQuery()->count();
        $averagePerformance = $totalAthletes > 0
            ? (int) round($athleteIds
                ->map(fn ($id) => $this->performanceProgress((int) $id))
                ->avg())
            : 0;
        $averageConsistency = $totalAthletes > 0
            ? (int) round($athleteIds
                ->map(fn ($id) => $this->consistencyProgress((int) $id))
                ->avg())
            : 0;

        return response()->json([
            'success' => true,
            'data' => [
                'total_athletes' => $totalAthletes,
                'active_athletes' => $activeAthletes,
                'pending_reviews' => $pendingReviews,
                'average_performance' => $averagePerformance,
                'average_consistency' => $averageConsistency,
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
            'feedback' => ['nullable', 'string', 'max:2000'],
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
                'feedback' => $validated['feedback'] ?? null,
                'reviewed_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Review coach berhasil disimpan',
            'data' => [
                'review' => $review,
                'athlete' => $this->athletePayload(User::find($recording->user_id)),
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

        return [
            'id' => (int) $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'training_level' => $user->training_level,
            'height' => $user->height ? (float) $user->height : null,
            'weight' => $user->weight ? (float) $user->weight : null,
            'age' => $user->age ? (int) $user->age : null,
            'consistency_progress' => $this->consistencyProgress((int) $user->id),
            'performance_progress' => $performance,
            'pending_reviews' => $pendingReviews,
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
                'workouts.title as workout_title',
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
            'workout_id' => (int) $recording->workout_id,
            'day_number' => (int) $recording->day_number,
            'workout_title' => $recording->workout_title ?: 'Day '.$recording->day_number,
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
        $totalWorkouts = max(Workout::count(), 1);
        $completedDays = UserWorkoutLog::where('user_id', $userId)
            ->where('status', 'completed')
            ->distinct('day_number')
            ->count('day_number');
        $recordedDays = WorkoutRecording::where('user_id', $userId)
            ->distinct('day_number')
            ->count('day_number');

        return min(100, (int) round((max($completedDays, $recordedDays) / $totalWorkouts) * 100));
    }

    private function performanceProgress(int $userId): int
    {
        $averageScore = CoachReview::where('user_id', $userId)
            ->whereIn('status', ['approved', 'needs_revision'])
            ->whereNotNull('score')
            ->avg('score');

        return $averageScore === null ? 0 : (int) round($averageScore);
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
