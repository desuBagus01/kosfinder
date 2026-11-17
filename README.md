# KosFinder

Aplikasi pencari kos dan manajemen kos mandiri berbasis **Flutter** dan **Supabase**.

---

## 1. Deskripsi Aplikasi

**KosFinder** adalah aplikasi *cross-platform* yang dirancang untuk mempermudah pencari kos dalam menemukan informasi kos yang akurat (lokasi, tarif sewa, fasilitas, ketersediaan kamar, dan kontak pemilik) secara langsung tanpa kewajiban mendaftar atau masuk (*login*).

Aplikasi ini juga menyediakan sarana terpadu bagi pemilik kos untuk mengelola publikasi kos mereka secara mandiri, memperbarui jumlah kamar yang tersedia, serta menandai status kamar penuh dengan perlindungan keamanan tingkat data menggunakan PostgreSQL *Row Level Security* (RLS).

---

## 2. Fitur Utama

Sesuai dengan spesifikasi Versi `0.1.0`, fitur yang tersedia meliputi:

1. **Eksplorasi Kos Publik (Akses Tamu):**
   - Menjelajah seluruh daftar kos aktif tanpa kewajiban registrasi atau login.
   - Ringkasan kartu kos memuat nama kos, area, tarif sewa per bulan (Rp/bulan), dan indikator sisa kamar.
2. **Pencarian Bebas (Nama, Area, dan Alamat):**
   - Pencarian teks bebas (*free-text search*) yang mencakup kolom nama kos, area kecamatan/wilayah, serta alamat jalan secara *case-insensitive*.
3. **Penyaringan Harga & Fasilitas:**
   - Filter anggaran sewa bulanan maksimum.
   - Filter kombinasi fasilitas pilihan tetap: **WiFi**, **Kamar Mandi Dalam**, dan **Parkir** (kondisi logika AND).
4. **Detail Informasi Kos & Kontak Pemilik:**
   - Halaman detail komprehensif menampilkan nama, alamat lengkap, tarif bulanan, fasilitas, deskripsi kos, dan ketersediaan kamar.
   - Integrasi tombol panggilan telepon dan tautan percakapan langsung WhatsApp (`wa.me`) ke nomor kontak pemilik kos.
5. **Autentikasi Pemilik Kos:**
   - Pendaftaran akun pemilik baru secara praktis menggunakan email dan kata sandi (minimal 6 karakter).
   - Masuk (*login*) dan keluar (*logout*) akun dengan manajemen sesi aman melalui Supabase Auth.
6. **Dashboard Pengelolaan Kos Pemilik:**
   - Dashboard khusus pemilik untuk melihat daftar kos milik sendiri setelah login.
   - Pembatasan akses ketat bagi pengguna yang belum terautentikasi.
7. **Publikasi & Tambah Kos Baru:**
   - Menambahkan data kos baru lengkap dengan validasi formulir dan penetapan `owner_id` otomatis dari sesi login.
8. **Ubah (Edit) Kos Milik Sendiri:**
   - Formulir pengeditan data kos yang terisi otomatis (*auto-fill*) sesuai data saat ini.
9. **Hapus Kos dengan Dialog Konfirmasi:**
   - Penghapusan data kos dengan dialog konfirmasi pencegahan ketidaksengajaan.
10. **Pembaruan Cepat Ketersediaan Kamar:**
    - Dialog pembaruan kamar cepat (`UpdateRoomsDialog`) langsung dari kartu kos tanpa harus membuka formulir edit lengkap.
    - Status **"Kamar Penuh"** otomatis tampil tegas saat jumlah kamar bernilai `0`.
11. **Keamanan Data Backend (Row Level Security - RLS):**
    - Akses baca terbuka untuk publik (`SELECT`).
    - Operasi `INSERT`, `UPDATE`, dan `DELETE` hanya diizinkan untuk pemilik data yang sah (`auth.uid() = owner_id`). Pemilik lain ditolak oleh basis data.
12. **Halaman About & Identitas Pengembang:**
    - Memuat informasi identitas baku pengembang aplikasi: `2415051014 - Gede Supadma`.

---

## 3. Teknologi yang Digunakan

