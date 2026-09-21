const express = require('express');
const { pool } = require('../db');
const { backfillTeacherOwnership } = require('./teacherOwnership');

const router = express.Router();

let journalTableReady = false;

async function ensureJournalTable() {
  if (journalTableReady) return;

  await pool.query(`
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
    )
  `);

  const [columns] = await pool.query('SHOW COLUMNS FROM journal_entries');
  const names = new Set(columns.map((column) => String(column.Field || '').toLowerCase()));
  if (!names.has('teacher_id')) {
    await pool.query('ALTER TABLE journal_entries ADD COLUMN teacher_id INT NULL AFTER id');
  }
  if (!names.has('teacher_nip')) {
    await pool.query(
      'ALTER TABLE journal_entries ADD COLUMN teacher_nip VARCHAR(50) NULL AFTER teacher_id',
    );
  }
  if (!names.has('teacher_name')) {
    await pool.query(
      'ALTER TABLE journal_entries ADD COLUMN teacher_name VARCHAR(120) NULL AFTER teacher_nip',
    );
  }
  await backfillTeacherOwnership({
    tableName: 'journal_entries',
    subjectColumn: 'subject',
    classColumn: 'class_name',
  });

  await pool.query(`
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
    LIMIT 1
  `);

  await pool.query(`
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
    LIMIT 1
  `);

  await pool.query(`
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
    LIMIT 1
  `);

  journalTableReady = true;
}

