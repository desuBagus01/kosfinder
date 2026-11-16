# Dokumen Arsitektur Sistem KosFinder (Architecture Specification)

Dokumen ini mendefinisikan arsitektur teknis, pola perancangan perangkat lunak, daftar layar dan navigasi, skema basis data Supabase, kebijakan keamanan Row Level Security (RLS), serta dependensi pustaka (*packages*) untuk aplikasi **KosFinder** Versi 1.

Dokumen ini disusun mengacu pada dokumen spesifikasi [docs/requirements.md](file:///c:/src/kosfinder/docs/requirements.md), [docs/user-story.md](file:///c:/src/kosfinder/docs/user-story.md), [docs/prd.md](file:///c:/src/kosfinder/docs/prd.md), dan panduan kerja [AGENTS.md](file:///c:/src/kosfinder/AGENTS.md).

---

## 1. Arsitektur Aplikasi

Aplikasi KosFinder dibangun menggunakan arsitektur berlapis (*layered architecture*) dengan pola **Screen – Provider – Repository – Service**. Pola ini dipilih untuk memisahkan tanggung jawab antarmuka pengguna (*UI*), pengelolaan status (*state management*), abstraksi data (*data abstraction*), dan komunikasi jaringan backend (*backend service*), dengan tetap mempertahankan prinsip kesederhanaan (*Keep It Simple, Stupid - KISS*).

```
+-------------------------------------------------------------+
|                     PRESENTATION LAYER                      |
|  Screens / Pages (UI Widget, Dialog, Form, User Feedback)   |
+-------------------------------------------------------------+
                              |
                     notifies | listens / triggers
                              v
+-------------------------------------------------------------+
|                   STATE MANAGEMENT LAYER                    |
|  Providers (ChangeNotifier: KosProvider, AuthProvider)      |
+-------------------------------------------------------------+
                              |
                              | calls methods
                              v
+-------------------------------------------------------------+
|                     REPOSITORY LAYER                        |
|  Repositories (KosRepository, AuthRepository)               |
|  - Mengabstraksi model data (KosModel, UserModel)           |
|  - Menangani transformasi data & logika query/filter lokal  |
+-------------------------------------------------------------+
                              |
                              | calls service
                              v
+-------------------------------------------------------------+
|                       SERVICE LAYER                         |
|  Services (SupabaseKosService, SupabaseAuthService)         |
|  - Komunikasi langsung dengan Supabase Client SDK (REST/Auth)|
+-------------------------------------------------------------+
                              |
                              | HTTPS / TLS
                              v
+-------------------------------------------------------------+
|                      BACKEND SUPABASE                       |
|  PostgreSQL Database + Row Level Security (RLS) + Auth      |
+-------------------------------------------------------------+
```

### 1.1 Tugas Setiap Komponen

1. **Screen / Presentation Layer (Widget Flutter):**
   - **Tugas:** Menampilkan data ke layar, menerima interaksi pengguna (ketukan tombol, input form, filter), dan memberikan respons visual (indikator pemuatan, pesan kesalahan, dialog konfirmasi).
   - **Aturan:** Screen tidak boleh memanggil Supabase Client secara langsung dan tidak boleh memuat logika bisnis manipulasi data mentah.
   - **Dasar Kebutuhan:** Memenuhi seluruh AC tampilan antarmuka (US01 s.d. US08, NFR04, NFR05).

2. **Provider Layer (State Management):**
   - **Tugas:** Mengelola status aplikasi (*state*) menggunakan `ChangeNotifier` dari paket `provider`. Mengatur status pemuatan (`isLoading`), status kesalahan (`errorMessage`), seluruh data kos, data filter pencarian, dan status login pengguna.
   - **Komponen:**
     - `KosProvider`: Mengelola daftar kos publik, pencarian teks bebas (area dan alamat), filter harga dan fasilitas, detail kos, penambahan kos, pengubahan kos, penghapusan kos, dan pembaruan jumlah kamar.
     - `AuthProvider`: Mengelola status autentikasi pemilik kos (sesi aktif, proses registrasi, proses login, dan proses logout).
   - **Dasar Kebutuhan:** Memisahkan siklus hidup data dari widget sehingga antarmuka tetap responsif (< 200 ms) sesuai NFR05 dan status form tidak hilang saat terjadi kesalahan jaringan sesuai NFR03.

3. **Repository Layer (Data Abstraction):**
   - **Tugas:** Menjadi jembatan antara Provider dan Service. Repository bertugas mengonversi data mentah (JSON / Map) dari backend menjadi objek model Dart yang *type-safe* (`KosModel`), serta menangani logika transformasi data, validasi objek, dan penyaringan lokal sebelum request dikirim ke backend. Sesuai batasan Versi 1, komponen ini tidak menggunakan caching data lokal.
   - **Komponen:**
     - `KosRepository`: Mengambil daftar kos, menyaring data, serta mengirim data create/update/delete kos.
     - `AuthRepository`: Mengabstraksi operasi registrasi, login, logout, dan pengecekan sesi pemilik saat ini (`currentUser`).
   - **Dasar Kebutuhan:** Memudahkan pengujian (*unit testing*) dan memastikan validasi data lokal sebelum request dikirim ke backend (FR01–FR13, AC06-2, AC08-2).

4. **Service Layer (Backend Client & Networking):**
   - **Tugas:** Melakukan interaksi teknis langsung dengan Supabase SDK melalui jaringan internet terenkripsi HTTPS (NFR02).
   - **Komponen:**
     - `SupabaseKosService`: Menjalankan query PostgreSQL melalui Supabase Client (`.from('kos').select()`, `.insert()`, `.update()`, `.delete()`).
     - `SupabaseAuthService`: Menjalankan fungsi autentikasi Supabase (`supabase.auth.signUp()`, `signInWithPassword()`, `signOut()`).
   - **Dasar Kebutuhan:** Memusatkan penanganan *exception* jaringan/koneksi backend agar error dapat diteruskan secara terstandar ke Repository dan Provider untuk memicu tombol *Retry* (NFR03, AC01-3, AC04-3).

---

## 2. Daftar Halaman dan Alur Navigasi

Aplikasi KosFinder memiliki 7 halaman utama dan 1 dialog/lembar filter:

| Nama Halaman | Berkas Kode Rencana | Fungsi Halaman | Akses Pengguna |
|---|---|---|---|
| **Halaman Utama (Daftar Kos)** | `kos_list_screen.dart` | Menampilkan seluruh data kos dari backend, kolom pencarian teks bebas (area/alamat), tombol filter fasilitas/harga, tombol navigasi ke login pemilik, dan tombol navigasi ke halaman About. | Publik (Tanpa Login) |
| **Lembar / Modal Filter Kos** | `kos_filter_bottom_sheet.dart` | Form modal untuk menentukan batas harga maksimum per bulan (Rp/bulan) dan checkbox fasilitas tetap (WiFi, Kamar Mandi Dalam, Parkir). | Publik (Tanpa Login) |
| **Halaman Detail Kos** | `kos_detail_screen.dart` | Menampilkan rincian lengkap kos: nama, alamat, harga/bulan, fasilitas, deskripsi, jumlah kamar tersedia, dan nomor telepon/WhatsApp pemilik untuk kontak langsung. | Publik (Tanpa Login) |
| **Halaman Login Pemilik** | `login_screen.dart` | Formulir masuk bagi pemilik kos menggunakan email dan kata sandi, serta tautan menuju pendaftaran akun baru. | Pemilik Kos |
| **Halaman Pendaftaran Pemilik** | `register_screen.dart` | Formulir pembuatan akun pemilik baru yang hanya memerlukan email dan kata sandi. Setelah berhasil, diarahkan ke halaman login. | Pemilik Kos Baru |
| **Halaman Kelola Kos Pemilik** | `owner_kos_screen.dart` | Menampilkan daftar kos milik pemilik yang sedang login, tombol tambah kos baru, tombol ubah kos, tombol hapus kos, tombol update kamar, dan tombol logout. | Pemilik Login |
| **Halaman Tambah / Ubah Kos** | `kos_form_screen.dart` | Formulir input data kos (nama, alamat, area, nomor telepon/WhatsApp, harga per bulan, checkbox fasilitas, deskripsi, kamar tersedia). Digunakan untuk mode tambah maupun mode edit. | Pemilik Login |
| **Halaman About** | `about_screen.dart` | Menampilkan identitas pengembang aplikasi (`2415051014 - Gede Supadma`) sesuai mandat AGENTS.md. | Publik (Semua Pengguna) |

### 2.1 Alur Navigasi Pengguna

#### A. Alur Navigasi Pencari Kos (Akses Publik Tanpa Login)
```
[Buka Aplikasi]
       |
       v
[Halaman Utama / Daftar Kos] <========================+
   |             |                   |                 |
   | (Cari Area/ | (Buka Filter)     | (Pilih Kos)     | (Ketuk Ikon Info)
   |  Alamat)    v                   v                 v
   v          [Modal Filter]     [Detail Kos]     [Halaman About]
[Ketik Teks]     | (Terapkan)        | (Kontak WA)     | (Kembali)
   |             |                   v                 |
   +--->(Hasil)--+               [Buka WhatsApp/       |
                                  Panggilan Manual]    |
                                     |                 |
                                     +-----------------+
```

#### B. Alur Navigasi Pemilik Kos (Autentikasi & Pengelolaan)
```
[Halaman Utama / Daftar Kos]
       |
       | (Ketuk Tombol "Kelola Kos / Masuk")
       v
[Halaman Login] <---------- (Registrasi Sukses) ----------+
   |       |                                               |
   |       | (Belum punya akun)                            |
   |       v                                               |
   |    [Halaman Register] --------------------------------+
   |       (Isi Email & Kata Sandi -> Submit)
   |
   | (Login Sukses dengan Kredensial Valid)
   v
[Halaman Kelola Kos Pemilik] <------------------------+
   |            |                  |                  |
   | (Logout)   | (Tambah Kos)     | (Ubah Kos)       | (Update Kamar)
   v            v                  v                  v
[Halaman     [Form Tambah]      [Form Ubah]      [Form / Dialog Kamar]
 Login]         | (Simpan)         | (Simpan)         | (Simpan)
                +------------------+------------------+
```

---

## 3. Rancangan Basis Data Supabase

Sesuai prinsip kesederhanaan (*KISS*) dan batasan ruang lingkup Versi 1, aplikasi KosFinder menggunakan **1 tabel utama** di skema publik: tabel `kos`. Data pengguna/pemilik dikelola langsung oleh modul bawaan **`auth.users`** milik Supabase Auth. Tidak diperlukan tabel profil tambahan karena pendaftaran pemilik hanya mengumpulkan email dan password, sedangkan nomor kontak telepon/WhatsApp disimpan langsung pada setiap entitas kos yang dipublikasikan.

### 3.1 Struktur Tabel `public.kos`

| Nama Kolom | Tipe Data | Nullable | Nilai Baku / Constraint | Keterangan & Alasan Kebutuhan |
|---|---|:---:|---|---|
| `id` | `UUID` | **NO** | `gen_random_uuid()` (PRIMARY KEY) | Pengidentifikasi unik untuk setiap data kos. Format UUID lebih sulit ditebak dibanding integer berurutan, namun **bukan merupakan mekanisme keamanan utama**. Perlindungan kepemilikan data tetap ditegakkan secara mutlak melalui Row Level Security (RLS). |
| `owner_id` | `UUID` | **NO** | `REFERENCES auth.users(id) ON DELETE CASCADE` | Menautkan kos dengan akun pemilik yang membuatnya (US06, US07, NFR01). |
| `name` | `TEXT` | **NO** | `CHECK (char_length(trim(name)) > 0)` | Nama kos yang dipublikasikan (US04, US06). |
| `address` | `TEXT` | **NO** | `CHECK (char_length(trim(address)) > 0)` | Alamat fisik lengkap dari kos, dicakup dalam pencarian teks bebas (US02, US04, US06, FR02). |
| `area` | `TEXT` | **NO** | `CHECK (char_length(trim(area)) > 0)` | Nama area/wilayah/kecamatan untuk pencarian teks bebas (US02, FR02). |
| `contact_number` | `TEXT` | **NO** | `CHECK (char_length(trim(contact_number)) >= 8)` | Nomor telepon/WhatsApp pemilik kos agar pencari kos dapat menghubungi (US04, FR06). |
| `price_per_month` | `BIGINT` | **NO** | `CHECK (price_per_month >= 0)` | **Wajib bertipe angka**. Menyimpan tarif sewa bulanan dalam Rupiah (US03, FR03). |
| `description` | `TEXT` | **NO** | - | Deskripsi rincian kondisi kos (US04, US06). |
| `available_rooms` | `INTEGER` | **NO** | `DEFAULT 0 CHECK (available_rooms >= 0)` | **Wajib bertipe angka >= 0**. Jumlah sisa kamar yang tersedia (US08, FR13). |
| `has_wifi` | `BOOLEAN` | **NO** | `DEFAULT FALSE` | Penanda fasilitas WiFi via checkbox pilihan tetap (US03, US06). |
| `has_bathroom_inside` | `BOOLEAN` | **NO** | `DEFAULT FALSE` | Penanda fasilitas Kamar Mandi Dalam via checkbox pilihan tetap (US03, US06). |
| `has_parking` | `BOOLEAN` | **NO** | `DEFAULT FALSE` | Penanda fasilitas Parkir via checkbox pilihan tetap (US03, US06). |
| `created_at` | `TIMESTAMPTZ` | **NO** | `now()` | Waktu pembuatan data kos. |
| `updated_at` | `TIMESTAMPTZ` | **NO** | `now()` | Waktu pembaruan data terakhir. |

### 3.2 Status Publikasi dan Ketersediaan Kamar
- **Publikasi Langsung:** Semua data kos yang berhasil ditambahkan oleh pemilik kos langsung berstatus terpublikasi secara publik dan dapat dilihat oleh pencari kos.
- **Tidak Memerlukan Kolom Status/Draf:** Versi 1 tidak memerlukan kolom `is_active` maupun fitur sakelar Draf/Aktif.
- **Ketersediaan Kamar:** Nilai `available_rooms = 0` merepresentasikan bahwa kamar kos sedang penuh (*Kamar Penuh*), dan **bukan** berarti kos tersebut disembunyikan dari daftar publik. Data kos tetap ditampilkan dengan penanda kamar habis agar pencari kos mengetahui status ketersediaannya (US08, AC08-3).

### 3.3 Strategi Query Pencarian Nama Kos, Area, dan Alamat (FR02) serta Performa
Pencarian berbasis kata kunci teks bebas (FR02) diterapkan secara fleksibel pada **tiga kolom**: kolom `name`, kolom `area`, dan kolom `address`.
- **Strategi Query:** Pada lapisan Service/Repository, aplikasi mengirimkan filter gabungan menggunakan operator OR pada Supabase Client SDK dengan pencocokan *case-insensitive* (`ilike`):
  ```dart
  supabase.from('kos').select().or('name.ilike.%$keyword%,area.ilike.%$keyword%,address.ilike.%$keyword%');
  ```
- **Karakteristik Indeks & Sequential Scan:** Karena pencarian substring menggunakan karakter wildcard di awal kata (`%keyword%`), indeks B-tree standar pada PostgreSQL **tidak dapat digunakan secara efektif** untuk mempercepat pencarian pola tersebut. Untuk target awal sekitar 20 data kos (sesuai spesifikasi pengujian NFR05), pembacaan berurutan (*Sequential Scan*) oleh basis data diperkirakan memadai untuk memenuhi target antarmuka. Performa aktual dari strategi query ini akan diverifikasi secara langsung melalui pengujian NFR05 pada lingkungan pengujian yang telah ditentukan. Oleh karena itu, indeks B-tree pada kolom `name`, `area`, dan `address` ditiadakan, serta ekstensi tambahan seperti `pg_trgm` / indeks GIN sengaja tidak ditambahkan demi menjaga kesederhanaan skema Versi 1 (*KISS*).
- **Indeks yang Tetap Digunakan:** Indeks B-tree tetap dipertahankan untuk kolom yang menggunakan perbandingan langsung atau pengurutan terindeks:
  - `idx_kos_price_per_month` untuk filter rentang numerik (`price_per_month <= max_price`).
  - `idx_kos_owner_id` untuk query filter kos milik akun pemilik yang sedang login.
  - `idx_kos_created_at` untuk pengurutan kos terbaru secara menurun (*DESC*).

---

## 4. Aturan Akses Basis Data (Row Level Security / RLS)

Sesuai aturan keamanan pada `AGENTS.md` dan NFR01, seluruh aturan kepemilikan data **wajib ditegakkan di backend menggunakan Row Level Security (RLS) PostgreSQL pada Supabase**, dan tidak boleh hanya mengandalkan penyembunyian antarmuka pada Flutter.

### 4.1 Hubungan Antara Hak Akses Tabel (GRANT) dan RLS
Penting untuk membedakan antara izin tingkat tabel dan izin tingkat baris:
- **`GRANT` (Izin Tingkat Tabel):** Mengatur jenis operasi SQL apa saja yang secara umum diizinkan untuk suatu role database (`anon` atau `authenticated`). Jika suatu role tidak memiliki izin `GRANT` untuk suatu perintah (misalnya role `anon` tidak diberi `INSERT`), maka request akan langsung ditolak pada tingkat tabel tanpa membaca baris data. Ketika RLS tidak aktif, akses tetap dibatasi oleh `GRANT`, bukan berarti semua orang otomatis dapat mengakses tabel tanpa izin `GRANT`.
- **`RLS` (Izin Tingkat Baris / Row):** Mengatur baris data mana yang boleh dilihat atau dimanipulasi oleh pengguna tertentu berdasarkan ekspresi logika (seperti `auth.uid() = owner_id`). Pengguna harus lolos kedua lapisan: memiliki izin `GRANT` pada tabel dan memenuhi kondisi kebijakan `RLS` pada baris yang dituju.
- **Hak Istimewa Bypass RLS:** Pemilik tabel (*table owner*) dan role khusus berhak istimewa administratif seperti `service_role` (atau superuser PostgreSQL) memiliki hak istimewa yang melewati (*bypass*) RLS. Oleh sebab itu, kunci `service_role` dilarang keras dimasukkan ke dalam aplikasi klien Flutter.

### 4.2 Rangkuman Kebijakan (Policies) pada Tabel `kos`

| Operasi SQL | Nama Kebijakan RLS | Sasaran Role | Ekspresi USING / WITH CHECK | Deskripsi Hak Akses |
|---|---|---|---|---|
| **SELECT** | `"Semua pengguna dapat melihat kos"` | `public`, `anon`, `authenticated` | `USING (true)` | Siapa pun (termasuk pencari kos tanpa login) dapat membaca seluruh data kos. |
| **INSERT** | `"Pemilik dapat menambahkan kos miliknya"` | `authenticated` | `WITH CHECK (auth.uid() = owner_id)` | Hanya pengguna yang login yang dapat menambah kos, dan nilai `owner_id` wajib sama dengan ID akun yang sedang login. |
| **UPDATE** | `"Pemilik hanya dapat mengubah kos miliknya sendiri"` | `authenticated` | `USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id)` | Pemilik hanya dapat mengubah baris data kos miliknya sendiri. Request update dari Pemilik B terhadap kos Pemilik A akan ditolak/tidak mempengaruhi data. |
| **DELETE** | `"Pemilik hanya dapat menghapus kos miliknya sendiri"` | `authenticated` | `USING (auth.uid() = owner_id)` | Pemilik hanya dapat menghapus data kos miliknya sendiri. Request delete dari pihak lain otomatis ditolak. |

### 4.3 Pembatasan Hak Akses Tabel Secara Eksplisit (REVOKE & GRANT)
Untuk menjamin prinsip hak akses terkecil (*least privilege*) dan kepastian konfigurasi tanpa mewarisi izin bawaan yang tidak terduga, skema menerapkan pencabutan izin secara menyeluruh terlebih dahulu lalu memberikan izin yang diperlukan secara eksplisit:
```sql
REVOKE ALL ON TABLE public.kos FROM anon, authenticated, public;
GRANT SELECT ON TABLE public.kos TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.kos TO authenticated;
```
- **Role `anon`:** Hanya memiliki izin `SELECT`. Role ini sama sekali tidak memiliki izin `INSERT`, `UPDATE`, maupun `DELETE` di tingkat tabel.
- **Role `authenticated`:** Diberikan izin `SELECT, INSERT, UPDATE, DELETE`, namun seluruh eksekusinya wajib lolos filter RLS `auth.uid() = owner_id`.
- **Role Administratif:** Hak akses langsung `service_role` tidak diubah atau dicabut agar integrasi administratif backend tetap berfungsi normal.

---

## 5. Daftar Pustaka / Package Flutter

Daftar pustaka yang digunakan dibatasi secara ketat hanya pada paket yang mutlak dibutuhkan untuk memenuhi spesifikasi fungsional, non-fungsional, dan arsitektur proyek:

| Nama Package | Versi Rekomendasi | Fungsi & Alasan Penggunaan | Keterkaitan Kebutuhan |
|---|---|---|---|
| **`provider`** | `^6.1.2` | Pustaka manajemen *state* resmi proyek KosFinder (sesuai mandat `AGENTS.md` poin 3). Memisahkan logika status aplikasi dan tampilan, menjaga efisiensi rendering antarmuka, serta mencegah kehilangan data form lokal saat kegagalan jaringan. | `AGENTS.md`, NFR03, NFR05, FR01–FR13 |
| **`supabase_flutter`** | `^2.8.0` | SDK resmi Supabase untuk Flutter. Menyediakan integrasi klien autentikasi (registrasi, login, logout berbasis JWT) dan klien database PostgreSQL dengan penegakan RLS bawaan melalui protokol terenkripsi HTTPS. | `AGENTS.md`, NFR01, NFR02, FR07–FR13 |
| **`flutter_dotenv`** | `^5.2.1` | Pustaka untuk memuat konfigurasi lokal dari file `.env`. File `.env` pada aplikasi klien Flutter **hanya digunakan untuk konfigurasi alamat URL endpoint backend dan Publishable Key (Anon Key) Supabase**. Publishable Key aman digunakan di aplikasi klien karena hak akses data dilindungi sepenuhnya oleh Row Level Security (RLS) di database. **PENTING:** Kunci rahasia administratif (`service_role key`) **TIDAK BOLEH** dimasukkan ke dalam file `.env` aplikasi Flutter, repositori kode, maupun aplikasi klien dalam bentuk apa pun. | `AGENTS.md` (Aturan Keamanan poin 1 & 2), NFR02 |

*(Catatan: Pemformatan nominal mata uang Rupiah bulanan seperti "Rp 1.500.000/bulan" dan validasi nomor telepon dapat diimplementasikan menggunakan utilitas logika bawaan Dart tanpa memerlukan paket eksternal tambahan demi mematuhi prinsip KISS).*
