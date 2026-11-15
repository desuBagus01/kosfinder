# Rencana Tugas Pengembangan KosFinder (Vertical Slice Tasks)

Dokumen ini memuat daftar tugas pengembangan perangkat lunak untuk aplikasi **KosFinder** Versi 1. Tugas disusun secara berurutan menggunakan pendekatan **Vertical Slice Architecture** (Screen – Provider – Repository – Service) agar setiap irisan (*slice*) menghasilkan aplikasi Flutter yang dapat dijalankan (*runnable*), teruji, dan mempertahankan seluruh fitur dari irisan sebelumnya.

---

## Ringkasan Alur Vertical Slice

1. **Slice 1: Daftar dan Detail Kos (Akses Tamu / Publik)**  
   Menghasilkan aplikasi yang dapat menampilkan seluruh data kos dan detail lengkap kos dari Supabase tanpa kewajiban login, menangani data kosong dan gangguan jaringan, serta mempertahankan halaman About.
2. **Slice 2: Pencarian dan Filter**  
   Menambahkan bar pencarian teks bebas (area dan alamat) serta modal filter harga bulanan maksimum dan fasilitas tetap (WiFi, Kamar Mandi Dalam, Parkir).
3. **Slice 3: Login Pemilik (Termasuk Registrasi dan Logout)**  
   Menyediakan modul autentikasi akun pemilik kos menggunakan Supabase Auth (daftar email & kata sandi, login, logout, dan manajemen sesi).
4. **Slice 4: Tambah, Ubah, dan Hapus Kos Milik Sendiri**  
   Menyediakan modul manajemen kos mandiri bagi pemilik kos terautentikasi dengan penegakan otorisasi ketat di backend (Row Level Security).
5. **Slice 5: Pembaruan Ketersediaan Kamar & Integrasi Akhir**  
   Menyediakan fungsi pembaruan cepat jumlah kamar tersedia (termasuk status Kamar Penuh jika 0) serta verifikasi menyeluruh seluruh kriteria penerimaan.

---

## Slice 1: Daftar dan Detail Kos

### TASK-1.1: Konfigurasi Proyek, Dependensi & Model Data Kos
- **Tujuan Pengerjaan:** Menambahkan pustaka resmi yang disetujui (`provider`, `supabase_flutter`, `flutter_dotenv`) ke `pubspec.yaml`, membuat file `.env.example` yang hanya berisi placeholder konfigurasi (`SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY`), memastikan `.env` tercantum dalam `.gitignore`, membaca kredensial backend Supabase secara konsisten dari konfigurasi eksternal (`SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY`) baik di `.env.example`, konfigurasi `.env`, maupun kode inisialisasi Flutter tanpa pernah menggunakan atau menyimpan `service_role key` pada aplikasi Flutter, serta membuat model data `KosModel` yang *type-safe* untuk parsing data dari PostgreSQL Supabase.
- **Requirement Terkait:** Fondasi untuk FR01 & FR05, US01, US04.
- **Acceptance Criteria Terkait:** AC01-1, AC04-1, NFR02.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `pubspec.yaml`
  - `.env.example`
  - `.gitignore`
  - `lib/models/kos_model.dart`
  - `test/models/kos_model_test.dart`
- **Langkah Pengujian:**
  1. Jalankan `flutter pub get` untuk memastikan seluruh pustaka berhasil terpasang tanpa konflik versi.
  2. Periksa berkas `.gitignore` untuk memastikan `.env` terdaftar dan tidak terlacak di Git.
  3. Periksa berkas `.env.example` untuk memastikan konsistensi penamaan variabel (`SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY`) serta hanya memuat placeholder aman tanpa kredensial asli maupun `service_role key`.
  4. Jalankan unit test `kos_model_test.dart` untuk memverifikasi serialisasi dan deserialisasi JSON (termasuk konversi tipe numerik `price_per_month` dan `available_rooms`).
  5. Jalankan `flutter analyze` untuk memastikan tidak ada issue.
