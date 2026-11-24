# Coach API Contract

Base URL default:

```text
http://127.0.0.1:8000/api
```

## Auth

```http
POST /login
Content-Type: application/json
```

Request:

```json
{
  "email": "coach@example.com",
  "password": "secret"
}
```

Response minimal:

```json
{
  "success": true,
  "data": {
    "token": "plain-token",
    "user": {
      "id": 10,
      "name": "Coach",
      "role": "coach"
    }
  }
}
```

## Dashboard

```http
GET /coach/dashboard
Authorization: Bearer {token}
```

Response:

```json
{
  "success": true,
  "data": {
    "total_athletes": 18,
    "active_athletes": 12,
    "pending_reviews": 5,
    "average_performance": 78,
    "average_consistency": 64
  }
}
```

## Athletes

```http
GET /coach/athletes
Authorization: Bearer {token}
```

Response:

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Dimas Ramdhan",
      "email": "dimas@example.com",
      "training_level": "Beginner",
      "consistency_progress": 71,
      "performance_progress": 82,
      "pending_reviews": 1,
      "completed_days": 10,
      "recorded_days": 10,
      "total_program_days": 14,
      "program_days": [
        {
          "workout_id": 1,
          "day_number": 1,
          "title": "Day 1",
          "level": "Beginner"
        }
      ],
      "last_activity_at": "2026-06-08T08:40:00+07:00",
      "status": "active"
    }
  ]
}
```

## Athlete Detail

```http
GET /coach/athletes/{userId}
Authorization: Bearer {token}
```

Response:

```json
{
  "success": true,
  "data": {
    "athlete": {
      "id": 1,
      "name": "Dimas Ramdhan",
      "consistency_progress": 71,
      "performance_progress": 82,
      "pending_reviews": 1
    },
    "recordings": []
  }
}
```

## Recordings

```http
GET /coach/recordings?status=all
Authorization: Bearer {token}
```

Response:

```json
{
  "success": true,
  "data": [
    {
      "id": 101,
      "user_id": 1,
      "athlete_name": "Dimas Ramdhan",
      "athlete_email": "dimas@example.com",
      "athlete_training_level": "Beginner",
      "workout_id": 11,
      "day_number": 5,
      "workout_title": "Day 5",
      "workout_level": "Beginner",
      "uploaded_at": "2026-06-08T08:40:00+07:00",
      "status": "pending",
      "duration_seconds": 74,
      "video_url": "http://127.0.0.1:8000/storage/recordings/day5.webm"
    }
  ]
}
```

## Submit Review

```http
POST /coach/recordings/{recordingId}/review
Authorization: Bearer {token}
Content-Type: application/json
```

Request:

```json
{
  "status": "approved",
  "score": 84,
  "feedback": "Landing sudah stabil, start sprint perlu lebih eksplosif."
}
```

Status yang dipakai web:

```text
pending
approved
needs_revision
```

Performance progress atlet dihitung dari hasil review coach. Consistency progress
dihitung dari workout selesai/recording pada level aktif atlet. Jumlah dan urutan
day berasal dari tabel `workouts`, sehingga program Beginner dan Intermediate
tidak memakai pembagi gabungan.
