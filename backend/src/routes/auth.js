const express = require('express');
const { pool } = require('../db');
const { ensureProfileTable } = require('./profile');

const router = express.Router();

async function ensureUsersTable() {
  await pool.query(`
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
    )
  `);

  const [passwordColumn] = await pool.query(`
    SHOW COLUMNS FROM app_users LIKE 'password'
  `);

  if (!Array.isArray(passwordColumn) || passwordColumn.length == 0) {
    await pool.query(`
      ALTER TABLE app_users
      ADD COLUMN password VARCHAR(150) NOT NULL DEFAULT '123456' AFTER email
    `);
  }

  // Rapikan akun guru lama yang sempat memakai email legacy agar tidak bentrok
  // dengan akun guru aktif yang memakai email canonical.
  await pool.query(`
    DELETE legacy
    FROM app_users legacy
    INNER JOIN app_users canonical
      ON canonical.nip = legacy.nip
     AND canonical.role = legacy.role
     AND canonical.email = 'rizqi.guru@sekolah.id'
    WHERE legacy.email = 'guru@sekolah.id'
      AND legacy.id <> canonical.id
  `);
}

router.post('/login', async (req, res) => {
  const email = `${req.body?.email ?? ''}`.trim();
  const password = `${req.body?.password ?? ''}`;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email dan password wajib diisi' });
  }

  try {
    await ensureUsersTable();
    await ensureProfileTable();

    const [rows] = await pool.query(
      `
        SELECT
          u.id,
          COALESCE(ksp.name, kp.name, tp.name, u.name) AS name,
          u.role AS role,
          u.nip,
          u.email AS email,
          u.password,
          COALESCE(ksp.phone, kp.phone, tp.phone, u.phone) AS phone,
          COALESCE(ksp.avatar_base64, kp.avatar_base64, tp.avatar_base64, u.avatar_base64) AS avatar_base64
        FROM app_users u
        LEFT JOIN teacher_profile tp ON tp.id = u.id AND u.role = 'Guru'
        LEFT JOIN kepsek_profile kp ON kp.id = u.id AND u.role = 'Kepala Sekolah'
        LEFT JOIN kesiswaan_profile ksp ON ksp.id = u.id AND u.role = 'Kesiswaan'
        WHERE u.email = ? OR tp.email = ? OR kp.email = ? OR ksp.email = ?
        LIMIT 1
      `,
      [email, email, email, email],
    );

    const user = rows[0];
    if (!user) {
      return res.status(401).json({ message: 'Email tidak terdaftar' });
    }

    if (user.password !== password) {
      return res.status(401).json({ message: 'Password salah' });
    }

    res.json({
      id: user.id,
      name: user.name,
      role: user.role,
      nip: user.nip,
      email: user.email,
      phone: user.phone,
      avatarBase64: user.avatar_base64,
    });
  } catch (err) {
    res.status(500).json({ message: 'Gagal login', error: err.message });
  }
});

router.post('/forgot-password', async (req, res) => {
  const email = `${req.body?.email ?? ''}`.trim();

  if (!email) {
    return res.status(400).json({ message: 'Email wajib diisi' });
  }

  try {
    await ensureUsersTable();
    // Panggil ini agar tabel profil dipastikan ada dan terisi saat login
    await ensureProfileTable();

    const [rows] = await pool.query(
      `
        SELECT id
        FROM app_users
        WHERE email = ?
        LIMIT 1
      `,
      [email],
    );

    const user = rows[0];
    if (!user) {
      return res.status(404).json({ message: 'Email tidak ditemukan' });
    }

    return res.json({
      message: 'Instruksi reset password telah dikirim ke email Anda',
    });
  } catch (err) {
    return res.status(500).json({
      message: 'Gagal memproses lupa password',
      error: err.message,
    });
  }
});

module.exports = router;
