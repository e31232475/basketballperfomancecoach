# Coach Monitor

Web coach sederhana untuk memantau atlet dan memberi validasi performance based progress.

## Cara buka

Buka `coach_web/index.html` langsung di browser.

Tidak ada proses build dan tidak perlu install dependency.

Jika folder ini berada di Laragon:

```text
http://localhost/basketballperfomancecoach_coach_web/
```

## Cara testing cepat

1. Buka halaman login.
2. Klik `Lihat Demo`.
3. Buka menu `Review`.
4. Klik salah satu tombol `Review`.
5. Isi status, score, dan catatan coach.
6. Klik `Simpan Review`.

Review demo akan tersimpan di browser melalui `localStorage`. Untuk mengulang dari awal, buka menu `API`, lalu klik `Reset Demo`.

## Menyambungkan ke backend Laravel

Di project backend `basketballperfomancecoach`, jalankan:

```text
php artisan migrate
php artisan serve
```

Default API web ini:

```text
http://127.0.0.1:8000/api
```

Akun coach/admin bisa dibuat dengan mengubah role user di database:

```sql
UPDATE users SET role = 'coach' WHERE email = 'coach@gmail.com';
```

## Endpoint yang disiapkan

Web ini siap memakai endpoint berikut:

```text
POST /api/login
GET  /api/coach/dashboard
GET  /api/coach/athletes
GET  /api/coach/athletes/{userId}
GET  /api/coach/recordings?status=all
POST /api/coach/recordings/{recordingId}/review
```

Jika endpoint coach belum tersedia, web otomatis masuk mode demo agar alur UI tetap bisa dilihat.

## Konsep progress

- Consistency progress: otomatis dari aktivitas atlet, seperti latihan dikirim dan waktu upload.
- Performance progress: hanya berubah setelah coach memberi validasi video.

Status review yang dipakai:

```text
pending
approved
needs_revision
```
