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
2. Login memakai akun coach/admin dari backend Laravel.
3. Periksa ringkasan dashboard dan buka menu `Review`.
4. Cari/filter recording, lalu klik salah satu tombol `Review`.
5. Isi status, score, dan catatan coach (semuanya wajib).
6. Klik `Simpan Review`.

Detail atlet menampilkan progress Day 1-14 dan riwayat review lengkap. Hasil
status, score, dan feedback yang disimpan juga tersedia pada halaman progress
aplikasi atlet.

## Menyambungkan ke backend Laravel

Di project backend `basketballperfomancecoach`, jalankan:

```text
php artisan migrate
php artisan serve
```

Default API web ini:

```text
http://127.0.0.1:8001/api
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

Web ini memakai endpoint backend secara langsung. Jika endpoint belum tersedia atau token tidak valid, halaman akan menampilkan error dari API.

## Fitur admin

- Dashboard ringkasan total user, program, exercise, video latihan, dan video atlet pending.
- Role management untuk athlete, coach, dan admin.
- Exercise dikelola di dalam program/workout agar relasinya sesuai ERD.
- Video latihan dapat memakai URL/path server atau upload file. Upload disimpan
  backend sebagai path publik `/storage/...`.
- Penghapusan user, program, exercise, dan video selalu meminta konfirmasi.

## Konsep progress

- Consistency progress: otomatis dari aktivitas atlet, seperti latihan dikirim dan waktu upload.
- Performance progress: hanya berubah setelah coach memberi validasi video.
- Jumlah day dan pembagi consistency mengikuti workout pada `training_level`
  atlet di database. Contoh: 3 dari 14 workout menghasilkan 21%, bukan 3 dari
  seluruh program lintas level.

Status review yang dipakai:

```text
pending
approved
needs_revision
```
