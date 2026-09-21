const express = require('express');
const { pool } = require('../db');

const router = express.Router();

const defaultSubjects = [
  { name: 'Matematika', code: 'MTK' },
  { name: 'Bahasa Indonesia', code: 'BIN' },
  { name: 'Bahasa Inggris', code: 'BIG' },
  { name: 'IPA', code: 'IPA' },
  { name: 'IPS', code: 'IPS' },
  { name: 'PKN', code: 'PKN' },
];

const defaultStudents = [
  { name: 'Dewi Santosa', className: 'X IPA 1', major: 'IPA' },
  { name: 'Hadi Wijaya', className: 'X IPA 1', major: 'IPA' },
  { name: 'Siti Lestari', className: 'X IPA 1', major: 'IPA' },
  { name: 'Andi Saputra', className: 'X IPA 1', major: 'IPA' },
  { name: 'Bunga Maharani', className: 'X IPA 1', major: 'IPA' },
  { name: 'Cahyo Pratama', className: 'X IPA 1', major: 'IPA' },
  { name: 'Dimas Kurnia', className: 'X IPA 1', major: 'IPA' },
  { name: 'Eka Putri', className: 'X IPA 1', major: 'IPA' },
  { name: 'Fajar Nugroho', className: 'X IPA 1', major: 'IPA' },
  { name: 'Gita Anggraini', className: 'X IPA 1', major: 'IPA' },
  { name: 'Hendra Prakoso', className: 'X IPA 1', major: 'IPA' },
  { name: 'Intan Permata', className: 'X IPA 2', major: 'IPA' },
  { name: 'Joko Susanto', className: 'X IPA 2', major: 'IPA' },
  { name: 'Kartika Sari', className: 'X IPA 2', major: 'IPA' },
  { name: 'Lukman Hakim', className: 'X IPA 2', major: 'IPA' },
  { name: 'Maya Puspita', className: 'X IPA 2', major: 'IPA' },
  { name: 'Nanda Saputri', className: 'X IPA 2', major: 'IPA' },
  { name: 'Oki Ramadhan', className: 'X IPA 2', major: 'IPA' },
  { name: 'Putri Amelia', className: 'X IPA 2', major: 'IPA' },
  { name: 'Qori Azzahra', className: 'X IPA 2', major: 'IPA' },
  { name: 'Raka Maulana', className: 'X IPA 3', major: 'IPA' },
  { name: 'Salsa Nabila', className: 'X IPA 3', major: 'IPA' },
  { name: 'Teguh Pranata', className: 'X IPA 3', major: 'IPA' },
  { name: 'Ulfa Rahma', className: 'X IPA 3', major: 'IPA' },
  { name: 'Vina Oktavia', className: 'X IPA 3', major: 'IPA' },
  { name: 'Wahyu Firmansyah', className: 'X IPA 3', major: 'IPA' },
  { name: 'Yuni Lestari', className: 'X IPA 3', major: 'IPA' },
  { name: 'Zaki Akbar', className: 'X IPA 3', major: 'IPA' },
];

const defaultActivities = [
  {
    title: 'Data siswa baru "Naufal Ramadhan" telah ditambahkan',
    actor: 'oleh Admin',
    type: 'student_add',
  },
  {
    title: 'Perubahan wali kelas pada kelas XII TKJ 1',
    actor: 'oleh Admin',
    type: 'class_update',
  },
  {
    title: 'Absensi siswa kelas XI RPL 1 telah diperbarui',
    actor: 'oleh Admin',
    type: 'attendance_update',
  },
  {
    title: 'Siswa "Kayla Lestari" dimutasi ke SMK 2 Bandung',
    actor: 'oleh Admin',
    type: 'student_mutation',
  },
];

const defaultCurriculums = [
  {
    subject: 'Matematika',
    code: 'MTK',
    major: 'RPL',
    grade: 'X',
    teacher: 'Rizqi Wicaksono',
    status: 'Aktif',
    schoolYear: '2024/2025',
  },
  {
    subject: 'Bahasa Indonesia',
    code: 'BIN',
    major: 'TKJ',
    grade: 'X',
    teacher: 'Siti Aminah',
    status: 'Aktif',
    schoolYear: '2024/2025',
  },
  {
    subject: 'Bahasa Inggris',
    code: 'BIG',
    major: 'DKV',
    grade: 'XI',
    teacher: 'Andi Nugraha',
    status: 'Aktif',
    schoolYear: '2024/2025',
  },
  {
    subject: 'IPA',
    code: 'IPA',
    major: 'IPA',
    grade: 'XI',
    teacher: 'Dewi Lestari',
    status: 'Aktif',
    schoolYear: '2024/2025',
  },
  {
    subject: 'IPS',
    code: 'IPS',
    major: 'IPS',
    grade: 'XII',
    teacher: 'Budi Santoso',
    status: 'Aktif',
    schoolYear: '2024/2025',
  },
  {
    subject: 'PKN',
    code: 'PKN',
    major: 'AKL',
    grade: 'XII',
    teacher: 'Nina Marlina',
    status: 'Nonaktif',
    schoolYear: '2023/2024',
  },
];

const defaultSarpras = [
  {
    itemName: 'Proyektor Epson X500',
    category: 'Elektronik',
    itemCondition: 'Baik',
    location: 'Lab Komputer 1',
    quantity: 2,
  },
  {
    itemName: 'Kursi Siswa Ergo',
    category: 'Mebel',
    itemCondition: 'Rusak Ringan',
    location: 'Kelas X RPL 1',
    quantity: 8,
  },
  {
    itemName: 'AC Split 2 PK',
    category: 'Elektronik',
    itemCondition: 'Rusak',
    location: 'Ruang Guru',
    quantity: 1,
  },
  {
    itemName: 'Whiteboard Magnetik',
    category: 'Perlengkapan Kelas',
    itemCondition: 'Baik',
    location: 'Kelas XI TKJ 2',
    quantity: 1,
  },
  {
    itemName: 'Meja Guru',
    category: 'Mebel',
    itemCondition: 'Baik',
    location: 'Kelas XII DKV 1',
    quantity: 1,
  },
];

const defaultHumasRecords = [
  {
    title: 'Rapat Wali Murid',
    category: 'Pertemuan',
    partner: 'Komite Sekolah',
    location: 'Aula Sekolah',
    scheduleDate: '20 Mei 2026',
    status: 'Terjadwal',
    description: 'Koordinasi agenda pembelajaran dan komunikasi sekolah-orang tua.',
  },
  {
    title: 'Kerja Sama PKL dengan PT. Maju Bersama',
    category: 'Kemitraan',
    partner: 'PT. Maju Bersama',
    location: 'Ruang Kepala Sekolah',
    scheduleDate: '15 Mei 2026',
    status: 'Berjalan',
    description: 'Menyiapkan peluang PKL dan penguatan relasi industri sekolah.',
  },
  {
    title: 'Kunjungan Industri Kelas XI',
    category: 'Publikasi',
    partner: 'PT. Tekno Nusantara',
    location: 'Jakarta',
    scheduleDate: '10 Mei 2026',
    status: 'Selesai',
    description: 'Kegiatan publikasi dan dokumentasi program kunjungan industri siswa.',
  },
];

