import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kepala_sekolah/models/kepsek_nav_data.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/bottom_nav.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/kepala_sekolah_dashboard_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/humas/humas_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kesiswaan/kesiswaan_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/sarpras/sarpras_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/absensi/absensi_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/widgets/kepala_sekolah_feature_page.dart';

class KurikulumPage extends StatelessWidget {
  final int totalMateri;
  final int mapelCount;
  final List<KepalaSekolahHighlight> highlights;
  final KepsekNavData navData;

  const KurikulumPage({
    super.key,
    required this.totalMateri,
    required this.mapelCount,
    required this.highlights,
    required this.navData,
  });

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 2) return;

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
    final materiPerMapel = mapelCount == 0 ? 0 : (totalMateri / mapelCount).ceil();
    final highlightItems = highlights.isEmpty
        ? const [
            KepalaSekolahHighlight(
              title: 'Belum ada materi terbaru',
              description: 'Unggahan materi akan tampil di panel ini setelah data tersedia.',
              badge: 'Kosong',
            ),
          ]
        : highlights;
    final curriculumEntries = navData.curriculums
        .map(
          (item) => KepalaSekolahDetailEntry(
            title: item.subject,
            subtitle: '${item.grade} - ${item.major}',
            badge: item.status,
            fields: [
              KepalaSekolahDetailField(label: 'Kode', value: item.code),
              KepalaSekolahDetailField(label: 'Guru', value: item.teacher),
              KepalaSekolahDetailField(label: 'Kelas', value: item.grade),
              KepalaSekolahDetailField(label: 'Jurusan', value: item.major),
              KepalaSekolahDetailField(label: 'Tahun Ajaran', value: item.schoolYear),
              KepalaSekolahDetailField(label: 'Status', value: item.status),
            ],
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: KepalaSekolahFeaturePage(
        title: 'Kurikulum',
        subtitle: 'Monitoring materi dan capaian pembelajaran.',
        icon: Icons.menu_book_rounded,
        accentColor: const Color(0xFF2CB34A),
        metrics: [
          KepalaSekolahMetric(
            label: 'Total Materi',
            value: '$totalMateri',
            note: 'Terunggah',
          ),
          KepalaSekolahMetric(
            label: 'Mata Pelajaran',
            value: '$mapelCount',
            note: 'Aktif',
          ),
          KepalaSekolahMetric(
            label: 'Tahun Ajaran',
            value: navData.schoolYear,
            note: 'Aktif',
          ),
          KepalaSekolahMetric(
            label: 'Rata-rata Materi',
            value: '$materiPerMapel',
            note: 'Per Mapel',
          ),
        ],
        highlights: highlightItems,
        focusItems: const [
          'Pantau distribusi materi di setiap jenjang.',
          'Evaluasi kesesuaian materi dengan kalender akademik.',
          'Pastikan aksesibilitas materi bagi siswa.',
        ],
        actionNotes: const [
          'Tinjau materi baru setiap awal bulan.',
          'Koordinasi dengan bagian kurikulum untuk jadwal ujian.',
        ],
        extraHighlightSections: [
          KepalaSekolahHighlightSection(
            title: 'Ringkasan Distribusi Materi',
            icon: Icons.auto_graph_rounded,
            items: [
              KepalaSekolahHighlight(
                title: '$totalMateri materi sudah terunggah',
                description:
                    'Seluruh materi yang sudah masuk menjadi dasar monitoring kesiapan pembelajaran.',
                badge: 'Materi',
              ),
              KepalaSekolahHighlight(
                title: '$mapelCount mata pelajaran aktif',
                description:
                    'Sebaran mapel aktif membantu melihat apakah distribusi materi sudah merata.',
                badge: 'Mapel',
              ),
              KepalaSekolahHighlight(
                title: '$materiPerMapel materi per mapel',
                description:
                    'Rata-rata materi per mapel dapat dipakai untuk membaca kepadatan unggahan dan pemerataan konten.',
                badge: 'Rata-rata',
              ),
            ],
          ),
        ],
        detailSection: KepalaSekolahDetailSection(
          title: 'Data Sumber Kurikulum',
          icon: Icons.table_chart_rounded,
          searchHint: 'Cari mapel, guru, jurusan, kelas, atau tahun ajaran...',
          entries: curriculumEntries,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: KepsekBottomNav(
            currentIndex: 2,
            onTap: (index) => _onBottomNavTap(context, index),
          ),
        ),
      ),
    );
  }
}