- **Status:** Pending

---

### TASK-1.2: Implementasi Service dan Repository Kos (Akses Baca Publik)
- **Tujuan Pengerjaan:** Membuat `SupabaseKosService` untuk menjalankan query pembacaan ke Supabase dan `KosRepository` sebagai lapisan abstraksi data untuk mengambil seluruh data kos (`getKosList`) dan rincian detail kos (`getKosDetailById`).
- **Requirement Terkait:** FR01, FR05, US01, US04.
- **Acceptance Criteria Terkait:** AC01-1, AC01-2, AC01-3, AC04-1, AC04-2, AC04-3, NFR02, NFR03.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/services/supabase_kos_service.dart`
  - `lib/repositories/kos_repository.dart`
  - `test/repositories/kos_repository_test.dart`
- **Langkah Pengujian:**
  1. Jalankan unit test `kos_repository_test.dart` dengan mock service untuk menguji skenario pemuatan data berhasil.
  2. Uji penanganan skenario data kosong (`[]`).
  3. Uji penanganan skenario kegagalan jaringan (*SocketException* / timeout) agar melempar pesan error terstandar.
- **Status:** Pending

---

### TASK-1.3: Implementasi KosProvider untuk Pengelolaan Status Publik
- **Tujuan Pengerjaan:** Membuat `KosProvider` berbasis `ChangeNotifier` untuk mengelola status reaktif pemuatan (`isLoading`), pesan kesalahan (`errorMessage`), seluruh daftar data kos, serta kos yang sedang dibuka detailnya.
- **Requirement Terkait:** FR01, FR05, US01, US04.
- **Acceptance Criteria Terkait:** AC01-1, AC01-2, AC01-3, AC04-1, AC04-3, NFR03, NFR05.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/providers/kos_provider.dart`
  - `test/providers/kos_provider_test.dart`
- **Langkah Pengujian:**
  1. Jalankan unit test `kos_provider_test.dart` untuk memverifikasi transisi state: saat data mulai diambil (`isLoading = true`), saat berhasil (`isLoading = false` dan list terisi), serta saat gagal (`errorMessage` terisi).
  2. Verifikasi pemanggilan ulang method pemuatan data saat tombol *Retry* ditekan.
- **Status:** Pending

---

### TASK-1.4: Tampilan Halaman Utama / Daftar Kos Publik
- **Tujuan Pengerjaan:** Membuat `KosListScreen` dan kartu kos `KosCardWidget` untuk menampilkan seluruh data kos dari backend tanpa login, menampilkan indikator loading < 200 ms, menampilkan status kosong jika tidak ada data, menampilkan pesan kesalahan dan tombol *Retry* saat koneksi gagal, serta mempertahankan akses navigasi ke `AboutPage`.
- **Requirement Terkait:** FR01, US01.
- **Acceptance Criteria Terkait:** AC01-1, AC01-2, AC01-3, NFR03, NFR04, NFR05, AGENTS.md (Identitas Pengembang).
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/screens/kos_list_screen.dart`
  - `lib/widgets/kos_card_widget.dart`
  - `lib/main.dart`
  - `test/screens/kos_list_screen_test.dart`
- **Langkah Pengujian:**
  1. Jalankan widget test `kos_list_screen_test.dart` untuk memverifikasi daftar kartu kos muncul tanpa meminta pengguna untuk mendaftar atau login.
  2. Uji kondisi database kosong: pastikan pesan informatif muncul dan bukan layar blank.
  3. Uji kondisi offline: pastikan muncul pesan kesalahan jaringan dan tombol *Retry*.
  4. Uji penekanan tombol info pada AppBar: pastikan tetap mengarah ke halaman About dan menampilkan `2415051014 - Gede Supadma`.
- **Status:** Pending

---

### TASK-1.5: Tampilan Halaman Detail Kos & Kontak Pemilik
- **Tujuan Pengerjaan:** Membuat `KosDetailScreen` yang menampilkan seluruh komponen rincian kos (nama kos, alamat lengkap, harga per bulan Rp/bulan, daftar fasilitas tetap WiFi/kamar mandi dalam/parkir, deskripsi, kamar tersedia) serta nomor telepon/WhatsApp pemilik agar dapat dihubungi langsung, tanpa mewajibkan pengguna login.
- **Requirement Terkait:** FR05, FR06, US04.
- **Acceptance Criteria Terkait:** AC04-1, AC04-2, AC04-3, NFR04.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/screens/kos_detail_screen.dart`
  - `lib/screens/kos_list_screen.dart`
  - `test/screens/kos_detail_screen_test.dart`