const defaultViolations = [
  {
    studentName: 'Andi Saputra',
    className: 'X IPA 1',
    violationType: 'Terlambat',
    description: 'Datang terlambat 20 menit saat apel pagi.',
    actionTaken: 'Peringatan lisan',
    points: 5,
    violationDate: '20 Mei 2026',
  },
  {
    studentName: 'Putri Ananda',
    className: 'XI TKJ 2',
    violationType: 'Atribut Tidak Lengkap',
    description: 'Tidak memakai atribut seragam lengkap.',
    actionTaken: 'Pencatatan pelanggaran',
    points: 3,
    violationDate: '19 Mei 2026',
  },
  {
    studentName: 'Dimas Ramadhan',
    className: 'XII MM 1',
    violationType: 'Keluar Kelas Tanpa Izin',
    description: 'Meninggalkan kelas saat pembelajaran berlangsung tanpa izin.',
    actionTaken: 'Panggilan pembinaan',
    points: 8,
    violationDate: '18 Mei 2026',
  },
];

function normalizeText(value) {
  return `${value ?? ''}`.trim();
}

function deriveMajorFromClassName(className) {
  const upper = normalizeText(className).toUpperCase();
  if (upper.includes('RPL')) return 'RPL';
  if (upper.includes('TKJ')) return 'TKJ';
  if (upper.includes('MM')) return 'MM';
  if (upper.includes('IPA')) return 'IPA';
  if (upper.includes('IPS')) return 'IPS';
  return 'Umum';
}

function buildNis(seed) {
  return `${22000 + seed}`;
}

function buildCurriculumCode(subjectName, index = 0) {
  const text = normalizeText(subjectName)
    .replace(/[^A-Za-z0-9\s]/g, ' ')
    .trim();
  if (!text) {
    return `SUB${String(index + 1).padStart(2, '0')}`;
  }

  const words = text.split(/\s+/).filter(Boolean);
  const acronym = words.map((word) => word[0]).join('').toUpperCase();
  if (acronym.length >= 3) {
    return acronym.substring(0, 6);
  }

  return text.replace(/\s+/g, '').substring(0, 6).toUpperCase();
}

function normalizeStudentPayload(payload) {
  const name = normalizeText(payload.name);
  const nis = normalizeText(payload.nis);
  const className = normalizeText(payload.class_name ?? payload.className);
  const major = normalizeText(payload.major);
  const status = normalizeText(payload.status);

  return {
    name,
    nis,
    className,
    major,
    status,
  };
}

function normalizeSarprasPayload(payload) {
  return {
    itemName: normalizeText(payload.item_name ?? payload.itemName),
    category: normalizeText(payload.category),
    itemCondition: normalizeText(payload.item_condition ?? payload.itemCondition) || 'Baik',
    location: normalizeText(payload.location),
    quantity: Number(payload.quantity ?? 0),
  };
}

function normalizeHumasPayload(payload) {
  return {
    title: normalizeText(payload.title),
    category: normalizeText(payload.category),
    partner: normalizeText(payload.partner),
    location: normalizeText(payload.location),
    scheduleDate: normalizeText(payload.schedule_date ?? payload.scheduleDate),
    status: normalizeText(payload.status) || 'Terjadwal',
    description: normalizeText(payload.description),
  };
}

function normalizeViolationPayload(payload) {
  return {
    studentName: normalizeText(payload.student_name ?? payload.studentName),
    className: normalizeText(payload.class_name ?? payload.className),
    violationType: normalizeText(payload.violation_type ?? payload.violationType),
    description: normalizeText(payload.description),
    actionTaken: normalizeText(payload.action_taken ?? payload.actionTaken),
    points: Number(payload.points ?? 0),
    violationDate: normalizeText(payload.violation_date ?? payload.violationDate),
  };
}

async function ensureStudentsTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS students (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(120) NOT NULL UNIQUE,
      class_name VARCHAR(50) NOT NULL DEFAULT 'X IPA 1',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  const [columnRows] = await pool.query(`
    SELECT COLUMN_NAME
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'students'
  `);
  const columns = new Set(columnRows.map((row) => row.COLUMN_NAME));

  if (!columns.has('nis')) {
    await pool.query(
      `ALTER TABLE students ADD COLUMN nis VARCHAR(30) NOT NULL DEFAULT ''`,
    );
  }
  if (!columns.has('major')) {
    await pool.query(
      `ALTER TABLE students ADD COLUMN major VARCHAR(50) NOT NULL DEFAULT 'IPA'`,
    );
  }
  if (!columns.has('status')) {
    await pool.query(
      `ALTER TABLE students ADD COLUMN status VARCHAR(30) NOT NULL DEFAULT 'Aktif'`,
    );
  }
  if (!columns.has('updated_at')) {
    await pool.query(
      `ALTER TABLE students ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`,
    );
  }

  const [countRows] = await pool.query(`
    SELECT COUNT(*) AS total
    FROM students
  `);
  const totalStudents = Number(countRows[0]?.total || 0);

  if (totalStudents === 0) {
    for (let index = 0; index < defaultStudents.length; index += 1) {
      const student = defaultStudents[index];
      await pool.query(
        `
          INSERT INTO students (name, nis, class_name, major, status)
          VALUES (?, ?, ?, ?, ?)
        `,
        [
          student.name,
          buildNis(index + 1),
          student.className,
          student.major,
          'Aktif',
        ],
      );
    }
  }

  await pool.query(`
    UPDATE students
    SET nis = CONCAT('22', LPAD(id, 4, '0'))
    WHERE nis IS NULL OR nis = ''
  `);

  await pool.query(`
    UPDATE students
    SET major = CASE
      WHEN major IS NULL OR major = '' THEN
        CASE
          WHEN UPPER(class_name) LIKE '%RPL%' THEN 'RPL'
          WHEN UPPER(class_name) LIKE '%TKJ%' THEN 'TKJ'
          WHEN UPPER(class_name) LIKE '%MM%' THEN 'MM'
          WHEN UPPER(class_name) LIKE '%IPS%' THEN 'IPS'
          ELSE 'IPA'
        END
      ELSE major
    END,
    status = CASE
      WHEN status IS NULL OR status = '' THEN 'Aktif'
      ELSE status
    END
  `);

  const [indexRows] = await pool.query(`
    SHOW INDEX FROM students WHERE Key_name = 'students_nis_unique'
  `);
  if (indexRows.length === 0) {
    await pool.query(
      `ALTER TABLE students ADD UNIQUE KEY students_nis_unique (nis)`,
    );
  }
}

