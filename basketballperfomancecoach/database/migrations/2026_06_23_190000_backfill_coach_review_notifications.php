<?php

use App\Models\CoachReview;
use App\Models\User;
use App\Models\Workout;
use App\Notifications\CoachReviewSubmitted;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('notifications') || ! Schema::hasTable('coach_reviews')) {
            return;
        }

        CoachReview::query()
            ->orderBy('id')
            ->chunkById(100, function ($reviews): void {
                foreach ($reviews as $review) {
                    $athlete = User::find($review->user_id);

                    if (! $athlete || $this->hasReviewNotification($athlete, $review)) {
                        continue;
                    }

                    $workoutTitle = Workout::find($review->workout_id)?->title
                        ?: 'Day '.$review->day_number;
                    $athlete->notify(new CoachReviewSubmitted($review, $workoutTitle));
                }
            });
    }

    public function down(): void
    {
        // Notifications are user-facing history and should not be removed on rollback.
    }

    private function hasReviewNotification(User $athlete, CoachReview $review): bool
    {
        return $athlete->notifications()
            ->where('type', CoachReviewSubmitted::class)
            ->get()
            ->contains(
                fn ($notification) => (int) ($notification->data['review_id'] ?? 0)
                    === (int) $review->id
            );
    }
};
