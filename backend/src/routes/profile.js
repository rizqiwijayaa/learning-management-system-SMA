const express = require('express');
const { pool } = require('../db');

const router = express.Router();

const defaultProfile = {
  id: 1,
  name: 'Rizqi',
  role: 'Guru',
  nip: '1987654321',
  email: 'rizqi.guru@sekolah.id',
  phone: '08xx-xxxx-xxxx',
  avatarBase64: null,
};

async function ensureProfileTable() {
  await pool.query(`
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
    )
  `);
  await pool.query(`
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
    )
  `);
  await pool.query(`
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
    )
  `);

  // Auto-seed profile tables from app_users if they are empty to ensure data persistence
  try {
    // Hapus profil legacy yang masih terikat ke akun guru lama agar pembacaan
    // profil tidak lagi loncat ke record duplikat.
    await pool.query(`
      DELETE legacy_tp
      FROM teacher_profile legacy_tp
      INNER JOIN app_users legacy_u ON legacy_u.id = legacy_tp.id
      INNER JOIN app_users canonical_u
        ON canonical_u.nip = legacy_u.nip
       AND canonical_u.role = legacy_u.role
       AND canonical_u.email = 'rizqi.guru@sekolah.id'
      WHERE legacy_u.email = 'guru@sekolah.id'
        AND legacy_u.id <> canonical_u.id
    `);

    const [tCount] = await pool.query('SELECT COUNT(*) as total FROM teacher_profile');
    if (tCount[0].total === 0) {
      await pool.query(`
        INSERT IGNORE INTO teacher_profile (id, name, role, nip, email, phone, avatar_base64)
        SELECT id, name, role, nip, email, phone, avatar_base64 FROM app_users WHERE role = 'Guru'
      `);
    }
    const [kCount] = await pool.query('SELECT COUNT(*) as total FROM kepsek_profile');
    if (kCount[0].total === 0) {
      await pool.query(`
        INSERT IGNORE INTO kepsek_profile (id, name, role, nip, email, phone, avatar_base64)
        SELECT id, name, role, nip, email, phone, avatar_base64 FROM app_users WHERE role = 'Kepala Sekolah'
      `);
    }
    const [ksCount] = await pool.query('SELECT COUNT(*) as total FROM kesiswaan_profile');
    if (ksCount[0].total === 0) {
      await pool.query(`
        INSERT IGNORE INTO kesiswaan_profile (id, name, role, nip, email, phone, avatar_base64)
        SELECT id, name, role, nip, email, phone, avatar_base64 FROM app_users WHERE role = 'Kesiswaan'
      `);
    }
  } catch (err) {
    console.error('Auto-seeding profiles failed:', err.message);
  }
}

