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

  const ensureColumn = async (name, sql) => {
    const [rows] = await pool.query(`SHOW COLUMNS FROM app_users LIKE ?`, [name]);
    if (!Array.isArray(rows) || rows.length === 0) {
      await pool.query(sql);
    }
  };

  await ensureColumn(
    'password',
    "ALTER TABLE app_users ADD COLUMN password VARCHAR(150) NOT NULL DEFAULT '123456' AFTER email",
  );
  await ensureColumn(
    'username',
    "ALTER TABLE app_users ADD COLUMN username VARCHAR(120) NOT NULL DEFAULT '' AFTER name",
  );
  await ensureColumn(
    'status',
    "ALTER TABLE app_users ADD COLUMN status VARCHAR(30) NOT NULL DEFAULT 'Aktif' AFTER role",
  );

  await pool.query(`
    UPDATE app_users
    SET username = CONCAT(LOWER(SUBSTRING_INDEX(email, '@', 1)), '_', id)
    WHERE TRIM(IFNULL(username, '')) = ''
  `);

  const [duplicateRows] = await pool.query(`
    SELECT username
    FROM app_users
    WHERE TRIM(IFNULL(username, '')) <> ''
    GROUP BY username
    HAVING COUNT(*) > 1
  `);

  for (const row of duplicateRows) {
    await pool.query(
      `
        UPDATE app_users
        SET username = CONCAT(username, '_', id)
        WHERE username = ?
      `,
      [row.username],
    );
  }

  await pool.query(`
    UPDATE app_users
    SET status = 'Aktif'
    WHERE TRIM(IFNULL(status, '')) = ''
  `);

  const [usernameIndex] = await pool.query(
    "SHOW INDEX FROM app_users WHERE Key_name = 'app_users_username_unique'",
  );
  if (!Array.isArray(usernameIndex) || usernameIndex.length === 0) {
    await pool.query(
      'ALTER TABLE app_users ADD UNIQUE KEY app_users_username_unique (username)',
    );
  }
}

function normalizeRole(role) {
  const value = `${role ?? ''}`.trim().toLowerCase();
  if (value === 'kepala sekolah') return 'Kepala Sekolah';
  if (value === 'kesiswaan') return 'Kesiswaan';
  return 'Guru';
}

function resolveProfileTable(role) {
  const normalized = normalizeRole(role).toLowerCase();
  if (normalized === 'kepala sekolah') return 'kepsek_profile';
  if (normalized === 'kesiswaan') return 'kesiswaan_profile';
  return 'teacher_profile';
}

async function syncProfileForUser(connection, user) {
  const targetTable = resolveProfileTable(user.role);
  const nip = `${user.nip ?? user.username ?? ''}`.trim();
  const phone = `${user.phone ?? ''}`.trim();

  if (targetTable !== 'teacher_profile') {
    await connection.query('DELETE FROM teacher_profile WHERE id = ?', [user.id]);
  }
  if (targetTable !== 'kepsek_profile') {
    await connection.query('DELETE FROM kepsek_profile WHERE id = ?', [user.id]);
  }
  if (targetTable !== 'kesiswaan_profile') {
    await connection.query('DELETE FROM kesiswaan_profile WHERE id = ?', [user.id]);
  }

  await connection.query(
    `
      INSERT INTO ${targetTable} (id, name, role, nip, email, phone, avatar_base64)
      VALUES (?, ?, ?, ?, ?, ?, NULL)
      ON DUPLICATE KEY UPDATE
        name = VALUES(name),
        role = VALUES(role),
        nip = VALUES(nip),
        email = VALUES(email),
        phone = VALUES(phone)
    `,
    [user.id, user.name, user.role, nip, user.email, phone],
  );
}

async function getUserById(id) {
  const [rows] = await pool.query(
    `
      SELECT id, name, username, email, role, status
      FROM app_users
      WHERE id = ?
      LIMIT 1
    `,
    [id],
  );
  return rows[0] ?? null;
}

router.get('/', async (_req, res) => {
  try {
    await ensureUsersTable();
    await ensureProfileTable();

    const [rows] = await pool.query(`
      SELECT id, name, username, email, role, status
      FROM app_users
      ORDER BY created_at DESC, id DESC
    `);

    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat daftar user', error: err.message });
  }
});

