CREATE DATABASE IF NOT EXISTS lms_guru_db;
USE lms_guru_db;

CREATE TABLE IF NOT EXISTS subjects (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  code VARCHAR(30) NOT NULL DEFAULT '',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS materi (
  id INT AUTO_INCREMENT PRIMARY KEY,
  teacher_id INT NULL,
  teacher_nip VARCHAR(50) NULL,
  teacher_name VARCHAR(120) NULL,
  title VARCHAR(255) NOT NULL,
  subject VARCHAR(100) NOT NULL,
  upload_date VARCHAR(50) NOT NULL,
  description TEXT,
  content LONGTEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tugas_ujian (
  id INT AUTO_INCREMENT PRIMARY KEY,
  teacher_id INT NULL,
  teacher_nip VARCHAR(50) NULL,
  teacher_name VARCHAR(120) NULL,
  title VARCHAR(255) NOT NULL,
  subject VARCHAR(100) NOT NULL,
  date VARCHAR(50) NOT NULL,
  type ENUM('tugas', 'ujian') NOT NULL,
  description TEXT,
  attachment_name VARCHAR(255),
  duration_minutes INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS teacher_profile (
  id INT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  role VARCHAR(120) NOT NULL,
  nip VARCHAR(50) NOT NULL,
  email VARCHAR(150) NOT NULL,
  phone VARCHAR(50) NOT NULL,
  avatar_base64 LONGTEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS kepsek_profile (
  id INT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  role VARCHAR(120) NOT NULL,
  nip VARCHAR(50) NOT NULL,
  email VARCHAR(150) NOT NULL,
  phone VARCHAR(50) NOT NULL,
  avatar_base64 LONGTEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS kesiswaan_profile (
  id INT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  role VARCHAR(120) NOT NULL,
  nip VARCHAR(50) NOT NULL,
  email VARCHAR(150) NOT NULL,
  phone VARCHAR(50) NOT NULL,
  avatar_base64 LONGTEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app_users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  role VARCHAR(120) NOT NULL,
  nip VARCHAR(50) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password VARCHAR(150) NOT NULL,
  phone VARCHAR(50) NOT NULL,
  avatar_base64 LONGTEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS students (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  nis VARCHAR(30) NOT NULL UNIQUE,
  class_name VARCHAR(50) NOT NULL DEFAULT 'X IPA 1',
  major VARCHAR(50) NOT NULL DEFAULT 'IPA',
  status VARCHAR(30) NOT NULL DEFAULT 'Aktif',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS student_grades (
  id INT AUTO_INCREMENT PRIMARY KEY,
  teacher_id INT NULL,
  teacher_nip VARCHAR(50) NULL,
  teacher_name VARCHAR(120) NULL,
  student_name VARCHAR(120) NOT NULL,
  subject VARCHAR(100) NOT NULL,
  class_name VARCHAR(50) NOT NULL,
  score INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS attendance_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  teacher_id INT NULL,
  teacher_nip VARCHAR(50) NULL,
  teacher_name VARCHAR(120) NULL,
  student_name VARCHAR(120) NOT NULL,
  class_name VARCHAR(50) NOT NULL,
  month_label VARCHAR(50) NOT NULL,
  present_days INT NOT NULL DEFAULT 0,
  izin_days INT NOT NULL DEFAULT 0,
  alfa_days INT NOT NULL DEFAULT 0,
  accent_color VARCHAR(20) NOT NULL DEFAULT '#D6E6FF',
  initial VARCHAR(4) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS attendance_daily_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  attendance_record_id INT NOT NULL,
  teacher_id INT NULL,
  teacher_nip VARCHAR(50) NULL,
  teacher_name VARCHAR(120) NULL,
  student_name VARCHAR(120) NOT NULL,
  class_name VARCHAR(50) NOT NULL,
  month_label VARCHAR(50) NOT NULL,
  date_label VARCHAR(50) NOT NULL,
  day_order INT NOT NULL DEFAULT 1,
  date_value DATE NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'hadir',
  note TEXT NULL,
  accent_color VARCHAR(20) NOT NULL DEFAULT '#D6E6FF',
  initial VARCHAR(4) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY attendance_daily_unique (attendance_record_id, day_order),
  CONSTRAINT fk_attendance_daily_parent
    FOREIGN KEY (attendance_record_id) REFERENCES attendance_records(id)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS journal_entries (
  id INT AUTO_INCREMENT PRIMARY KEY,
  teacher_id INT NULL,
  teacher_nip VARCHAR(50) NULL,
  teacher_name VARCHAR(120) NULL,
  date_label VARCHAR(50) NOT NULL,
  subject VARCHAR(100) NOT NULL,
  title VARCHAR(255) NOT NULL,
  material_summary TEXT NOT NULL,
  class_name VARCHAR(50) NOT NULL,
  attendance_count INT NOT NULL DEFAULT 0,
  accent_color VARCHAR(20) NOT NULL DEFAULT '#4D7CFF',
  learning_points LONGTEXT,
  summary_paragraphs LONGTEXT,
  progress_title VARCHAR(120) NOT NULL DEFAULT 'Progress Pembelajaran',
  progress_note TEXT,
  task_title TEXT,
  task_deadline VARCHAR(120),
  image_base64 LONGTEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sarpras (
  id INT AUTO_INCREMENT PRIMARY KEY,
  item_name VARCHAR(255) NOT NULL,
  category VARCHAR(100) NOT NULL,
  item_condition ENUM('Baik', 'Rusak Ringan', 'Rusak') NOT NULL DEFAULT 'Baik',
  location VARCHAR(100) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS humas_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  category VARCHAR(100) NOT NULL,
  partner VARCHAR(150) NOT NULL,
  location VARCHAR(150) NOT NULL,
  schedule_date VARCHAR(50) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'Terjadwal',
  description TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS curriculums (
  id INT AUTO_INCREMENT PRIMARY KEY,
  subject VARCHAR(120) NOT NULL,
  code VARCHAR(30) NOT NULL,
  major VARCHAR(50) NOT NULL,
  grade VARCHAR(20) NOT NULL,
  teacher VARCHAR(120) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'Aktif',
  school_year VARCHAR(20) NOT NULL DEFAULT '2024/2025',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY curriculums_code_major_grade_unique (code, major, grade)
);

CREATE TABLE IF NOT EXISTS student_violations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  student_name VARCHAR(120) NOT NULL,
  class_name VARCHAR(50) NOT NULL,
  violation_type VARCHAR(120) NOT NULL,
  description TEXT NOT NULL,
  action_taken VARCHAR(150) NOT NULL DEFAULT '',
  points INT NOT NULL DEFAULT 0,
  violation_date VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO subjects (name, code) VALUES
('Matematika', 'MTK'),
('Bahasa Indonesia', 'BIN'),
('Bahasa Inggris', 'BIG'),
('IPA', 'IPA'),
('IPS', 'IPS'),
('PKN', 'PKN')
ON DUPLICATE KEY UPDATE
  code = VALUES(code);

INSERT INTO app_users (name, role, nip, email, password, phone, avatar_base64) VALUES
('Rizqi', 'Guru', '1987654321', 'rizqi.guru@sekolah.id', 'guru123', '08xx-xxxx-0001', NULL),
('Dian Pratama', 'Kesiswaan', '1987654322', 'kesiswaan@sekolah.id', 'kesiswaan123', '08xx-xxxx-0002', NULL),
('Budi Santoso', 'Kepala Sekolah', '1987654323', 'kepsek@sekolah.id', 'kepsek123', '08xx-xxxx-0003', NULL)
ON DUPLICATE KEY UPDATE
  id = id;

INSERT IGNORE INTO teacher_profile (id, name, role, nip, email, phone, avatar_base64)
SELECT id, name, role, nip, email, phone, avatar_base64 FROM app_users WHERE role = 'Guru';

INSERT IGNORE INTO kepsek_profile (id, name, role, nip, email, phone, avatar_base64)
SELECT id, name, role, nip, email, phone, avatar_base64 FROM app_users WHERE role = 'Kepala Sekolah';

INSERT IGNORE INTO kesiswaan_profile (id, name, role, nip, email, phone, avatar_base64)
SELECT id, name, role, nip, email, phone, avatar_base64 FROM app_users WHERE role = 'Kesiswaan';

INSERT INTO students (name, nis, class_name, major, status) VALUES
('Dewi Santosa', '22001', 'X IPA 1', 'IPA', 'Aktif'),
('Hadi Wijaya', '22002', 'X IPA 1', 'IPA', 'Aktif'),
('Siti Lestari', '22003', 'X IPA 1', 'IPA', 'Aktif'),
('Andi Saputra', '22004', 'X IPA 1', 'IPA', 'Aktif'),
('Bunga Maharani', '22005', 'X IPA 1', 'IPA', 'Aktif'),
('Cahyo Pratama', '22006', 'X IPA 1', 'IPA', 'Aktif'),
('Dimas Kurnia', '22007', 'X IPA 1', 'IPA', 'Aktif'),
('Eka Putri', '22008', 'X IPA 1', 'IPA', 'Aktif'),
('Fajar Nugroho', '22009', 'X IPA 1', 'IPA', 'Aktif'),
('Gita Anggraini', '22010', 'X IPA 1', 'IPA', 'Aktif'),
('Hendra Prakoso', '22011', 'X IPA 1', 'IPA', 'Aktif'),
('Intan Permata', '22012', 'X IPA 2', 'IPA', 'Aktif'),
('Joko Susanto', '22013', 'X IPA 2', 'IPA', 'Aktif'),
('Kartika Sari', '22014', 'X IPA 2', 'IPA', 'Aktif'),
('Lukman Hakim', '22015', 'X IPA 2', 'IPA', 'Aktif'),
('Maya Puspita', '22016', 'X IPA 2', 'IPA', 'Aktif'),
('Nanda Saputri', '22017', 'X IPA 2', 'IPA', 'Aktif'),
('Oki Ramadhan', '22018', 'X IPA 2', 'IPA', 'Aktif'),
('Putri Amelia', '22019', 'X IPA 2', 'IPA', 'Aktif'),
('Qori Azzahra', '22020', 'X IPA 2', 'IPA', 'Aktif'),
('Raka Maulana', '22021', 'X IPA 3', 'IPA', 'Aktif'),
('Salsa Nabila', '22022', 'X IPA 3', 'IPA', 'Aktif'),
('Teguh Pranata', '22023', 'X IPA 3', 'IPA', 'Aktif'),
('Ulfa Rahma', '22024', 'X IPA 3', 'IPA', 'Aktif'),
('Vina Oktavia', '22025', 'X IPA 3', 'IPA', 'Aktif'),
('Wahyu Firmansyah', '22026', 'X IPA 3', 'IPA', 'Aktif'),
('Yuni Lestari', '22027', 'X IPA 3', 'IPA', 'Aktif'),
('Zaki Akbar', '22028', 'X IPA 3', 'IPA', 'Aktif')
ON DUPLICATE KEY UPDATE
  nis = VALUES(nis),
  class_name = VALUES(class_name),
  major = VALUES(major),
  status = VALUES(status);

INSERT INTO student_grades (student_name, subject, class_name, score) VALUES
('Dewi Santosa', 'Matematika', 'X IPA 1', 85),
('Hadi Wijaya', 'Matematika', 'X IPA 1', 70),
('Siti Lestari', 'Matematika', 'X IPA 1', 60),
('Ahmad Fauzi', 'Matematika', 'X IPA 1', 92),
('Nadia Putri', 'Matematika', 'X IPA 1', 78),
('Rian Saputra', 'Bahasa Inggris', 'X IPA 1', 88),
('Citra Lestari', 'Bahasa Inggris', 'X IPA 2', 73),
('Bagas Pratama', 'IPA', 'X IPA 2', 66),
('Salma Azzahra', 'IPA', 'X IPA 1', 94);

INSERT INTO attendance_records (
  student_name, class_name, month_label, present_days, izin_days, alfa_days, accent_color, initial
) VALUES
('Dewi Santosa', 'X IPA 1', 'Maret 2026', 18, 3, 1, '#F7D6F8', 'D'),
('Hadi Wijaya', 'X IPA 1', 'Maret 2026', 26, 1, 0, '#D6E6FF', 'H'),
('Siti Lestari', 'X IPA 1', 'Maret 2026', 26, 3, 1, '#E6D6FF', 'S'),
('Ahmad Fauzi', 'X IPA 1', 'Maret 2026', 21, 3, 1, '#D5E5FF', 'A'),
('Rina Putri', 'X IPA 1', 'Maret 2026', 21, 1, 0, '#D4F2EC', 'R');

INSERT INTO attendance_daily_records (
  attendance_record_id,
  teacher_id,
  teacher_nip,
  teacher_name,
  student_name,
  class_name,
  month_label,
  date_label,
  day_order,
  date_value,
  status,
  note,
  accent_color,
  initial
)
SELECT
  ar.id,
  ar.teacher_id,
  ar.teacher_nip,
  ar.teacher_name,
  ar.student_name,
  ar.class_name,
  ar.month_label,
  CONCAT(seq.day_order, ' Maret 2026'),
  seq.day_order,
  STR_TO_DATE(CONCAT('2026-03-', LPAD(seq.day_order, 2, '0')), '%Y-%m-%d'),
  CASE
    WHEN seq.day_order <= ar.present_days THEN 'hadir'
    WHEN seq.day_order <= ar.present_days + ar.izin_days THEN 'izin'
    ELSE 'alfa'
  END,
  '',
  ar.accent_color,
  ar.initial
FROM attendance_records ar
JOIN (
  SELECT 1 AS day_order UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
  SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL
  SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL
  SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL
  SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL
  SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL
  SELECT 30 UNION ALL SELECT 31
) seq
  ON seq.day_order <= ar.present_days + ar.izin_days + ar.alfa_days
LEFT JOIN attendance_daily_records adr
  ON adr.attendance_record_id = ar.id
 AND adr.day_order = seq.day_order
WHERE adr.id IS NULL;

INSERT INTO journal_entries (
  date_label, subject, title, material_summary, class_name, attendance_count, accent_color,
  learning_points, summary_paragraphs, progress_title, progress_note, task_title, task_deadline, image_base64
)
SELECT * FROM (
  SELECT
    '26 Maret 2026',
    'Matematika',
    'Pembelajaran Persamaan Linear',
    'Penjelasan konsep dasar + latihan soal',
    'X IPA 1',
    28,
    '#4D7CFF',
    JSON_ARRAY('Penjelasan konsep dasar persamaan linear', 'Latihan soal SPLDV (sistem persamaan linear dua variabel)'),
    JSON_ARRAY('Persamaan linear adalah persamaan yang berbentuk ax + b = 0 di mana a dan b adalah konstanta dan x adalah variabel.', 'SPLDV adalah bentuk persamaan linear yang memiliki dua variabel.'),
    'Progress Pembelajaran',
    'Materi hari ini sudah dipahami dan latihan dasar berjalan lancar.',
    'Kerjakan soal SPLDV halaman 25 nomor 1-10',
    'Besok',
    NULL
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM journal_entries WHERE title = 'Pembelajaran Persamaan Linear' AND date_label = '26 Maret 2026'
)
LIMIT 1;

INSERT INTO journal_entries (
  date_label, subject, title, material_summary, class_name, attendance_count, accent_color,
  learning_points, summary_paragraphs, progress_title, progress_note, task_title, task_deadline, image_base64
)
SELECT * FROM (
  SELECT
    '25 Maret 2026',
    'Fisika',
    'Teori Gerak Parabola',
    'Persamaan dan grafik gerak parabola',
    'X IPA 1',
    27,
    '#2F83FF',
    JSON_ARRAY('Menjelaskan konsep kecepatan awal dan sudut elevasi', 'Membaca grafik lintasan gerak parabola'),
    JSON_ARRAY('Gerak parabola merupakan perpaduan gerak lurus beraturan pada sumbu-x dan gerak lurus berubah beraturan pada sumbu-y.', 'Siswa berlatih menghitung titik puncak dan jarak jangkau lintasan.'),
    'Progress Pembelajaran',
    'Sebagian besar siswa sudah memahami hubungan sudut dan tinggi maksimum.',
    'Rangkum rumus gerak parabola di buku catatan',
    'Lusa',
    NULL
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM journal_entries WHERE title = 'Teori Gerak Parabola' AND date_label = '25 Maret 2026'
)
LIMIT 1;

INSERT INTO journal_entries (
  date_label, subject, title, material_summary, class_name, attendance_count, accent_color,
  learning_points, summary_paragraphs, progress_title, progress_note, task_title, task_deadline, image_base64
)
SELECT * FROM (
  SELECT
    '24 Maret 2026',
    'Biologi',
    'Sistem Pernapasan Manusia',
    'Organ pernapasan dan fungsinya',
    'X IPA 1',
    29,
    '#4A86F7',
    JSON_ARRAY('Mengidentifikasi organ pernapasan manusia', 'Menjelaskan fungsi alveolus dan paru-paru'),
    JSON_ARRAY('Sistem pernapasan manusia terdiri dari hidung, tenggorokan, bronkus, dan paru-paru.', 'Siswa mampu menjelaskan jalur masuknya udara hingga proses pertukaran oksigen.'),
    'Progress Pembelajaran',
    'Diskusi kelas aktif dan siswa antusias saat memetakan fungsi organ.',
    'Buat bagan sistem pernapasan manusia',
    'Jumat',
    NULL
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM journal_entries WHERE title = 'Sistem Pernapasan Manusia' AND date_label = '24 Maret 2026'
)
LIMIT 1;

INSERT INTO curriculums (subject, code, major, grade, teacher, status, school_year)
SELECT * FROM (
  SELECT 'Matematika', 'MTK', 'RPL', 'X', 'Rizqi Wicaksono', 'Aktif', '2024/2025'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM curriculums WHERE code = 'MTK' AND major = 'RPL' AND grade = 'X'
)
LIMIT 1;

INSERT INTO student_violations (
  student_name, class_name, violation_type, description, action_taken, points, violation_date
)
SELECT * FROM (
  SELECT
    'Andi Saputra',
    'X IPA 1',
    'Terlambat',
    'Datang terlambat 20 menit saat apel pagi.',
    'Peringatan lisan',
    5,
    '20 Mei 2026'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM student_violations
  WHERE student_name = 'Andi Saputra' AND violation_type = 'Terlambat' AND violation_date = '20 Mei 2026'
)
LIMIT 1;

INSERT INTO student_violations (
  student_name, class_name, violation_type, description, action_taken, points, violation_date
)
SELECT * FROM (
  SELECT
    'Putri Ananda',
    'XI TKJ 2',
    'Atribut Tidak Lengkap',
    'Tidak memakai atribut seragam lengkap.',
    'Pencatatan pelanggaran',
    3,
    '19 Mei 2026'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM student_violations
  WHERE student_name = 'Putri Ananda' AND violation_type = 'Atribut Tidak Lengkap' AND violation_date = '19 Mei 2026'
)
LIMIT 1;

INSERT INTO student_violations (
  student_name, class_name, violation_type, description, action_taken, points, violation_date
)
SELECT * FROM (
  SELECT
    'Dimas Ramadhan',
    'XII MM 1',
    'Keluar Kelas Tanpa Izin',
    'Meninggalkan kelas saat pembelajaran berlangsung tanpa izin.',
    'Panggilan pembinaan',
    8,
    '18 Mei 2026'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM student_violations
  WHERE student_name = 'Dimas Ramadhan' AND violation_type = 'Keluar Kelas Tanpa Izin' AND violation_date = '18 Mei 2026'
)
LIMIT 1;

INSERT INTO curriculums (subject, code, major, grade, teacher, status, school_year)
SELECT * FROM (
  SELECT 'Bahasa Indonesia', 'BIN', 'TKJ', 'X', 'Siti Aminah', 'Aktif', '2024/2025'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM curriculums WHERE code = 'BIN' AND major = 'TKJ' AND grade = 'X'
)
LIMIT 1;

INSERT INTO curriculums (subject, code, major, grade, teacher, status, school_year)
SELECT * FROM (
  SELECT 'Bahasa Inggris', 'BIG', 'DKV', 'XI', 'Andi Nugraha', 'Aktif', '2024/2025'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM curriculums WHERE code = 'BIG' AND major = 'DKV' AND grade = 'XI'
)
LIMIT 1;

INSERT INTO curriculums (subject, code, major, grade, teacher, status, school_year)
SELECT * FROM (
  SELECT 'IPA', 'IPA', 'IPA', 'XI', 'Dewi Lestari', 'Aktif', '2024/2025'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM curriculums WHERE code = 'IPA' AND major = 'IPA' AND grade = 'XI'
)
LIMIT 1;

INSERT INTO curriculums (subject, code, major, grade, teacher, status, school_year)
SELECT * FROM (
  SELECT 'IPS', 'IPS', 'IPS', 'XII', 'Budi Santoso', 'Aktif', '2024/2025'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM curriculums WHERE code = 'IPS' AND major = 'IPS' AND grade = 'XII'
)
LIMIT 1;

INSERT INTO curriculums (subject, code, major, grade, teacher, status, school_year)
SELECT * FROM (
  SELECT 'PKN', 'PKN', 'AKL', 'XII', 'Nina Marlina', 'Nonaktif', '2023/2024'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM curriculums WHERE code = 'PKN' AND major = 'AKL' AND grade = 'XII'
)
LIMIT 1;

INSERT INTO sarpras (item_name, category, item_condition, location, quantity)
SELECT * FROM (
  SELECT 'Proyektor Epson X500', 'Elektronik', 'Baik', 'Lab Komputer 1', 2
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM sarpras WHERE item_name = 'Proyektor Epson X500' AND location = 'Lab Komputer 1'
)
LIMIT 1;

INSERT INTO sarpras (item_name, category, item_condition, location, quantity)
SELECT * FROM (
  SELECT 'Kursi Siswa Ergo', 'Mebel', 'Rusak Ringan', 'Kelas X RPL 1', 8
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM sarpras WHERE item_name = 'Kursi Siswa Ergo' AND location = 'Kelas X RPL 1'
)
LIMIT 1;

INSERT INTO sarpras (item_name, category, item_condition, location, quantity)
SELECT * FROM (
  SELECT 'AC Split 2 PK', 'Elektronik', 'Rusak', 'Ruang Guru', 1
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM sarpras WHERE item_name = 'AC Split 2 PK' AND location = 'Ruang Guru'
)
LIMIT 1;

INSERT INTO humas_records (title, category, partner, location, schedule_date, status, description)
SELECT * FROM (
  SELECT
    'Rapat Wali Murid',
    'Pertemuan',
    'Komite Sekolah',
    'Aula Sekolah',
    '20 Mei 2026',
    'Terjadwal',
    'Koordinasi agenda pembelajaran dan komunikasi sekolah-orang tua.'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM humas_records WHERE title = 'Rapat Wali Murid' AND schedule_date = '20 Mei 2026'
)
LIMIT 1;

INSERT INTO humas_records (title, category, partner, location, schedule_date, status, description)
SELECT * FROM (
  SELECT
    'Kerja Sama PKL dengan PT. Maju Bersama',
    'Kemitraan',
    'PT. Maju Bersama',
    'Ruang Kepala Sekolah',
    '15 Mei 2026',
    'Berjalan',
    'Menyiapkan peluang PKL dan penguatan relasi industri sekolah.'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM humas_records WHERE title = 'Kerja Sama PKL dengan PT. Maju Bersama' AND schedule_date = '15 Mei 2026'
)
LIMIT 1;

INSERT INTO humas_records (title, category, partner, location, schedule_date, status, description)
SELECT * FROM (
  SELECT
    'Kunjungan Industri Kelas XI',
    'Publikasi',
    'PT. Tekno Nusantara',
    'Jakarta',
    '10 Mei 2026',
    'Selesai',
    'Kegiatan publikasi dan dokumentasi program kunjungan industri siswa.'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM humas_records WHERE title = 'Kunjungan Industri Kelas XI' AND schedule_date = '10 Mei 2026'
)
LIMIT 1;

INSERT INTO materi (title, subject, upload_date, description, content)
SELECT * FROM (
  SELECT 'Matematika - Persamaan Linear', 'Matematika', '20 Maret 2026', 'Pengenalan persamaan linear', 'Materi dasar persamaan linear dan contoh penyelesaian.'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM materi WHERE title = 'Matematika - Persamaan Linear'
)
LIMIT 1;

INSERT INTO materi (title, subject, upload_date, description, content)
SELECT * FROM (
  SELECT 'Bahasa Inggris - Present Tense', 'Bahasa Inggris', '18 Maret 2026', 'Pengenalan simple present tense', 'Materi penggunaan simple present tense dalam kalimat positif, negatif, dan tanya.'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM materi WHERE title = 'Bahasa Inggris - Present Tense'
)
LIMIT 1;

INSERT INTO materi (title, subject, upload_date, description, content)
SELECT * FROM (
  SELECT 'IPA - Sistem Peredaran Darah', 'IPA', '15 Maret 2026', 'Sistem peredaran darah manusia', 'Pembahasan jantung, pembuluh darah, dan alur peredaran darah besar-kecil.'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM materi WHERE title = 'IPA - Sistem Peredaran Darah'
)
LIMIT 1;

INSERT INTO materi (title, subject, upload_date, description, content)
SELECT * FROM (
  SELECT 'IPS - Keragaman Ekonomi', 'IPS', '10 Maret 2026', 'Keragaman ekonomi di Indonesia', 'Contoh kegiatan ekonomi masyarakat berdasarkan wilayah dan potensi sumber daya.'
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM materi WHERE title = 'IPS - Keragaman Ekonomi'
)
LIMIT 1;

INSERT INTO tugas_ujian (title, subject, date, type, description, attachment_name, duration_minutes)
SELECT * FROM (
  SELECT 'Matematika - Latihan Persamaan Linear', 'Matematika', '25 Maret 2026', 'tugas', 'Kerjakan soal latihan bab persamaan linear.', '', NULL
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM tugas_ujian WHERE title = 'Matematika - Latihan Persamaan Linear' AND type = 'tugas'
)
LIMIT 1;

INSERT INTO tugas_ujian (title, subject, date, type, description, attachment_name, duration_minutes)
SELECT * FROM (
  SELECT 'Bahasa Inggris - Present Tense Quiz', 'Bahasa Inggris', '26 Maret 2026', 'tugas', 'Kerjakan quiz present tense sesuai instruksi.', '', NULL
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM tugas_ujian WHERE title = 'Bahasa Inggris - Present Tense Quiz' AND type = 'tugas'
)
LIMIT 1;

INSERT INTO tugas_ujian (title, subject, date, type, description, attachment_name, duration_minutes)
SELECT * FROM (
  SELECT 'IPA - Sistem Peredaran Darah', 'IPA', '28 Maret 2026', 'tugas', 'Kerjakan lembar kerja sistem peredaran darah.', '', NULL
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM tugas_ujian WHERE title = 'IPA - Sistem Peredaran Darah' AND type = 'tugas'
)
LIMIT 1;

INSERT INTO tugas_ujian (title, subject, date, type, description, attachment_name, duration_minutes)
SELECT * FROM (
  SELECT 'IPS - Keragaman Ekonomi', 'IPS', '30 Maret 2026', 'tugas', 'Buat rangkuman keragaman ekonomi.', '', NULL
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM tugas_ujian WHERE title = 'IPS - Keragaman Ekonomi' AND type = 'tugas'
)
LIMIT 1;

INSERT INTO tugas_ujian (title, subject, date, type, description, attachment_name, duration_minutes)
SELECT * FROM (
  SELECT 'Ujian Matematika - Persamaan Linear', 'Matematika', '27 Maret 2026', 'ujian', 'Ujian materi persamaan linear.', 'soal_ujian_matematika.pdf', 90
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM tugas_ujian WHERE title = 'Ujian Matematika - Persamaan Linear' AND type = 'ujian'
)
LIMIT 1;

INSERT INTO tugas_ujian (title, subject, date, type, description, attachment_name, duration_minutes)
SELECT * FROM (
  SELECT 'Ujian Bahasa Inggris - Present Tense', 'Bahasa Inggris', '29 Maret 2026', 'ujian', 'Ujian materi present tense.', 'soal_ujian_binggris.pdf', 90
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM tugas_ujian WHERE title = 'Ujian Bahasa Inggris - Present Tense' AND type = 'ujian'
)
LIMIT 1;

INSERT INTO tugas_ujian (title, subject, date, type, description, attachment_name, duration_minutes)
SELECT * FROM (
  SELECT 'Ujian IPA - Sistem Peredaran Darah', 'IPA', '31 Maret 2026', 'ujian', 'Ujian materi sistem peredaran darah.', 'soal_ujian_ipa.pdf', 90
) AS tmp
WHERE NOT EXISTS (
  SELECT 1 FROM tugas_ujian WHERE title = 'Ujian IPA - Sistem Peredaran Darah' AND type = 'ujian'
)
LIMIT 1;