- **Framework:** [Flutter](https://flutter.dev/) (SDK `>= 3.13.0`)
- **Bahasa Pemrograman:** [Dart](https://dart.dev/)
- **Backend & Database:** [Supabase](https://supabase.com/) (PostgreSQL dengan Row Level Security)
- **Layanan Autentikasi:** Supabase Auth (Email & Password)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Komunikasi Jaringan:** `supabase_flutter` (^2.8.0)
- **Konfigurasi Lingkungan:** `flutter_dotenv` (^5.2.1)
- **Integrasi Panggilan & URL:** `url_launcher` (^6.3.0)
- **Arsitektur Kode:** *Vertical Slice Architecture* (Screen – Provider – Repository – Service)

---

## 4. Struktur Proyek

```text
kosfinder/
├── android/                  # Konfigurasi platform Android
├── docs/                     # Dokumentasi proyek (PRD, Arsitektur, Tasks, Test Plan)
│   ├── architecture.md
│   ├── prd.md
│   ├── requirements.md
│   ├── tasks.md
│   ├── test-plan.md
│   └── user-story.md
├── lib/
│   ├── models/               # Model data entitas (KosModel)
│   ├── providers/            # State management (KosProvider, AuthProvider)
│   ├── repositories/         # Abstraksi data & transformasi (KosRepository, AuthRepository)
│   ├── screens/              # Tampilan layar antarmuka pengguna
│   ├── services/             # Klien jaringan Supabase (SupabaseKosService, SupabaseAuthService)
│   ├── theme/                # Tema visual Modern Minimalist Blue Theme
│   ├── widgets/              # Komponen widget UI modular
│   └── main.dart             # Titik masuk utama aplikasi (Entry Point)
├── supabase/
│   └── schema.sql            # Skema tabel PostgreSQL, indeks, dan kebijakan RLS
├── test/                     # Rangkaian unit test dan widget test komprehensif
├── .env.example              # Template variabel lingkungan lokal
├── pubspec.yaml              # Konfigurasi dependensi dan versi aplikasi
└── README.md                 # Dokumentasi panduan proyek
```

---

## 5. Persyaratan Sistem

Sebelum menjalankan atau membangun proyek, pastikan lingkungan pengembangan telah memenuhi:

- **Flutter SDK:** Versi 3.13.0 atau yang lebih baru.
- **Dart SDK:** Versi 3.1.0 atau yang lebih baru.
- **Android SDK:** Compile SDK 34 / Target SDK 34, Min SDK 21 (Android 5.0 Lollipop ke atas).
- **Java Development Kit (JDK):** Versi 17.
- **Proyek Supabase:** Akun Supabase aktif dengan skema basis data dan kebijakan RLS yang telah dieksekusi dari file `supabase/schema.sql`.

---

## 6. Cara Menjalankan Aplikasi (Development)

1. **Clone repository:**
   ```bash
   git clone https://github.com/desuBagus01/kosfinder.git
   cd kosfinder
   ```

2. **Pasang seluruh dependensi:**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi variabel lingkungan:**
   Salin berkas `.env.example` menjadi `.env`:
   ```bash
   cp .env.example .env
   ```
   Buka file `.env` dan masukkan kredensial proyek Supabase Anda:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_PUBLISHABLE_KEY=your-publishable-anon-key-here
   ```
   > **PENTING:** Jangan pernah memasukkan `service_role key` ke dalam aplikasi Flutter. Gunakan selalu anon/publishable key publik.

4. **Jalankan aplikasi:**
   ```bash
   flutter run
   ```

---

## 7. Cara Membangun APK Android (Build APK)

### A. Membangun APK Release

Untuk membangun file instalasi APK Release Android:

```bash
flutter build apk --release
```

Atau jika menggunakan parameter `--dart-define` secara langsung tanpa file `.env`:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-anon-key-here
```

File APK hasil build akan berada pada lokasi:
```text
build/app/outputs/flutter-apk/app-release.apk
```

### B. Membangun APK Debug (Pengujian Cepat)

```bash
flutter build apk --debug
```

File APK debug akan berada pada lokasi:
```text
build/app/outputs/flutter-apk/app-debug.apk
```

---

## 8. Batasan Aplikasi pada Versi 0.1.0

Fitur-fitur berikut secara terencana **belum disertakan** pada rilis versi 0.1.0:
- Pembayaran sewa daring (*online payment gateway*) di dalam aplikasi.
- Fitur percakapan obrolan (*in-app chat*) bawaan (komunikasi diarahkan ke telepon dan WhatsApp pemilik secara langsung).
- Ulasan (*review*) dan penilaian bintang (*rating*).
- Sistem rekomendasi kos berbasis kecerdasan buatan (AI).
- Unggah foto kos (*photo upload*).
- Peta digital interaktif berbasis GPS.
- Pembagian halaman (*pagination*) atau *infinite scrolling* pada daftar kos.
- Pilihan periode sewa harian, mingguan, atau tahunan (hanya sewa bulanan).
- Penambahan nama fasilitas kustom di luar 3 fasilitas baku (WiFi, Kamar Mandi Dalam, Parkir).

---

## 9. Status Rilis & Unduhan

- **Versi Rilis:** `0.1.0+1`
- **Git Tag:** `v0.1.0`
- **Distribusi File APK:** File instalasi `app-release.apk` dapat diunduh melalui halaman resmi [GitHub Releases KosFinder](https://github.com/desuBagus01/kosfinder/releases).

---

## 10. Pengembang Aplikasi

- **NIM:** 2415051014
- **Nama:** Gede Supadma
- **Institusi:** Universitas Pendidikan Ganesha
