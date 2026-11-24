<?php

namespace App\Notifications;

use App\Models\CoachReview;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class CoachReviewSubmitted extends Notification
{
    use Queueable;

    public function __construct(
        private readonly CoachReview $review,
        private readonly string $workoutTitle,
    ) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        $needsRevision = $this->review->status === 'needs_revision';
        $statusLabel = $needsRevision ? 'Perlu ulang' : 'Approved';
        $score = $this->review->score === null ? null : (int) $this->review->score;
        $scoreText = $score === null ? '' : " dengan score {$score}";

        return [
            'kind' => 'coach_review',
            'title' => $needsRevision
                ? 'Coach meminta latihan diulang'
                : 'Latihan disetujui coach',
            'message' => $needsRevision
                ? "Review {$this->workoutTitle} sudah tersedia. Buka feedback coach sebelum mengulang latihan."
                : "Review {$this->workoutTitle} sudah tersedia{$scoreText}.",
            'review_id' => (int) $this->review->id,
            'recording_id' => (int) $this->review->workout_recording_id,
            'workout_id' => (int) $this->review->workout_id,
            'workout_title' => $this->workoutTitle,
            'day_number' => (int) $this->review->day_number,
            'status' => $this->review->status,
            'status_label' => $statusLabel,
            'score' => $score,
            'feedback' => $this->review->feedback,
            'reviewed_at' => optional($this->review->reviewed_at)->toISOString(),
        ];
    }
}
