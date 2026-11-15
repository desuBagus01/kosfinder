-- ==============================================================================
-- SKEMA BASIS DATA SUPABASE - PROYEK KOSFINDER
-- Berkas: supabase/schema.sql
-- ==============================================================================

-- 1. PEMBUATAN TABEL KOS
-- Tabel utama untuk menyimpan informasi data kos yang dipublikasikan oleh pemilik.
-- Seluruh kos yang berhasil ditambahkan langsung terpublikasi untuk umum (tanpa status Draft/is_active).
-- Nilai available_rooms = 0 merepresentasikan bahwa kamar sedang penuh, bukan disembunyikan.
CREATE TABLE IF NOT EXISTS public.kos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) > 0),
    address TEXT NOT NULL CHECK (char_length(trim(address)) > 0),
    area TEXT NOT NULL CHECK (char_length(trim(area)) > 0),
    contact_number TEXT NOT NULL CHECK (char_length(trim(contact_number)) >= 8),
    price_per_month BIGINT NOT NULL CHECK (price_per_month >= 0),
    description TEXT NOT NULL,
    available_rooms INTEGER NOT NULL DEFAULT 0 CHECK (available_rooms >= 0),
    has_wifi BOOLEAN NOT NULL DEFAULT FALSE,
    has_bathroom_inside BOOLEAN NOT NULL DEFAULT FALSE,
    has_parking BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Komentar dokumentasi tabel dan kolom
COMMENT ON TABLE public.kos IS 'Tabel untuk menyimpan data kos pada aplikasi KosFinder (seluruh kos langsung dipublikasikan)';
COMMENT ON COLUMN public.kos.id IS 'ID unik kos (UUID). Lebih sulit ditebak dibanding integer berurutan, namun keamanan kepemilikan tetap ditegakkan via RLS';
COMMENT ON COLUMN public.kos.owner_id IS 'ID pemilik kos yang terhubung dengan tabel auth.users';
COMMENT ON COLUMN public.kos.price_per_month IS 'Tarif sewa kos per bulan dalam satuan Rupiah (wajib bertipe angka)';
COMMENT ON COLUMN public.kos.available_rooms IS 'Jumlah sisa kamar yang tersedia (angka >= 0; 0 = kamar penuh)';
COMMENT ON COLUMN public.kos.contact_number IS 'Nomor telepon atau WhatsApp pemilik untuk dihubungi oleh pencari kos';
COMMENT ON COLUMN public.kos.address IS 'Alamat fisik kos, digunakan dalam pencarian teks bebas bersama kolom area';
COMMENT ON COLUMN public.kos.area IS 'Nama area/wilayah kos, digunakan dalam pencarian teks bebas bersama kolom address';

-- 2. INDEKS PENCARIAN & PERFORMA
-- Indeks untuk mengoptimalkan filter rentang harga, query kos milik pemilik, dan pengurutan waktu (NFR05)
-- Catatan: Pencarian teks bebas menggunakan ILIKE '%keyword%' tidak efektif memanfaatkan indeks B-tree standar.
-- Pada skala target awal sekitar 20 data kos, sequential scan sepenuhnya memadai dan efisien tanpa indeks GIN/pg_trgm.
CREATE INDEX IF NOT EXISTS idx_kos_price_per_month ON public.kos (price_per_month);
CREATE INDEX IF NOT EXISTS idx_kos_owner_id ON public.kos (owner_id);
CREATE INDEX IF NOT EXISTS idx_kos_created_at ON public.kos (created_at DESC);

-- 3. FUNGSI & TRIGGER PEMBARUAN OTOMATIS UPDATED_AT
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at ON public.kos;
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON public.kos
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- 4. PENGAKTIFAN ROW LEVEL SECURITY (RLS)
-- Seluruh aturan akses data wajib ditegakkan di backend menggunakan Supabase RLS.
ALTER TABLE public.kos ENABLE ROW LEVEL SECURITY;

-- 5. KEBIJAKAN ROW LEVEL SECURITY (RLS POLICIES)

-- Kebijakan 1: Melihat Kos (SELECT)
-- Semua pengguna (pencari kos tanpa login maupun pengguna terautentikasi) dapat melihat seluruh data kos yang tersimpan.
DROP POLICY IF EXISTS "Semua pengguna dapat melihat kos" ON public.kos;
CREATE POLICY "Semua pengguna dapat melihat kos"
ON public.kos
FOR SELECT
TO public
USING (true);

-- Kebijakan 2: Menambahkan Kos (INSERT)
-- Hanya pemilik yang sudah login yang dapat menambahkan data kos, dan ID pemilik harus sesuai dengan ID pengguna yang login.
DROP POLICY IF EXISTS "Pemilik dapat menambahkan kos miliknya" ON public.kos;
CREATE POLICY "Pemilik dapat menambahkan kos miliknya"
ON public.kos
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = owner_id);

-- Kebijakan 3: Mengubah Kos (UPDATE)
-- Pemilik kos hanya boleh mengubah data kos miliknya sendiri. Pemilik lain tidak dapat mengubah kos tersebut.
DROP POLICY IF EXISTS "Pemilik hanya dapat mengubah kos miliknya sendiri" ON public.kos;
CREATE POLICY "Pemilik hanya dapat mengubah kos miliknya sendiri"
ON public.kos
FOR UPDATE
TO authenticated
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

-- Kebijakan 4: Menghapus Kos (DELETE)
-- Pemilik kos hanya boleh menghapus data kos miliknya sendiri. Pemilik lain tidak dapat menghapus kos tersebut.
DROP POLICY IF EXISTS "Pemilik hanya dapat menghapus kos miliknya sendiri" ON public.kos;
CREATE POLICY "Pemilik hanya dapat menghapus kos miliknya sendiri"
ON public.kos
FOR DELETE
TO authenticated
USING (auth.uid() = owner_id);

-- 6. PENGATURAN HAK AKSES TABEL (GRANT & REVOKE)
-- Cabut seluruh hak akses bawaan terlebih dahulu demi kepastian izin peran yang eksplisit:
REVOKE ALL ON TABLE public.kos FROM anon, authenticated, public;

-- Berikan izin eksplisit yang diperlukan sesuai peran (least privilege):
-- Role 'anon' (pencari kos yang belum login) hanya diberi izin baca (SELECT).
GRANT SELECT ON TABLE public.kos TO anon;

-- Role 'authenticated' (pemilik kos yang telah login) diberi izin baca, tambah, ubah, dan hapus.
-- Seluruh aksi ini tetap dibatasi dan dilindungi oleh kebijakan Row Level Security (RLS) di atas.
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.kos TO authenticated;

-- Catatan: Hak akses role administratif khusus (seperti service_role) tidak diubah atau dicabut.
