# Ide Awal: KosFinder

## 1. Siapa Pengguna?

KosFinder memiliki dua jenis pengguna:

- **Pencari kos:** Mahasiswa atau masyarakat yang membutuhkan informasi tempat kos, khususnya di sekitar Singaraja. Pengguna dapat melihat daftar kos tanpa harus melakukan login.
- **Pemilik kos:** Orang yang memiliki tempat kos dan ingin mempublikasikan serta mengelola informasi kos miliknya. Pemilik harus mendaftar dan login sebelum mengelola data kos.

## 2. Masalah yang Dihadapi

Informasi tempat kos sering tersebar di berbagai media, seperti media sosial, grup WhatsApp, dan informasi dari mulut ke mulut. Hal ini membuat pencari kos kesulitan menemukan dan membandingkan kos berdasarkan lokasi, harga, dan fasilitas.

Di sisi lain, pemilik kos membutuhkan cara yang lebih mudah untuk mempublikasikan informasi kos serta memperbarui informasi jumlah kamar yang masih tersedia.

## 3. Apa yang Diharapkan Bisa Dilakukan?

KosFinder diharapkan dapat menyediakan satu platform untuk mempertemukan pencari kos dan pemilik kos.

Fitur utama yang diharapkan:

**Untuk pencari kos:**

- Melihat daftar tempat kos yang tersedia.
- Mencari kos berdasarkan nama, area, atau alamat.
- Menyaring kos berdasarkan harga maksimum dan fasilitas WiFi, kamar mandi dalam, serta parkir.
- Melihat detail kos, termasuk alamat, harga bulanan, fasilitas, deskripsi, dan jumlah kamar tersedia.
- Menghubungi pemilik melalui telepon atau WhatsApp.

**Untuk pemilik kos:**

- Mendaftar, login, dan logout menggunakan email dan password.
- Menambahkan informasi kos.
- Mengubah dan menghapus data kos miliknya sendiri.
- Memperbarui jumlah kamar yang tersedia.

## 4. Batasan

- Aplikasi dibuat untuk platform Android menggunakan Flutter.
- Supabase digunakan sebagai backend untuk database dan autentikasi pengguna.
- Provider digunakan untuk pengelolaan state aplikasi.
- Pencari kos dapat melihat informasi tanpa harus login.
- Pemilik harus login untuk mengelola data kos.
- Setiap pemilik hanya boleh mengubah dan menghapus data kos miliknya sendiri.
- Harga kos menggunakan sistem pembayaran bulanan dalam Rupiah.
- Fasilitas dibatasi pada WiFi, kamar mandi dalam, dan parkir.
- Aplikasi tidak menyediakan fitur pembayaran online, chat internal, ulasan dan rating, rekomendasi AI, verifikasi identitas pemilik, upload foto, dan peta atau GPS.

## 5. Tujuan Produk

KosFinder bertujuan mempermudah pencari kos menemukan tempat tinggal sesuai kebutuhan dan anggaran, sekaligus membantu pemilik kos mempublikasikan serta mengelola informasi tempat kos secara praktis.