async function getProfileRowByIdentity({ id = null, nip = '', email = '' } = {}) {
  await ensureProfileTable();
  
  let foundRow = null;

  const normalizedId =
    typeof id === 'number' && Number.isFinite(id)
      ? id
      : Number.parseInt(`${id ?? ''}`, 10);

  if (Number.isInteger(normalizedId) && normalizedId > 0) {
    const [rows] = await pool.query(
      `
        SELECT
          COALESCE(kp.id, tp.id, u.id) AS id,
          COALESCE(ksp.name, kp.name, tp.name, u.name) AS name,
          u.role AS role,
          u.nip,
          u.email AS email,
          COALESCE(ksp.phone, kp.phone, tp.phone, u.phone) AS phone,
          COALESCE(ksp.avatar_base64, kp.avatar_base64, tp.avatar_base64, u.avatar_base64) AS avatar_base64
        FROM app_users u
        LEFT JOIN teacher_profile tp ON tp.id = u.id AND u.role = 'Guru'
        LEFT JOIN kepsek_profile kp ON kp.id = u.id AND u.role = 'Kepala Sekolah'
        LEFT JOIN kesiswaan_profile ksp ON ksp.id = u.id AND u.role = 'Kesiswaan'
        WHERE u.id = ?
        LIMIT 1
      `,
      [normalizedId],
    );

    if (Array.isArray(rows) && rows.length > 0) {
      foundRow = rows[0];
    }
  }

  if (!foundRow && typeof nip === 'string' && nip.trim() !== '') {
    const [rows] = await pool.query(
      `
        SELECT
          COALESCE(kp.id, tp.id, u.id) AS id,
          COALESCE(ksp.name, kp.name, tp.name, u.name) AS name,
          u.role AS role,
          u.nip,
          u.email AS email,
          COALESCE(ksp.phone, kp.phone, tp.phone, u.phone) AS phone,
          COALESCE(ksp.avatar_base64, kp.avatar_base64, tp.avatar_base64, u.avatar_base64) AS avatar_base64
        FROM app_users u
        LEFT JOIN teacher_profile tp ON tp.id = u.id AND u.role = 'Guru'
        LEFT JOIN kepsek_profile kp ON kp.id = u.id AND u.role = 'Kepala Sekolah'
        LEFT JOIN kesiswaan_profile ksp ON ksp.id = u.id AND u.role = 'Kesiswaan'
        WHERE u.nip = ?
        LIMIT 1
      `,
      [nip.trim()],
    );

    if (Array.isArray(rows) && rows.length > 0) {
      foundRow = rows[0];
    }
  }

  if (!foundRow && typeof email === 'string' && email.trim() !== '') {
    const [rows] = await pool.query(
      `
        SELECT
          COALESCE(kp.id, tp.id, u.id) AS id,
          COALESCE(ksp.name, kp.name, tp.name, u.name) AS name,
          u.role AS role,
          u.nip,
          u.email AS email,
          COALESCE(ksp.phone, kp.phone, tp.phone, u.phone) AS phone,
          COALESCE(ksp.avatar_base64, kp.avatar_base64, tp.avatar_base64, u.avatar_base64) AS avatar_base64
        FROM app_users u
        LEFT JOIN teacher_profile tp ON tp.id = u.id AND u.role = 'Guru'
        LEFT JOIN kepsek_profile kp ON kp.id = u.id AND u.role = 'Kepala Sekolah'
        LEFT JOIN kesiswaan_profile ksp ON ksp.id = u.id AND u.role = 'Kesiswaan'
        WHERE u.email = ? OR tp.email = ? OR kp.email = ? OR ksp.email = ?
        LIMIT 1
      `,
      [email.trim(), email.trim(), email.trim(), email.trim()],
    );

    if (Array.isArray(rows) && rows.length > 0) {
      foundRow = rows[0];
    }
  }

  return foundRow;
}

async function getAccountRowByIdentity({ id = null, nip = '', email = '' } = {}) {
  await ensureProfileTable();

  const normalizedId =
    typeof id === 'number' && Number.isFinite(id)
      ? id
      : Number.parseInt(`${id ?? ''}`, 10);
  const normalizedNip = typeof nip === 'string' ? nip.trim() : '';
  const normalizedEmail = typeof email === 'string' ? email.trim() : '';

  if (!(Number.isInteger(normalizedId) && normalizedId > 0) && !normalizedNip && !normalizedEmail) {
    return null;
  }

  const [rows] = await pool.query(
    `
      SELECT
        u.id,
        u.name,
        u.role,
        u.nip,
        u.email,
        u.phone,
        u.avatar_base64
      FROM app_users u
      LEFT JOIN teacher_profile tp ON tp.id = u.id
      LEFT JOIN kepsek_profile kp ON kp.id = u.id
      LEFT JOIN kesiswaan_profile ksp ON ksp.id = u.id
      WHERE
        (? > 0 AND u.id = ?)
        OR (? <> '' AND u.nip = ?)
        OR (? <> '' AND (u.email = ? OR tp.email = ? OR kp.email = ? OR ksp.email = ?))
      LIMIT 1
    `,
    [
      Number.isInteger(normalizedId) && normalizedId > 0 ? normalizedId : 0,
      Number.isInteger(normalizedId) && normalizedId > 0 ? normalizedId : 0,
      normalizedNip,
      normalizedNip,
      normalizedEmail,
      normalizedEmail,
      normalizedEmail,
      normalizedEmail,
      normalizedEmail,
    ],
  );

  return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
}