- **Langkah Pengujian:**
  1. Jalankan widget test: ketuk kartu kos dari halaman utama, pastikan berpindah ke `KosDetailScreen`.
  2. Verifikasi seluruh 7 atribut data tampil lengkap di layar (termasuk nomor kontak pemilik).
  3. Uji penanganan kondisi ID kos tidak ditemukan atau telah dihapus: pastikan menampilkan pesan kesalahan dan tombol kembali.
  4. Jalankan `flutter analyze` dan `flutter test`.
- **Status:** Pending

---

## Slice 2: Pencarian dan Filter

### TASK-2.1: Logika Pencarian Area & Alamat serta Filter pada Repository & Provider
- **Tujuan Pengerjaan:** Menambahkan fungsi pencarian kata kunci teks bebas (mencocokkan kolom `area` dan `address` via operator OR / ILIKE) serta penyaringan kombinasi harga bulanan maksimum dan fasilitas checkbox (WiFi, kamar mandi dalam, parkir) pada `KosRepository` dan `KosProvider`.
- **Requirement Terkait:** FR02, FR03, FR04, US02, US03.
- **Acceptance Criteria Terkait:** AC02-1, AC02-2, AC02-3, AC03-1, AC03-2.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/repositories/kos_repository.dart`
  - `lib/providers/kos_provider.dart`
  - `test/providers/kos_provider_search_test.dart`
- **Langkah Pengujian:**
  1. Jalankan unit test `kos_provider_search_test.dart` untuk memverifikasi pencarian *case-insensitive* kata kunci area: lakukan pencarian kata `"singaraja"` dan kata `"Singaraja"`, pastikan hasil pencarian keduanya sama persis karena menggunakan pencocokan ILIKE.
  2. Uji pencarian nama jalan pada kolom `address`.
  3. Uji filter harga maksimum Rp 1.500.000 dan centang fasilitas WiFi + Kamar Mandi Dalam: pastikan hanya data yang memenuhi seluruh kriteria yang lolos saring.
  4. Uji kondisi pencarian/filter tidak menemukan hasil: pastikan list hasil kosong tanpa menimbulkan error.
- **Status:** Pending

---

### TASK-2.2: Implementasi Antarmuka Pencarian Teks Bebas pada Daftar Kos
- **Tujuan Pengerjaan:** Menambahkan kolom input pencarian teks bebas (*free-text input*) pada `KosListScreen` tanpa dropdown atau autocomplete wilayah, yang mengeksekusi pencarian area/alamat, menampilkan pesan tidak ditemukan jika tidak ada hasil, dan mempertahankan teks pencarian saat jaringan gagal.
- **Requirement Terkait:** FR02, US02.
- **Acceptance Criteria Terkait:** AC02-1, AC02-2, AC02-3, NFR03, NFR04.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/screens/kos_list_screen.dart`
  - `test/screens/kos_search_ui_test.dart`
- **Langkah Pengujian:**
  1. Jalankan widget test: ketik teks area pada kolom pencarian dan tekan enter/cari, pastikan kartu kos yang relevan ditampilkan.
  2. Ketik kata kunci yang tidak ada di data (misal *"AreaTidakAda"*), pastikan pesan *"Tidak ditemukan kos di area 'AreaTidakAda'"* muncul di layar.
  3. Simulasikan error koneksi saat pencarian: pastikan teks yang telah diketik tidak terhapus.
