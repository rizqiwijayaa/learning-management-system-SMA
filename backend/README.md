# LMS Guru API (MySQL)

## 1) Setup database
1. Buat database + tabel dengan file `backend/sql/schema.sql`.
2. Contoh lewat MySQL CLI:
   - `mysql -u root -p < backend/sql/schema.sql`

## 2) Setup environment
1. Copy `backend/.env.example` menjadi `backend/.env`.
2. Isi koneksi MySQL sesuai laptop/server kamu.

## 3) Jalankan API
1. Masuk folder backend:
   - `cd backend`
2. Install dependency:
   - `npm install`
3. Run:
   - `npm run dev`

API default: `http://localhost:3000/api`

## Endpoint
- `GET /api/health`
- `GET /api/master/subjects`
- `GET /api/master/curriculums`
- `POST /api/master/curriculums`
- `PUT /api/master/curriculums/:id`
- `DELETE /api/master/curriculums/:id`
- `GET /api/materi`
- `POST /api/materi`
- `PUT /api/materi/:id`
- `GET /api/tugas?type=tugas|ujian`
- `POST /api/tugas`
- `PUT /api/tugas/:id`
