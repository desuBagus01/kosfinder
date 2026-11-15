# Spesifikasi Kebutuhan Aplikasi KosFinder (Requirements Specification)

Dokumen ini disusun berdasarkan kebutuhan pengguna pada [user-story.md](file:///c:/src/kosfinder/docs/user-story.md) untuk mendefinisikan kriteria penerimaan (*Acceptance Criteria*) konkret yang dapat diuji pada rilis Versi 1.

---

## 1. Peran Pengguna & Aturan Akses

| Peran | Wajib Login | Hak Akses Utama |
|---|---|---|
| **Pencari Kos** | Tidak | Menjelajah daftar kos, mencari area, memfilter harga & fasilitas, melihat detail kos. |
| **Pemilik Kos** | Ya | Mendaftar, masuk, keluar, menambah kos, mengubah & menghapus kos milik sendiri, memperbarui ketersediaan kamar. |

---

## 2. Batasan Ruang Lingkup Versi 1 (Out of Scope)

Fitur-fitur berikut **tidak diimplementasikan** pada versi 1:
- Pembayaran online
- Fitur chat interaktif
- Ulasan (*review*) dan rating
- Rekomendasi berbasis AI
- Verifikasi identitas pemilik kos (KTP/dokumen legalitas)
- Unggah foto kos (*photo upload*)
- Tampilan peta (*maps*)

---

## 3. Spesifikasi Kebutuhan & Acceptance Criteria (US01 - US08)

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

### US02: Mencari Kos Berdasarkan Area
> *Sebagai pencari kos, saya ingin mencari kos berdasarkan area, agar hanya melihat kos di lokasi yang saya inginkan.*

#### AC02-1: Pencarian berdasarkan kata kunci area yang cocok (Input Teks Bebas)
- **Given** pengguna berada di halaman daftar kos tanpa perlu login, dan tersedia kolom input pencarian teks bebas (*free-text input*) tanpa dropdown atau autocomplete wilayah.
- **When** pengguna mengetikkan teks bebas nama jalan, kecamatan, atau area (misal: *"Tembalang"*) pada kolom pencarian dan menekan tombol cari.
- **Then** sistem menampilkan daftar kos yang memiliki informasi area atau alamat yang cocok dengan kata kunci *"Tembalang"*.

#### AC02-2: Hasil pencarian area tidak ditemukan
- **Given** pengguna berada di halaman pencarian tanpa login.
- **When** pengguna memasukkan nama area yang tidak memiliki kos terdaftar (misal: *"AreaTidakAda"*) lalu menekan tombol cari.
- **Then** sistem menampilkan pesan bahwa kos di area tersebut tidak ditemukan (misal: *"Tidak ditemukan kos di area 'AreaTidakAda'"*) dan menyarankan pengguna untuk mencoba kata kunci lain.

#### AC02-3: Penanganan kegagalan koneksi jaringan saat melakukan pencarian
- **Given** pengguna telah mengetikkan kata kunci pencarian area.
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

## 4. Matriks Skenario Khusus yang Wajib Dicakup

| Skenario Khusus | Referensi Acceptance Criteria |
|---|---|
| **Data Kos Kosong / Hasil Pencarian Tidak Ditemukan** | AC01-2 (Daftar kos kosong), AC02-2 (Area tidak ditemukan), AC03-2 (Filter tidak ditemukan) |
| **Koneksi Jaringan / Backend Gagal** | AC01-3, AC02-3, AC04-3, AC05-6, AC06-4, AC07-4 |
| **Otorisasi Kepemilikan (Mencoba Akses Kos Pemilik Lain)** | AC07-3 (Ubah/Hapus kos orang lain ditolak), AC08-4 (Update kamar orang lain ditolak) |
| **Akses Tanpa Login untuk Pencari Kos** | AC01-1 (Daftar kos), AC02-1 (Cari area), AC03-1 (Filter), AC04-1 (Detail kos) |
| **Wajib Login untuk Pengelolaan Kos oleh Pemilik** | AC05-3, AC06-3 (Blokir guest tambah kos), AC07-1, AC08-1 |

---

## 5. Daftar Pertanyaan & Hal Ambigu (Open Questions)

Seluruh pertanyaan dan aspek ambigu yang sebelumnya diidentifikasi telah dibahas dan disepakati secara final untuk ruang lingkup Versi 1:
- **Kontak Pemilik Kos:** Pemilik mengisi nomor telepon/WhatsApp saat menambah/mengubah kos; nomor kontak ditampilkan di detail kos; fitur chat ditiadakan.
- **Pencarian Area Kos:** Menggunakan input teks bebas (*free-text input*) tanpa dropdown atau autocomplete wilayah.
- **Pendaftaran Pemilik:** Formulir pendaftaran hanya memerlukan email dan password (tanpa nama lengkap atau nomor telepon tambahan).
- **Satuan Harga Sewa:** Seluruh harga sewa menggunakan format baku Rupiah per bulan (Rp/bulan) tanpa opsi sewa periode lain.
- **Pemuatan Daftar Kos:** Daftar kos ditampilkan sebagai daftar biasa dari backend tanpa pagination atau infinite scrolling.
- **Fasilitas Kos:** Menggunakan pilihan tetap (*fixed checkbox*) berisi WiFi, kamar mandi dalam, dan parkir tanpa opsi penambahan kustom.

*Saat ini tidak ada pertanyaan ambigu atau open questions yang tersisa untuk kebutuhan dan ruang lingkup Versi 1.*
