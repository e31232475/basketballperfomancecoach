# Basketball Performance Coach Flutter

Aplikasi atlet untuk program latihan, recording, progress, dan feedback coach.

## Notifikasi review coach

Setiap coach menyimpan atau memperbarui review, backend membuat notifikasi
untuk atlet terkait. Aplikasi menampilkan:

- badge jumlah notifikasi yang belum dibaca;
- snackbar ketika review baru terdeteksi saat aplikasi aktif;
- daftar status, score, dan feedback coach;
- aksi baca satu atau baca semua;
- refresh otomatis setiap 20 detik dan saat aplikasi kembali aktif.

Jalankan migrasi backend setelah mengambil perubahan ini:

```text
php artisan migrate
```

Notifikasi saat ini bersifat in-app dan tersimpan di database. Push notification
saat aplikasi benar-benar tertutup memerlukan konfigurasi FCM terpisah.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