- **Status:** Pending

---

### TASK-2.3: Implementasi Lembar Modal Filter Harga dan Fasilitas
- **Tujuan Pengerjaan:** Membuat komponen modal `KosFilterBottomSheet` yang berisi input harga maksimum bulanan (Rp/bulan) dan kontrol checkbox untuk 3 pilihan fasilitas tetap (WiFi, Kamar Mandi Dalam, Parkir), tombol *"Terapkan Filter"*, serta menampilkan pesan informatif saat tidak ada kos yang sesuai kriteria.
- **Requirement Terkait:** FR03, FR04, US03.
- **Acceptance Criteria Terkait:** AC03-1, AC03-2, NFR04.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/widgets/kos_filter_bottom_sheet.dart`
  - `lib/screens/kos_list_screen.dart`
  - `test/widgets/kos_filter_bottom_sheet_test.dart`
- **Langkah Pengujian:**
  1. Jalankan widget test: ketuk tombol filter di halaman utama, pastikan `KosFilterBottomSheet` terbuka.
  2. Isi batas harga Rp 1.500.000 dan centang fasilitas WiFi, lalu tekan *"Terapkan Filter"*. Pastikan modal tertutup dan daftar kos diperbarui.
  3. Uji filter dengan kriteria mustahil (misal harga Rp 10.000): pastikan muncul pesan informasi bahwa tidak ada kos yang cocok.
  4. Jalankan `flutter analyze` dan `flutter test`.
- **Status:** Pending

---

## Slice 3: Login Pemilik (Termasuk Registrasi dan Logout)

### TASK-3.1: Implementasi Service dan Repository Autentikasi Supabase
- **Tujuan Pengerjaan:** Membuat `SupabaseAuthService` dan `AuthRepository` untuk menangani pendaftaran akun pemilik (`signUp`), masuk akun (`signInWithPassword`), keluar akun (`signOut`), dan pengecekan sesi aktif (`currentUser`) menggunakan SDK Supabase Auth.
- **Requirement Terkait:** FR07, FR08, FR09, US05.
- **Acceptance Criteria Terkait:** AC05-1, AC05-2, AC05-3, AC05-4, AC05-5, AC05-6, NFR01, NFR02.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/services/supabase_auth_service.dart`
  - `lib/repositories/auth_repository.dart`
  - `test/repositories/auth_repository_test.dart`
- **Langkah Pengujian:**
  1. Jalankan unit test `auth_repository_test.dart` untuk menguji alur registrasi berhasil (hanya membutuhkan email dan password).
  2. Uji login dengan kredensial valid menghasilkan objek sesi pengguna.
  3. Uji login dengan kredensial salah menghasilkan exception error autentikasi yang ramah pengguna.
  4. Uji fungsi logout menghapus sesi aktif.
- **Status:** Pending

---

### TASK-3.2: Implementasi AuthProvider untuk Manajemen Status Sesi Pemilik
- **Tujuan Pengerjaan:** Membuat `AuthProvider` untuk mengelola status reaktif sesi login pemilik kos (`currentUser`, `isAuthenticated`, `isLoading`, `errorMessage`), menangani validasi lokal, dan menjaga isian form tidak hilang saat terjadi gangguan koneksi.
- **Requirement Terkait:** FR07, FR08, FR09, US05.
- **Acceptance Criteria Terkait:** AC05-1, AC05-3, AC05-4, AC05-5, AC05-6, NFR03.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/providers/auth_provider.dart`
  - `lib/main.dart`
  - `test/providers/auth_provider_test.dart`
- **Langkah Pengujian:**
  1. Jalankan unit test `auth_provider_test.dart` untuk menguji transisi state login dan logout.
  2. Verifikasi state error dan penanganan pesan kesalahan jaringan.
- **Status:** Pending

---

### TASK-3.3: Tampilan Halaman Pendaftaran Akun Pemilik Kos
- **Tujuan Pengerjaan:** Membuat `RegisterScreen` dengan formulir pendaftaran yang hanya memerlukan email dan kata sandi (tanpa nama lengkap atau nomor telepon), memvalidasi format email dan password, menangani penolakan email duplikat dengan menampilkan pesan kesalahan yang ramah pengguna, serta mengarahkan pengguna ke halaman login dengan pesan sukses setelah registrasi berhasil.
- **Requirement Terkait:** FR07, US05.
- **Acceptance Criteria Terkait:** AC05-1, AC05-2, AC05-6, NFR04.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/screens/register_screen.dart`
  - `lib/screens/login_screen.dart`
  - `test/screens/register_screen_test.dart`
