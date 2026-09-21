const express = require('express');
const { pool } = require('../db');
const { backfillTeacherOwnership } = require('./teacherOwnership');

const router = express.Router();

async function ensureGradesTable() {
  await pool.query(`
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
    )
  `);

  const [columns] = await pool.query('SHOW COLUMNS FROM student_grades');
  const names = new Set(columns.map((column) => String(column.Field || '').toLowerCase()));
  if (!names.has('teacher_id')) {
    await pool.query('ALTER TABLE student_grades ADD COLUMN teacher_id INT NULL AFTER id');
  }
  if (!names.has('teacher_nip')) {
    await pool.query(
      'ALTER TABLE student_grades ADD COLUMN teacher_nip VARCHAR(50) NULL AFTER teacher_id',
    );
  }
  if (!names.has('teacher_name')) {
    await pool.query(
      'ALTER TABLE student_grades ADD COLUMN teacher_name VARCHAR(120) NULL AFTER teacher_nip',
    );
  }
  await backfillTeacherOwnership({
    tableName: 'student_grades',
    subjectColumn: 'subject',
    classColumn: 'class_name',
  });

  const [rows] = await pool.query('SELECT COUNT(*) AS total FROM student_grades');
  if (Number(rows[0]?.total || 0) > 0) return;

  await pool.query(
    `
      INSERT INTO student_grades (student_name, subject, class_name, score)
      VALUES
        ('Dewi Santosa', 'Matematika', 'X IPA 1', 85),
        ('Hadi Wijaya', 'Matematika', 'X IPA 1', 70),
        ('Siti Lestari', 'Matematika', 'X IPA 1', 60),
        ('Ahmad Fauzi', 'Matematika', 'X IPA 1', 92),
        ('Nadia Putri', 'Matematika', 'X IPA 1', 78),
        ('Rian Saputra', 'Bahasa Inggris', 'X IPA 1', 88),
        ('Citra Lestari', 'Bahasa Inggris', 'X IPA 2', 73),
        ('Bagas Pratama', 'IPA', 'X IPA 2', 66),
        ('Salma Azzahra', 'IPA', 'X IPA 1', 94)
    `,
  );
}

router.get('/', async (req, res) => {
  const subject = (req.query.subject || '').toString().trim();
  const className = (req.query.className || '').toString().trim();
  const teacherId = Number(req.query.teacherId || 0);
  const teacherNip = (req.query.teacherNip || '').toString().trim();
  const teacherName = (req.query.teacherName || '').toString().trim();

  try {
    await ensureGradesTable();
    let sql = `
      SELECT id, teacher_id, teacher_nip, teacher_name, student_name, subject, class_name, score
      FROM student_grades
    `;
    const params = [];
    const clauses = [];

    if (subject) {
      clauses.push('subject = ?');
      params.push(subject);
    }
    if (className) {
      clauses.push('class_name = ?');
      params.push(className);
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
    res.status(500).json({ message: 'Gagal memuat data nilai', error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  const id = Number(req.params.id);
  const { teacher_id, teacher_nip, teacher_name, student_name, subject, class_name, score } = req.body ?? {};

  if (!id) return res.status(400).json({ message: 'ID nilai tidak valid' });
  if (!student_name || !subject || !class_name) {
    return res.status(400).json({ message: 'student_name, subject, class_name wajib diisi' });
  }
  if (!Number.isInteger(score) || score < 0 || score > 100) {
    return res.status(400).json({ message: 'score harus angka 0 sampai 100' });
  }

  try {
    await ensureGradesTable();
    await pool.query(
      `
        UPDATE student_grades
        SET teacher_id = ?, teacher_nip = ?, teacher_name = ?, student_name = ?,
            subject = ?, class_name = ?, score = ?
        WHERE id = ?
      `,
      [
        Number.isInteger(teacher_id) ? teacher_id : Number(teacher_id || 0) || null,
        teacher_nip || '',
        teacher_name || '',
        student_name,
        subject,
        class_name,
        score,
        id,
      ],
    );
    const [rows] = await pool.query(
      `
        SELECT id, teacher_id, teacher_nip, teacher_name, student_name, subject, class_name, score
        FROM student_grades
        WHERE id = ?
      `,
      [id],
    );
    if (!rows.length) {
      return res.status(404).json({ message: 'Data nilai tidak ditemukan' });
    }
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ message: 'Gagal menyimpan data nilai', error: err.message });
  }
});

module.exports = router;
