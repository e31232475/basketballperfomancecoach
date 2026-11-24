<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class AthleteNotificationController extends Controller
{
    public function index(Request $request)
    {
        if ($denied = $this->denyUnlessAthlete($request)) {
            return $denied;
        }

        $limit = min(100, max(1, (int) $request->query('limit', 50)));
        $user = $request->user();
        $notifications = $user->notifications()
            ->latest()
            ->limit($limit)
            ->get()
            ->map(fn ($notification) => $this->notificationPayload($notification))
            ->values();

        return response()->json([
            'success' => true,
            'data' => $notifications,
            'meta' => [
                'unread_count' => $user->unreadNotifications()->count(),
            ],
        ]);
    }

    public function unreadCount(Request $request)
    {
        if ($denied = $this->denyUnlessAthlete($request)) {
            return $denied;
        }

        return response()->json([
            'success' => true,
            'data' => [
                'unread_count' => $request->user()->unreadNotifications()->count(),
            ],
        ]);
    }

    public function markRead(Request $request, string $notificationId)
    {
        if ($denied = $this->denyUnlessAthlete($request)) {
            return $denied;
        }

        $notification = $request->user()
            ->notifications()
            ->whereKey($notificationId)
            ->first();

        if (! $notification) {
            return response()->json([
                'success' => false,
                'message' => 'Notifikasi tidak ditemukan',
            ], 404);
        }

        $notification->markAsRead();

        return response()->json([
            'success' => true,
            'message' => 'Notifikasi sudah dibaca',
            'data' => $this->notificationPayload($notification->fresh()),
        ]);
    }

    public function markAllRead(Request $request)
    {
        if ($denied = $this->denyUnlessAthlete($request)) {
            return $denied;
        }

        $request->user()->unreadNotifications->markAsRead();

        return response()->json([
            'success' => true,
            'message' => 'Semua notifikasi sudah dibaca',
            'data' => [
                'unread_count' => 0,
            ],
        ]);
    }

    private function notificationPayload($notification): array
    {
        $data = is_array($notification->data) ? $notification->data : [];

        return [
            'id' => (string) $notification->id,
            'type' => $data['kind'] ?? 'notification',
            'title' => $data['title'] ?? 'Notifikasi',
            'message' => $data['message'] ?? '',
            'review_id' => $data['review_id'] ?? null,
            'recording_id' => $data['recording_id'] ?? null,
            'workout_id' => $data['workout_id'] ?? null,
            'workout_title' => $data['workout_title'] ?? null,
            'day_number' => $data['day_number'] ?? null,
            'status' => $data['status'] ?? null,
            'status_label' => $data['status_label'] ?? null,
            'score' => $data['score'] ?? null,
            'feedback' => $data['feedback'] ?? null,
            'reviewed_at' => $data['reviewed_at'] ?? null,
            'is_read' => $notification->read_at !== null,
            'read_at' => optional($notification->read_at)->toISOString(),
            'created_at' => optional($notification->created_at)->toISOString(),
        ];
    }

    private function denyUnlessAthlete(Request $request)
    {
        $role = strtolower((string) ($request->user()?->role ?? 'athlete'));

        if ($role === 'athlete' || $role === '') {
            return null;
        }

        return response()->json([
            'success' => false,
            'message' => 'Akses notifikasi hanya untuk atlet',
        ], 403);
    }
}
