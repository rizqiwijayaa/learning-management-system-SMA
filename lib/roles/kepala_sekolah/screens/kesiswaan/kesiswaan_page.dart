import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kepala_sekolah/models/kepsek_nav_data.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/kepala_sekolah_dashboard_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/bottom_nav.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/humas/humas_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kurikulum/kurikulum_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/sarpras/sarpras_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/absensi/absensi_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/widgets/kepala_sekolah_feature_page.dart';

class KesiswaanPage extends StatelessWidget {
  final int totalSiswa;
  final KepsekNavData navData;

  const KesiswaanPage({
    super.key,
    required this.totalSiswa,
    required this.navData,
  });

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 1) return;

    Widget page;
    switch (index) {
      case 0:
        page = const KepalaSekolahDashboardPage();
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
      case 6:
        page = AbsensiPage(
          hadir: navData.hadir,
          izin: navData.izin,
          alfa: navData.alfa,
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
    final siswaAktif = navData.totalSiswaAktif;
    final siswaButuhAtensi = navData.izin + navData.alfa;
    final totalCatatanAbsensi = navData.hadir + navData.izin + navData.alfa;
    final persentaseKehadiran = totalCatatanAbsensi == 0
        ? 0
        : ((navData.hadir / totalCatatanAbsensi) * 100).round();
    final jurnalTerkait = navData.totalJurnal;
    final highlightItems = [
      KepalaSekolahHighlight(
        title: '${navData.hadir} catatan hadir tercatat',
        description:
            'Data absensi yang masuk mencatat ${navData.hadir} hadir, ${navData.izin} izin/sakit, dan ${navData.alfa} alfa.',
        badge: 'Monitoring Harian',
      ),
      KepalaSekolahHighlight(
        title: '$siswaButuhAtensi siswa perlu perhatian',
        description:
            'Data izin dan alfa perlu dicek bersama wali kelas agar tidak berkembang menjadi masalah disiplin.',
        badge: 'Atensi',
      ),
      KepalaSekolahHighlight(
        title: '${navData.totalSiswaMutasi} siswa mutasi terpantau',
        description:
            'Data status siswa menunjukkan jumlah mutasi yang perlu dipantau untuk kebutuhan administrasi dan pembinaan.',
        badge: 'Pembinaan',
      ),
      KepalaSekolahHighlight(
        title: 'Sinkronkan jurnal dengan kesiswaan',
        description:
            '$jurnalTerkait jurnal guru dapat dipakai untuk membaca dinamika kelas dan perilaku siswa.',
        badge: 'Kolaborasi',
      ),
    ];
    final studentEntries = navData.students
        .map(
          (item) => KepalaSekolahDetailEntry(
            title: item.name,
            subtitle: '${item.className} - ${item.major}',
            badge: item.status,
            fields: [
              KepalaSekolahDetailField(label: 'NIS', value: item.nis),
              KepalaSekolahDetailField(label: 'Kelas', value: item.className),
              KepalaSekolahDetailField(label: 'Jurusan', value: item.major),
              KepalaSekolahDetailField(label: 'Status', value: item.status),
            ],
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: KepalaSekolahFeaturePage(
        title: 'Kesiswaan',
        subtitle: 'Pantau disiplin, kehadiran, pembinaan, dan kondisi siswa dalam satu ringkasan.',
        icon: Icons.groups_rounded,
        accentColor: const Color(0xFF2F6BFF),
        metrics: [
          KepalaSekolahMetric(
            label: 'Total Siswa',
            value: '$totalSiswa',
            note: 'Data siswa tercatat',
          ),
          KepalaSekolahMetric(
            label: 'Kehadiran',
            value: '$persentaseKehadiran%',
            note: 'Persentase hadir',
          ),
          KepalaSekolahMetric(
            label: 'Perlu Atensi',
            value: '$siswaButuhAtensi',
            note: 'Izin dan alfa',
          ),
          KepalaSekolahMetric(
            label: 'Jurnal Terkait',
            value: '$jurnalTerkait',
            note: 'Dukungan pemantauan',
          ),
        ],
        highlights: highlightItems,
        focusItems: [
          'Pantau perkembangan jumlah siswa aktif dan siswa yang perlu pembinaan setiap pekan.',
          'Cermati tren izin, sakit, dan alfa untuk mendeteksi penurunan disiplin lebih awal.',
          'Sinkronkan data kesiswaan dengan jurnal guru dan absensi agar keputusan lebih akurat.',
          'Gunakan ringkasan ini untuk evaluasi wali kelas, BK, dan agenda pembinaan siswa.',
        ],
        actionNotes: [
          'Prioritaskan tindak lanjut pada $siswaButuhAtensi siswa yang tercatat izin atau alfa hari ini.',
          'Bahas siswa dengan pola kehadiran menurun pada rapat koordinasi wali kelas dan BK.',
          'Siapkan laporan singkat kesiswaan mingguan untuk memantau disiplin, mutasi, dan pembinaan.',
        ],
        extraHighlightSections: [
          KepalaSekolahHighlightSection(
            title: 'Ringkasan Data Kesiswaan',
            icon: Icons.analytics_rounded,
            items: [
              KepalaSekolahHighlight(
                title: '$siswaAktif siswa aktif tercatat',
                description:
                    'Jumlah siswa aktif menjadi dasar pemantauan kesiswaan dan evaluasi kebutuhan pembinaan.',
                badge: 'Siswa',
              ),
              KepalaSekolahHighlight(
                title: '${navData.totalKelasSiswa} kelas aktif terdata',
                description:
                    'Sebaran kelas aktif membantu kepala sekolah melihat cakupan pemantauan siswa secara menyeluruh.',
                badge: 'Kelas',
              ),
              KepalaSekolahHighlight(
                title: '$totalCatatanAbsensi data absensi terhimpun',
                description:
                    'Akumulasi catatan hadir, izin/sakit, dan alfa dipakai sebagai bahan pemantauan operasional kesiswaan.',
                badge: 'Absensi',
              ),
              KepalaSekolahHighlight(
                title: '$jurnalTerkait jurnal mendukung evaluasi',
                description:
                    'Jurnal guru membantu menghubungkan temuan kesiswaan dengan aktivitas kelas yang sedang berjalan.',
                badge: 'Jurnal',
              ),
            ],
          ),
        ],
        detailSection: KepalaSekolahDetailSection(
          title: 'Data Sumber Siswa',
          icon: Icons.table_rows_rounded,
          searchHint: 'Cari nama, NIS, kelas, atau status siswa...',
          entries: studentEntries,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: KepsekBottomNav(
            currentIndex: 1,
            onTap: (index) => _onBottomNavTap(context, index),
          ),
        ),
      ),
    );
  }
}
