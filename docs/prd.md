# Product Requirement Document (PRD): KosFinder

---

## 1. Nama Produk
**KosFinder**

---

## 2. Masalah
1. **Bagi Pencari Kos:**  
   Pencari kos menghadapi kesulitan dalam menemukan informasi kos yang sesuai dengan lokasi, harga, dan fasilitas karena informasi tersebar di media sosial, grup WhatsApp, dan dari mulut ke mulut, sehingga memakan waktu dan tenaga.
2. **Bagi Pemilik Kos:**  
   Pemilik kos membutuhkan cara yang mudah untuk mempublikasikan kos mereka secara mandiri dan dapat memperbarui jumlah kamar yang tersedia agar pencari kos mengetahui ketersediaan kamar.

---

## 3. Pengguna Sasaran
1. **Pencari Kos:**  
   Masyarakat umum, mahasiswa, atau pekerja yang membutuhkan tempat tinggal sewa. Pengguna ini dapat langsung menggunakan aplikasi secara bebas tanpa perlu mendaftar atau masuk (*login*).
2. **Pemilik Kos:**  
   Individu yang mengelola rumah kos dan membutuhkan sarana sederhana untuk mempublikasikan serta mengelola data kos miliknya. Pengguna ini wajib mendaftar dan masuk (*login*) untuk mengelola kos.

---

## 4. Fitur Inti Versi 1
1. **Eksplorasi Kos Publik:** Pencari kos dapat langsung menjelajah seluruh daftar kos yang tersedia tanpa proses registrasi atau login.
2. **Pencarian Berdasarkan Area:** Pencari kos dapat mengetikkan nama jalan, kecamatan, atau area secara bebas untuk menemukan kos di lokasi yang diinginkan.
3. **Penyaringan Harga & Fasilitas:** Pencari kos dapat membatasi pencarian berdasarkan anggaran harga sewa bulanan maksimum (Rp/bulan) dan memilih fasilitas yang diinginkan (WiFi, Kamar Mandi Dalam, Parkir).
4. **Informasi Detail & Kontak Pemilik:** Halaman detail menampilkan nama kos, alamat lengkap, harga bulanan, daftar fasilitas, deskripsi kos, jumlah kamar tersedia, serta nomor telepon/WhatsApp pemilik untuk dihubungi secara langsung.
5. **Akun Pemilik Kos:** Pemilik kos dapat mendaftar secara praktis hanya dengan email dan kata sandi, serta masuk dan keluar dari akun dengan aman.
6. **Publikasi Kos Baru:** Pemilik kos dapat menambahkan data kos lengkap agar dapat ditemukan oleh calon penyewa.
7. **Pengelolaan Kos Mandiri:** Pemilik kos dapat mengubah informasi dan menghapus kos miliknya sendiri secara aman tanpa risiko diubah oleh pemilik lain.
8. **Pembaruan Kamar Tersedia:** Pemilik kos dapat memperbarui jumlah kamar tersedia kapan saja agar pencari kos mengetahui apakah masih ada kamar atau sudah penuh.

---

## 5. Di Luar Ruang Lingkup (Out of Scope Versi 1)
Fitur-fitur berikut secara eksplisit **tidak disertakan** pada rilis versi 1:
- Pembayaran sewa online melalui aplikasi.
- Fitur percakapan (*chat*) internal di dalam aplikasi.
- Ulasan (*review*) dan penilaian bintang (*rating*).
- Sistem rekomendasi kos berbasis kecerdasan buatan (AI).
- Proses verifikasi identitas pemilik kos (KTP/dokumen resmi).
- Unggah foto kos (*photo upload*).
- Tampilan peta digital interaktif (GPS/Maps).
- Pilihan periode sewa harian, mingguan, atau tahunan.
- Penambahan nama fasilitas khusus di luar 3 pilihan baku (WiFi, kamar mandi dalam, parkir).
- Mekanisme pembagian halaman (*pagination*) atau gulir tak terbatas (*infinite scrolling*) pada daftar kos.

---

## 6. Kriteria Keberhasilan
1. **Akses Publik Tanpa Hambatan:** Seluruh skenario akses publik—meliputi melihat daftar kos, melakukan pencarian area, menyaring berdasarkan harga dan fasilitas, serta melihat rincian detail kos—dapat diselesaikan sepenuhnya oleh pencari kos tanpa kewajiban mendaftar atau masuk (*login*).
2. **Kecepatan Registrasi dan Publikasi Kos:** Pemilik kos baru dapat menyelesaikan proses pendaftaran akun hingga berhasil menambahkan kos pertama dalam waktu kurang dari 5 menit, diukur sejak membuka formulir pendaftaran menggunakan data valid dan koneksi internet normal.
3. **Akurasi Informasi Kontak & Kamar:** 100% data kos yang dipublikasikan menampilkan nomor kontak telepon/WhatsApp pemilik dan informasi ketersediaan kamar yang jelas (termasuk penanda jika kamar telah penuh / bernilai 0).
4. **Keamanan Kepemilikan Data:** Nol (0) insiden perubahan atau penghapusan data kos oleh pihak yang tidak berhak; saat Pemilik B mencoba mengubah atau menghapus data kos milik Pemilik A (baik melalui antarmuka aplikasi maupun permintaan langsung ke backend), data Pemilik A harus terbukti tetap utuh dan tidak berubah.
5. **Responsivitas dan Performa:** Indikator pemuatan (*loading indicator*) muncul dalam waktu kurang dari 200 ms setelah aksi pengguna, dan sebanyak 20 data kos aktif selesai dimuat serta ditampilkan di layar dalam waktu kurang dari 2 detik pada kondisi pengujian acuan (perangkat Android/emulator RAM min. 4 GB, koneksi internet stabil kecepatan unduh min. 10 Mbps dan latency < 100 ms).

---

## 7. Risiko dan Asumsi
### Risiko:
1. **Kelalaian Pembaruan Data Kamar:** Pemilik kos mungkin terlambat memperbarui jumlah kamar saat kamar sudah terisi penuh secara *offline*, sehingga pencari kos menghubungi untuk kos yang sebenarnya sudah habis.
2. **Ketergantungan pada Saluran Kontak Eksternal:** Karena tidak adanya fitur *chat* di dalam aplikasi, kelancaran komunikasi sepenuhnya bergantung pada respon pemilik kos melalui telepon atau WhatsApp.

### Asumsi:
1. Pencari kos sudah terbiasa berkomunikasi langsung menggunakan aplikasi WhatsApp atau panggilan telepon biasa.
2. Pemilik kos memiliki perangkat ponsel pintar (*smartphone*) dan alamat email aktif untuk mengelola publikasi kos mereka.
3. Tarif sewa bulanan adalah standar yang paling umum dan relevan bagi target pasar awal.
