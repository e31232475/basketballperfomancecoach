# Android Backend URL

APK Android tidak membaca URL backend dari browser. URL API tertanam saat APK dibuild.

Untuk backend online tetap, gunakan:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.domain-kamu.com/api
```

Untuk HP Android fisik melalui USB, aktifkan port forwarding:

```bash
adb reverse tcp:8000 tcp:8000
flutter run
```

Default project ini sudah memakai:

```text
http://127.0.0.1:8000/api
```

Untuk emulator Android, gunakan alamat host bawaan emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Pastikan Laravel lokal berjalan di port `8000`:

```bash
php artisan serve --host=127.0.0.1 --port=8000
```

Untuk testing di HP Android fisik lewat laptop, gunakan IP laptop yang sedang aktif:

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://IP-LAPTOP:8000/api
```

Contoh:

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.23:8000/api
```

Catatan:

- HP dan laptop harus satu jaringan jika memakai IP lokal.
- Jalankan Laravel lokal dengan `php artisan serve --host=0.0.0.0 --port=8000` jika memakai HP fisik.
- Untuk pemakaian sungguhan, gunakan URL online tetap, bukan IP lokal.
