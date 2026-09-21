const express = require('express');
const { pool } = require('../db');
const { backfillTeacherOwnership } = require('./teacherOwnership');

const router = express.Router();

const selectFields = `
  id, teacher_id, teacher_nip, teacher_name, title, subject, date, type,
  description, attachment_name, attachment_data, attachment_mime, duration_minutes
`;

async function ensureAttachmentColumns() {
  const [columns] = await pool.query('SHOW COLUMNS FROM tugas_ujian');
  const names = new Set(columns.map((column) => String(column.Field || '').toLowerCase()));

  if (!names.has('attachment_data')) {
    await pool.query('ALTER TABLE tugas_ujian ADD COLUMN attachment_data LONGTEXT NULL');
  }

  if (!names.has('attachment_mime')) {
    await pool.query(
      'ALTER TABLE tugas_ujian ADD COLUMN attachment_mime VARCHAR(255) NULL',
    );
  }
  if (!names.has('teacher_id')) {
    await pool.query('ALTER TABLE tugas_ujian ADD COLUMN teacher_id INT NULL');
  }
  if (!names.has('teacher_nip')) {
    await pool.query('ALTER TABLE tugas_ujian ADD COLUMN teacher_nip VARCHAR(50) NULL');
  }
  if (!names.has('teacher_name')) {
    await pool.query('ALTER TABLE tugas_ujian ADD COLUMN teacher_name VARCHAR(120) NULL');
  }
  await backfillTeacherOwnership({
    tableName: 'tugas_ujian',
    subjectColumn: 'subject',
  });
}

router.get('/', async (req, res) => {
  const type = (req.query.type || 'tugas').toString().toLowerCase();
  const teacherId = Number(req.query.teacherId || 0);
  const teacherNip = (req.query.teacherNip || '').toString().trim();
  const teacherName = (req.query.teacherName || '').toString().trim();
  if (!['tugas', 'ujian'].includes(type)) {
    return res.status(400).json({ message: 'type harus tugas atau ujian' });
  }

  try {
    await ensureAttachmentColumns();
    const clauses = ['type = ?'];
    const params = [type];
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
    const [rows] = await pool.query(
       `SELECT ${selectFields}
        FROM tugas_ujian
       WHERE ${clauses.join(' AND ')}
        ORDER BY id DESC`,
      params,
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat data tugas/ujian', error: err.message });
  }
});

router.post('/', async (req, res) => {
  const {
    teacher_id,
    teacher_nip,
    teacher_name,
    title,
    subject,
    date,
    type,
    description,
    attachment_name,
    attachment_data,
    attachment_mime,
    duration_minutes,
  } = req.body;
  if (!title || !subject || !date || !type) {
    return res.status(400).json({ message: 'title, subject, date, type wajib diisi' });
  }
  if (!['tugas', 'ujian'].includes(type)) {
    return res.status(400).json({ message: 'type harus tugas atau ujian' });
  }

  try {
    await ensureAttachmentColumns();
    const [result] = await pool.query(
      `INSERT INTO tugas_ujian (
         teacher_id, teacher_nip, teacher_name, title, subject, date, type,
         description, attachment_name, attachment_data, attachment_mime, duration_minutes
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        Number.isInteger(teacher_id) ? teacher_id : Number(teacher_id || 0) || null,
        teacher_nip || '',
        teacher_name || '',
        title,
        subject,
        date,
        type,
        description || '',
        attachment_name || '',
        attachment_data || '',
        attachment_mime || '',
        duration_minutes ?? null,
      ],
    );
    const [rows] = await pool.query(
      `SELECT ${selectFields} FROM tugas_ujian WHERE id = ?`,
      [result.insertId],
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ message: 'Gagal tambah data tugas/ujian', error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  const id = Number(req.params.id);
  const {
    teacher_id,
    teacher_nip,
    teacher_name,
    title,
    subject,
    date,
    type,
    description,
    attachment_name,
    attachment_data,
    attachment_mime,
    duration_minutes,
  } = req.body;
  if (!id) return res.status(400).json({ message: 'ID tidak valid' });
  if (!title || !subject || !date || !type) {
    return res.status(400).json({ message: 'title, subject, date, type wajib diisi' });
  }
  if (!['tugas', 'ujian'].includes(type)) {
    return res.status(400).json({ message: 'type harus tugas atau ujian' });
  }

  try {
    await ensureAttachmentColumns();
    await pool.query(
      `UPDATE tugas_ujian
       SET teacher_id = ?, teacher_nip = ?, teacher_name = ?, title = ?, subject = ?,
           date = ?, type = ?, description = ?,
            attachment_name = ?, attachment_data = ?, attachment_mime = ?,
            duration_minutes = ?
       WHERE id = ?`,
      [
        Number.isInteger(teacher_id) ? teacher_id : Number(teacher_id || 0) || null,
        teacher_nip || '',
        teacher_name || '',
        title,
        subject,
        date,
        type,
        description || '',
        attachment_name || '',
        attachment_data || '',
        attachment_mime || '',
        duration_minutes ?? null,
        id,
      ],
    );
    const [rows] = await pool.query(
      `SELECT ${selectFields} FROM tugas_ujian WHERE id = ?`,
      [id],
    );
    if (!rows.length) return res.status(404).json({ message: 'Data tidak ditemukan' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ message: 'Gagal update data tugas/ujian', error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ message: 'ID tidak valid' });

  try {
    const [result] = await pool.query('DELETE FROM tugas_ujian WHERE id = ?', [id]);
    if (!result.affectedRows) {
      return res.status(404).json({ message: 'Data tidak ditemukan' });
    }
    res.json({ ok: true, id });
  } catch (err) {
    res.status(500).json({ message: 'Gagal hapus data tugas/ujian', error: err.message });
  }
});

module.exports = router;