router.post('/', async (req, res) => {
  const name = `${req.body?.name ?? ''}`.trim();
  const username = `${req.body?.username ?? ''}`.trim();
  const email = `${req.body?.email ?? ''}`.trim();
  const role = normalizeRole(req.body?.role);
  const status = `${req.body?.status ?? 'Aktif'}`.trim() || 'Aktif';

  if (!name || !username || !email) {
    return res.status(400).json({ message: 'Nama, username, dan email wajib diisi' });
  }

  const connection = await pool.getConnection();
  try {
    await ensureUsersTable();
    await ensureProfileTable();
    await connection.beginTransaction();

    const [duplicate] = await connection.query(
      `
        SELECT id
        FROM app_users
        WHERE username = ? OR email = ?
        LIMIT 1
      `,
      [username, email],
    );

    if (Array.isArray(duplicate) && duplicate.length > 0) {
      await connection.rollback();
      return res.status(409).json({ message: 'Username atau email sudah digunakan' });
    }

    const [result] = await connection.query(
      `
        INSERT INTO app_users (name, username, role, status, nip, email, password, phone, avatar_base64)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL)
      `,
      [name, username, role, status, username, email, '123456', ''],
    );

    const createdUser = {
      id: result.insertId,
      name,
      username,
      email,
      role,
      status,
      nip: username,
      phone: '',
    };

    await syncProfileForUser(connection, createdUser);
    await connection.commit();

    res.status(201).json(createdUser);
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ message: 'Gagal menambah user', error: err.message });
  } finally {
    connection.release();
  }
});

router.put('/:id', async (req, res) => {
  const id = Number.parseInt(req.params.id, 10);
  const name = `${req.body?.name ?? ''}`.trim();
  const username = `${req.body?.username ?? ''}`.trim();
  const email = `${req.body?.email ?? ''}`.trim();
  const role = normalizeRole(req.body?.role);
  const status = `${req.body?.status ?? 'Aktif'}`.trim() || 'Aktif';

  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ message: 'ID user tidak valid' });
  }

  if (!name || !username || !email) {
    return res.status(400).json({ message: 'Nama, username, dan email wajib diisi' });
  }

  const connection = await pool.getConnection();
  try {
    await ensureUsersTable();
    await ensureProfileTable();
    await connection.beginTransaction();

    const [duplicate] = await connection.query(
      `
        SELECT id
        FROM app_users
        WHERE (username = ? OR email = ?) AND id <> ?
        LIMIT 1
      `,
      [username, email, id],
    );

    if (Array.isArray(duplicate) && duplicate.length > 0) {
      await connection.rollback();
      return res.status(409).json({ message: 'Username atau email sudah digunakan' });
    }

    const [result] = await connection.query(
      `
        UPDATE app_users
        SET
          name = ?,
          username = ?,
          role = ?,
          status = ?,
          nip = ?,
          email = ?
        WHERE id = ?
      `,
      [name, username, role, status, username, email, id],
    );

    if (!result.affectedRows) {
      await connection.rollback();
      return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    const updatedUser = { id, name, username, email, role, status };
    updatedUser.nip = username;
    updatedUser.phone = '';
    await syncProfileForUser(connection, updatedUser);
    await connection.commit();

    res.json(updatedUser);
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ message: 'Gagal mengubah user', error: err.message });
  } finally {
    connection.release();
  }
});

router.delete('/:id', async (req, res) => {
  const id = Number.parseInt(req.params.id, 10);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ message: 'ID user tidak valid' });
  }

  const connection = await pool.getConnection();
  try {
    await ensureUsersTable();
    await ensureProfileTable();
    await connection.beginTransaction();

    const existing = await getUserById(id);
    if (!existing) {
      await connection.rollback();
      return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    await connection.query('DELETE FROM teacher_profile WHERE id = ?', [id]);
    await connection.query('DELETE FROM kepsek_profile WHERE id = ?', [id]);
    await connection.query('DELETE FROM kesiswaan_profile WHERE id = ?', [id]);
    await connection.query('DELETE FROM app_users WHERE id = ?', [id]);

    await connection.commit();
    res.json({ ok: true });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ message: 'Gagal menghapus user', error: err.message });
  } finally {
    connection.release();
  }
});

module.exports = router;
