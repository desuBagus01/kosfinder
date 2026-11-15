# Aturan Kerja Agen AI - Proyek KosFinder

Dokumen ini berisi panduan dan aturan kerja baku bagi seluruh agen AI yang berkontribusi dalam pengembangan aplikasi **KosFinder**. Setiap agen wajib membaca, memahami, dan mematuhi aturan berikut sebelum menjalankan tugas.

---

## 1. Konteks Proyek
- **Nama Aplikasi:** KosFinder.
- **Tujuan Aplikasi:** Membantu pencari kos menemukan informasi kos yang sesuai dengan kebutuhan (area, harga, dan fasilitas) tanpa wajib login, serta membantu pemilik kos mengelola publikasi dan ketersediaan kamar kos miliknya.
- **Dokumen Acuan:** Seluruh spesifikasi kebutuhan produk dan pengguna berada pada folder `docs/`:
  - `docs/user-story.md`: Latar belakang dan cerita pengguna.
  - `docs/requirements.md`: Kebutuhan fungsional (FR), non-fungsional (NFR), batasan ruang lingkup, dan acceptance criteria (AC).
  - `docs/prd.md`: Ringkasan dokumen kebutuhan produk untuk pemangku kepentingan.
- **Resolusi Konflik:** Jika terdapat perbedaan atau konflik informasi antar dokumen, maka **`docs/requirements.md` adalah sumber kebenaran utama (*single source of truth*)** untuk kebutuhan fungsional dan *acceptance criteria*.

---

## 2. Aturan Cara Kerja Agen
1. **Fokus Tunggal:** Kerjakan hanya satu task untuk setiap permintaan yang diberikan pengguna.
2. **Cakupan File Terbatas:** Jangan mengubah atau membuat file di luar cakupan task yang diminta.
3. **Rencana untuk Perubahan Besar:** Untuk perubahan arsitektural atau refactoring besar, susun dan tampilkan rencana kerja secara tertulis terlebih dahulu, lalu tunggu konfirmasi pengguna sebelum melakukan perubahan file.
4. **Prinsip Kesederhanaan (KISS):** Gunakan solusi paling sederhana yang langsung memenuhi kebutuhan tanpa melakukan *over-engineering* atau menambahkan abstraksi yang belum diperlukan.
5. **Persetujuan Dependency:** Dilarang menambahkan package atau library baru pada `pubspec.yaml` tanpa persetujuan eksplisit dari pengguna.
6. **Persetujuan Git Commit & Push:** Dilarang melakukan `git commit` maupun `git push` tanpa instruksi atau persetujuan langsung dari pengguna.

---

## 3. Teknologi Proyek
- **Framework Aplikasi:** Flutter (Cross-platform).
- **State Management:** Provider.
- **Backend & Autentikasi:** Supabase sebagai backend, database PostgreSQL, dan layanan autentikasi.

---

## 4. Aturan Keamanan
1. **Kerahasiaan Kredensial:** Dilarang keras menuliskan API key, secret key, password, token, atau informasi rahasia lainnya secara *hardcoded* di dalam kode program maupun riwayat repositori Git.
2. **Pengelolaan Lingkungan:** Gunakan konfigurasi lingkungan yang aman (misalnya environment variables atau file `.env` yang masuk dalam `.gitignore`) untuk menyimpan kredensial backend.
3. **Aturan Kepemilikan Data:**
   - Semua pengguna boleh melihat daftar kos aktif dan detail kos.
   - Pemilik yang login boleh menambahkan kos.
   - Pemilik hanya boleh mengubah dan menghapus kos miliknya sendiri.
   - Pemilik lain tidak boleh mengubah atau menghapus data kos tersebut.
4. **Penegakan Hak Akses di Backend (RLS):** Seluruh aturan akses data **wajib ditegakkan menggunakan Row Level Security (RLS) di Supabase**, bukan hanya sekadar mengandalkan penyembunyian tombol pada antarmuka aplikasi Flutter.

---

## 5. Standar Penyelesaian Task (Definition of Done)
Sebuah task dinyatakan selesai dan dapat diserahkan ke pengguna hanya jika memenuhi seluruh kriteria berikut:
1. Perintah `flutter analyze` berhasil dijalankan dan tidak menghasilkan error/warning kritis.
2. Seluruh unit test dan widget test yang relevan berhasil dijalankan dengan sukses (`flutter test`).
3. Tidak ada modifikasi atau pembuatan file di luar cakupan pekerjaan yang diminta.
4. Agen melaporkan secara transparan daftar seluruh file yang dibuat atau diubah.
5. Agen memberikan penjelasan mengenai hasil pengujian yang telah dilakukan serta menyebutkan secara jujur bagian mana yang belum diuji.

---

## 6. Identitas Pengembang pada Halaman About
Aplikasi KosFinder memuat identitas pengembang pada halaman About dengan ketentuan:
- **NIM:** 2415051014
- **Nama:** Gede Supadma
- **Format Tampilan:**  
  `2415051014 - Gede Supadma`

Setiap perubahan atau pengembangan pada halaman About wajib mempertahankan informasi identitas tersebut dan memastikan akses navigasi ke halaman About tetap tersedia secara wajar dari antarmuka aplikasi.