async function ensureSubjectsTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS subjects (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL UNIQUE,
      code VARCHAR(30) NOT NULL DEFAULT '',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  const [columnRows] = await pool.query(`
    SELECT COLUMN_NAME
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'subjects'
  `);
  const columns = new Set(columnRows.map((row) => row.COLUMN_NAME));

  if (!columns.has('code')) {
    await pool.query(
      `ALTER TABLE subjects ADD COLUMN code VARCHAR(30) NOT NULL DEFAULT ''`,
    );
  }

  for (const item of defaultSubjects) {
    await pool.query(
      `
        INSERT INTO subjects (name, code)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE code = VALUES(code)
      `,
      [item.name, item.code],
    );
  }
}

async function ensureActivitiesTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS activity_logs (
      id INT AUTO_INCREMENT PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      actor VARCHAR(120) NOT NULL,
      type VARCHAR(60) NOT NULL DEFAULT 'general',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  for (const item of defaultActivities) {
    await pool.query(
      `
        DELETE FROM activity_logs
        WHERE title = ? AND actor = ? AND type = ?
      `,
      [item.title, item.actor, item.type],
    );
  }
}

async function ensureViolationsTable() {
  await pool.query(`
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
    )
  `);

  const [countRows] = await pool.query(`
    SELECT COUNT(*) AS total
    FROM student_violations
  `);
  const total = Number(countRows[0]?.total || 0);

  if (total === 0) {
    for (const item of defaultViolations) {
      await pool.query(
        `
          INSERT INTO student_violations (
            student_name, class_name, violation_type, description, action_taken, points, violation_date
          )
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `,
        [
          item.studentName,
          item.className,
          item.violationType,
          item.description,
          item.actionTaken,
          item.points,
          item.violationDate,
        ],
      );
    }
  }
}

async function ensureSarprasTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS sarpras (
      id INT AUTO_INCREMENT PRIMARY KEY,
      item_name VARCHAR(255) NOT NULL,
      category VARCHAR(100) NOT NULL,
      item_condition ENUM('Baik', 'Rusak Ringan', 'Rusak') NOT NULL DEFAULT 'Baik',
      location VARCHAR(100) NOT NULL,
      quantity INT NOT NULL DEFAULT 1,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `);

  const [countRows] = await pool.query(`
    SELECT COUNT(*) AS total
    FROM sarpras
  `);
  const total = Number(countRows[0]?.total || 0);

  if (total === 0) {
    for (const item of defaultSarpras) {
      await pool.query(
        `
          INSERT INTO sarpras (item_name, category, item_condition, location, quantity)
          VALUES (?, ?, ?, ?, ?)
        `,
        [
          item.itemName,
          item.category,
          item.itemCondition,
          item.location,
          item.quantity,
        ],
      );
    }
  }
}

async function ensureHumasTable() {
  await pool.query(`
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
    )
  `);

  const [countRows] = await pool.query(`
    SELECT COUNT(*) AS total
    FROM humas_records
  `);
  const total = Number(countRows[0]?.total || 0);

  if (total === 0) {
    for (const item of defaultHumasRecords) {
      await pool.query(
        `
          INSERT INTO humas_records (
            title, category, partner, location, schedule_date, status, description
          )
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `,
        [
          item.title,
          item.category,
          item.partner,
          item.location,
          item.scheduleDate,
          item.status,
          item.description,
        ],
      );
    }
  }
}

async function ensureCurriculumsTable() {
  await ensureSubjectsTable();
  await pool.query(`
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
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  `);

  const [codeIndexRows] = await pool.query(`
    SHOW INDEX FROM curriculums WHERE Key_name = 'curriculums_code_major_grade_unique'
  `);
  if (codeIndexRows.length === 0) {
    await pool.query(`
      ALTER TABLE curriculums
      ADD UNIQUE KEY curriculums_code_major_grade_unique (code, major, grade)
    `);
  }

  const [countRows] = await pool.query(`
    SELECT COUNT(*) AS total
    FROM curriculums
  `);
  const total = Number(countRows[0]?.total || 0);

  if (total === 0) {
    const [subjectRows] = await pool.query(
      'SELECT id, name, code FROM subjects ORDER BY name ASC',
    );

    const seededItems = subjectRows.length > 0
      ? defaultCurriculums.map((item, index) => {
          const matchedSubject = subjectRows.find(
            (subjectRow) => normalizeText(subjectRow.name) === item.subject,
          );
          return {
            ...item,
            code:
              normalizeText(matchedSubject?.code).toUpperCase() ||
              item.code ||
              buildCurriculumCode(item.subject, index),
          };
        })
      : defaultCurriculums;

    for (let index = 0; index < seededItems.length; index += 1) {
      const item = seededItems[index];
      await pool.query(
        `
          INSERT INTO curriculums (subject, code, major, grade, teacher, status, school_year)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `,
        [
          item.subject,
          normalizeText(item.code).toUpperCase() || buildCurriculumCode(item.subject, index),
          item.major,
          item.grade,
          item.teacher,
          item.status,
          item.schoolYear,
        ],
      );
    }
  }
}

function normalizeCurriculumPayload(payload) {
  return {
    subject: normalizeText(payload.subject),
    code: normalizeText(payload.code).toUpperCase(),
    major: normalizeText(payload.major).toUpperCase(),
    grade: normalizeText(payload.grade).toUpperCase(),
    teacher: normalizeText(payload.teacher),
    status: normalizeText(payload.status) || 'Aktif',
    schoolYear: normalizeText(payload.school_year ?? payload.schoolYear) || '2024/2025',
  };
}

async function findCurriculumById(id) {
  const [rows] = await pool.query(
    `
      SELECT id, subject, code, major, grade, teacher, status, school_year
      FROM curriculums
      WHERE id = ?
      LIMIT 1
    `,
    [id],
  );

  return rows[0] ?? null;
}

async function findStudentById(id) {
  const [rows] = await pool.query(
    `
      SELECT id, name, nis, class_name, major, status
      FROM students
      WHERE id = ?
      LIMIT 1
    `,
    [id],
  );

  return rows[0] ?? null;
}

async function findSarprasById(id) {
  const [rows] = await pool.query(
    `
      SELECT id, item_name, category, item_condition, location, quantity
      FROM sarpras
      WHERE id = ?
      LIMIT 1
    `,
    [id],
  );

  return rows[0] ?? null;
}

async function findHumasById(id) {
  const [rows] = await pool.query(
    `
      SELECT id, title, category, partner, location, schedule_date, status, description
      FROM humas_records
      WHERE id = ?
      LIMIT 1
    `,
    [id],
  );

  return rows[0] ?? null;
}

async function findViolationById(id) {
  const [rows] = await pool.query(
    `
      SELECT id, student_name, class_name, violation_type, description, action_taken, points, violation_date
      FROM student_violations
      WHERE id = ?
      LIMIT 1
    `,
    [id],
  );

  return rows[0] ?? null;
}

router.get('/subjects', async (_req, res) => {
  try {
    await ensureSubjectsTable();
    const [rows] = await pool.query(
      'SELECT id, name, code FROM subjects ORDER BY name ASC',
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat mapel', error: err.message });
  }
});

router.get('/students', async (_req, res) => {
  try {
    await ensureStudentsTable();
    const [rows] = await pool.query(
      `
        SELECT id, name, nis, class_name, major, status
        FROM students
        ORDER BY name ASC
      `,
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat siswa', error: err.message });
  }
});

router.post('/students', async (req, res) => {
  try {
    await ensureStudentsTable();
    const payload = normalizeStudentPayload(req.body);
    const major = payload.major || deriveMajorFromClassName(payload.className);
    const status = payload.status || 'Aktif';

    if (!payload.name || !payload.nis || !payload.className) {
      return res.status(400).json({
        message: 'Nama, NIS, dan kelas wajib diisi',
      });
    }

    const [duplicateRows] = await pool.query(
      'SELECT id FROM students WHERE name = ? OR nis = ? LIMIT 1',
      [payload.name, payload.nis],
    );
    if (duplicateRows.length > 0) {
      return res.status(409).json({ message: 'Nama atau NIS siswa sudah digunakan' });
    }

    const [result] = await pool.query(
      `
        INSERT INTO students (name, nis, class_name, major, status)
        VALUES (?, ?, ?, ?, ?)
      `,
      [payload.name, payload.nis, payload.className, major, status],
    );

    const student = await findStudentById(result.insertId);
    res.status(201).json(student);
  } catch (err) {
    res.status(500).json({ message: 'Gagal menambah siswa', error: err.message });
  }
});

router.put('/students/:id', async (req, res) => {
  try {
    await ensureStudentsTable();
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ message: 'ID siswa tidak valid' });
    }

    const payload = normalizeStudentPayload(req.body);
    const major = payload.major || deriveMajorFromClassName(payload.className);
    const status = payload.status || 'Aktif';

    if (!payload.name || !payload.nis || !payload.className) {
      return res.status(400).json({
        message: 'Nama, NIS, dan kelas wajib diisi',
      });
    }

    const [duplicateRows] = await pool.query(
      'SELECT id FROM students WHERE (name = ? OR nis = ?) AND id <> ? LIMIT 1',
      [payload.name, payload.nis, id],
    );
    if (duplicateRows.length > 0) {
      return res.status(409).json({ message: 'Nama atau NIS siswa sudah digunakan' });
    }

    const [result] = await pool.query(
      `
        UPDATE students
        SET name = ?, nis = ?, class_name = ?, major = ?, status = ?
        WHERE id = ?
      `,
      [payload.name, payload.nis, payload.className, major, status, id],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Siswa tidak ditemukan' });
    }

    const student = await findStudentById(id);
    res.json(student);
  } catch (err) {
    res.status(500).json({ message: 'Gagal mengubah siswa', error: err.message });
  }
});

router.delete('/students/:id', async (req, res) => {
  try {
    await ensureStudentsTable();
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ message: 'ID siswa tidak valid' });
    }

    const [result] = await pool.query('DELETE FROM students WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Siswa tidak ditemukan' });
    }

    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ message: 'Gagal menghapus siswa', error: err.message });
  }
});

router.get('/students/count', async (_req, res) => {
  try {
    await ensureStudentsTable();
    const [rows] = await pool.query('SELECT COUNT(*) AS total FROM students');
    res.json({ total: Number(rows[0]?.total || 0) });
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat jumlah siswa', error: err.message });
  }
});

router.get('/activities', async (_req, res) => {
  try {
    await ensureActivitiesTable();
    const [rows] = await pool.query(`
      SELECT id, title, actor, type, created_at
      FROM activity_logs
      ORDER BY id DESC
      LIMIT 10
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat aktivitas', error: err.message });
  }
});

