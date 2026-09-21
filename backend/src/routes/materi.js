const express = require('express');
const { pool } = require('../db');
const { backfillTeacherOwnership } = require('./teacherOwnership');

const router = express.Router();

const selectFields = `
  id, teacher_id, teacher_nip, teacher_name, title, subject, upload_date,
  description, content, attachments_json
`;

async function ensureAttachmentColumn() {
  const [columns] = await pool.query('SHOW COLUMNS FROM materi');
  const names = new Set(columns.map((column) => String(column.Field || '').toLowerCase()));
  if (!names.has('attachments_json')) {
    await pool.query('ALTER TABLE materi ADD COLUMN attachments_json LONGTEXT NULL');
  }
  if (!names.has('teacher_id')) {
    await pool.query('ALTER TABLE materi ADD COLUMN teacher_id INT NULL');
  }
  if (!names.has('teacher_nip')) {
    await pool.query('ALTER TABLE materi ADD COLUMN teacher_nip VARCHAR(50) NULL');
  }
  if (!names.has('teacher_name')) {
    await pool.query('ALTER TABLE materi ADD COLUMN teacher_name VARCHAR(120) NULL');
  }
  await backfillTeacherOwnership({
    tableName: 'materi',
    subjectColumn: 'subject',
  });
}

router.get('/', async (req, res) => {
  try {
    await ensureAttachmentColumn();
    const teacherId = Number(req.query.teacherId || 0);
    const teacherNip = (req.query.teacherNip || '').toString().trim();
    const teacherName = (req.query.teacherName || '').toString().trim();
    const clauses = [];
    const params = [];

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
      `SELECT ${selectFields} FROM materi ${clauses.length ? `WHERE ${clauses.join(' AND ')}` : ''} ORDER BY id DESC`,
      params,
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat materi', error: err.message });
  }
});

router.post('/', async (req, res) => {
  const {
    teacher_id,
    teacher_nip,
    teacher_name,
    title,
    subject,
    upload_date,
    description,
    content,
    attachments_json,
  } = req.body;
  if (!title || !subject || !upload_date) {
    return res.status(400).json({ message: 'title, subject, upload_date wajib diisi' });
  }
  try {
    await ensureAttachmentColumn();
    const [result] = await pool.query(
      `INSERT INTO materi (
        teacher_id, teacher_nip, teacher_name, title, subject, upload_date,
        description, content, attachments_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        Number.isInteger(teacher_id) ? teacher_id : Number(teacher_id || 0) || null,
        teacher_nip || '',
        teacher_name || '',
        title,
        subject,
        upload_date,
        description || '',
        content || '',
        JSON.stringify(attachments_json || []),
      ],
    );
    const [rows] = await pool.query(
      `SELECT ${selectFields} FROM materi WHERE id = ?`,
      [result.insertId],
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ message: 'Gagal tambah materi', error: err.message });
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
    upload_date,
    description,
    content,
    attachments_json,
  } = req.body;
  if (!id) return res.status(400).json({ message: 'ID tidak valid' });
  if (!title || !subject || !upload_date) {
    return res.status(400).json({ message: 'title, subject, upload_date wajib diisi' });
  }
  try {
    await ensureAttachmentColumn();
    await pool.query(
      `UPDATE materi
       SET teacher_id = ?, teacher_nip = ?, teacher_name = ?, title = ?, subject = ?,
           upload_date = ?, description = ?, content = ?, attachments_json = ?
       WHERE id = ?`,
      [
        Number.isInteger(teacher_id) ? teacher_id : Number(teacher_id || 0) || null,
        teacher_nip || '',
        teacher_name || '',
        title,
        subject,
        upload_date,
        description || '',
        content || '',
        JSON.stringify(attachments_json || []),
        id,
      ],
    );
    const [rows] = await pool.query(
      `SELECT ${selectFields} FROM materi WHERE id = ?`,
      [id],
    );
    if (!rows.length) return res.status(404).json({ message: 'Materi tidak ditemukan' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ message: 'Gagal update materi', error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ message: 'ID tidak valid' });

  try {
    const [result] = await pool.query('DELETE FROM materi WHERE id = ?', [id]);
    if (!result.affectedRows) {
      return res.status(404).json({ message: 'Materi tidak ditemukan' });
    }
    res.json({ ok: true, id });
  } catch (err) {
    res.status(500).json({ message: 'Gagal hapus materi', error: err.message });
  }
});

module.exports = router;
