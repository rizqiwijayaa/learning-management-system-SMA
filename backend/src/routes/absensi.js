const express = require('express');
const { pool } = require('../db');
const { backfillTeacherOwnership } = require('./teacherOwnership');

const router = express.Router();

const INDONESIAN_MONTHS = {
  januari: 1,
  februari: 2,
  maret: 3,
  april: 4,
  mei: 5,
  juni: 6,
  juli: 7,
  agustus: 8,
  september: 9,
  oktober: 10,
  november: 11,
  desember: 12,
};

function normalizeText(value) {
  return String(value || '').trim();
}

function initialFromName(name) {
  const parts = normalizeText(name)
    .split(/\s+/)
    .filter(Boolean);
  if (!parts.length) return 'S';
  return parts
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join('');
}

function parseMonthLabel(monthLabel) {
  const raw = normalizeText(monthLabel);
  const match = raw.match(/^([A-Za-zÀ-ÿ]+)\s+(\d{4})$/);
  if (!match) return null;
  const month = INDONESIAN_MONTHS[match[1].toLowerCase()];
  const year = Number(match[2]);
  if (!month || !year) return null;
  return {
    month,
    monthName: match[1],
    year,
  };
}

function createDateLabel(dayOrder, monthLabel) {
  const parsed = parseMonthLabel(monthLabel);
  if (!parsed) return `Pertemuan ${dayOrder}`;
  const maxDay = new Date(parsed.year, parsed.month, 0).getDate();
  if (dayOrder > maxDay) {
    return `Pertemuan ${dayOrder} - ${parsed.monthName} ${parsed.year}`;
  }
  return `${dayOrder} ${parsed.monthName} ${parsed.year}`;
}

function createDateValue(dayOrder, monthLabel) {
  const parsed = parseMonthLabel(monthLabel);
  if (!parsed) return null;
  const maxDay = new Date(parsed.year, parsed.month, 0).getDate();
  if (dayOrder > maxDay) return null;
  const month = String(parsed.month).padStart(2, '0');
  const day = String(Math.max(1, dayOrder)).padStart(2, '0');
  return `${parsed.year}-${month}-${day}`;
}

function seededStatus(dayOrder, presentDays, izinDays, alfaDays) {
  if (dayOrder <= presentDays) return 'hadir';
  if (dayOrder <= presentDays + izinDays) return 'izin';
  if (dayOrder <= presentDays + izinDays + alfaDays) return 'alfa';
  return 'hadir';
}

async function ensureAttendanceTable() {
  await pool.query(`
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
    )
  `);

  const [columns] = await pool.query('SHOW COLUMNS FROM attendance_records');
  const names = new Set(columns.map((column) => String(column.Field || '').toLowerCase()));
  if (!names.has('teacher_id')) {
    await pool.query('ALTER TABLE attendance_records ADD COLUMN teacher_id INT NULL AFTER id');
  }
  if (!names.has('teacher_nip')) {
    await pool.query(
      'ALTER TABLE attendance_records ADD COLUMN teacher_nip VARCHAR(50) NULL AFTER teacher_id',
    );
  }
  if (!names.has('teacher_name')) {
    await pool.query(
      'ALTER TABLE attendance_records ADD COLUMN teacher_name VARCHAR(120) NULL AFTER teacher_nip',
    );
  }
  await backfillTeacherOwnership({
    tableName: 'attendance_records',
    classColumn: 'class_name',
  });

  const [rows] = await pool.query('SELECT COUNT(*) AS total FROM attendance_records');
  if (Number(rows[0]?.total || 0) > 0) return;

  await pool.query(
    `
      INSERT INTO attendance_records (
        student_name, class_name, month_label, present_days, izin_days, alfa_days, accent_color, initial
      )
      VALUES
        ('Dewi Santosa', 'X IPA 1', 'Maret 2026', 18, 3, 1, '#F7D6F8', 'D'),
        ('Hadi Wijaya', 'X IPA 1', 'Maret 2026', 26, 1, 0, '#D6E6FF', 'H'),
        ('Siti Lestari', 'X IPA 1', 'Maret 2026', 26, 3, 1, '#E6D6FF', 'S'),
        ('Ahmad Fauzi', 'X IPA 1', 'Maret 2026', 21, 3, 1, '#D5E5FF', 'A'),
        ('Rina Putri', 'X IPA 1', 'Maret 2026', 21, 1, 0, '#D4F2EC', 'R')
    `,
  );
}

