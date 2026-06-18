# Deploy Backend Laravel Online

Backend Laravel harus punya URL publik tetap agar APK Android yang sudah ter-install tidak bergantung pada IP laptop. Bentuk URL yang disarankan:

```text
https://api.domain-kamu.com/api
```

## Yang Harus Disiapkan

1. Domain atau subdomain, contoh `api.domain-kamu.com`.
2. Hosting yang mendukung PHP 8.3+ dan MySQL, atau VPS.
3. Database MySQL kosong untuk backend.
4. Akses terminal/SSH atau file manager hosting.

## Upload Backend

Upload isi folder backend Laravel ini:

```text
C:\laragon\www\basketballperfomancecoach
```

Document root domain/subdomain harus diarahkan ke:

```text
public
```

Contoh:

```text
/home/user/basketballperfomancecoach/public
```

## Konfigurasi `.env`

Copy:

```text
.env.production.example
```

menjadi:

```text
.env
```

Lalu ubah nilai berikut:

```env
APP_URL=https://api.domain-kamu.com
DB_DATABASE=nama_database_hosting
DB_USERNAME=username_database
DB_PASSWORD=password_database
```

Pastikan:

```env
APP_ENV=production
APP_DEBUG=false
FILESYSTEM_DISK=public
```

## Command Laravel

Jalankan di server:

```bash
composer install --no-dev --optimize-autoloader
php artisan key:generate
php artisan migrate --force
php artisan storage:link
php artisan config:cache
php artisan route:cache
```

Kalau memakai hosting tanpa SSH, jalankan command ini lewat fitur terminal hosting. Jika tidak ada terminal, minta hosting menjalankannya atau gunakan VPS.

## Test API

Buka:

```text
https://api.domain-kamu.com/api/progress/5
```

Jika backend benar, response akan berupa JSON.

## Build APK Android

Setelah URL backend online aktif, build APK dengan URL tersebut:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.domain-kamu.com/api
```

Install APK baru ke HP. APK lama harus dihapus dulu agar tidak masih memakai URL lama.

## Update Coach Web

Di web coach, API base URL harus:

```text
https://api.domain-kamu.com/api
```

Jika app web coach masih membaca URL lama dari browser storage, logout lalu clear site data/localStorage, kemudian login lagi.