- **Langkah Pengujian:**
  1. Jalankan widget test `register_screen_test.dart`: submit form kosong, pastikan pesan validasi spesifik muncul di dekat kolom bersangkutan.
  2. Masukkan email yang sudah terdaftar sebelumnya: pastikan aplikasi menampilkan pesan kesalahan yang sesuai (misal: *"Email sudah terdaftar"*) dan aplikasi tidak mengalami *crash*.
  3. Masukkan data valid, simulasikan pendaftaran berhasil: pastikan navigasi berpindah ke halaman login dan menampilkan pesan sukses.
  4. Uji kondisi offline: pastikan aplikasi tidak crash dan isian email/password tidak hilang dari form.
- **Status:** Pending

---

### TASK-3.4: Tampilan Halaman Login dan Fitur Logout Pemilik Kos
- **Tujuan Pengerjaan:** Membuat `LoginScreen` untuk autentikasi masuk pemilik kos, tautan ke formulir pendaftaran, serta tombol Logout pada halaman kelola kos yang menghapus token/sesi dan mengembalikan antarmuka ke mode publik.
- **Requirement Terkait:** FR08, FR09, US05.
- **Acceptance Criteria Terkait:** AC05-3, AC05-4, AC05-5, AC05-6, NFR04.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/screens/login_screen.dart`
  - `lib/screens/kos_list_screen.dart`
  - `test/screens/login_screen_test.dart`
- **Langkah Pengujian:**
  1. Jalankan widget test: login dengan email dan password yang valid, pastikan pengguna diarahkan ke antarmuka kelola kos pemilik.
  2. Masukkan password salah: pastikan muncul pesan kesalahan *"Email atau kata sandi yang Anda masukkan salah"*.
  3. Jalankan aksi logout: pastikan sesi dihapus dan pengguna kembali ke tampilan publik.
  4. Jalankan `flutter analyze` dan `flutter test`.
- **Status:** Pending

---

## Slice 4: Tambah, Ubah, dan Hapus Kos Milik Sendiri

### TASK-4.1: Penambahan Operasi CRUD dan Pengambilan UID Pemilik pada Repository & Provider
- **Tujuan Pengerjaan:** Menambahkan method `createKos`, `updateKos`, `deleteKos`, dan `getOwnerKosList` pada `SupabaseKosService`, `KosRepository`, dan `KosProvider`. Sebelum menambahkan kos, aplikasi secara ketat memeriksa sesi login pengguna (pemeriksaan *null-safety*, misal `final user = supabase.auth.currentUser; if (user == null) throw ...`). Jika pengguna belum login, operasi penambahan kos wajib ditolak dengan penanganan error yang sesuai. Setelah sesi terverifikasi valid, gunakan `user.id` sebagai nilai kolom `owner_id`. Di tingkat database, kebijakan Supabase RLS memvalidasi kesesuaian nilai `owner_id` dengan `auth.uid()` pengguna untuk menjamin aturan kepemilikan.
- **Requirement Terkait:** FR10, FR11, FR12, US06, US07.
- **Acceptance Criteria Terkait:** AC06-1, AC06-2, AC06-4, AC07-1, AC07-2, AC07-3, AC07-4, NFR01.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/services/supabase_kos_service.dart`
  - `lib/repositories/kos_repository.dart`
  - `lib/providers/kos_provider.dart`
  - `test/providers/kos_crud_test.dart`