async function ensureDailyAttendanceTable() {
  await pool.query(`
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
    )
  `);
}

async function seedDailyAttendanceForRecord(record) {
  const totalDays =
    Number(record.present_days || 0) +
    Number(record.izin_days || 0) +
    Number(record.alfa_days || 0);

  if (totalDays <= 0) return;

  const values = [];
  for (let dayOrder = 1; dayOrder <= totalDays; dayOrder += 1) {
    values.push([
      record.id,
      record.teacher_id || null,
      normalizeText(record.teacher_nip),
      normalizeText(record.teacher_name),
      normalizeText(record.student_name),
      normalizeText(record.class_name),
      normalizeText(record.month_label),
      createDateLabel(dayOrder, record.month_label),
      dayOrder,
      createDateValue(dayOrder, record.month_label),
      seededStatus(dayOrder, record.present_days, record.izin_days, record.alfa_days),
      '',
      normalizeText(record.accent_color) || '#D6E6FF',
      normalizeText(record.initial) || initialFromName(record.student_name),
    ]);
  }

  await pool.query(
    `
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
      ) VALUES ?
      ON DUPLICATE KEY UPDATE
        teacher_id = VALUES(teacher_id),
        teacher_nip = VALUES(teacher_nip),
        teacher_name = VALUES(teacher_name),
        student_name = VALUES(student_name),
        class_name = VALUES(class_name),
        month_label = VALUES(month_label),
        date_label = VALUES(date_label),
        date_value = VALUES(date_value),
        accent_color = VALUES(accent_color),
        initial = VALUES(initial)
    `,
    [values],
  );
}

async function ensureDailyAttendanceSeed() {
  const [records] = await pool.query(`
    SELECT
      id,
      teacher_id,
      teacher_nip,
      teacher_name,
      student_name,
      class_name,
      month_label,
      present_days,
      izin_days,
      alfa_days,
      accent_color,
      initial
    FROM attendance_records
  `);

  for (const record of records) {
    const [existing] = await pool.query(
      'SELECT COUNT(*) AS total FROM attendance_daily_records WHERE attendance_record_id = ?',
      [record.id],
    );
    if (Number(existing[0]?.total || 0) > 0) continue;
    await seedDailyAttendanceForRecord(record);
  }
}

async function ensureAttendanceReady() {
  await ensureAttendanceTable();
  await ensureDailyAttendanceTable();
  await ensureDailyAttendanceSeed();
}

async function getAttendanceRecordById(id) {
  const [rows] = await pool.query(
    `
      SELECT
        id,
        teacher_id,
        teacher_nip,
        teacher_name,
        student_name,
        class_name,
        month_label,
        present_days,
        izin_days,
        alfa_days,
        accent_color,
        initial
      FROM attendance_records
      WHERE id = ?
      LIMIT 1
    `,
    [id],
  );
  return rows[0] || null;
}

async function syncAttendanceSummary(attendanceRecordId) {
  const [summaryRows] = await pool.query(
    `
      SELECT
        COUNT(CASE WHEN status = 'hadir' THEN 1 END) AS present_days,
        COUNT(CASE WHEN status = 'izin' THEN 1 END) AS izin_days,
        COUNT(CASE WHEN status = 'alfa' THEN 1 END) AS alfa_days
      FROM attendance_daily_records
      WHERE attendance_record_id = ?
    `,
    [attendanceRecordId],
  );

  const counts = summaryRows[0] || {};
  await pool.query(
    `
      UPDATE attendance_records
      SET
        present_days = ?,
        izin_days = ?,
        alfa_days = ?
      WHERE id = ?
    `,
    [
      Number(counts.present_days || 0),
      Number(counts.izin_days || 0),
      Number(counts.alfa_days || 0),
      attendanceRecordId,
    ],
  );

  return getAttendanceRecordById(attendanceRecordId);
}

async function resolveAttendanceRecordId({
  attendanceRecordId,
  studentName,
  className,
  monthLabel,
}) {
  if (attendanceRecordId) return attendanceRecordId;

  const [rows] = await pool.query(
    `
      SELECT id
      FROM attendance_records
      WHERE student_name = ? AND class_name = ? AND month_label = ?
      LIMIT 1
    `,
    [studentName, className, monthLabel],
  );

  return rows[0]?.id ? Number(rows[0].id) : null;
}