router.get('/violations', async (_req, res) => {
  try {
    await ensureViolationsTable();
    const [rows] = await pool.query(`
      SELECT id, student_name, class_name, violation_type, description, action_taken, points, violation_date
      FROM student_violations
      ORDER BY id DESC
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat pelanggaran siswa', error: err.message });
  }
});

router.post('/violations', async (req, res) => {
  try {
    await ensureViolationsTable();
    const payload = normalizeViolationPayload(req.body);

    if (
      !payload.studentName ||
      !payload.className ||
      !payload.violationType ||
      !payload.description ||
      !payload.violationDate
    ) {
      return res.status(400).json({
        message: 'Nama siswa, kelas, jenis pelanggaran, deskripsi, dan tanggal wajib diisi',
      });
    }

    const [result] = await pool.query(
      `
        INSERT INTO student_violations (
          student_name, class_name, violation_type, description, action_taken, points, violation_date
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `,
      [
        payload.studentName,
        payload.className,
        payload.violationType,
        payload.description,
        payload.actionTaken,
        payload.points,
        payload.violationDate,
      ],
    );

    const created = await findViolationById(result.insertId);
    res.status(201).json(created);
  } catch (err) {
    res.status(500).json({ message: 'Gagal menambah pelanggaran siswa', error: err.message });
  }
});

router.put('/violations/:id', async (req, res) => {
  try {
    await ensureViolationsTable();
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ message: 'ID pelanggaran tidak valid' });
    }

    const payload = normalizeViolationPayload(req.body);
    if (
      !payload.studentName ||
      !payload.className ||
      !payload.violationType ||
      !payload.description ||
      !payload.violationDate
    ) {
      return res.status(400).json({
        message: 'Nama siswa, kelas, jenis pelanggaran, deskripsi, dan tanggal wajib diisi',
      });
    }

    const [result] = await pool.query(
      `
        UPDATE student_violations
        SET student_name = ?, class_name = ?, violation_type = ?, description = ?, action_taken = ?, points = ?, violation_date = ?
        WHERE id = ?
      `,
      [
        payload.studentName,
        payload.className,
        payload.violationType,
        payload.description,
        payload.actionTaken,
        payload.points,
        payload.violationDate,
        id,
      ],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Pelanggaran siswa tidak ditemukan' });
    }

    const updated = await findViolationById(id);
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: 'Gagal mengubah pelanggaran siswa', error: err.message });
  }
});

router.delete('/violations/:id', async (req, res) => {
  try {
    await ensureViolationsTable();
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ message: 'ID pelanggaran tidak valid' });
    }

    const [result] = await pool.query('DELETE FROM student_violations WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Pelanggaran siswa tidak ditemukan' });
    }

    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ message: 'Gagal menghapus pelanggaran siswa', error: err.message });
  }
});

router.get('/sarpras', async (_req, res) => {
  try {
    await ensureSarprasTable();
    const [rows] = await pool.query(`
      SELECT id, item_name, category, item_condition, location, quantity
      FROM sarpras
      ORDER BY item_name ASC, location ASC
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat sarpras', error: err.message });
  }
});

router.get('/sarpras/summary', async (_req, res) => {
  try {
    await ensureSarprasTable();
    const [rows] = await pool.query(`
      SELECT
        COUNT(*) AS total_sarpras,
        SUM(CASE WHEN item_condition <> 'Baik' THEN 1 ELSE 0 END) AS damaged_count,
        SUM(CASE WHEN item_condition = 'Baik' THEN 1 ELSE 0 END) AS safe_count
      FROM sarpras
    `);
    const totalSarpras = Number(rows[0]?.total_sarpras || 0);
    const damagedCount = Number(rows[0]?.damaged_count || 0);
    const safeCount = Number(rows[0]?.safe_count || 0);
    const damagePercentage =
      totalSarpras <= 0 ? 0 : Math.round((damagedCount / totalSarpras) * 100);

    res.json({
      totalSarpras,
      damagedCount,
      safeCount,
      damagePercentage,
    });
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat ringkasan sarpras', error: err.message });
  }
});

router.post('/sarpras', async (req, res) => {
  try {
    await ensureSarprasTable();
    const payload = normalizeSarprasPayload(req.body);

    if (!payload.itemName || !payload.category || !payload.location || payload.quantity <= 0) {
      return res.status(400).json({
        message: 'Nama barang, kategori, lokasi, dan jumlah wajib diisi',
      });
    }

    const [result] = await pool.query(
      `
        INSERT INTO sarpras (item_name, category, item_condition, location, quantity)
        VALUES (?, ?, ?, ?, ?)
      `,
      [
        payload.itemName,
        payload.category,
        payload.itemCondition,
        payload.location,
        payload.quantity,
      ],
    );

    const created = await findSarprasById(result.insertId);
    res.status(201).json(created);
  } catch (err) {
    res.status(500).json({ message: 'Gagal menambah sarpras', error: err.message });
  }
});

router.put('/sarpras/:id', async (req, res) => {
  try {
    await ensureSarprasTable();
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ message: 'ID sarpras tidak valid' });
    }

    const payload = normalizeSarprasPayload(req.body);
    if (!payload.itemName || !payload.category || !payload.location || payload.quantity <= 0) {
      return res.status(400).json({
        message: 'Nama barang, kategori, lokasi, dan jumlah wajib diisi',
      });
    }

    const [result] = await pool.query(
      `
        UPDATE sarpras
        SET item_name = ?, category = ?, item_condition = ?, location = ?, quantity = ?
        WHERE id = ?
      `,
      [
        payload.itemName,
        payload.category,
        payload.itemCondition,
        payload.location,
        payload.quantity,
        id,
      ],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Data sarpras tidak ditemukan' });
    }

    const updated = await findSarprasById(id);
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: 'Gagal mengubah sarpras', error: err.message });
  }
});