- **Langkah Pengujian:**
  1. Jalankan unit test `kos_crud_test.dart` untuk menguji alur penambahan kos baru dengan pemeriksaan sesi login terlebih dahulu dan penyematan `user.id` ke `owner_id`.
  2. Uji kondisi jika pengguna belum login: pastikan operasi penambahan kos ditolak dengan error yang terstandar dan data form tidak dapat disimpan.
  3. Uji fungsi pengubahan kos milik sendiri: pastikan data terupdate di repository/provider.
  4. Uji fungsi penghapusan kos milik sendiri: pastikan item terhapus dari daftar kos pemilik dan daftar kos publik.
- **Status:** Pending

---

### TASK-4.2: Tampilan Halaman Kelola Kos Pemilik (OwnerKosScreen)
- **Tujuan Pengerjaan:** Membuat `OwnerKosScreen` dan `OwnerKosCardWidget` untuk menampilkan seluruh kos yang dimiliki oleh pemilik yang sedang login, tombol *"Tambah Kos"*, tombol aksi edit kos, tombol aksi hapus kos, dan tombol logout.
- **Requirement Terkait:** FR09, FR10, FR11, FR12, US05, US06, US07.
- **Acceptance Criteria Terkait:** AC05-5, AC07-1, AC07-2, NFR04.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/screens/owner_kos_screen.dart`
  - `lib/widgets/owner_kos_card_widget.dart`
  - `test/screens/owner_kos_screen_test.dart`
- **Langkah Pengujian:**
  1. Jalankan widget test: verifikasi halaman menampilkan daftar kos milik pemilik yang login.
  2. Pastikan terdapat tombol mengarah ke form tambah kos dan tombol logout.
  3. Uji tombol aksi pada setiap kartu kos (edit dan hapus).
- **Status:** Pending

---

### TASK-4.3: Tampilan Formulir Tambah Kos Baru
- **Tujuan Pengerjaan:** Membuat `KosFormScreen` (mode tambah) yang memuat field wajib: nama kos, alamat, area, nomor telepon/WhatsApp aktif pemilik, tarif sewa bulanan (Rp/bulan), checkbox pilihan fasilitas tetap (WiFi, Kamar Mandi Dalam, Parkir), deskripsi, dan kamar tersedia (>= 0). Memblokir akses jika pengguna belum login.
- **Requirement Terkait:** FR10, US06.
- **Acceptance Criteria Terkait:** AC06-1, AC06-2, AC06-3, AC06-4, NFR03, NFR04.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/screens/kos_form_screen.dart`
  - `lib/screens/owner_kos_screen.dart`
  - `test/screens/kos_create_form_test.dart`
- **Langkah Pengujian:**
  1. Jalankan widget test: coba submit form dalam keadaan kolom wajib kosong atau harga bernilai negatif; pastikan pesan validasi muncul spesifik pada masing-masing field.
  2. Isi seluruh field dengan data valid dan simpan: pastikan kos baru tersimpan dan muncul di daftar kos pemilik serta publik.
  3. Simulasikan pengguna tamu (belum login) mencoba membuka form: pastikan diarahkan ke halaman login.
  4. Uji kondisi kegagalan jaringan saat simpan: pastikan pesan error muncul dan data yang diisi pada formulir tidak hilang.
- **Status:** Pending

---

