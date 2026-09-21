import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kepala_sekolah/models/kepsek_nav_data.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/bottom_nav.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/kepala_sekolah_dashboard_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/humas/humas_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kesiswaan/kesiswaan_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kurikulum/kurikulum_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/sarpras/sarpras_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/widgets/kepala_sekolah_feature_page.dart';

class AbsensiPage extends StatelessWidget {
  final int hadir;
  final int izin;
  final int alfa;
  final KepsekNavData navData;

  const AbsensiPage({
    super.key,
    required this.hadir,
    required this.izin,
    required this.alfa,
    required this.navData,
  });

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 6) return;

    Widget page;
    switch (index) {
      case 0:
        page = const KepalaSekolahDashboardPage();
        break;
      case 1:
        page = KesiswaanPage(
          totalSiswa: navData.totalSiswa,
          navData: navData,
        );
        break;
      case 2:
        page = KurikulumPage(
          totalMateri: navData.totalMateri,
          mapelCount: navData.mapelCount,
          highlights: navData.kurikulumHighlights,
          navData: navData,
        );
        break;
      case 3:
        page = SarprasPage(
          totalSarpras: navData.totalSarpras,
          sarprasRusak: navData.sarprasRusak,
          highlights: navData.sarprasHighlights,
          navData: navData,
        );
        break;
      case 4:
        page = HumasPage(
          highlights: navData.humasHighlights,
          navData: navData,
        );
        break;
      case 5:
        page = JurnalPage(
          totalJurnal: navData.totalJurnal,
          avgAttendance: navData.avgAttendance,
          highlights: navData.journalHighlights,
          navData: navData,
        );
        break;
      default:
        return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAbsensi = hadir + izin + alfa;
    final persentaseHadir = totalAbsensi == 0
        ? 0
        : ((hadir / totalAbsensi) * 100).round();
    final siswaAtensi = izin + alfa;
    final attendanceEntries = navData.attendanceRecords
        .map(
          (item) => KepalaSekolahDetailEntry(
            title: item.studentName,
            subtitle: 'Rekap kehadiran siswa',
            badge: '${item.presentDays} hadir',
            fields: [
              KepalaSekolahDetailField(
                label: 'Hadir',
                value: '${item.presentDays}',
              ),
              KepalaSekolahDetailField(
                label: 'Izin/Sakit',
                value: '${item.izinDays}',
              ),
              KepalaSekolahDetailField(
                label: 'Alfa',
                value: '${item.alfaDays}',
              ),
            ],
          ),
        )
        .toList(growable: false);
    final highlightItems = [
      KepalaSekolahHighlight(
        title: '$hadir catatan hadir tercatat',
        description:
            'Jumlah kehadiran menjadi acuan utama untuk memantau stabilitas aktivitas belajar hari ini.',
        badge: 'Hadir',
      ),
      KepalaSekolahHighlight(
        title: '$izin izin atau sakit tercatat',
        description:
            'Absensi izin dan sakit perlu dipantau agar tidak berkembang menjadi penurunan partisipasi belajar.',
        badge: 'Izin/Sakit',
      ),
      KepalaSekolahHighlight(
        title: '$alfa tanpa keterangan perlu dicek',
        description:
            'Data alfa menjadi sinyal awal untuk tindak lanjut wali kelas, BK, atau pembinaan kesiswaan.',
        badge: 'Alfa',
      ),
      KepalaSekolahHighlight(
        title: '$persentaseHadir% tingkat kehadiran',
        description:
            'Persentase hadir membantu melihat kondisi umum kehadiran dari seluruh catatan absensi yang masuk.',
        badge: 'Persentase',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: KepalaSekolahFeaturePage(
        title: 'Rekap Absensi',
        subtitle: 'Ringkasan kehadiran dan catatan absensi siswa.',
        icon: Icons.assignment_turned_in_rounded,
        accentColor: const Color(0xFFFF395D),
        metrics: [
          KepalaSekolahMetric(
            label: 'Hadir',
            value: '$hadir',
            note: 'Hari ini',
          ),
          KepalaSekolahMetric(
            label: 'Izin/Sakit',
            value: '$izin',
            note: 'Perlu dipantau',
          ),
          KepalaSekolahMetric(
            label: 'Tanpa Ket.',
            value: '$alfa',
            note: 'Perlu tindak lanjut',
          ),
          KepalaSekolahMetric(
            label: 'Kehadiran',
            value: '$persentaseHadir%',
            note: 'Tingkat Hadir',
          ),
        ],
        highlights: highlightItems,
        focusItems: const [
          'Identifikasi tren ketidakhadiran siswa.',
          'Pantau siswa dengan catatan izin, sakit, atau alfa yang berulang.',
          'Cermati keseimbangan hadir, izin, dan alfa untuk membaca kondisi kelas.',
        ],
        actionNotes: [
          'Hubungi wali kelas jika angka alfa meningkat.',
          'Prioritaskan tindak lanjut untuk $siswaAtensi catatan izin dan alfa yang perlu perhatian.',
        ],
        extraHighlightSections: [
          KepalaSekolahHighlightSection(
            title: 'Ringkasan Kondisi Absensi',
            icon: Icons.query_stats_rounded,
            items: [
              KepalaSekolahHighlight(
                title: '$totalAbsensi total catatan absensi',
                description:
                    'Seluruh catatan hadir, izin/sakit, dan alfa dipakai untuk membaca situasi kehadiran secara umum.',
                badge: 'Total',
              ),
              KepalaSekolahHighlight(
                title: '$siswaAtensi catatan perlu atensi',
                description:
                    'Gabungan izin dan alfa membantu menentukan kelompok siswa yang perlu dipantau lebih dekat.',
                badge: 'Atensi',
              ),
              KepalaSekolahHighlight(
                title: '$persentaseHadir% tingkat hadir',
                description:
                    'Persentase hadir menjadi ringkasan cepat untuk melihat kualitas kehadiran dari data yang masuk.',
                badge: 'Kehadiran',
              ),
              KepalaSekolahHighlight(
                title: '$hadir hadir dominan dalam catatan',
                description:
                    'Jumlah hadir yang lebih tinggi menunjukkan aktivitas belajar masih berjalan, namun tetap perlu kontrol rutin.',
                badge: 'Monitoring',
              ),
            ],
          ),
        ],
        detailSection: KepalaSekolahDetailSection(
          title: 'Data Sumber Absensi',
          icon: Icons.fact_check_rounded,
          searchHint: 'Cari nama siswa atau angka kehadiran...',
          entries: attendanceEntries,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: KepsekBottomNav(
            currentIndex: 6,
            onTap: (index) => _onBottomNavTap(context, index),
          ),
        ),
      ),
    );
  }
}
