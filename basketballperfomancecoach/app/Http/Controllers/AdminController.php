<?php

namespace App\Http\Controllers;

use App\Models\CoachReview;
use App\Models\Exercise;
use App\Models\User;
use App\Models\Workout;
use App\Models\WorkoutRecording;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class AdminController extends Controller
{
    private const ROLES = ['athlete', 'coach', 'admin'];

    public function index(Request $request)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $role = strtolower((string) $request->query('role', 'all'));
        $search = trim((string) $request->query('search', ''));

        $users = User::query()
            ->when(in_array($role, self::ROLES, true), fn ($query) => $query->where('role', $role))
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($inner) use ($search) {
                    $inner->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('training_level', 'like', "%{$search}%");
                });
            })
            ->orderBy('role')
            ->orderBy('name')
            ->get()
            ->map(fn (User $user) => $this->userPayload($user))
            ->values();

        return response()->json([
            'success' => true,
            'data' => $users,
        ]);
    }

    public function store(Request $request)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $validated = $this->validatedUserData($request, true);
        $role = strtolower($validated['role']);

        $user = User::create([
            ...$this->profileData($validated),
            'email' => strtolower($validated['email']),
            'role' => $role,
            'password' => Hash::make($validated['password']),
            'personalization_completed' => $this->isPersonalized($validated, $role),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User berhasil dibuat',
            'data' => $this->userPayload($user->fresh()),
        ], 201);
    }

    public function show(Request $request, $id)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $user = User::find($id);

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->userPayload($user),
        ]);
    }

    public function update(Request $request, $id)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $user = User::find($id);

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        $validated = $this->validatedUserData($request, false, (int) $user->id);
        $role = strtolower($validated['role'] ?? $user->role ?? 'athlete');
        $updates = [
            ...$this->profileData($validated, $user),
            'role' => $role,
            'personalization_completed' => $this->isPersonalized($validated, $role, $user),
        ];

        if (isset($validated['email'])) {
            $updates['email'] = strtolower($validated['email']);
        }

        if (! empty($validated['password'])) {
            $updates['password'] = Hash::make($validated['password']);
        }

        $user->update($updates);

        return response()->json([
            'success' => true,
            'message' => 'User berhasil diperbarui',
            'data' => $this->userPayload($user->fresh()),
        ]);
    }

    public function destroy(Request $request, $id)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $user = User::find($id);

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        if ((int) $request->user()->id === (int) $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Admin tidak bisa menghapus akun yang sedang dipakai.',
            ], 422);
        }

        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'User berhasil dihapus',
        ]);
    }

    public function programs(Request $request)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $search = trim((string) $request->query('search', ''));

        $programs = Workout::query()
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($inner) use ($search) {
                    $inner->where('title', 'like', "%{$search}%")
                        ->orWhere('name', 'like', "%{$search}%")
                        ->orWhere('level', 'like', "%{$search}%")
                        ->orWhere('day_number', $search);
                });
            })
            ->orderBy('day_number')
            ->get()
            ->map(fn (Workout $workout) => $this->programPayload($workout, true))
            ->values();

        return response()->json([
            'success' => true,
            'data' => $programs,
        ]);
    }

    public function storeProgram(Request $request)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $validated = $this->validatedProgramData($request);

        $workout = Workout::create([
            'title' => $validated['title'],
            'name' => $validated['name'] ?? $validated['title'],
            'level' => $validated['level'],
            'day_number' => (int) $validated['day_number'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Program berhasil dibuat',
            'data' => $this->programPayload($workout->fresh(), true),
        ], 201);
    }

    public function showProgram(Request $request, $id)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $workout = Workout::find($id);

        if (! $workout) {
            return response()->json([
                'success' => false,
                'message' => 'Program tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->programPayload($workout, true),
        ]);
    }

    public function updateProgram(Request $request, $id)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $workout = Workout::find($id);

        if (! $workout) {
            return response()->json([
                'success' => false,
                'message' => 'Program tidak ditemukan',
            ], 404);
        }

        $validated = $this->validatedProgramData($request, (int) $workout->id);
        $workout->update([
            'title' => $validated['title'],
            'name' => $validated['name'] ?? $validated['title'],
            'level' => $validated['level'],
            'day_number' => (int) $validated['day_number'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Program berhasil diperbarui',
            'data' => $this->programPayload($workout->fresh(), true),
        ]);
    }

    public function destroyProgram(Request $request, $id)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $workout = Workout::find($id);

        if (! $workout) {
            return response()->json([
                'success' => false,
                'message' => 'Program tidak ditemukan',
            ], 404);
        }

        DB::table('workout_exercises')->where('workout_id', (int) $workout->id)->delete();
        $workout->delete();

        return response()->json([
            'success' => true,
            'message' => 'Program berhasil dihapus',
        ]);
    }

    public function storeProgramExercise(Request $request, $programId)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $workout = Workout::find($programId);

        if (! $workout) {
            return response()->json([
                'success' => false,
                'message' => 'Program tidak ditemukan',
            ], 404);
        }

        $validated = $this->validatedProgramExerciseData($request);

        $exercise = Exercise::create([
            'name' => $validated['name'],
            'type' => $validated['type'] ?? 'training',
            'video' => $validated['video_url'] ?? null,
            'video_url' => $validated['video_url'] ?? null,
        ]);

        $pivot = [
            'workout_id' => (int) $workout->id,
            'exercise_id' => (int) $exercise->id,
            'sets' => (int) $validated['sets'],
            'reps' => $validated['reps'],
            'duration' => $validated['duration'] ?? null,
            'rest_seconds' => (int) $validated['rest_seconds'],
        ];

        if (Schema::hasColumn('workout_exercises', 'video_url')) {
            $pivot['video_url'] = $validated['video_url'] ?? null;
        }

        DB::table('workout_exercises')->insert($pivot);

        return response()->json([
            'success' => true,
            'message' => 'Exercise program berhasil ditambahkan',
            'data' => $this->programPayload($workout->fresh(), true),
        ], 201);
    }

    public function updateProgramExercise(Request $request, $workoutExerciseId)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $pivot = DB::table('workout_exercises')->where('id', $workoutExerciseId)->first();

        if (! $pivot) {
            return response()->json([
                'success' => false,
                'message' => 'Exercise program tidak ditemukan',
            ], 404);
        }

        $validated = $this->validatedProgramExerciseData($request);
        $exercise = Exercise::find($pivot->exercise_id);

        if ($exercise) {
            $exercise->update([
                'name' => $validated['name'],
                'type' => $validated['type'] ?? 'training',
                'video' => $validated['video_url'] ?? null,
                'video_url' => $validated['video_url'] ?? null,
            ]);
        }

        $updates = [
            'sets' => (int) $validated['sets'],
            'reps' => $validated['reps'],
            'duration' => $validated['duration'] ?? null,
            'rest_seconds' => (int) $validated['rest_seconds'],
        ];

        if (Schema::hasColumn('workout_exercises', 'video_url')) {
            $updates['video_url'] = $validated['video_url'] ?? null;
        }

        DB::table('workout_exercises')->where('id', $workoutExerciseId)->update($updates);

        return response()->json([
            'success' => true,
            'message' => 'Exercise program berhasil diperbarui',
            'data' => $this->programPayload(Workout::find($pivot->workout_id), true),
        ]);
    }

    public function destroyProgramExercise(Request $request, $workoutExerciseId)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $pivot = DB::table('workout_exercises')->where('id', $workoutExerciseId)->first();

        if (! $pivot) {
            return response()->json([
                'success' => false,
                'message' => 'Exercise program tidak ditemukan',
            ], 404);
        }

        DB::table('workout_exercises')->where('id', $workoutExerciseId)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Exercise program berhasil dihapus',
            'data' => $this->programPayload(Workout::find($pivot->workout_id), true),
        ]);
    }

    public function videos(Request $request)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $search = trim((string) $request->query('search', ''));

        $videos = $this->videoQuery()
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($inner) use ($search) {
                    $inner->where('workouts.title', 'like', "%{$search}%")
                        ->orWhere('workouts.name', 'like', "%{$search}%")
                        ->orWhere('workouts.level', 'like', "%{$search}%")
                        ->orWhere('exercises.name', 'like', "%{$search}%")
                        ->orWhere('exercises.type', 'like', "%{$search}%")
                        ->orWhere('exercises.video', 'like', "%{$search}%");

                    if (Schema::hasColumn('exercises', 'video_url')) {
                        $inner->orWhere('exercises.video_url', 'like', "%{$search}%");
                    }

                    if (is_numeric($search)) {
                        $inner->orWhere('workouts.day_number', (int) $search);
                    }

                    if (Schema::hasColumn('workout_exercises', 'video_url')) {
                        $inner->orWhere('workout_exercises.video_url', 'like', "%{$search}%");
                    }
                });
            })
            ->orderBy('workouts.day_number')
            ->orderBy('workout_exercises.id')
            ->get()
            ->map(fn ($video) => $this->videoPayload($video))
            ->values();

        return response()->json([
            'success' => true,
            'data' => $videos,
        ]);
    }

    public function storeVideo(Request $request)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $validated = $this->validatedVideoData($request);
        $this->syncExerciseVideo((int) $validated['workout_exercise_id'], $validated['video_url']);
        $video = $this->videoQuery()
            ->where('workout_exercises.id', (int) $validated['workout_exercise_id'])
            ->first();

        return response()->json([
            'success' => true,
            'message' => 'Video latihan berhasil disimpan',
            'data' => $this->videoPayload($video),
        ], 201);
    }

    public function showVideo(Request $request, $id)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $video = $this->videoQuery()->where('workout_exercises.id', $id)->first();

        if (! $video) {
            return response()->json([
                'success' => false,
                'message' => 'Video latihan tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->videoPayload($video),
        ]);
    }

    public function updateVideo(Request $request, $id)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $video = $this->videoQuery()->where('workout_exercises.id', $id)->first();

        if (! $video) {
            return response()->json([
                'success' => false,
                'message' => 'Video latihan tidak ditemukan',
            ], 404);
        }

        $validated = $this->validatedVideoData($request, (int) $id);
        $this->syncExerciseVideo((int) $validated['workout_exercise_id'], $validated['video_url']);
        $video = $this->videoQuery()->where('workout_exercises.id', $id)->first();

        return response()->json([
            'success' => true,
            'message' => 'Video latihan berhasil diperbarui',
            'data' => $this->videoPayload($video),
        ]);
    }

    public function destroyVideo(Request $request, $id)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $video = $this->videoQuery()->where('workout_exercises.id', $id)->first();

        if (! $video) {
            return response()->json([
                'success' => false,
                'message' => 'Video latihan tidak ditemukan',
            ], 404);
        }

        $this->syncExerciseVideo((int) $id, null);
        $video = $this->videoQuery()->where('workout_exercises.id', $id)->first();

        return response()->json([
            'success' => true,
            'message' => 'Video latihan berhasil dihapus',
            'data' => $this->videoPayload($video),
        ]);
    }

    public function athleteVideos(Request $request)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $search = trim((string) $request->query('search', ''));
        $status = strtolower((string) $request->query('status', 'all'));

        $query = $this->athleteVideoQuery();

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

        if ($search !== '') {
            $query->where(function ($inner) use ($search) {
                $inner->where('users.name', 'like', "%{$search}%")
                    ->orWhere('users.email', 'like', "%{$search}%")
                    ->orWhere('workouts.title', 'like', "%{$search}%")
                    ->orWhere('workouts.name', 'like', "%{$search}%")
                    ->orWhere('workout_recordings.file_url', 'like', "%{$search}%")
                    ->orWhere('workout_recordings.mime_type', 'like', "%{$search}%");

                if (is_numeric($search)) {
                    $inner->orWhere('workout_recordings.day_number', (int) $search)
                        ->orWhere('workout_recordings.user_id', (int) $search);
                }
            });
        }

        $videos = $query
            ->orderByDesc('workout_recordings.created_at')
            ->get()
            ->map(fn ($recording) => $this->athleteVideoPayload($recording))
            ->values();

        return response()->json([
            'success' => true,
            'data' => $videos,
        ]);
    }

    public function showAthleteVideo(Request $request, $id)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $recording = $this->athleteVideoQuery()
            ->where('workout_recordings.id', $id)
            ->first();

        if (! $recording) {
            return response()->json([
                'success' => false,
                'message' => 'Video atlet tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->athleteVideoPayload($recording),
        ]);
    }

    public function destroyAthleteVideo(Request $request, $id)
    {
        if ($denied = $this->denyUnlessAdmin($request)) {
            return $denied;
        }

        $recording = WorkoutRecording::find($id);

        if (! $recording) {
            return response()->json([
                'success' => false,
                'message' => 'Video atlet tidak ditemukan',
            ], 404);
        }

        $filePath = $recording->file_path;

        DB::transaction(function () use ($recording) {
            CoachReview::where('workout_recording_id', (int) $recording->id)->delete();
            $recording->delete();
        });

        if ($filePath) {
            Storage::disk('public')->delete($filePath);
        }

        return response()->json([
            'success' => true,
            'message' => 'Video atlet berhasil dihapus',
        ]);
    }

    private function validatedUserData(Request $request, bool $creating, ?int $userId = null): array
    {
        $passwordRules = $creating
            ? ['required', 'string', 'min:8', 'regex:/^(?=.*[A-Za-z])(?=.*\d).+$/', 'confirmed']
            : ['nullable', 'string', 'min:8', 'regex:/^(?=.*[A-Za-z])(?=.*\d).+$/', 'confirmed'];

        return $request->validate([
            'name' => [$creating ? 'required' : 'sometimes', 'string', 'max:255'],
            'email' => [
                $creating ? 'required' : 'sometimes',
                'email',
                'max:255',
                'ends_with:@gmail.com',
                Rule::unique('users', 'email')->ignore($userId),
            ],
            'role' => [$creating ? 'required' : 'sometimes', 'string', Rule::in(self::ROLES)],
            'password' => $passwordRules,
            'height' => ['nullable', 'numeric', 'min:80', 'max:250'],
            'weight' => ['nullable', 'numeric', 'min:25', 'max:250'],
            'age' => ['nullable', 'integer', 'min:8', 'max:80'],
            'training_level' => ['nullable', Rule::in(['Beginner', 'Intermediate'])],
        ], [
            'email.ends_with' => 'Email wajib menggunakan Gmail',
            'email.unique' => 'Email sudah terdaftar',
            'password.confirmed' => 'Konfirmasi password tidak cocok',
            'password.regex' => 'Password wajib berisi huruf dan angka',
        ]);
    }

    private function validatedProgramData(Request $request, ?int $programId = null): array
    {
        return $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'name' => ['nullable', 'string', 'max:255'],
            'level' => ['required', 'string', 'max:64'],
            'day_number' => [
                'required',
                'integer',
                'min:1',
                'max:365',
                Rule::unique('workouts', 'day_number')->ignore($programId),
            ],
        ], [
            'day_number.unique' => 'Day number sudah dipakai program lain',
        ]);
    }

    private function validatedProgramExerciseData(Request $request): array
    {
        return $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'type' => ['nullable', 'string', 'max:64'],
            'video_url' => $this->videoSourceRules(),
            'sets' => ['required', 'integer', 'min:1', 'max:20'],
            'reps' => ['required', 'string', 'max:255'],
            'duration' => ['nullable', 'integer', 'min:1', 'max:3600'],
            'rest_seconds' => ['required', 'integer', 'min:0', 'max:3600'],
        ]);
    }

    private function validatedVideoData(Request $request, ?int $workoutExerciseId = null): array
    {
        $validated = $request->validate([
            'workout_exercise_id' => [
                $workoutExerciseId ? 'nullable' : 'required',
                'integer',
                'exists:workout_exercises,id',
            ],
            'video_url' => $this->videoSourceRules(),
            'video' => ['nullable', 'file', 'mimes:mp4,mov,m4v,webm,avi,mkv', 'max:512000'],
        ]);

        $validated['workout_exercise_id'] = $workoutExerciseId
            ?: (int) $validated['workout_exercise_id'];

        if ($request->hasFile('video')) {
            $validated['video_url'] = $this->storeExerciseVideoFile(
                $request->file('video'),
                (int) $validated['workout_exercise_id']
            );

            return $validated;
        }

        $validated['video_url'] = trim((string) ($validated['video_url'] ?? ''));

        if ($validated['video_url'] === '') {
            throw \Illuminate\Validation\ValidationException::withMessages([
                'video_url' => 'Video URL atau file video wajib diisi.',
            ]);
        }

        return $validated;
    }

    private function storeExerciseVideoFile($file, int $workoutExerciseId): string
    {
        $extension = $file->guessExtension()
            ?: $file->getClientOriginalExtension()
            ?: 'mp4';
        $extension = strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $extension) ?: 'mp4');
        $path = $file->storeAs(
            'videos/admin/exercises/'.$workoutExerciseId,
            'exercise-'.$workoutExerciseId.'-'.now()->format('YmdHis').'.'.$extension,
            'public'
        );

        return Storage::url($path);
    }

    private function videoSourceRules(): array
    {
        return [
            'nullable',
            'string',
            'max:2048',
            function (string $attribute, mixed $value, \Closure $fail): void {
                $source = trim((string) $value);

                if ($source === ''
                    || str_starts_with($source, '/storage/')
                    || str_starts_with($source, '/videos/')) {
                    return;
                }

                $scheme = strtolower((string) parse_url($source, PHP_URL_SCHEME));
                if (! in_array($scheme, ['http', 'https'], true)
                    || filter_var($source, FILTER_VALIDATE_URL) === false) {
                    $fail('Video URL harus berupa http(s), /storage/..., atau /videos/....');
                }
            },
        ];
    }

    private function profileData(array $validated, ?User $fallback = null): array
    {
        return [
            'name' => $validated['name'] ?? $fallback?->name,
            'height' => array_key_exists('height', $validated) ? $validated['height'] : $fallback?->height,
            'weight' => array_key_exists('weight', $validated) ? $validated['weight'] : $fallback?->weight,
            'age' => array_key_exists('age', $validated) ? $validated['age'] : $fallback?->age,
            'training_level' => array_key_exists('training_level', $validated)
                ? $validated['training_level']
                : $fallback?->training_level,
        ];
    }

    private function isPersonalized(array $validated, string $role, ?User $fallback = null): bool
    {
        if ($role !== 'athlete') {
            return true;
        }

        $height = $validated['height'] ?? $fallback?->height;
        $weight = $validated['weight'] ?? $fallback?->weight;
        $age = $validated['age'] ?? $fallback?->age;
        $level = $validated['training_level'] ?? $fallback?->training_level;

        return filled($height) && filled($weight) && filled($age) && filled($level);
    }

    private function userPayload(User $user): array
    {
        return [
            'id' => (int) $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role ?? 'athlete',
            'height' => $user->height ? (float) $user->height : null,
            'weight' => $user->weight ? (float) $user->weight : null,
            'age' => $user->age ? (int) $user->age : null,
            'training_level' => $user->training_level,
            'personalization_completed' => (bool) $user->personalization_completed,
            'created_at' => optional($user->created_at)->toISOString(),
            'updated_at' => optional($user->updated_at)->toISOString(),
        ];
    }

    private function programPayload(?Workout $workout, bool $withExercises = false): array
    {
        if (! $workout) {
            return [];
        }

        $payload = [
            'id' => (int) $workout->id,
            'title' => $workout->title,
            'name' => $workout->name,
            'level' => $workout->level,
            'day_number' => (int) $workout->day_number,
            'exercise_count' => (int) DB::table('workout_exercises')
                ->where('workout_id', (int) $workout->id)
                ->count(),
        ];

        if ($withExercises) {
            $payload['exercises'] = $this->programExercises((int) $workout->id);
        }

        return $payload;
    }

    private function programExercises(int $workoutId)
    {
        $hasWorkoutVideoUrl = Schema::hasColumn('workout_exercises', 'video_url');
        $hasExerciseVideoUrl = Schema::hasColumn('exercises', 'video_url');
        $videoSelect = match (true) {
            $hasWorkoutVideoUrl && $hasExerciseVideoUrl => DB::raw('COALESCE(workout_exercises.video_url, exercises.video_url, exercises.video) as video_url'),
            $hasWorkoutVideoUrl => DB::raw('COALESCE(workout_exercises.video_url, exercises.video) as video_url'),
            $hasExerciseVideoUrl => DB::raw('COALESCE(exercises.video_url, exercises.video) as video_url'),
            default => DB::raw('exercises.video as video_url'),
        };

        return DB::table('workout_exercises')
            ->join('exercises', 'exercises.id', '=', 'workout_exercises.exercise_id')
            ->where('workout_exercises.workout_id', $workoutId)
            ->orderBy('workout_exercises.id')
            ->select([
                DB::raw('workout_exercises.id as workout_exercise_id'),
                'workout_exercises.exercise_id',
                'exercises.name',
                'exercises.type',
                $videoSelect,
                'workout_exercises.sets',
                'workout_exercises.reps',
                'workout_exercises.duration',
                'workout_exercises.rest_seconds',
            ])
            ->get()
            ->map(fn ($exercise) => [
                'workout_exercise_id' => (int) $exercise->workout_exercise_id,
                'exercise_id' => (int) $exercise->exercise_id,
                'name' => $exercise->name,
                'type' => $exercise->type,
                'video_url' => $exercise->video_url,
                'sets' => (int) $exercise->sets,
                'reps' => $exercise->reps,
                'duration' => $exercise->duration === null ? null : (int) $exercise->duration,
                'rest_seconds' => (int) $exercise->rest_seconds,
            ])
            ->values();
    }

    private function videoQuery()
    {
        $hasWorkoutVideoUrl = Schema::hasColumn('workout_exercises', 'video_url');
        $hasExerciseVideoUrl = Schema::hasColumn('exercises', 'video_url');
        $videoSelect = match (true) {
            $hasWorkoutVideoUrl && $hasExerciseVideoUrl => DB::raw('COALESCE(workout_exercises.video_url, exercises.video_url, exercises.video) as video_url'),
            $hasWorkoutVideoUrl => DB::raw('COALESCE(workout_exercises.video_url, exercises.video) as video_url'),
            $hasExerciseVideoUrl => DB::raw('COALESCE(exercises.video_url, exercises.video) as video_url'),
            default => DB::raw('exercises.video as video_url'),
        };

        return DB::table('workout_exercises')
            ->join('workouts', 'workouts.id', '=', 'workout_exercises.workout_id')
            ->join('exercises', 'exercises.id', '=', 'workout_exercises.exercise_id')
            ->select([
                DB::raw('workout_exercises.id as id'),
                DB::raw('workout_exercises.id as workout_exercise_id'),
                'workout_exercises.exercise_id',
                'workout_exercises.workout_id',
                'workout_exercises.sets',
                'workout_exercises.reps',
                'workout_exercises.duration',
                'workout_exercises.rest_seconds',
                'workouts.title as workout_title',
                'workouts.name as workout_name',
                'workouts.level',
                'workouts.day_number',
                'exercises.name as exercise_name',
                'exercises.type as exercise_type',
                $videoSelect,
            ]);
    }

    private function syncExerciseVideo(int $workoutExerciseId, ?string $videoUrl): void
    {
        $videoUrl = $videoUrl === null ? null : trim($videoUrl);
        $videoUrl = $videoUrl === '' ? null : $videoUrl;
        $pivot = DB::table('workout_exercises')->where('id', $workoutExerciseId)->first();

        if (! $pivot) {
            return;
        }

        if (Schema::hasColumn('workout_exercises', 'video_url')) {
            DB::table('workout_exercises')
                ->where('id', $workoutExerciseId)
                ->update(['video_url' => $videoUrl]);
        }

        $exercise = Exercise::find($pivot->exercise_id);

        if ($exercise) {
            $exerciseUpdates = [
                'video' => $videoUrl,
            ];

            if (Schema::hasColumn('exercises', 'video_url')) {
                $exerciseUpdates['video_url'] = $videoUrl;
            }

            $exercise->update($exerciseUpdates);
        }
    }

    private function videoPayload($video): array
    {
        if (! $video) {
            return [];
        }

        return [
            'id' => (int) $video->workout_exercise_id,
            'workout_exercise_id' => (int) $video->workout_exercise_id,
            'exercise_id' => (int) $video->exercise_id,
            'workout_id' => (int) $video->workout_id,
            'workout_title' => $video->workout_title ?: ($video->workout_name ?: 'Day '.$video->day_number),
            'program_title' => $video->workout_title ?: ($video->workout_name ?: 'Day '.$video->day_number),
            'day_number' => (int) $video->day_number,
            'level' => $video->level,
            'exercise_name' => $video->exercise_name,
            'exercise_type' => $video->exercise_type ?: 'training',
            'video_url' => $video->video_url,
            'file_url' => $video->video_url,
            'sets' => (int) $video->sets,
            'reps' => $video->reps,
            'duration' => $video->duration === null ? null : (int) $video->duration,
            'rest_seconds' => (int) $video->rest_seconds,
            'has_video' => filled($video->video_url),
        ];
    }

    private function athleteVideoQuery()
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
                'workouts.title as workout_title',
                'workouts.name as workout_name',
                'coach_reviews.status as review_status',
                'coach_reviews.score as review_score',
                'coach_reviews.feedback as review_feedback',
                'coach_reviews.reviewed_at as reviewed_at',
            ]);
    }

    private function athleteVideoPayload($recording): array
    {
        if (! $recording) {
            return [];
        }

        return [
            'id' => (int) $recording->id,
            'user_id' => (int) $recording->user_id,
            'athlete_name' => $recording->athlete_name,
            'athlete_email' => $recording->athlete_email,
            'workout_id' => (int) $recording->workout_id,
            'day_number' => (int) $recording->day_number,
            'workout_title' => $recording->workout_title
                ?: ($recording->workout_name ?: 'Day '.$recording->day_number),
            'uploaded_at' => $this->dateToIso($recording->created_at),
            'recorded_at' => $this->dateToIso($recording->recorded_at),
            'status' => $recording->review_status ?: 'pending',
            'score' => $recording->review_score === null
                ? null
                : (int) $recording->review_score,
            'feedback' => $recording->review_feedback,
            'reviewed_at' => $this->dateToIso($recording->reviewed_at),
            'duration_seconds' => $recording->duration_seconds === null
                ? null
                : (int) $recording->duration_seconds,
            'mime_type' => $recording->mime_type,
            'file_size' => $recording->file_size === null
                ? null
                : (int) $recording->file_size,
            'video_url' => $this->absoluteUrl($recording->file_url),
            'file_url' => $this->absoluteUrl($recording->file_url),
        ];
    }

    private function dateToIso($value): ?string
    {
        if (! $value) {
            return null;
        }

        return \Illuminate\Support\Carbon::parse($value)->toISOString();
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

    private function denyUnlessAdmin(Request $request)
    {
        if (strtolower($request->user()?->role ?? '') === 'admin') {
            return null;
        }

        return response()->json([
            'success' => false,
            'message' => 'Akses hanya untuk admin',
        ], 403);
    }
}
