<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AuthController extends Controller
{
    private const ATHLETE_PORTAL = 'athlete_app';
    private const STAFF_PORTALS = ['coach_web', 'admin_web', 'staff_web'];
    private const STAFF_ROLES = ['coach', 'admin'];

    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'email',
                'max:255',
                'ends_with:@gmail.com',
                'unique:users,email',
            ],
            'password' => [
                'required',
                'string',
                'min:8',
                'regex:/^(?=.*[A-Za-z])(?=.*\d).+$/',
                'confirmed',
            ],
            'role' => [
                'sometimes',
                'string',
                Rule::in(['athlete', 'coach', 'admin']),
            ],
            'portal' => [
                'sometimes',
                'string',
                Rule::in([self::ATHLETE_PORTAL, ...self::STAFF_PORTALS]),
            ],
        ], [
            'email.ends_with' => 'Please use a valid Gmail address',
            'email.unique' => 'Email already registered',
            'password.confirmed' => 'Password confirmation does not match',
            'password.regex' => 'Password must include letters and numbers',
        ]);
        $portal = $this->portal($validated);
        $role = strtolower($validated['role'] ?? ($this->isStaffPortal($portal) ? 'coach' : 'athlete'));

        if ($denied = $this->denyRoleForPortal($role, $portal)) {
            return $denied;
        }

        $user = User::create([
            'name' => $validated['name'],
            'email' => strtolower($validated['email']),
            'role' => $role,
            'password' => Hash::make($validated['password']),
            'training_level' => $role === 'athlete' ? 'Beginner' : null,
            'personalization_completed' => $role !== 'athlete',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Register berhasil',
            'data' => [
                ...$this->userPayload($user),
                'token' => $this->createPortalToken($user, $portal),
            ],
        ]);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => [
                'required',
                'email',
                'ends_with:@gmail.com',
            ],
            'password' => ['required', 'string'],
            'portal' => [
                'sometimes',
                'string',
                Rule::in([self::ATHLETE_PORTAL, ...self::STAFF_PORTALS]),
            ],
        ], [
            'email.ends_with' => 'Please use a Gmail address',
        ]);

        $portal = $this->portal($validated);
        $email = strtolower($validated['email']);
        $user = User::where('email', $email)->first();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Email not registered',
            ], 404);
        }

        if (! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Incorrect password',
            ], 401);
        }

        if ($denied = $this->denyUserForPortal($user, $portal)) {
            return $denied;
        }

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'data' => [
                ...$this->userPayload($user),
                'token' => $this->createPortalToken($user, $portal),
            ],
        ]);
    }

    public function firebaseLogin(Request $request)
    {
        $validated = $request->validate([
            'id_token' => ['required', 'string'],
            'portal' => [
                'sometimes',
                'string',
                Rule::in([self::ATHLETE_PORTAL, ...self::STAFF_PORTALS]),
            ],
        ]);
        $portal = $this->portal($validated);

        if ($this->isStaffPortal($portal)) {
            return response()->json([
                'success' => false,
                'message' => 'Google login hanya untuk app atlet. Coach/admin wajib login lewat web coach/admin.',
            ], 403);
        }

        $firebaseUser = $this->verifyFirebaseIdToken($validated['id_token']);

        if (! $firebaseUser) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid Firebase token',
            ], 401);
        }

        $email = strtolower($firebaseUser['email'] ?? '');

        if (! $email || ! str_ends_with($email, '@gmail.com')) {
            return response()->json([
                'success' => false,
                'message' => 'Please use a Gmail address',
            ], 422);
        }

        $user = User::where('email', $email)->first();
        $data = [
            'email' => $email,
            'email_verified_at' => now(),
            'firebase_uid' => $firebaseUser['uid'],
        ];

        if ($user) {
            if ($denied = $this->denyUserForPortal($user, $portal)) {
                return $denied;
            }

            $googleProfile = [
                ...$data,
                'name' => $user->name ?: ($firebaseUser['name'] ?? strtok($email, '@')),
                'profile_photo_url' => $user->profile_photo_url
                    ?: ($firebaseUser['picture'] ?? null),
                'training_level' => $user->training_level ?: 'Beginner',
            ];

            $user->forceFill($googleProfile)->save();
        } else {
            $user = User::create([
                ...$data,
                'name' => $firebaseUser['name'] ?? strtok($email, '@'),
                'role' => 'athlete',
                'password' => Hash::make(Str::random(40)),
                'profile_photo_url' => $firebaseUser['picture'] ?? null,
                'training_level' => 'Beginner',
                'personalization_completed' => false,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Firebase login berhasil',
            'data' => [
                ...$this->userPayload($user->fresh()),
                'token' => $this->createPortalToken($user->fresh(), $portal),
            ],
        ]);
    }

    public function forgotPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email', 'ends_with:@gmail.com'],
            'new_password' => [
                'required',
                'string',
                'min:8',
                'regex:/^(?=.*[A-Za-z])(?=.*\d).+$/',
            ],
        ], [
            'email.ends_with' => 'Please use a Gmail address',
            'new_password.regex' => 'Password must include letters and numbers',
        ]);

        $user = User::where('email', strtolower($validated['email']))->first();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'Email not registered',
            ], 404);
        }

        $user->password = Hash::make($validated['new_password']);
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil diubah',
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil',
        ]);
    }

    public function user(Request $request, $id)
    {
        return $this->profile($request, $id);
    }

    public function profile(Request $request, $id)
    {
        $authenticatedUser = $request->user('sanctum');

        if (! $authenticatedUser) {
            return response()->json([
                'success' => false,
                'message' => 'Token login wajib untuk mengakses profil',
            ], 401);
        }

        if ((int) $authenticatedUser->id !== (int) $id) {
            return response()->json([
                'success' => false,
                'message' => 'Token login tidak cocok dengan profil user',
            ], 403);
        }

        $user = User::find($id);

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan',
            ], 404);
        }

        $portal = $this->portal($request->query());
        if ($portal === self::ATHLETE_PORTAL && ! $this->isAthleteRole($user->role)) {
            return response()->json([
                'success' => false,
                'message' => 'Akun coach/admin tidak bisa mengakses profil app atlet. Silakan register akun atlet terlebih dahulu.',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'data' => $this->userPayload($user),
        ]);
    }

    public function personalization(Request $request)
    {
        $validated = $request->validate([
            'user_id' => ['nullable', 'integer', 'exists:users,id'],
            'name' => ['required', 'string', 'max:255'],
            'height' => ['required', 'numeric', 'min:80', 'max:250'],
            'weight' => ['required', 'numeric', 'min:25', 'max:250'],
            'age' => ['required', 'integer', 'min:8', 'max:80'],
            'gender' => ['required', 'string', Rule::in(['male', 'female'])],
            'profile_photo_url' => ['nullable', 'url', 'max:2048'],
            'profile_photo' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ]);

        $authenticatedUser = $request->user('sanctum');

        if (! $authenticatedUser) {
            return response()->json([
                'success' => false,
                'message' => 'Token login wajib untuk menyimpan personalisasi',
            ], 401);
        }

        $userId = $validated['user_id'] ?? $request->user()?->id;

        if (! $userId) {
            return response()->json([
                'success' => false,
                'message' => 'User wajib diisi',
            ], 422);
        }

        if ((int) $authenticatedUser->id !== (int) $userId) {
            return response()->json([
                'success' => false,
                'message' => 'Token login tidak cocok dengan user personalisasi',
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
                'message' => 'Akun coach/admin tidak bisa memakai personalisasi app atlet. Silakan register akun atlet terlebih dahulu.',
            ], 403);
        }

        $profilePhotoUrl = $user->profile_photo_url;

        if ($request->hasFile('profile_photo')) {
            $profilePhotoUrl = $this->storeProfilePhoto($request, $user);
        } elseif (array_key_exists('profile_photo_url', $validated)) {
            if ($validated['profile_photo_url'] !== $user->profile_photo_url) {
                $this->deleteLocalProfilePhoto($user->profile_photo_url);
            }

            $profilePhotoUrl = $validated['profile_photo_url'];
        }

        $userData = [
            'name' => $validated['name'],
            'height' => $validated['height'],
            'weight' => $validated['weight'],
            'age' => $validated['age'],
            'gender' => $validated['gender'],
            'profile_photo_url' => $profilePhotoUrl,
            'training_level' => $this->trainingLevel($user),
            'personalization_completed' => true,
        ];

        $user->update($userData);

        return response()->json([
            'success' => true,
            'message' => 'Personalization saved',
            'data' => $this->userPayload($user->fresh()),
        ]);
    }

    private function userPayload(User $user): array
    {
        $height = $user->height ? (float) $user->height : null;
        $weight = $user->weight ? (float) $user->weight : null;
        $bmi = $this->bmi($height, $weight);
        $isPersonalized = $this->isPersonalized($user);

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role ?? 'athlete',
            'height' => $height,
            'weight' => $weight,
            'age' => $user->age ? (int) $user->age : null,
            'gender' => $user->gender,
            'profile_photo_url' => $this->absoluteUrl($user->profile_photo_url),
            'training_level' => $this->trainingLevel($user),
            'intermediate_access_approved' => $this->trainingLevel($user) === 'Intermediate',
            'intermediate_approved_at' => optional($user->intermediate_approved_at)->toISOString(),
            'personalization_completed' => $isPersonalized,
            'is_personalized' => $isPersonalized,
            'athlete_info' => [
                'bmi' => $bmi,
                'bmi_category' => $this->bmiCategory($bmi),
                'profile_label' => $this->athleteProfileLabel($user),
            ],
        ];
    }

    private function portal(array $source): string
    {
        $portal = strtolower((string) ($source['portal'] ?? self::ATHLETE_PORTAL));

        return in_array($portal, [self::ATHLETE_PORTAL, ...self::STAFF_PORTALS], true)
            ? $portal
            : self::ATHLETE_PORTAL;
    }

    private function isStaffPortal(string $portal): bool
    {
        return in_array($portal, self::STAFF_PORTALS, true);
    }

    private function isAthleteRole(?string $role): bool
    {
        $normalized = strtolower(trim((string) ($role ?? 'athlete')));

        return $normalized === '' || $normalized === 'athlete';
    }

    private function denyRoleForPortal(string $role, string $portal)
    {
        $normalizedRole = strtolower(trim($role));

        if ($portal === self::ATHLETE_PORTAL && ! $this->isAthleteRole($normalizedRole)) {
            return response()->json([
                'success' => false,
                'message' => 'App atlet hanya untuk akun athlete. Coach/admin wajib memakai web coach/admin.',
            ], 403);
        }

        if ($this->isStaffPortal($portal) && ! in_array($normalizedRole, self::STAFF_ROLES, true)) {
            return response()->json([
                'success' => false,
                'message' => 'Web coach/admin hanya untuk akun coach atau admin.',
            ], 403);
        }

        return null;
    }

    private function denyUserForPortal(User $user, string $portal)
    {
        return $this->denyRoleForPortal(strtolower($user->role ?? 'athlete'), $portal);
    }

    private function createPortalToken(User $user, string $portal): string
    {
        if ($portal === self::ATHLETE_PORTAL) {
            return $user->createToken('athlete-app', ['athlete-app'])->plainTextToken;
        }

        return $user->createToken('coach-admin-web', ['coach-admin-web'])->plainTextToken;
    }

    private function verifyFirebaseIdToken(string $idToken): ?array
    {
        $parts = explode('.', $idToken);

        if (count($parts) !== 3) {
            return null;
        }

        [$encodedHeader, $encodedPayload, $encodedSignature] = $parts;
        $header = json_decode($this->base64UrlDecode($encodedHeader), true);
        $payload = json_decode($this->base64UrlDecode($encodedPayload), true);

        if (! is_array($header) || ! is_array($payload)) {
            return null;
        }

        $projectId = env('FIREBASE_PROJECT_ID', 'basketballperformancecoa-feaf6');
        $keyId = $header['kid'] ?? null;

        if (($header['alg'] ?? null) !== 'RS256' || ! $keyId) {
            return null;
        }

        $certificates = Cache::remember(
            'firebase_public_certificates',
            now()->addHour(),
            fn () => Http::timeout(8)
                ->get('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com')
                ->throw()
                ->json()
        );

        $certificate = $certificates[$keyId] ?? null;

        if (! $certificate) {
            return null;
        }

        $signature = $this->base64UrlDecode($encodedSignature);
        $verified = openssl_verify(
            $encodedHeader.'.'.$encodedPayload,
            $signature,
            $certificate,
            OPENSSL_ALGO_SHA256
        );

        if ($verified !== 1) {
            return null;
        }

        $now = time();
        $issuer = 'https://securetoken.google.com/'.$projectId;

        if (($payload['iss'] ?? null) !== $issuer ||
            ($payload['aud'] ?? null) !== $projectId ||
            empty($payload['sub']) ||
            ($payload['exp'] ?? 0) < $now ||
            ($payload['iat'] ?? PHP_INT_MAX) > $now + 60
        ) {
            return null;
        }

        return [
            'uid' => $payload['sub'],
            'email' => $payload['email'] ?? null,
            'name' => $payload['name'] ?? null,
            'picture' => $payload['picture'] ?? null,
        ];
    }

    private function base64UrlDecode(string $value): string
    {
        return base64_decode(strtr($value, '-_', '+/').str_repeat('=', (4 - strlen($value) % 4) % 4));
    }

    private function isPersonalized(User $user): bool
    {
        if ((bool) $user->personalization_completed) {
            return true;
        }

        return filled($user->name)
            && filled($user->height)
            && filled($user->weight)
            && filled($user->age)
            && filled($user->gender)
            && filled($this->trainingLevel($user));
    }

    private function bmi(?float $height, ?float $weight): ?float
    {
        if (! $height || ! $weight) {
            return null;
        }

        $heightInMeters = $height / 100;

        return round($weight / ($heightInMeters * $heightInMeters), 1);
    }

    private function bmiCategory(?float $bmi): string
    {
        if (! $bmi) {
            return 'Not set';
        }

        return match (true) {
            $bmi < 18.5 => 'Lean build',
            $bmi < 25 => 'Athletic range',
            $bmi < 30 => 'Power build',
            default => 'Conditioning focus',
        };
    }

    private function athleteProfileLabel(User $user): string
    {
        if (! $this->isPersonalized($user)) {
            return 'Setup required';
        }

        return $this->trainingLevel($user).' Basketball Athlete';
    }

    private function trainingLevel(User $user): string
    {
        return strtolower(trim((string) $user->training_level)) === 'intermediate'
            ? 'Intermediate'
            : 'Beginner';
    }

    private function storeProfilePhoto(Request $request, User $user): string
    {
        $file = $request->file('profile_photo');
        $extension = $file->guessExtension()
            ?: $file->getClientOriginalExtension()
            ?: 'jpg';
        $path = $file->storeAs(
            'profile-photos/user-'.$user->id,
            'profile-'.now()->format('YmdHis').'.'.$extension,
            'public'
        );

        $this->deleteLocalProfilePhoto($user->profile_photo_url);

        return $this->absoluteUrl(Storage::url($path));
    }

    private function deleteLocalProfilePhoto(?string $url): void
    {
        if (! $url) {
            return;
        }

        $path = parse_url($url, PHP_URL_PATH) ?: $url;
        $normalized = ltrim($path, '/');

        if (str_starts_with($normalized, 'storage/profile-photos/')) {
            $normalized = substr($normalized, strlen('storage/'));
        }

        if (! str_starts_with($normalized, 'profile-photos/')) {
            return;
        }

        Storage::disk('public')->delete($normalized);
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