### TASK-4.4: Formulir Ubah Kos dan Dialog Konfirmasi Hapus Kos Milik Sendiri serta Verifikasi RLS
- **Tujuan Pengerjaan:** Mengintegrasikan `KosFormScreen` untuk mode ubah (memuat data kos yang sudah ada) dan menambahkan dialog konfirmasi penghapusan kos pada `OwnerKosScreen`. Memastikan bahwa Pemilik A dapat mengubah dan menghapus kos miliknya, sedangkan Pemilik B ditolak saat mencoba mengubah atau menghapus kos milik Pemilik A dengan pembuktian data database tetap tidak berubah.
- **Requirement Terkait:** FR11, FR12, US07.
- **Acceptance Criteria Terkait:** AC07-1, AC07-2, AC07-3, AC07-4, NFR01.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/screens/kos_form_screen.dart`
  - `lib/screens/owner_kos_screen.dart`
  - `test/screens/kos_update_delete_test.dart`
- **Langkah Pengujian:**
  1. **Pengujian Unit / Widget di Flutter:**
     - Jalankan widget test `kos_update_delete_test.dart`: buka mode ubah sebagai Pemilik A, lakukan perubahan harga atau nomor kontak, simpan, dan pastikan data terbaru tampil.
     - Ketuk tombol hapus pada kartu kos Pemilik A: pastikan muncul dialog konfirmasi *"Ya, Hapus"*. Setelah dikonfirmasi, pastikan kos terhapus dari daftar.
  2. **Pengujian Keamanan RLS Nyata di Backend (Dua Akun Berbeda):**
     - Siapkan data *"Kos Melati"* milik Akun Pemilik A di backend Supabase.
     - Login sebagai Akun Pemilik B, peroleh token JWT milik Pemilik B.
     - Kirim request HTTP langsung ke endpoint backend Supabase menggunakan token Pemilik B:
       - UPDATE: `PATCH /rest/v1/kos?id=eq.<ID_Kos_Melati>`
       - DELETE: `DELETE /rest/v1/kos?id=eq.<ID_Kos_Melati>`
     - Verifikasi hasil pengujian RLS: pastikan aksi Pemilik B gagal (0 baris terpengaruh / 403), dan pastikan data *"Kos Melati"* milik Pemilik A di database terbukti tetap utuh tanpa perubahan.
  3. Jalankan `flutter analyze` dan `flutter test`.
- **Status:** Pending

---

## Slice 5: Pembaruan Ketersediaan Kamar & Integrasi Akhir

### TASK-5.1: Penambahan Method Pembaruan Kamar Tersedia pada Service, Repository & Provider
- **Tujuan Pengerjaan:** Membuat method khusus `updateAvailableRooms(kosId, newRooms)` pada `SupabaseKosService`, `KosRepository`, dan `KosProvider` untuk memperbarui jumlah kamar secara cepat dengan validasi angka >= 0 dan penegakan otorisasi kepemilikan.
- **Requirement Terkait:** FR13, US08.
- **Acceptance Criteria Terkait:** AC08-1, AC08-2, AC08-4, NFR01.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/services/supabase_kos_service.dart`
  - `lib/repositories/kos_repository.dart`
  - `lib/providers/kos_provider.dart`
  - `test/providers/kos_rooms_update_test.dart`
- **Langkah Pengujian:**
  1. Jalankan unit test `kos_rooms_update_test.dart`: uji pembaruan jumlah kamar dengan nilai valid (misal dari 5 menjadi 2).
  2. Uji validasi input nilai negatif (misal -1): pastikan ditolak dengan pesan kesalahan *"Jumlah kamar tidak boleh kurang dari 0"*.
  3. Uji pembaruan ke angka 0: pastikan tersimpan sebagai 0.
- **Status:** Pending

---

### TASK-5.2: Tampilan Dialog Pembaruan Kamar Cepat pada Layar Pemilik
- **Tujuan Pengerjaan:** Membuat komponen dialog cepat `UpdateRoomsDialog` yang dapat diakses langsung dari kartu kos pada `OwnerKosScreen` untuk memperbarui sisa kamar tanpa harus membuka form edit lengkap, serta menampilkan penanda *"Kamar Penuh"* pada kartu kos jika bernilai 0.
- **Requirement Terkait:** FR13, US08.
- **Acceptance Criteria Terkait:** AC08-1, AC08-2, AC08-3, AC08-4, NFR04.
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `lib/widgets/update_rooms_dialog.dart`
  - `lib/widgets/owner_kos_card_widget.dart`
  - `lib/widgets/kos_card_widget.dart`
  - `lib/screens/kos_detail_screen.dart`
  - `test/widgets/update_rooms_dialog_test.dart`