router.get('/', async (req, res) => {
  const { className, subject, dateLabel } = req.query;
  const teacherId = Number(req.query.teacherId || 0);
  const teacherNip = (req.query.teacherNip || '').toString().trim();
  const teacherName = (req.query.teacherName || '').toString().trim();
  const where = [];
  const params = [];

  if (className) {
    where.push('class_name = ?');
    params.push(className);
  }
  if (subject) {
    where.push('subject = ?');
    params.push(subject);
  }
  if (dateLabel) {
    where.push('date_label = ?');
    params.push(dateLabel);
  }
  if (teacherId > 0) {
    where.push('teacher_id = ?');
    params.push(teacherId);
  }
  if (teacherNip) {
    where.push('teacher_nip = ?');
    params.push(teacherNip);
  }
  if (teacherName) {
    where.push('teacher_name = ?');
    params.push(teacherName);
  }

  const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';

  try {
    await ensureJournalTable();
    const [rows] = await pool.query(
      `SELECT id, teacher_id, teacher_nip, teacher_name, date_label, subject, title, material_summary, class_name, attendance_count, accent_color, learning_points, summary_paragraphs, progress_title, progress_note, task_title, task_deadline, image_base64
       FROM journal_entries
       ${whereSql}
       ORDER BY id DESC`,
      params,
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat jurnal', error: err.message });
  }
});

router.get('/summary', async (_req, res) => {
  try {
    await ensureJournalTable();

    const [[journalSummary]] = await pool.query(`
      SELECT
        COUNT(*) AS totalJurnal,
        ROUND(COALESCE(AVG(attendance_count), 0)) AS avgAttendance,
        COUNT(DISTINCT NULLIF(TRIM(class_name), '')) AS totalClasses,
        COUNT(DISTINCT NULLIF(TRIM(subject), '')) AS totalSubjects
      FROM journal_entries
    `);

    const [[materialSummary]] = await pool.query(`
      SELECT COUNT(*) AS totalMateri
      FROM materi
    `);

    const totalJurnal = Number(journalSummary?.totalJurnal || 0);
    const avgAttendance = Number(journalSummary?.avgAttendance || 0);
    const totalClasses = Number(journalSummary?.totalClasses || 0);
    const totalSubjects = Number(journalSummary?.totalSubjects || 0);
    const totalMateri = Number(materialSummary?.totalMateri || 0);
    const syncMaterialPercentage = totalMateri <= 0
      ? 0
      : Math.min(100, Math.round((totalJurnal / totalMateri) * 100));

    res.json({
      totalJurnal,
      avgAttendance,
      totalClasses,
      totalSubjects,
      totalMateri,
      syncMaterialPercentage,
    });
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat ringkasan jurnal', error: err.message });
  }
});

router.post('/', async (req, res) => {
  const {
    teacher_id,
    teacher_nip,
    teacher_name,
    date_label,
    subject,
    title,
    material_summary,
    class_name,
    attendance_count,
    accent_color,
    learning_points,
    summary_paragraphs,
    progress_title,
    progress_note,
    task_title,
    task_deadline,
    image_base64,
  } = req.body;

  if (!date_label || !subject || !title || !material_summary || !class_name) {
    return res.status(400).json({ message: 'Data jurnal wajib diisi lengkap' });
  }

  try {
    await ensureJournalTable();
    const [result] = await pool.query(
      `INSERT INTO journal_entries (
        teacher_id, teacher_nip, teacher_name, date_label, subject, title,
        material_summary, class_name, attendance_count,
        accent_color, learning_points, summary_paragraphs, progress_title,
        progress_note, task_title, task_deadline, image_base64
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        Number.isInteger(teacher_id) ? teacher_id : Number(teacher_id || 0) || null,
        teacher_nip || '',
        teacher_name || '',
        date_label,
        subject,
        title,
        material_summary,
        class_name,
        Number(attendance_count || 0),
        accent_color || '#4D7CFF',
        JSON.stringify(learning_points || []),
        JSON.stringify(summary_paragraphs || []),
        progress_title || 'Progress Pembelajaran',
        progress_note || '',
        task_title || '',
        task_deadline || '',
        image_base64 || null,
      ],
    );

    const [rows] = await pool.query(
      `SELECT id, teacher_id, teacher_nip, teacher_name, date_label, subject, title, material_summary, class_name, attendance_count, accent_color, learning_points, summary_paragraphs, progress_title, progress_note, task_title, task_deadline, image_base64
       FROM journal_entries WHERE id = ?`,
      [result.insertId],
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ message: 'Gagal menambah jurnal', error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ message: 'ID jurnal tidak valid' });

  const {
    teacher_id,
    teacher_nip,
    teacher_name,
    date_label,
    subject,
    title,
    material_summary,
    class_name,
    attendance_count,
    accent_color,
    learning_points,
    summary_paragraphs,
    progress_title,
    progress_note,
    task_title,
    task_deadline,
    image_base64,
  } = req.body;

  if (!date_label || !subject || !title || !material_summary || !class_name) {
    return res.status(400).json({ message: 'Data jurnal wajib diisi lengkap' });
  }

  try {
    await ensureJournalTable();
    await pool.query(
      `UPDATE journal_entries SET
        teacher_id = ?, teacher_nip = ?, teacher_name = ?, date_label = ?, subject = ?,
        title = ?, material_summary = ?, class_name = ?,
        attendance_count = ?, accent_color = ?, learning_points = ?, summary_paragraphs = ?,
        progress_title = ?, progress_note = ?, task_title = ?, task_deadline = ?, image_base64 = ?
       WHERE id = ?`,
      [
        Number.isInteger(teacher_id) ? teacher_id : Number(teacher_id || 0) || null,
        teacher_nip || '',
        teacher_name || '',
        date_label,
        subject,
        title,
        material_summary,
        class_name,
        Number(attendance_count || 0),
        accent_color || '#4D7CFF',
        JSON.stringify(learning_points || []),
        JSON.stringify(summary_paragraphs || []),
        progress_title || 'Progress Pembelajaran',
        progress_note || '',
        task_title || '',
        task_deadline || '',
        image_base64 || null,
        id,
      ],
    );

    const [rows] = await pool.query(
      `SELECT id, teacher_id, teacher_nip, teacher_name, date_label, subject, title, material_summary, class_name, attendance_count, accent_color, learning_points, summary_paragraphs, progress_title, progress_note, task_title, task_deadline, image_base64
       FROM journal_entries WHERE id = ?`,
      [id],
    );
    if (!rows.length) {
      return res.status(404).json({ message: 'Jurnal tidak ditemukan' });
    }
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ message: 'Gagal mengubah jurnal', error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!id) return res.status(400).json({ message: 'ID jurnal tidak valid' });

  try {
    await ensureJournalTable();
    const [result] = await pool.query('DELETE FROM journal_entries WHERE id = ?', [id]);
    if (!result.affectedRows) {
      return res.status(404).json({ message: 'Jurnal tidak ditemukan' });
    }
    res.json({ ok: true, id });
  } catch (err) {
    res.status(500).json({ message: 'Gagal menghapus jurnal', error: err.message });
  }
});

module.exports = router;
