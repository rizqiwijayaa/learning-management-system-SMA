require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { ensureDatabaseExists } = require('./db');
const absensiRoutes = require('./routes/absensi');
const authRoutes = require('./routes/auth');
const jurnalRoutes = require('./routes/jurnal');
const materiRoutes = require('./routes/materi');
const profileRoutes = require('./routes/profile');
const nilaiRoutes = require('./routes/nilai');
const tugasRoutes = require('./routes/tugas');
const masterRoutes = require('./routes/master');
const usersRoutes = require('./routes/users');

const app = express();
const port = Number(process.env.PORT || 3000);
let server;

app.use(cors());
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ extended: true, limit: '100mb' }));

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, service: 'lms-guru-api' });
});

app.use('/api/auth', authRoutes);
app.use('/api/materi', materiRoutes);
app.use('/api/tugas', tugasRoutes);
app.use('/api/master', masterRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/nilai', nilaiRoutes);
app.use('/api/absensi', absensiRoutes);
app.use('/api/jurnal', jurnalRoutes);

app.use((_req, res) => {
  res.status(404).json({ message: 'Route tidak ditemukan' });
});

async function startServer() {
  try {
    await ensureDatabaseExists();

    server = app.listen(port, () => {
      console.log(`API running on http://localhost:${port}`);
    });

    server.on('error', (error) => {
      if (error.code === 'EADDRINUSE') {
        console.error(
          `Port ${port} sedang dipakai proses lain. Hentikan proses yang memakai port ini atau jalankan server dengan PORT berbeda, misalnya PORT=3001 npm run dev.`,
        );
        process.exit(1);
      }

      console.error('Gagal menjalankan server:', error.message);
      process.exit(1);
    });
  } catch (error) {
    console.error('Gagal menyiapkan database:', error.message);
    process.exit(1);
  }
}

function shutdown(signal) {
  if (!server) {
    process.exit(0);
  }

  server.close(() => {
    console.log(`Server dihentikan (${signal}).`);
    process.exit(0);
  });
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

startServer();
