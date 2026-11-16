# Spesifikasi Kebutuhan Aplikasi KosFinder (Requirements Specification)

Dokumen ini disusun berdasarkan kebutuhan pengguna pada [user-story.md](file:///c:/src/kosfinder/docs/user-story.md) untuk mendefinisikan kebutuhan fungsional (*Functional Requirements*), kebutuhan non-fungsional (*Non-Functional Requirements*), kriteria penerimaan (*Acceptance Criteria*), batasan ruang lingkup, serta matriks keterlacakan (*Traceability Matrix*) pada rilis KosFinder Versi 1.

---

## 1. Peran Pengguna & Aturan Akses

| Peran | Wajib Login | Hak Akses Utama |
|---|---|---|
| **Pencari Kos** | Tidak | Menjelajah daftar kos, mencari area, memfilter harga & fasilitas, melihat detail kos beserta kontak pemilik. |
| **Pemilik Kos** | Ya | Mendaftar akun, masuk, keluar, menambah kos, mengubah & menghapus kos milik sendiri, memperbarui ketersediaan kamar. |

---

## 2. Ruang Lingkup Versi 1 (Scope)

### 2.1 Fitur yang Termasuk dalam Versi 1 (In Scope)
1. **Pemuatan Daftar Kos Publik:** Pencari kos dapat melihat seluruh daftar kos aktif langsung dari backend tanpa perlu login.
2. **Pencarian Kos Berdasarkan Area:** Pencari kos dapat mencari kos menggunakan kata kunci teks bebas (*free-text input*) seperti nama jalan, kecamatan, atau area tanpa dropdown/autocomplete wilayah.
3. **Penyaringan Kos:** Pencari kos dapat memfilter kos berdasarkan harga maksimum per bulan (format baku Rp/bulan) dan fasilitas tetap (*fixed checkbox*: WiFi, Kamar Mandi Dalam, Parkir).
4. **Tampilan Detail Kos & Kontak Pemilik:** Menampilkan informasi detail kos (nama, alamat, harga/bulan, fasilitas, deskripsi, kamar tersedia) serta nomor telepon/WhatsApp pemilik kos agar pencari dapat menghubungi secara langsung.
5. **Autentikasi Pemilik Kos:** Registrasi pemilik baru hanya dengan email dan password (tanpa nama lengkap atau nomor telepon), login akun, dan logout akun.
6. **Penambahan Data Kos:** Pemilik kos dapat menambahkan data kos baru yang memuat seluruh informasi wajib (termasuk nomor kontak dan harga per bulan).
7. **Pengelolaan Kos Milik Sendiri:** Pemilik kos dapat mengubah dan menghapus data kos miliknya sendiri dengan penegakan otorisasi ketat di backend.
8. **Pembaruan Kamar Tersedia:** Pemilik kos dapat memperbarui jumlah kamar tersedia (>= 0), termasuk status kamar penuh jika bernilai 0.

### 2.2 Fitur yang Tidak Termasuk dalam Versi 1 (Out of Scope)
1. **Pembayaran Online:** Tidak ada integrasi dengan *payment gateway* atau dompet digital.
2. **Fitur Chat:** Tidak ada fitur perpesanan instan bawaan di dalam aplikasi; komunikasi dilakukan melalui kontak manual (telepon/WhatsApp).
3. **Ulasan dan Rating:** Tidak ada fitur memberikan ulasan, bintang, atau penilaian kos.
4. **Rekomendasi Berbasis AI:** Tidak ada algoritma rekomendasi otomatis atau fitur cerdas berbasis kecerdasan buatan.
5. **Verifikasi Identitas Pemilik:** Tidak ada proses unggah KTP/dokumen legalitas kepemilikan kos.
6. **Unggah Foto Kos (*Photo Upload*):** Tidak ada fitur penyimpanan dan penayangan file foto kos pada versi 1.
7. **Peta Interaktif (*Interactive Maps*):** Tidak ada visualisasi peta GPS atau penunjuk rute berbasis peta.
8. **Pagination & Infinite Scrolling:** Data kos dimuat secara langsung sebagai daftar biasa dari backend.
9. **Penambahan Fasilitas Kustom:** Pemilik tidak dapat menambahkan nama fasilitas sendiri di luar 3 pilihan tetap.
10. **Pilihan Periode Sewa Selain Bulanan:** Tidak ada opsi harga sewa harian, mingguan, atau tahunan.

---

## 3. Kebutuhan Fungsional (Functional Requirements)

Seluruh kebutuhan fungsional diturunkan secara langsung dari kebutuhan pada `user-story.md` dan keputusan rilis Versi 1:

| ID FR | Kebutuhan Fungsional | Deskripsi Kebutuhan | User Story Asal |
|---|---|---|---|
| **FR01** | Menampilkan Daftar Kos Publik | Sistem harus dapat memuat dan menampilkan daftar seluruh kos aktif ke pengguna (pencari kos) tanpa kewajiban login, memuat ringkasan nama kos, area, harga sewa per bulan (Rp/bulan), dan ketersediaan kamar. | US01 |
| **FR02** | Pencarian Berbasis Teks Bebas (Nama, Area, Alamat) | Sistem harus menyediakan kolom input pencarian teks bebas (*free-text input*) dan menyaring daftar kos yang memiliki nama kos, area, atau alamat yang cocok dengan kata kunci yang dimasukkan pencari kos. | US02 |
| **FR03** | Penyaringan Berdasarkan Harga Maksimum per Bulan | Sistem harus menyediakan kontrol filter untuk menyaring daftar kos dengan batasan harga sewa maksimum dalam satuan Rupiah per bulan (Rp/bulan). | US03 |
| **FR04** | Penyaringan Berdasarkan Fasilitas Tetap | Sistem harus menyediakan kontrol filter berupa *checkbox* untuk menyaring daftar kos berdasarkan fasilitas tetap (WiFi, Kamar Mandi Dalam, Parkir). | US03 |
| **FR05** | Menampilkan Rincian Lengkap Kos | Sistem harus menampilkan halaman detail lengkap suatu kos tanpa login, memuat: nama kos, alamat lengkap, harga per bulan, daftar fasilitas, deskripsi, dan jumlah kamar tersedia. | US04 |
| **FR06** | Menampilkan Kontak Telepon/WhatsApp Pemilik | Sistem harus menampilkan nomor telepon/WhatsApp pemilik kos pada halaman detail kos agar pencari kos dapat menghubungi pemilik secara manual tanpa fitur chat aplikasi. | US04 |
| **FR07** | Pendaftaran Akun Pemilik Kos | Sistem harus menyediakan formulir pendaftaran pemilik kos yang hanya membutuhkan email unik dan kata sandi, serta mengarahkan ke halaman login setelah registrasi sukses. | US05 |
| **FR08** | Masuk (Login) Akun Pemilik Kos | Sistem harus memvalidasi kredensial (email dan kata sandi) pemilik kos dan memberikan sesi otentikasi aktif untuk mengakses modul pengelolaan kos. | US05 |
| **FR09** | Keluar (Logout) Akun Pemilik Kos | Sistem harus memungkinkan pemilik kos untuk mengakhiri sesi aktif (*logout*), menghapus sesi/token, dan mengembalikan antarmuka ke mode publik. | US05 |
| **FR10** | Menambahkan Data Kos Baru | Sistem harus memungkinkan pemilik kos yang telah login untuk menambahkan kos baru dengan mengisi nama, alamat, nomor telepon/WhatsApp, harga per bulan, fasilitas tetap via checkbox, deskripsi, dan kamar tersedia (>= 0). | US06 |
| **FR11** | Mengubah Data Kos Milik Sendiri | Sistem harus memungkinkan pemilik kos untuk memperbarui informasi data kos yang dimilikinya sendiri dan menolak pengubahan terhadap kos milik pemilik lain. | US07 |
| **FR12** | Menghapus Data Kos Milik Sendiri | Sistem harus memungkinkan pemilik kos untuk menghapus data kos yang dimilikinya sendiri dari sistem melalui dialog konfirmasi, serta menolak penghapusan terhadap kos milik orang lain. | US07 |
| **FR13** | Memperbarui Jumlah Kamar Tersedia | Sistem harus menyediakan antarmuka bagi pemilik kos untuk memperbarui jumlah kamar tersedia (>= 0) pada kos miliknya, dan langsung merefleksikan perubahan ke publik. | US08 |

---

## 4. Kebutuhan Non-Fungsional (Non-Functional Requirements)

Kebutuhan non-fungsional disusun untuk menjamin kualitas aplikasi pada aspek keamanan, keandalan, kemudahan penggunaan, performa, dan privasi:

### NFR01: Keamanan (Security) – Penegakan Otorisasi Data Kos Berbasis Row Level Security (RLS) di Backend
- **Deskripsi:**  
  Sistem wajib menjamin bahwa pemilik kos hanya dapat mengubah (*UPDATE*) dan menghapus (*DELETE*) data kos miliknya sendiri. Penegakan hak akses otorisasi ini **wajib ditegakkan di level database backend menggunakan Supabase Row Level Security (RLS)**, dan **tidak boleh hanya mengandalkan penyembunyian tombol pada antarmuka aplikasi Flutter**.
- **Cara Pengujian:**  
  1. Siapkan data "Kos A" yang terdaftar atas nama Akun Pemilik A.
  2. Lakukan login sebagai Akun Pemilik B melalui aplikasi/API untuk mendapatkan *access token / JWT* resmi milik Pemilik B.
  3. Menggunakan alat pengujian API (seperti cURL, Postman, atau script tes integrasi), kirimkan request HTTP langsung ke endpoint REST API Supabase (melewati/bypassing antarmuka Flutter) menggunakan token Pemilik B:
     - Request UPDATE: `PATCH /rest/v1/kos?id=eq.<ID_Kos_A>` dengan payload perubahan nama atau harga.
     - Request DELETE: `DELETE /rest/v1/kos?id=eq.<ID_Kos_A>`.
  4. Periksa kondisi data "Kos A" di database setelah request dieksekusi. Pengujian dinyatakan **berhasil (PASS)** jika data "Kos A" tetap utuh tanpa perubahan nilai atribut dan tidak terhapus dari database. Pengujian dinyatakan **gagal (FAIL)** jika data milik Pemilik A berubah atau terhapus, terlepas dari status kode HTTP yang dikembalikan oleh backend (apakah 403, 401, 404, atau 200/204 dengan 0 rows affected).

### NFR02: Keamanan (Security) – Proteksi Kredensial dan Enkripsi Komunikasi
- **Deskripsi:**  
  Seluruh komunikasi antara aplikasi Flutter dan backend Supabase wajib menggunakan protokol terenkripsi HTTPS/TLS. Manajemen autentikasi pemilik kos wajib menggunakan layanan Supabase Auth yang secara otomatis mengelola hashing kata sandi dengan algoritma kriptografi yang aman (seperti bcrypt), sehingga kata sandi tidak pernah disimpan dalam bentuk teks biasa (*plaintext*).
- **Cara Pengujian:**  
  1. Periksa konfigurasi proyek Flutter dan Supabase Client untuk memastikan URL endpoint backend menggunakan protokol aman `https://`.
  2. Pantau lalu lintas jaringan (network traffic) menggunakan network inspector / web debugging proxy untuk memastikan seluruh request autentikasi (sign-up, sign-in) terenkripsi saat transit.
  3. Verifikasi implementasi kode autentikasi bahwa proses pendaftaran dan login sepenuhnya mendelegasikan penanganan kredensial ke fungsi resmi Supabase Auth (`supabase.auth.signUp()` dan `supabase.auth.signInWithPassword()`), tanpa ada penyimpanan lokal atau pengiriman kata sandi mentah ke tabel aplikasi kustom.

### NFR03: Keandalan (Reliability) – Penanganan Kesalahan Jaringan dan Konsistensi Data Formulir
- **Deskripsi:**  
  Aplikasi harus menangani kegagalan jaringan atau server yang tidak merespons secara anggun (*graceful error handling*) tanpa mengalami *crash* atau *freeze*. Pada halaman pemuatan data yang telah ditentukan dalam acceptance criteria (halaman daftar kos dan detail kos), sistem wajib menyediakan tombol coba lagi (*Retry*). Pada seluruh formulir (pendaftaran, login, tambah kos, ubah kos), aplikasi wajib menampilkan pesan kesalahan yang ramah pengguna saat koneksi gagal dan tidak mengosongkan data yang telah diketikkan pengguna.
- **Cara Pengujian:**  
  1. Jalankan aplikasi pada perangkat/emulator, lalu matikan koneksi internet (aktifkan Airplane Mode atau matikan sambungan jaringan).
  2. Buka halaman daftar kos dan detail kos: verifikasi aplikasi tidak *crash*, menampilkan pesan kesalahan jaringan yang jelas, dan menyediakan tombol *Retry*.
  3. Isi data pada formulir tambah kos, ubah kos, atau autentikasi, lalu tekan tombol aksi (simpan/daftar/masuk) dalam kondisi offline: verifikasi aplikasi tidak *crash*, menampilkan notifikasi kesalahan jaringan, dan data yang telah diketikkan pada form tetap bertahan (tidak terhapus/reset).
  4. Aktifkan kembali internet, tekan tombol *Retry* pada halaman pemuatan data, dan pastikan data berhasil dimuat normal.

### NFR04: Kemudahan Penggunaan (Usability) – Akses Tamu Tanpa Hambatan dan Kejelasan Validasi
- **Deskripsi:**  
  Aplikasi harus memberikan pengalaman tanpa hambatan (*zero-friction*) bagi pencari kos, di mana pencari kos dapat melihat daftar, mencari area, memfilter fasilitas, dan melihat detail kos tanpa diminta mendaftar atau login. Seluruh kolom formulir harus memiliki indikator yang jelas dan pesan kesalahan validasi yang muncul langsung di dekat field yang bermasalah.
- **Cara Pengujian:**  
  1. Lakukan instalasi baru (*clean state*) dan jalankan alur pencarian kos secara penuh (buka aplikasi, cari area, filter fasilitas, buka detail) tanpa melakukan autentikasi apa pun. Pastikan tidak ada dialog login yang muncul atau menghalangi aksi.
  2. Buka formulir input (misal Tambah Kos atau Registrasi), kosongkan kolom wajib dan tekan tombol simpan; pastikan pesan validasi spesifik langsung muncul pada masing-masing field.

### NFR05: Performa (Performance) – Responsivitas UI dan Kecepatan Pemuatan Data
- **Deskripsi:**  
  Antarmuka aplikasi harus responsif dengan menampilkan umpan balik visual (*loading indicator* atau *progress state*) dalam waktu kurang dari 200 ms setelah aksi pengguna dipicu. Pada kondisi dataset acuan berupa 20 data kos aktif di backend, seluruh daftar kos harus selesai dimuat dan dirender di layar dalam waktu kurang dari 2 detik. Pengujian dilakukan menggunakan perangkat fisik Android atau emulator dengan RAM minimal 4 GB serta koneksi internet stabil (kecepatan unduh minimal 10 Mbps dan latency di bawah 100 ms). Pengukuran durasi dilakukan sejak pengguna membuka halaman daftar kos sampai seluruh 20 data kos selesai ditampilkan.
- **Cara Pengujian:**  
  1. Siapkan dataset pengujian yang konsisten berupa 20 data kos aktif yang tersedia di backend Supabase.
  2. Siapkan lingkungan pengujian acuan menggunakan perangkat Android fisik atau emulator dengan spesifikasi RAM minimal 4 GB serta koneksi internet stabil (kecepatan unduh minimal 10 Mbps dan latency di bawah 100 ms).
  3. Buka halaman daftar kos, lalu gunakan Flutter DevTools (tab *Performance* & *Network*) atau utilitas *Stopwatch* terukur pada kode aplikasi untuk mencatat waktu.
  4. Verifikasi bahwa umpan balik visual (*loading indicator*) muncul dalam waktu kurang dari 200 ms sejak pengguna membuka halaman.
  5. Ukur total waktu dari saat pengguna membuka halaman daftar kos hingga seluruh 20 data kos selesai dimuat dan dirender di layar; pastikan total waktu berada di bawah 2 detik.

### NFR06: Privasi (Privacy) – Prinsip Minimalisasi Pengumpulan Data Pengguna
- **Deskripsi:**  
  Aplikasi menerapkan prinsip minimalisasi data (*data minimization*). Sistem hanya mengumpulkan data yang mutlak diperlukan untuk operasional aplikasi (email dan password untuk akun pemilik; nomor kontak pemilik untuk dicantumkan pada kos). Aplikasi tidak meminta izin akses perangkat yang tidak relevan (seperti lokasi GPS latar belakang, akses kontak pribadi, kamera, atau penyimpanan internal).
- **Cara Pengujian:**  
  1. Periksa berkas konfigurasi izin perangkat (`AndroidManifest.xml` pada Android dan `Info.plist` pada iOS) dan pastikan tidak terdapat deklarasi izin seperti `ACCESS_FINE_LOCATION`, `READ_CONTACTS`, atau `CAMERA`.
  2. Verifikasi skema database Supabase bahwa tidak ada tabel atau kolom yang merekam data pribadi pencari kos tamu.

---

## 5. Spesifikasi Kebutuhan & Acceptance Criteria (US01 - US08)

Format acceptance criteria menggunakan struktur standar:
- **Given** (Kondisi awal/prasyarat)
- **When** (Tindakan atau peristiwa)
- **Then** (Hasil yang diharapkan)

---

### US01: Melihat Daftar Kos
> *Sebagai pencari kos, saya ingin melihat daftar kos, agar saya tahu pilihan yang tersedia.*

#### AC01-1: Menampilkan daftar kos tanpa login (Akses Tamu / Guest)
- **Given** pengguna belum melakukan login (sebagai pencari kos) dan terdapat data kos aktif di sistem.
- **When** pengguna membuka aplikasi pada halaman utama / daftar kos.
- **Then** sistem menampilkan seluruh daftar kos aktif sebagai daftar biasa dari backend (tanpa pagination dan tanpa infinite scrolling pada Versi 1), memuat ringkasan informasi kos (nama kos, area, harga sewa per bulan [Rp/bulan], dan jumlah kamar tersedia) tanpa memunculkan dialog login atau memblokir akses pengguna.

#### AC01-2: Tampilan ketika data kos kosong
- **Given** pengguna membuka halaman daftar kos dan belum ada data kos yang terdaftar di dalam sistem.
- **When** halaman daftar kos selesai dimuat.
- **Then** sistem menampilkan status kosong dengan pesan informatif (misal: *"Belum ada kos yang terdaftar saat ini"*) dan tidak menampilkan halaman putih/blank.

#### AC01-3: Penanganan kegagalan koneksi jaringan saat memuat daftar kos
- **Given** koneksi internet perangkat terputus atau server backend tidak dapat dihubungi.
- **When** pengguna membuka halaman daftar kos.
- **Then** sistem menampilkan pesan kesalahan jaringan (misal: *"Gagal memuat data kos. Silakan periksa koneksi internet Anda"*) serta menyediakan tombol aksi untuk mencoba kembali (*Retry*).

---

### US02: Mencari Kos Berdasarkan Nama, Area, dan Alamat
> *Sebagai pencari kos, saya ingin mencari kos berdasarkan nama kos, area, atau alamat, agar dapat menemukan kos sesuai kebutuhan lokasi dan nama kos yang saya inginkan.*

#### AC02-1: Pencarian berdasarkan kata kunci nama kos, area, atau alamat yang cocok (Input Teks Bebas)
- **Given** pengguna berada di halaman daftar kos tanpa perlu login, dan tersedia kolom input pencarian teks bebas (*free-text input*) tanpa dropdown atau autocomplete wilayah.
- **When** pengguna mengetikkan teks bebas nama kos, nama jalan, kecamatan, atau area (misal: *"Mawar"* atau *"Tembalang"*) pada kolom pencarian dan menekan tombol cari.
- **Then** sistem menampilkan daftar kos yang memiliki informasi nama kos, area, atau alamat yang cocok dengan kata kunci tersebut secara *case-insensitive*.

#### AC02-2: Hasil pencarian tidak ditemukan
- **Given** pengguna berada di halaman pencarian tanpa login.
- **When** pengguna memasukkan kata kunci nama, area, atau alamat yang tidak memiliki kos terdaftar (misal: *"NamaAtauAreaTidakAda"*) lalu menekan tombol cari.
- **Then** sistem menampilkan pesan bahwa kos dengan kata kunci tersebut tidak ditemukan (misal: *"Tidak ditemukan kos dengan kata kunci 'NamaAtauAreaTidakAda'"*) dan menyarankan pengguna untuk mencoba kata kunci lain.

#### AC02-3: Penanganan kegagalan koneksi jaringan saat melakukan pencarian
- **Given** pengguna telah mengetikkan kata kunci pencarian.
- **When** pengguna mengeksekusi pencarian dalam kondisi jaringan terputus atau backend gagal merespons.
- **Then** sistem menampilkan notifikasi kesalahan koneksi dan teks yang sudah diketikkan pengguna pada kolom pencarian tidak hilang.

---

### US03: Menyaring Kos Berdasarkan Harga Maksimum dan Fasilitas
> *Sebagai pencari kos, saya ingin menyaring kos berdasarkan harga maksimum dan fasilitas (wifi, kamar mandi dalam, parkir), agar sesuai kebutuhan dan anggaran.*

#### AC03-1: Menyaring berdasarkan harga maksimum per bulan dan fasilitas spesifik (Pilihan Tetap)
- **Given** pengguna berada di halaman daftar kos tanpa login, dan pada menu filter tersedia input filter harga maksimum dalam satuan Rupiah per bulan (Rp/bulan) tanpa pilihan periode lain (harian/mingguan/tahunan), serta pilihan tetap fasilitas berupa checkbox (WiFi, Kamar Mandi Dalam, Parkir).
- **When** pengguna menentukan filter harga maksimum per bulan (misal: Rp 1.500.000/bulan) dan mencentang fasilitas *"WiFi"* serta *"Kamar Mandi Dalam"*, lalu menekan tombol *"Terapkan Filter"*.
- **Then** sistem hanya menampilkan kos yang memiliki harga sewa per bulan kurang dari atau sama dengan Rp 1.500.000/bulan serta memiliki fasilitas WiFi dan kamar mandi dalam.

#### AC03-2: Hasil filter tidak menemukan kos yang sesuai kriteria
- **Given** pengguna menentukan kombinasi filter harga atau fasilitas yang tidak ada pada data kos manapun (misal harga maksimum terlalu rendah atau kombinasi fasilitas tidak tersedia).
- **When** pengguna menekan tombol *"Terapkan Filter"*.
- **Then** sistem menampilkan pesan informasi bahwa tidak ada kos yang cocok dengan kriteria filter tersebut.

---

### US04: Melihat Detail Kos
> *Sebagai pencari kos, saya ingin melihat detail kos (nama, alamat, harga, fasilitas, deskripsi, kamar tersedia), agar dapat memutuskan sebelum menghubungi pemilik.*

#### AC04-1: Menampilkan seluruh komponen detail kos dan kontak pemilik tanpa login
- **Given** pengguna belum melakukan login dan berada di halaman daftar kos.
- **When** pengguna menekan salah satu kartu kos.
- **Then** sistem membuka halaman detail kos yang secara lengkap menampilkan:
  1. Nama kos
  2. Alamat lengkap
  3. Harga sewa dalam satuan Rupiah per bulan (Rp/bulan)
  4. Daftar fasilitas yang tersedia (WiFi, Kamar Mandi Dalam, Parkir)
  5. Deskripsi kos
  6. Jumlah kamar yang tersedia
  7. Nomor kontak telepon/WhatsApp pemilik kos untuk dihubungi langsung oleh pencari kos (sistem tidak menyediakan fitur chat bawaan aplikasi)
  tanpa mewajibkan pengguna untuk mendaftar atau login terlebih dahulu.

#### AC04-2: Menangani data kos yang tidak ditemukan atau telah dihapus
- **Given** pengguna mengakses tautan/ID kos yang datanya sudah tidak ada atau telah dihapus oleh pemilik.
- **When** halaman detail kos dimuat.
- **Then** sistem menampilkan pesan kesalahan *"Kos tidak ditemukan atau sudah tidak tersedia"* dan menyediakan tombol navigasi untuk kembali ke halaman daftar kos.

#### AC04-3: Penanganan kegagalan jaringan saat memuat halaman detail
- **Given** koneksi internet terputus saat pengguna membuka halaman detail kos.
- **When** data detail kos gagal diambil dari server.
- **Then** sistem menampilkan pesan error *"Gagal memuat detail kos. Periksa koneksi Anda"* disertai tombol untuk memuat ulang (*Retry*).

---

### US05: Pendaftaran, Masuk, dan Keluar Pemilik Kos
> *Sebagai pemilik kos, saya ingin mendaftar, masuk, dan keluar dari aplikasi, agar dapat mengelola kos saya.*

#### AC05-1: Pendaftaran akun baru pemilik kos berhasil (Hanya Email dan Password)
- **Given** calon pemilik kos berada pada halaman pendaftaran (*Register*).
- **When** calon pemilik mengisi formulir pendaftaran yang hanya memerlukan email dan kata sandi (tanpa memerlukan nama lengkap atau nomor telepon tambahan) dengan data yang valid, lalu menekan tombol *"Daftar"*.
- **Then** sistem membuat akun pemilik baru, menampilkan pesan sukses, dan mengarahkan pengguna ke halaman login.

#### AC05-2: Validasi pendaftaran dengan data tidak valid atau email duplikat
- **Given** calon pemilik berada pada halaman pendaftaran.
- **When** calon pemilik memasukkan email yang sudah terdaftar atau format isian tidak valid lalu menekan tombol *"Daftar"*.
- **Then** sistem menolak pendaftaran dan menampilkan pesan kesalahan validasi yang jelas di dekat kolom input yang bermasalah.

#### AC05-3: Masuk (Login) pemilik kos berhasil
- **Given** pemilik kos telah memiliki akun terdaftar dan berada di halaman login.
- **When** pemilik memasukkan email dan kata sandi yang valid lalu menekan tombol *"Masuk"*.
- **Then** sistem memvalidasi data akun, membuka sesi login, dan mengarahkan pemilik ke halaman pengelolaan kos miliknya.

#### AC05-4: Masuk (Login) dengan kredensial salah
- **Given** pengguna berada di halaman login.
- **When** pengguna memasukkan email yang belum terdaftar atau kata sandi yang salah lalu menekan tombol *"Masuk"*.
- **Then** sistem menolak login dan menampilkan pesan kesalahan *"Email atau kata sandi yang Anda masukkan salah"*, tanpa memberikan petunjuk spesifik apakah email atau kata sandinya yang keliru demi keamanan.

#### AC05-5: Keluar (Logout) dari akun pemilik kos
- **Given** pemilik kos sedang berada dalam keadaan login.
- **When** pemilik menekan tombol *"Keluar"* (*Logout*) dan mengonfirmasinya.
- **Then** sistem menghapus token/sesi login pengguna dan mengembalikan pengguna ke halaman utama publik, serta mencegah akses kembali ke halaman kelola kos tanpa login ulang.

#### AC05-6: Penanganan kegagalan jaringan saat proses autentikasi
- **Given** pengguna melakukan aksi login atau registrasi saat koneksi internet terputus.
- **When** form dikirimkan ke server.
- **Then** sistem menampilkan pesan kesalahan jaringan tanpa membuat aplikasi macet (*freeze*), dan data yang diisikan tetap dipertahankan pada formulir.

---

### US06: Menambahkan Kos
> *Sebagai pemilik kos, saya ingin menambahkan kos, agar kos saya dapat ditemukan pencari.*

#### AC06-1: Menambahkan kos baru dengan data lengkap, kontak pemilik, dan fasilitas pilihan tetap
- **Given** pemilik kos telah login dan berada pada halaman *"Tambah Kos"* yang menyediakan pilihan fasilitas tetap berbentuk checkbox (WiFi, Kamar Mandi Dalam, Parkir) tanpa opsi menambah fasilitas manual.
- **When** pemilik mengisi seluruh data wajib (nama kos, alamat, nomor telepon/WhatsApp aktif pemilik kos, harga sewa per bulan [Rp/bulan], memilih fasilitas yang relevan dari checkbox yang tersedia, deskripsi, dan jumlah kamar tersedia >= 0) lalu menekan tombol *"Simpan"*.
- **Then** sistem menyimpan data kos baru, mengasosiasikan kos tersebut dengan ID pemilik yang sedang login, dan menampilkannya pada daftar kos milik pemilik serta pada daftar kos pencari (termasuk nomor kontak dan harga per bulan).

#### AC06-2: Validasi input data kos kosong atau tidak valid
- **Given** pemilik kos berada pada formulir tambah kos.
- **When** pemilik mengosongkan salah satu kolom wajib (misal nama kos atau harga) atau memasukkan angka negatif pada harga/kamar lalu menekan *"Simpan"*.
- **Then** sistem menolak penyimpanan dan menampilkan pesan validasi spesifik pada masing-masing kolom yang belum valid. (Catatan: Fasilitas bersifat opsional atau dapat dipilih minimal 0 sampai 3 opsi dari checkbox tetap yang tersedia).

#### AC06-3: Pembatasan akses tambah kos bagi pengguna yang belum login
- **Given** pengguna belum melakukan login (sebagai pencari kos / guest).
- **When** pengguna mencoba mengakses navigasi atau halaman formulir tambah kos.
- **Then** sistem memblokir akses dan mengalihkan pengguna ke halaman login dengan pesan *"Silakan login sebagai pemilik kos untuk menambahkan kos"*.

#### AC06-4: Penanganan kegagalan koneksi jaringan saat menyimpan kos baru
- **Given** pemilik kos menekan tombol *"Simpan"* pada form tambah kos.
- **When** proses pengiriman data gagal karena koneksi terputus atau server backend bermasalah.
- **Then** sistem menampilkan pesan error *"Gagal menyimpan kos. Silakan coba kembali"* dan tidak menghapus data yang telah diketikkan oleh pemilik.

---

### US07: Mengubah dan Menghapus Kos Milik Sendiri
> *Sebagai pemilik kos, saya ingin mengubah dan menghapus kos MILIK SAYA SENDIRI, agar informasinya selalu benar, dan pemilik lain tidak dapat mengubah kos saya.*

#### AC07-1: Mengubah informasi kos milik sendiri
- **Given** Pemilik A telah login dan berada di halaman detail/edit kos miliknya.
- **When** Pemilik A mengubah data kos (seperti nama kos, alamat, nomor telepon/WhatsApp, harga sewa per bulan [Rp/bulan], fasilitas checkbox, deskripsi, atau kamar tersedia) lalu menekan *"Simpan Perubahan"*.
- **Then** sistem memperbarui data kos tersebut di database dan menampilkan data terbaru dengan pesan konfirmasi sukses.

#### AC07-2: Menghapus kos milik sendiri dengan dialog konfirmasi
- **Given** Pemilik A telah login dan berada di daftar kos miliknya.
- **When** Pemilik A memilih opsi *"Hapus"* pada kos miliknya dan menekan *"Ya, Hapus"* pada dialog konfirmasi.
- **Then** sistem menghapus kos tersebut dari database sehingga kos tidak lagi muncul di daftar kos pencari maupun daftar kelola pemilik.

#### AC07-3: Penolakan otorisasi saat mencoba mengubah atau menghapus kos milik orang lain
- **Given** Pemilik A telah login, dan terdapat data kos "Kos Melati" yang dibuat dan dimiliki oleh Pemilik B.
- **When** Pemilik A mencoba mengakses antarmuka edit atau mengirimkan permintaan (*request*) ubah/hapus terhadap data "Kos Melati" (misal melalui manipulasi ID parameter atau endpoint).
- **Then** sistem menolak aksi tersebut dengan status akses ditolak (*403 Forbidden*), tidak melakukan perubahan/penghapusan pada data "Kos Melati", dan menampilkan pesan kesalahan *"Anda tidak memiliki hak untuk mengelola kos ini"*.

#### AC07-4: Penanganan kegagalan koneksi saat ubah atau hapus kos
- **Given** pemilik kos melakukan aksi update atau delete kos miliknya.
- **When** koneksi jaringan terputus saat request dikirimkan ke server.
- **Then** sistem menampilkan pesan kesalahan koneksi dan tidak mengubah status tampilan lokal sebelum mendapatkan respons sukses dari backend.

---

### US08: Memperbarui Jumlah Kamar Tersedia
> *Sebagai pemilik kos, saya ingin memperbarui jumlah kamar tersedia, agar pencari tahu apakah masih ada kamar.*

#### AC08-1: Pembaruan jumlah kamar tersedia dengan angka valid
- **Given** pemilik kos telah login dan membuka menu pembaruan kamar pada kos miliknya yang memiliki 5 kamar tersedia.
- **When** pemilik mengubah jumlah kamar menjadi 2 dan menekan tombol simpan.
- **Then** sistem memperbarui data kamar tersedia menjadi 2 dan perubahan tersebut langsung terrefleksi pada tampilan detail kos untuk pencari.

#### AC08-2: Validasi angka kamar tidak boleh bernilai negatif
- **Given** pemilik kos berada pada form/input pembaruan jumlah kamar.
- **When** pemilik memasukkan nilai di bawah 0 (misal: -1) atau format selain angka dan mencoba menyimpan.
- **Then** sistem menolak pembaruan dan menampilkan pesan kesalahan *"Jumlah kamar tidak boleh kurang dari 0"*.

#### AC08-3: Pembaruan kamar tersedia menjadi 0 (Kamar Penuh)
- **Given** pemilik kos memperbarui jumlah kamar tersedia menjadi 0.
- **When** data disimpan.
- **Then** sistem memperbarui data dan pada tampilan pencari kos ditampilkan status jumlah kamar 0 atau indikator *"Kamar Penuh / Habis"*.

#### AC08-4: Penolakan otorisasi pembaruan kamar kos milik orang lain
- **Given** Pemilik A mencoba mengirimkan permintaan pembaruan jumlah kamar untuk kos milik Pemilik B.
- **When** request diterima oleh sistem backend.
- **Then** sistem memblokir request dengan respons otorisasi gagal (*403 Forbidden*) dan jumlah kamar pada kos Pemilik B tetap tidak berubah.

---

## 6. Traceability Matrix

Matriks berikut memetakan keterkaitan utuh antara setiap *User Story*, *Functional Requirement* (FR), dan *Acceptance Criteria* (AC) yang mengujinya:

| User Story | Functional Requirement (FR) | Acceptance Criteria (AC) |
|---|---|---|
| **US01: Melihat Daftar Kos** | **FR01** (Menampilkan Daftar Kos Publik) | AC01-1, AC01-2, AC01-3 |
| **US02: Mencari Kos Berdasarkan Area** | **FR02** (Pencarian Area Berbasis Teks Bebas) | AC02-1, AC02-2, AC02-3 |
| **US03: Menyaring Berdasarkan Harga & Fasilitas** | **FR03** (Penyaringan Harga Maksimum per Bulan)<br>**FR04** (Penyaringan Fasilitas Tetap) | AC03-1, AC03-2 |
| **US04: Melihat Detail Kos** | **FR05** (Menampilkan Rincian Lengkap Kos)<br>**FR06** (Menampilkan Kontak Pemilik) | AC04-1, AC04-2, AC04-3 |
| **US05: Pendaftaran, Masuk, Keluar Pemilik** | **FR07** (Pendaftaran Akun Pemilik Kos)<br>**FR08** (Masuk/Login Akun Pemilik Kos)<br>**FR09** (Keluar/Logout Akun Pemilik Kos) | AC05-1, AC05-2, AC05-3, AC05-4, AC05-5, AC05-6 |
| **US06: Menambahkan Kos** | **FR10** (Menambahkan Data Kos Baru) | AC06-1, AC06-2, AC06-3, AC06-4 |
| **US07: Mengubah & Menghapus Kos Sendiri** | **FR11** (Mengubah Data Kos Milik Sendiri)<br>**FR12** (Menghapus Data Kos Milik Sendiri) | AC07-1, AC07-2, AC07-3, AC07-4 |
| **US08: Memperbarui Kamar Tersedia** | **FR13** (Memperbarui Jumlah Kamar Tersedia) | AC08-1, AC08-2, AC08-3, AC08-4 |

---

## 7. Matriks Skenario Khusus yang Wajib Dicakup

| Skenario Khusus | Referensi Acceptance Criteria |
|---|---|
| **Data Kos Kosong / Hasil Pencarian Tidak Ditemukan** | AC01-2 (Daftar kos kosong), AC02-2 (Area tidak ditemukan), AC03-2 (Filter tidak ditemukan) |
| **Koneksi Jaringan / Backend Gagal** | AC01-3, AC02-3, AC04-3, AC05-6, AC06-4, AC07-4 |
| **Otorisasi Kepemilikan (Mencoba Akses Kos Pemilik Lain)** | AC07-3 (Ubah/Hapus kos orang lain ditolak), AC08-4 (Update kamar orang lain ditolak) |
| **Akses Tanpa Login untuk Pencari Kos** | AC01-1 (Daftar kos), AC02-1 (Cari area), AC03-1 (Filter), AC04-1 (Detail kos) |
| **Wajib Login untuk Pengelolaan Kos oleh Pemilik** | AC05-3, AC06-3 (Blokir guest tambah kos), AC07-1, AC08-1 |

---

## 8. Catatan Klarifikasi & Pertanyaan Terjawab (Open Questions Resolved)

Seluruh pertanyaan dan aspek ambigu yang sebelumnya diidentifikasi telah dibahas dan disepakati secara final untuk ruang lingkup Versi 1:
- **Kontak Pemilik Kos:** Pemilik mengisi nomor telepon/WhatsApp saat menambah/mengubah kos; nomor kontak ditampilkan di detail kos; fitur chat ditiadakan.
- **Pencarian Area Kos:** Menggunakan input teks bebas (*free-text input*) tanpa dropdown atau autocomplete wilayah.
- **Pendaftaran Pemilik:** Formulir pendaftaran hanya memerlukan email dan password (tanpa nama lengkap atau nomor telepon tambahan).
- **Satuan Harga Sewa:** Seluruh harga sewa menggunakan format baku Rupiah per bulan (Rp/bulan) tanpa opsi sewa periode lain.
- **Pemuatan Daftar Kos:** Daftar kos ditampilkan sebagai daftar biasa dari backend tanpa pagination atau infinite scrolling.
- **Fasilitas Kos:** Menggunakan pilihan tetap (*fixed checkbox*) berisi WiFi, kamar mandi dalam, dan parkir tanpa opsi penambahan kustom.

*Saat ini tidak ada pertanyaan ambigu atau open questions yang tersisa untuk kebutuhan dan ruang lingkup Versi 1.*