router.get('/me', async (req, res) => {
  try {
    const row = await getProfileRowByIdentity({
      id: req.query?.id,
      nip: String(req.query?.nip || '').trim(),
      email: String(req.query?.email || '').trim(),
    });

    if (!row) {
      return res.status(404).json({ message: 'Profil tidak ditemukan' });
    }

    res.json({
      id: row.id,
      name: row.name,
      role: row.role,
      nip: row.nip,
      email: row.email,
      phone: row.phone,
      avatarBase64: row.avatar_base64,
    });
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat profil', error: err.message });
  }
});

router.put('/me', async (req, res) => {
  const {
    id = null,
    name = '',
    role = '',
    nip = '',
    email = '',
    phone = '',
    avatarBase64 = null,
  } = req.body ?? {};

  if (
    [name, role, nip, email, phone].some(
      (value) => typeof value !== 'string' || value.trim().length === 0,
    )
  ) {
    return res.status(400).json({ message: 'Semua data profil wajib diisi' });
  }

  if (avatarBase64 != null && typeof avatarBase64 !== 'string') {
    return res.status(400).json({ message: 'Format avatar tidak valid' });
  }

  try {
    await ensureProfileTable();
    const normalizedName = name.trim();
    const normalizedPhone = phone.trim();

    const appUser = await getAccountRowByIdentity({
      id,
      nip,
      email,
    });

    if (!appUser) {
      return res.status(404).json({ message: 'User profil tidak ditemukan' });
    }

    const normalizedRole = String(appUser.role || role).trim();
    const normalizedNip = String(appUser.nip || nip).trim();
    const normalizedEmail = String(appUser.email || email).trim();
    const finalRole = normalizedRole.toLowerCase();
    const targetTable = finalRole === 'kepala sekolah'
      ? 'kepsek_profile'
      : finalRole === 'kesiswaan'
      ? 'kesiswaan_profile'
      : 'teacher_profile';

    await pool.query(
      `
        INSERT INTO ${targetTable} (id, name, role, nip, email, phone, avatar_base64)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          name = VALUES(name),
          role = VALUES(role),
          nip = VALUES(nip),
          email = VALUES(email),
          phone = VALUES(phone),
          avatar_base64 = VALUES(avatar_base64)
      `,
      [
        appUser.id,
        normalizedName,
        normalizedRole,
        normalizedNip,
        normalizedEmail,
        normalizedPhone,
        avatarBase64,
      ],
    );

    await pool.query(
      `
        UPDATE app_users
        SET
          name = ?,
          role = ?,
          nip = ?,
          email = ?,
          phone = ?,
          avatar_base64 = ?
        WHERE id = ?
      `,
      [
        normalizedName,
        normalizedRole,
        normalizedNip,
        normalizedEmail,
        normalizedPhone,
        avatarBase64,
        appUser.id,
      ],
    );

    const row = await getProfileRowByIdentity({
      id: appUser.id,
      nip: normalizedNip,
      email: normalizedEmail,
    });
    const responseRow = row ?? {
      id: appUser.id,
      name: normalizedName,
      role: normalizedRole,
      nip: normalizedNip,
      email: normalizedEmail,
      phone: normalizedPhone,
      avatar_base64: avatarBase64,
    };

    res.json({
      id: responseRow.id,
      name: responseRow.name,
      role: responseRow.role,
      nip: responseRow.nip,
      email: responseRow.email,
      phone: responseRow.phone,
      avatarBase64: responseRow.avatar_base64,
    });
  } catch (err) {
    res.status(500).json({ message: 'Gagal menyimpan profil', error: err.message });
  }
});

router.ensureProfileTable = ensureProfileTable;
module.exports = router;