router.get('/', async (req, res) => {
  const className = normalizeText(req.query.className);
  const month = normalizeText(req.query.month);
  const teacherId = Number(req.query.teacherId || 0);
  const teacherNip = normalizeText(req.query.teacherNip);
  const teacherName = normalizeText(req.query.teacherName);

  try {
    await ensureAttendanceReady();
    let sql = `
      SELECT
        id,
        teacher_id,
        teacher_nip,
        teacher_name,
        student_name,
        class_name,
        month_label,
        present_days,
        izin_days,
        alfa_days,
        accent_color,
        initial
      FROM attendance_records
    `;
    const params = [];
    const clauses = [];

    if (className) {
      clauses.push('class_name = ?');
      params.push(className);
    }
    if (month) {
      clauses.push('month_label = ?');
      params.push(month);
    }
    if (teacherId > 0) {
      clauses.push('teacher_id = ?');
      params.push(teacherId);
    }
    if (teacherNip) {
      clauses.push('teacher_nip = ?');
      params.push(teacherNip);
    }
    if (teacherName) {
      clauses.push('teacher_name = ?');
      params.push(teacherName);
    }
    if (clauses.length > 0) {
      sql += ` WHERE ${clauses.join(' AND ')}`;
    }
    sql += ' ORDER BY student_name ASC';

    const [rows] = await pool.query(sql, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat data absensi', error: err.message });
  }
});

router.get('/daily', async (req, res) => {
  const attendanceRecordId = Number(req.query.attendanceRecordId || 0);
  const studentName = normalizeText(req.query.studentName);
  const className = normalizeText(req.query.className);
  const month = normalizeText(req.query.month);

  try {
    await ensureAttendanceReady();

    let sql = `
      SELECT
        id,
        attendance_record_id,
        teacher_id,
        teacher_nip,
        teacher_name,
        student_name,
        class_name,
        month_label,
        date_label,
        day_order,
        status,
        note,
        accent_color,
        initial
      FROM attendance_daily_records
    `;
    const params = [];
    const clauses = [];

    if (attendanceRecordId > 0) {
      clauses.push('attendance_record_id = ?');
      params.push(attendanceRecordId);
    }
    if (studentName) {
      clauses.push('student_name = ?');
      params.push(studentName);
    }
    if (className) {
      clauses.push('class_name = ?');
      params.push(className);
    }
    if (month) {
      clauses.push('month_label = ?');
      params.push(month);
    }
    if (clauses.length > 0) {
      sql += ` WHERE ${clauses.join(' AND ')}`;
    }
    sql += ' ORDER BY day_order ASC, id ASC';

    const [rows] = await pool.query(sql, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({
      message: 'Gagal memuat absensi harian',
      error: err.message,
    });
  }
});

router.post('/daily', async (req, res) => {
  const attendanceRecordId = Number(req.body.attendanceRecordId || req.body.attendance_record_id || 0);
  const studentName = normalizeText(req.body.studentName || req.body.student_name);
  const className = normalizeText(req.body.className || req.body.class_name);
  const monthLabel = normalizeText(req.body.monthLabel || req.body.month_label);
  const dateLabel = normalizeText(req.body.dateLabel || req.body.date_label);
  const dayOrder = Number(req.body.dayOrder || req.body.day_order || 0);
  const note = normalizeText(req.body.note);
  const status = normalizeText(req.body.status).toLowerCase();

  try {
    await ensureAttendanceReady();

    const resolvedAttendanceRecordId = await resolveAttendanceRecordId({
      attendanceRecordId,
      studentName,
      className,
      monthLabel,
    });

    if (!resolvedAttendanceRecordId) {
      return res.status(400).json({ message: 'Data rekap absensi tidak ditemukan' });
    }

    const parent = await getAttendanceRecordById(resolvedAttendanceRecordId);
    if (!parent) {
      return res.status(404).json({ message: 'Rekap absensi tidak ditemukan' });
    }

    if (!['hadir', 'izin', 'alfa'].includes(status)) {
      return res.status(400).json({ message: 'Status absensi tidak valid' });
    }

    const safeDayOrder = dayOrder > 0 ? dayOrder : 1;
    const safeDateLabel = dateLabel || createDateLabel(safeDayOrder, parent.month_label);

    const [result] = await pool.query(
      `
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
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      [
        resolvedAttendanceRecordId,
        parent.teacher_id || null,
        normalizeText(parent.teacher_nip),
        normalizeText(parent.teacher_name),
        normalizeText(parent.student_name),
        normalizeText(parent.class_name),
        normalizeText(parent.month_label),
        safeDateLabel,
        safeDayOrder,
        createDateValue(safeDayOrder, parent.month_label),
        status,
        note,
        normalizeText(parent.accent_color) || '#D6E6FF',
        normalizeText(parent.initial) || initialFromName(parent.student_name),
      ],
    );

    const [rows] = await pool.query(
      'SELECT * FROM attendance_daily_records WHERE id = ? LIMIT 1',
      [result.insertId],
    );
    const summary = await syncAttendanceSummary(resolvedAttendanceRecordId);
    res.status(201).json({
      record: rows[0],
      summary,
    });
  } catch (err) {
    const duplicate = String(err.message || '').includes('attendance_daily_unique');
    res.status(duplicate ? 409 : 500).json({
      message: duplicate
          ? 'Hari absensi tersebut sudah ada'
          : 'Gagal menambah absensi harian',
      error: err.message,
    });
  }
});

router.put('/daily/:id', async (req, res) => {
  const id = Number(req.params.id || 0);
  const dateLabel = normalizeText(req.body.dateLabel || req.body.date_label);
  const dayOrder = Number(req.body.dayOrder || req.body.day_order || 0);
  const note = normalizeText(req.body.note);
  const status = normalizeText(req.body.status).toLowerCase();

  try {
    await ensureAttendanceReady();

    const [existingRows] = await pool.query(
      'SELECT * FROM attendance_daily_records WHERE id = ? LIMIT 1',
      [id],
    );
    const existing = existingRows[0];
    if (!existing) {
      return res.status(404).json({ message: 'Absensi harian tidak ditemukan' });
    }
    if (!['hadir', 'izin', 'alfa'].includes(status)) {
      return res.status(400).json({ message: 'Status absensi tidak valid' });
    }

    const nextDayOrder = dayOrder > 0 ? dayOrder : Number(existing.day_order || 1);
    const nextDateLabel =
      dateLabel || createDateLabel(nextDayOrder, existing.month_label);

    await pool.query(
      `
        UPDATE attendance_daily_records
        SET
          date_label = ?,
          day_order = ?,
          date_value = ?,
          status = ?,
          note = ?
        WHERE id = ?
      `,
      [
        nextDateLabel,
        nextDayOrder,
        createDateValue(nextDayOrder, existing.month_label),
        status,
        note,
        id,
      ],
    );

    const [rows] = await pool.query(
      'SELECT * FROM attendance_daily_records WHERE id = ? LIMIT 1',
      [id],
    );
    const summary = await syncAttendanceSummary(existing.attendance_record_id);
    res.json({
      record: rows[0],
      summary,
    });
  } catch (err) {
    const duplicate = String(err.message || '').includes('attendance_daily_unique');
    res.status(duplicate ? 409 : 500).json({
      message: duplicate
          ? 'Hari absensi tersebut sudah ada'
          : 'Gagal mengubah absensi harian',
      error: err.message,
    });
  }
});

router.delete('/daily/:id', async (req, res) => {
  const id = Number(req.params.id || 0);

  try {
    await ensureAttendanceReady();

    const [existingRows] = await pool.query(
      'SELECT * FROM attendance_daily_records WHERE id = ? LIMIT 1',
      [id],
    );
    const existing = existingRows[0];
    if (!existing) {
      return res.status(404).json({ message: 'Absensi harian tidak ditemukan' });
    }

    await pool.query('DELETE FROM attendance_daily_records WHERE id = ?', [id]);
    const summary = await syncAttendanceSummary(existing.attendance_record_id);
    res.json({
      record: null,
      summary,
    });
  } catch (err) {
    res.status(500).json({
      message: 'Gagal menghapus absensi harian',
      error: err.message,
    });
  }
});

module.exports = router;