- **Langkah Pengujian:**
  1. Jalankan widget test: ketuk tombol pembaruan kamar pada kartu kos pemilik, buka `UpdateRoomsDialog`, masukkan nilai 2 dan simpan; pastikan angka kamar terperbarui.
  2. Perbarui nilai menjadi 0: pastikan pada tampilan kartu kos publik dan detail kos muncul status *"Kamar Penuh / Habis"*.
  3. Masukkan angka negatif: pastikan form dialog menolak penyimpanan dan menampilkan pesan validasi.
- **Status:** Pending

---

### TASK-5.3: Pengujian Verifikasi Menyeluruh dan Pemenuhan Standar Selesai (DoD)
- **Tujuan Pengerjaan:** Melakukan pengujian menyeluruh lintas fitur dari Slice 1 sampai Slice 5 (pencarian publik, filter, navigasi About `2415051014 - Gede Supadma`, registrasi, login, penambahan kos, pengeditan kos, pembaruan kamar, dan penghapusan kos), melakukan pengukuran performa konkret sesuai NFR05 pada lingkungan pengujian acuan, memastikan seluruh unit test dan widget test lulus melalui `flutter test`, serta memastikan kode bersih dari error/warning melalui `flutter analyze`.
- **Requirement Terkait:** FR01 s.d. FR13, US01 s.d. US08.
- **Acceptance Criteria Terkait:** AC01-1 s.d. AC08-4, NFR01 s.d. NFR06, AGENTS.md (Standar Penyelesaian).
- **Daftar File yang Boleh Dibuat / Diubah:**
  - `test/widget_test.dart`
  - `docs/tasks.md`
- **Langkah Pengujian:**
  1. **Pengujian Otomatis Kode (Unit & Widget Test):**
     - Jalankan `flutter test` untuk mengeksekusi seluruh rangkaian unit test dan widget test yang telah dibuat dari Task 1.1 sampai 5.2. Pastikan 100% lulus.
     - Jalankan `flutter analyze` dan pastikan hasil analisis bersih (*No issues found!*).
  2. **Pengujian Manual Alur Pengguna pada Emulator / Perangkat:**
     - Jalankan aplikasi pada emulator Android, lakukan uji jelajah sebagai pencari kos (cari area, filter fasilitas, buka detail, buka halaman About).
     - Lakukan uji alur pemilik kos (daftar akun, login, tambah kos, ubah data, update kamar ke 0, hapus kos, logout).
  3. **Pengukuran Performa Konkret Sesuai NFR05:**
     - Siapkan lingkungan pengujian acuan sesuai `docs/requirements.md` (perangkat Android fisik atau emulator dengan spesifikasi RAM minimal 4 GB serta koneksi internet stabil dengan kecepatan unduh minimal 10 Mbps dan latency di bawah 100 ms).
     - Siapkan dataset pengujian berupa 20 data kos aktif di backend Supabase.
     - Buka halaman daftar kos dan gunakan Flutter DevTools (tab *Performance*) atau utilitas *Stopwatch* terukur untuk mencatat waktu:
       a. Pastikan umpan balik visual (*loading indicator*) muncul dalam waktu kurang dari 200 ms sejak pengguna membuka halaman.
       b. Pastikan seluruh 20 data kos selesai dimuat dan dirender di layar dalam waktu kurang dari 2 detik.
  4. **Pemeriksaan Kepatuhan Standar Selesai (Definition of Done):**
     - Verifikasi bahwa seluruh AC (AC01-1 s.d. AC08-4) dan NFR (NFR01 s.d. NFR06) telah terpenuhi secara nyata melalui pengujian otomatis, pengujian manual, dan pengukuran performa (bukan hanya mengasumsikan lulus dari `flutter test`).
     - Perbarui status pengerjaan task pada `docs/tasks.md`.
- **Status:** Pending