router.delete('/sarpras/:id', async (req, res) => {
  try {
    await ensureSarprasTable();
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ message: 'ID sarpras tidak valid' });
    }

    const [result] = await pool.query('DELETE FROM sarpras WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Data sarpras tidak ditemukan' });
    }

    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ message: 'Gagal menghapus sarpras', error: err.message });
  }
});

router.get('/humas', async (_req, res) => {
  try {
    await ensureHumasTable();
    const [rows] = await pool.query(`
      SELECT id, title, category, partner, location, schedule_date, status, description
      FROM humas_records
      ORDER BY id DESC
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat humas', error: err.message });
  }
});

router.get('/humas/summary', async (_req, res) => {
  try {
    await ensureHumasTable();
    const [rows] = await pool.query(`
      SELECT
        COUNT(*) AS total_agenda,
        COUNT(DISTINCT CASE WHEN TRIM(partner) <> '' THEN partner END) AS partner_count,
        SUM(CASE WHEN status = 'Terjadwal' THEN 1 ELSE 0 END) AS scheduled_count,
        SUM(CASE WHEN status <> 'Terjadwal' THEN 1 ELSE 0 END) AS other_status_count
      FROM humas_records
    `);

    res.json({
      totalAgenda: Number(rows[0]?.total_agenda || 0),
      partnerCount: Number(rows[0]?.partner_count || 0),
      scheduledCount: Number(rows[0]?.scheduled_count || 0),
      otherStatusCount: Number(rows[0]?.other_status_count || 0),
    });
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat ringkasan humas', error: err.message });
  }
});

router.post('/humas', async (req, res) => {
  try {
    await ensureHumasTable();
    const payload = normalizeHumasPayload(req.body);

    if (!payload.title || !payload.category || !payload.partner || !payload.location || !payload.scheduleDate) {
      return res.status(400).json({
        message: 'Judul, kategori, mitra, lokasi, dan tanggal kegiatan wajib diisi',
      });
    }

    const [result] = await pool.query(
      `
        INSERT INTO humas_records (
          title, category, partner, location, schedule_date, status, description
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `,
      [
        payload.title,
        payload.category,
        payload.partner,
        payload.location,
        payload.scheduleDate,
        payload.status,
        payload.description,
      ],
    );

    const created = await findHumasById(result.insertId);
    res.status(201).json(created);
  } catch (err) {
    res.status(500).json({ message: 'Gagal menambah humas', error: err.message });
  }
});

router.put('/humas/:id', async (req, res) => {
  try {
    await ensureHumasTable();
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ message: 'ID humas tidak valid' });
    }

    const payload = normalizeHumasPayload(req.body);
    if (!payload.title || !payload.category || !payload.partner || !payload.location || !payload.scheduleDate) {
      return res.status(400).json({
        message: 'Judul, kategori, mitra, lokasi, dan tanggal kegiatan wajib diisi',
      });
    }

    const [result] = await pool.query(
      `
        UPDATE humas_records
        SET title = ?, category = ?, partner = ?, location = ?, schedule_date = ?, status = ?, description = ?
        WHERE id = ?
      `,
      [
        payload.title,
        payload.category,
        payload.partner,
        payload.location,
        payload.scheduleDate,
        payload.status,
        payload.description,
        id,
      ],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Data humas tidak ditemukan' });
    }

    const updated = await findHumasById(id);
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: 'Gagal mengubah humas', error: err.message });
  }
});

router.delete('/humas/:id', async (req, res) => {
  try {
    await ensureHumasTable();
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ message: 'ID humas tidak valid' });
    }

    const [result] = await pool.query('DELETE FROM humas_records WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Data humas tidak ditemukan' });
    }

    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ message: 'Gagal menghapus humas', error: err.message });
  }
});

router.get('/curriculums', async (_req, res) => {
  try {
    await ensureCurriculumsTable();
    const [rows] = await pool.query(`
      SELECT id, subject, code, major, grade, teacher, status, school_year
      FROM curriculums
      ORDER BY subject ASC, grade ASC, major ASC
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat kurikulum', error: err.message });
  }
});

router.get('/kesiswaan/summary', async (_req, res) => {
  try {
    await ensureStudentsTable();
    await ensureActivitiesTable();
    await ensureViolationsTable();

    const safeRows = async (sql) => {
      try {
        const [rows] = await pool.query(sql);
        return Array.isArray(rows) ? rows : [];
      } catch (_) {
        return [];
      }
    };

    const students = await safeRows(`
      SELECT name, class_name, major, status
      FROM students
    `);
    const violations = await safeRows(`
      SELECT student_name, class_name, violation_type, violation_date
      FROM student_violations
      ORDER BY id DESC
    `);
    const activities = await safeRows(`
      SELECT title, actor, type, created_at
      FROM activity_logs
      ORDER BY id DESC
      LIMIT 10
    `);
    const attendance = await safeRows(`
      SELECT present_days, izin_days, alfa_days
      FROM attendance_records
    `);

    const totalStudents = students.length;
    const activeStudents = students.filter(
      (item) => String(item.status || '').trim().toLowerCase() === 'aktif',
    ).length;
    const mutationStudents = students.filter(
      (item) => String(item.status || '').trim().toLowerCase() === 'mutasi',
    ).length;
    const nonActiveStudents = students.filter(
      (item) => String(item.status || '').trim().toLowerCase() === 'nonaktif',
    ).length;
    const classCount = new Set(
      students
        .map((item) => String(item.class_name || '').trim())
        .filter(Boolean),
    ).size;

    let presentTotal = 0;
    let izinTotal = 0;
    let alfaTotal = 0;
    for (const row of attendance) {
      presentTotal += Number(row.present_days || 0);
      izinTotal += Number(row.izin_days || 0);
      alfaTotal += Number(row.alfa_days || 0);
    }
    const attendanceBase = presentTotal + izinTotal + alfaTotal;
    const attendanceRate = attendanceBase > 0
      ? Math.round((presentTotal / attendanceBase) * 100)
      : 0;

    const recentViolations = violations.slice(0, 3).map((item) => ({
      title: `${String(item.student_name || '').trim()} (${String(item.class_name || '').trim()})`,
      subtitle: String(item.violation_type || '').trim(),
      trailing: String(item.violation_date || '').trim(),
    }));

    const recentMutations = activities
      .filter((item) => String(item.type || '').trim().toLowerCase() === 'student_mutation')
      .slice(0, 3)
      .map((item) => ({
        title: String(item.title || '').trim(),
        subtitle: String(item.actor || '').trim(),
        trailing: item.created_at
          ? new Date(item.created_at).toISOString()
          : '',
      }));

    const recentActivities = activities.slice(0, 5).map((item) => ({
      title: String(item.title || '').trim(),
      actor: String(item.actor || '').trim(),
      type: String(item.type || '').trim(),
      createdAt: item.created_at ? new Date(item.created_at).toISOString() : null,
    }));

    const attentionStudentsByClass = new Map();
    const studentCountByClass = new Map();
    for (const item of students) {
      const className = String(item.class_name || '').trim();
      const status = String(item.status || '').trim().toLowerCase();
      if (!className) continue;
      studentCountByClass.set(
        className,
        Number(studentCountByClass.get(className) || 0) + 1,
      );
      if (status === 'mutasi' || status === 'nonaktif') {
        attentionStudentsByClass.set(
          className,
          Number(attentionStudentsByClass.get(className) || 0) + 1,
        );
      }
    }

    const violationCountByClass = new Map();
    for (const item of violations) {
      const className = String(item.class_name || '').trim();
      if (!className) continue;
      violationCountByClass.set(
        className,
        Number(violationCountByClass.get(className) || 0) + 1,
      );
    }

    const rankedClassAttention = [...new Set([
      ...studentCountByClass.keys(),
      ...violationCountByClass.keys(),
      ...attentionStudentsByClass.keys(),
    ])]
      .map((className) => {
        const studentCount = Number(studentCountByClass.get(className) || 0);
        const violationCount = Number(violationCountByClass.get(className) || 0);
        const attentionCount = Number(attentionStudentsByClass.get(className) || 0);
        const score = (violationCount * 2) + attentionCount;
        return { className, studentCount, violationCount, attentionCount, score };
      })
      .sort((a, b) => {
        if (b.score !== a.score) return b.score - a.score;
        if (b.studentCount !== a.studentCount) return b.studentCount - a.studentCount;
        return a.className.localeCompare(b.className);
      })
      .slice(0, 3);

    const statusInsights = [
      {
        title: 'Siswa Aktif',
        value: activeStudents,
        subtitle: totalStudents > 0
          ? `${Math.round((activeStudents / totalStudents) * 100)}% dari total siswa`
          : '0% dari total siswa',
      },
      {
        title: 'Status Mutasi',
        value: mutationStudents,
        subtitle: totalStudents > 0
          ? `${Math.round((mutationStudents / totalStudents) * 100)}% perlu pemantauan`
          : '0% perlu pemantauan',
      },
      {
        title: 'Siswa Nonaktif',
        value: nonActiveStudents,
        subtitle: totalStudents > 0
          ? `${Math.round((nonActiveStudents / totalStudents) * 100)}% perlu verifikasi`
          : '0% perlu verifikasi',
      },
      {
        title: 'Absensi Masuk',
        value: attendance.length,
        subtitle: totalStudents > 0
          ? `${Math.round((attendance.length / totalStudents) * 100)}% siswa tercatat`
          : 'Menunggu data siswa',
      },
    ];

    const classAttentionHighlights = rankedClassAttention.map((item) => ({
      title: item.className,
      subtitle: `${item.violationCount} pelanggaran, ${item.attentionCount} siswa atensi dari ${item.studentCount} siswa`,
      trailing: item.score >= 4 ? 'Prioritas' : 'Pantau kelas',
    }));

    const missingAttendance = totalStudents > attendance.length
      ? totalStudents - attendance.length
      : 0;
    const followUpHighlights = [
      {
        title: 'Rekap absensi perlu dilengkapi',
        subtitle: missingAttendance > 0
          ? `${missingAttendance} siswa belum masuk rekap absensi terbaru`
          : 'Seluruh siswa sudah tercatat pada rekap absensi',
        trailing: missingAttendance > 0 ? 'Cek absensi' : 'Sudah lengkap',
      },
      {
        title: 'Status siswa perlu verifikasi',
        subtitle: `${mutationStudents + nonActiveStudents} siswa berstatus mutasi atau nonaktif`,
        trailing: mutationStudents + nonActiveStudents > 0 ? 'Verifikasi' : 'Stabil',
      },
      {
        title: 'Pelanggaran perlu koordinasi',
        subtitle: violations.length > 0
          ? `${violations.length} catatan pelanggaran perlu tindak lanjut wali kelas`
          : 'Belum ada pelanggaran yang perlu ditindaklanjuti',
        trailing: violations.length > 0 ? 'Tindak lanjut' : 'Terkendali',
      },
    ];

    res.json({
      totalStudents,
      activeStudents,
      mutationStudents,
      nonActiveStudents,
      classCount,
      violationCount: Number(violations.length),
      attendanceSummary: {
        presentTotal,
        izinTotal,
        alfaTotal,
        attendanceStudentCount: attendance.length,
        attendanceRate,
      },
      recentViolations,
      recentMutations,
      recentActivities,
      statusInsights,
      classAttentionHighlights,
      followUpHighlights,
    });
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat ringkasan kesiswaan', error: err.message });
  }
});

router.get('/kepsek/summary', async (_req, res) => {
  try {
    await ensureStudentsTable();
    await ensureSarprasTable();
    await ensureHumasTable();
    await ensureCurriculumsTable();

    const safeRows = async (sql) => {
      try {
        const [rows] = await pool.query(sql);
        return Array.isArray(rows) ? rows : [];
      } catch (_) {
        return [];
      }
    };

    const students = await safeRows(`
      SELECT name, class_name, major, status
      FROM students
    `);
    const sarpras = await safeRows(`
      SELECT item_name, item_condition
      FROM sarpras
    `);
    const humas = await safeRows(`
      SELECT title, status
      FROM humas_records
    `);
    const curriculums = await safeRows(`
      SELECT subject
      FROM curriculums
    `);
    const journals = await safeRows(`
      SELECT title, class_name, attendance_count
      FROM journal_entries
    `);
    const attendance = await safeRows(`
      SELECT student_name, class_name, present_days, izin_days, alfa_days
      FROM attendance_records
    `);

    const studentByName = new Map(
      students.map((item) => [
        String(item.name || '').trim().toLowerCase(),
        {
          className: String(item.class_name || '').trim(),
          major: String(item.major || '').trim(),
          status: String(item.status || '').trim(),
        },
      ]),
    );

    const classStats = new Map();
    const majorStats = new Map();

    for (const row of attendance) {
      const student = studentByName.get(String(row.student_name || '').trim().toLowerCase());
      if (!student) continue;

      const className = student.className || '-';
      const major = student.major || '-';
      const present = Number(row.present_days || 0);
      const izin = Number(row.izin_days || 0);
      const alfa = Number(row.alfa_days || 0);

      if (!classStats.has(className)) classStats.set(className, { present: 0, izin: 0, alfa: 0, totalStudents: 0 });
      if (!majorStats.has(major)) majorStats.set(major, { present: 0, izin: 0, alfa: 0, totalStudents: 0 });

      const classBox = classStats.get(className);
      classBox.present += present;
      classBox.izin += izin;
      classBox.alfa += alfa;
      classBox.totalStudents += 1;

      const majorBox = majorStats.get(major);
      majorBox.present += present;
      majorBox.izin += izin;
      majorBox.alfa += alfa;
      majorBox.totalStudents += 1;
    }

    const rateLabel = (box) => {
      const total = box.present + box.izin + box.alfa;
      return total <= 0 ? '0%' : `${Math.round((box.present / total) * 100)}%`;
    };

    let highestAttendanceClass = null;
    let highestAttentionClass = null;
    for (const [key, value] of classStats.entries()) {
      const total = value.present + value.izin + value.alfa;
      const rate = total <= 0 ? 0 : value.present / total;
      const bestTotal = highestAttendanceClass
        ? highestAttendanceClass.value.present + highestAttendanceClass.value.izin + highestAttendanceClass.value.alfa
        : 0;
      const bestRate = !highestAttendanceClass || bestTotal <= 0
        ? -1
        : highestAttendanceClass.value.present / bestTotal;
      if (rate > bestRate) highestAttendanceClass = { key, value };

      const attention = value.izin + value.alfa;
      const bestAttention = highestAttentionClass
        ? highestAttentionClass.value.izin + highestAttentionClass.value.alfa
        : -1;
      if (attention > bestAttention) highestAttentionClass = { key, value };
    }

    let largestMajor = null;
    let highestAttentionMajor = null;
    for (const [key, value] of majorStats.entries()) {
      if (!largestMajor || value.totalStudents > largestMajor.value.totalStudents) {
        largestMajor = { key, value };
      }
      const attention = value.izin + value.alfa;
      const bestAttention = highestAttentionMajor
        ? highestAttentionMajor.value.izin + highestAttentionMajor.value.alfa
        : -1;
      if (attention > bestAttention) highestAttentionMajor = { key, value };
    }

    const totalStudents = students.length;
    const totalSarpras = sarpras.length;
    const sarprasRusak = sarpras.filter((item) => String(item.item_condition || '').trim().toLowerCase() !== 'baik').length;
    const sarprasAman = totalSarpras - sarprasRusak;
    const izinAlfa = attendance.reduce(
      (sum, item) => sum + Number(item.izin_days || 0) + Number(item.alfa_days || 0),
      0,
    );
    const totalKelasJurnal = new Set(
      journals
        .map((item) => String(item.class_name || '').trim())
        .filter((item) => item.length > 0),
    ).size;
    const mapelAktif = new Set(
      curriculums
        .map((item) => String(item.subject || '').trim())
        .filter((item) => item.length > 0),
    ).size;
    const humasTerjadwal = humas.filter(
      (item) => String(item.status || '').trim().toLowerCase() === 'terjadwal',
    ).length;

    const comparisonInsights = [
      highestAttendanceClass
        ? {
            title: `Kelas dengan hadir tertinggi: ${highestAttendanceClass.key}`,
            subtitle: `${highestAttendanceClass.value.present} hadir dari ${highestAttendanceClass.value.present + highestAttendanceClass.value.izin + highestAttendanceClass.value.alfa} catatan absensi.`,
            badge: rateLabel(highestAttendanceClass.value),
          }
        : {
            title: 'Belum ada pembanding kelas',
            subtitle: 'Data absensi per kelas akan tampil setelah rekap tersedia.',
            badge: '-',
          },
      highestAttentionClass
        ? {
            title: `Kelas perlu atensi: ${highestAttentionClass.key}`,
            subtitle: `${highestAttentionClass.value.izin + highestAttentionClass.value.alfa} catatan izin/alfa perlu ditindaklanjuti.`,
            badge: `${highestAttentionClass.value.izin + highestAttentionClass.value.alfa} atensi`,
          }
        : {
            title: 'Belum ada kelas atensi',
            subtitle: 'Perbandingan izin dan alfa akan muncul di sini.',
            badge: '-',
          },
      largestMajor
        ? {
            title: `Jurusan dengan populasi terbesar: ${largestMajor.key}`,
            subtitle: `${largestMajor.value.totalStudents} siswa tercatat pada jurusan ini.`,
            badge: `${largestMajor.value.totalStudents} siswa`,
          }
        : {
            title: 'Belum ada data jurusan',
            subtitle: 'Sebaran jurusan akan muncul setelah data siswa terbaca.',
            badge: '-',
          },
      highestAttentionMajor
        ? {
            title: `Jurusan dengan atensi tertinggi: ${highestAttentionMajor.key}`,
            subtitle: `${highestAttentionMajor.value.izin + highestAttentionMajor.value.alfa} izin/alfa terkumpul di jurusan ini.`,
            badge: `${highestAttentionMajor.value.izin + highestAttentionMajor.value.alfa} catatan`,
          }
        : {
            title: 'Belum ada jurusan atensi',
            subtitle: 'Tren disiplin per jurusan akan tampil di sini.',
            badge: '-',
          },
    ];

    const executiveSnapshots = [
      {
        label: 'Kelas Terpantau',
        value: `${totalKelasJurnal}`,
        note: 'kelas muncul pada jurnal guru',
      },
      {
        label: 'Mapel Aktif',
        value: `${mapelAktif}`,
        note: 'mata pelajaran pada kurikulum',
      },
      {
        label: 'Atensi Siswa',
        value: `${izinAlfa}`,
        note: 'izin dan alfa perlu tindak lanjut',
      },
      {
        label: 'Sarpras Aman',
        value: `${totalSarpras <= 0 ? 0 : Math.round((sarprasAman / totalSarpras) * 100)}%`,
        note: 'fasilitas dalam kondisi baik',
      },
    ];

    const priorityInsights = [
      {
        title: 'Sarpras rusak perlu keputusan perbaikan',
        description: `${sarprasRusak} fasilitas masih tercatat rusak dan berpotensi mengganggu kegiatan belajar.`,
        badge: 'Sarpras',
      },
      {
        title: 'Catatan izin dan alfa perlu pembinaan',
        description: `${izinAlfa} catatan absensi non-hadir perlu dibahas bersama wali kelas dan kesiswaan.`,
        badge: 'Absensi',
      },
      {
        title: 'Agenda humas di luar jadwal perlu kontrol',
        description: `${Math.max(0, humas.length - humasTerjadwal)} agenda humas tidak berada pada status terjadwal dan perlu dipastikan progresnya.`,
        badge: 'Humas',
      },
    ];

    const crossModuleInsights = [
      {
        title: 'Absensi + Kesiswaan',
        value: `${totalStudents <= 0 ? 0 : Math.round((izinAlfa / totalStudents) * 100)}%`,
        note: `${izinAlfa} catatan izin/alfa dibanding ${totalStudents} siswa perlu dijadikan fokus pembinaan.`,
      },
      {
        title: 'Jurnal + Kurikulum',
        value: `${curriculums.length <= 0 ? 0 : Math.min(100, Math.round((journals.length / curriculums.length) * 100))}%`,
        note: 'Sinkronisasi jurnal terhadap materi menunjukkan konsistensi dokumentasi pembelajaran lintas modul.',
      },
      {
        title: 'Sarpras + Humas',
        value: `${sarprasRusak + humasTerjadwal}`,
        note: 'Gabungan kebutuhan sarpras rusak dan agenda humas terjadwal membantu membaca kesiapan operasional sekolah.',
      },
      {
        title: 'Kelas + Jurnal',
        value: `${totalKelasJurnal}`,
        note: 'Jumlah kelas yang tercatat di jurnal dibanding sebaran siswa membantu kepala sekolah membaca cakupan pengawasan.',
      },
    ];

    res.json({
      comparisonInsights,
      executiveSnapshots,
      priorityInsights,
      crossModuleInsights,
    });
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat ringkasan kepsek', error: err.message });
  }
});

router.post('/curriculums', async (req, res) => {
  try {
    await ensureCurriculumsTable();
    const payload = normalizeCurriculumPayload(req.body);

    if (!payload.subject || !payload.code || !payload.major || !payload.grade || !payload.teacher) {
      return res.status(400).json({
        message: 'Mata pelajaran, kode, jurusan, kelas, dan guru pengampu wajib diisi',
      });
    }

    const [duplicateRows] = await pool.query(
      `
        SELECT id
        FROM curriculums
        WHERE code = ? AND major = ? AND grade = ?
        LIMIT 1
      `,
      [payload.code, payload.major, payload.grade],
    );
    if (duplicateRows.length > 0) {
      return res.status(409).json({ message: 'Kombinasi kode, jurusan, dan kelas sudah ada' });
    }

    const [result] = await pool.query(
      `
        INSERT INTO curriculums (subject, code, major, grade, teacher, status, school_year)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `,
      [
        payload.subject,
        payload.code,
        payload.major,
        payload.grade,
        payload.teacher,
        payload.status,
        payload.schoolYear,
      ],
    );

    const created = await findCurriculumById(result.insertId);
    res.status(201).json(created);
  } catch (err) {
    res.status(500).json({ message: 'Gagal menambah kurikulum', error: err.message });
  }
});

router.put('/curriculums/:id', async (req, res) => {
  try {
    await ensureCurriculumsTable();
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ message: 'ID kurikulum tidak valid' });
    }

    const payload = normalizeCurriculumPayload(req.body);
    if (!payload.subject || !payload.code || !payload.major || !payload.grade || !payload.teacher) {
      return res.status(400).json({
        message: 'Mata pelajaran, kode, jurusan, kelas, dan guru pengampu wajib diisi',
      });
    }

    const [duplicateRows] = await pool.query(
      `
        SELECT id
        FROM curriculums
        WHERE code = ? AND major = ? AND grade = ? AND id <> ?
        LIMIT 1
      `,
      [payload.code, payload.major, payload.grade, id],
    );
    if (duplicateRows.length > 0) {
      return res.status(409).json({ message: 'Kombinasi kode, jurusan, dan kelas sudah ada' });
    }

    const [result] = await pool.query(
      `
        UPDATE curriculums
        SET subject = ?, code = ?, major = ?, grade = ?, teacher = ?, status = ?, school_year = ?
        WHERE id = ?
      `,
      [
        payload.subject,
        payload.code,
        payload.major,
        payload.grade,
        payload.teacher,
        payload.status,
        payload.schoolYear,
        id,
      ],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Data kurikulum tidak ditemukan' });
    }

    const updated = await findCurriculumById(id);
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: 'Gagal mengubah kurikulum', error: err.message });
  }
});

router.delete('/curriculums/:id', async (req, res) => {
  try {
    await ensureCurriculumsTable();
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      return res.status(400).json({ message: 'ID kurikulum tidak valid' });
    }

    const [result] = await pool.query('DELETE FROM curriculums WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Data kurikulum tidak ditemukan' });
    }

    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ message: 'Gagal menghapus kurikulum', error: err.message });
  }
});

router.post('/activities', async (req, res) => {
  try {
    await ensureActivitiesTable();
    const title = `${req.body?.title ?? ''}`.trim();
    const actor = `${req.body?.actor ?? ''}`.trim();
    const type = `${req.body?.type ?? 'general'}`.trim() || 'general';

    if (!title || !actor) {
      return res.status(400).json({ message: 'Judul dan aktor wajib diisi' });
    }

    const [result] = await pool.query(
      `
        INSERT INTO activity_logs (title, actor, type)
        VALUES (?, ?, ?)
      `,
      [title, actor, type],
    );

    const [rows] = await pool.query(
      `
        SELECT id, title, actor, type, created_at
        FROM activity_logs
        WHERE id = ?
        LIMIT 1
      `,
      [result.insertId],
    );

    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ message: 'Gagal menyimpan aktivitas', error: err.message });
  }
});

module.exports = router;
