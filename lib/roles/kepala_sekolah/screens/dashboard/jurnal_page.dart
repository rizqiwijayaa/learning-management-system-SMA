import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kepala_sekolah/models/kepsek_nav_data.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/bottom_nav.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/kepala_sekolah_dashboard_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/humas/humas_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kesiswaan/kesiswaan_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kurikulum/kurikulum_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/sarpras/sarpras_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/absensi/absensi_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/widgets/kepala_sekolah_feature_page.dart';

class JurnalPage extends StatelessWidget {
  final int totalJurnal;
  final int avgAttendance;
  final List<KepalaSekolahHighlight> highlights;
  final KepsekNavData navData;

  const JurnalPage({
    super.key,
    required this.totalJurnal,
    required this.avgAttendance,
    required this.highlights,
    required this.navData,
  });

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 5) return;

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
    final highlightItems = highlights.isEmpty
        ? const [
            KepalaSekolahHighlight(
              title: 'Belum ada jurnal terbaru',
              description: 'Aktivitas pembelajaran dan jurnal guru akan tampil di panel ini saat data tersedia.',
              badge: 'Kosong',
            ),
          ]
        : highlights;
    final sinkronMateri = navData.journalSyncPercentage;
    final journalEntries = navData.journals
        .map(
          (item) => KepalaSekolahDetailEntry(
            title: item.title,
            subtitle: '${item.subject} - ${item.className}',
            badge: item.dateLabel,
            fields: [
              KepalaSekolahDetailField(label: 'Tanggal', value: item.dateLabel),
              KepalaSekolahDetailField(label: 'Mapel', value: item.subject),
              KepalaSekolahDetailField(label: 'Kelas', value: item.className),
              KepalaSekolahDetailField(
                label: 'Kehadiran',
                value: '${item.attendanceCount} siswa',
              ),
              KepalaSekolahDetailField(
                label: 'Ringkasan',
                value: item.materialSummary,
              ),
            ],
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: KepalaSekolahFeaturePage(
        title: 'Jurnal',
        subtitle: 'Jurnal pembelajaran guru dan aktivitas kelas.',
        icon: Icons.receipt_long_rounded,
        accentColor: const Color(0xFF1BB4C9),
        metrics: [
          KepalaSekolahMetric(
            label: 'Total Jurnal',
            value: '$totalJurnal',
            note: 'Data tersedia',
          ),
          KepalaSekolahMetric(
            label: 'Rata-rata Hadir',
            value: '$avgAttendance',
            note: 'Rata-rata per jurnal',
          ),
          KepalaSekolahMetric(
            label: 'Sinkron Materi',
            value: '$sinkronMateri%',
            note: 'Jurnal dan materi',
          ),
          KepalaSekolahMetric(
            label: 'Kelas Tercatat',
            value: '${navData.totalKelasJurnal}',
            note: 'Kelas terpantau',
          ),
        ],
        highlights: highlightItems,
        focusItems: const [
          'Pantau konsistensi jurnal guru.',
          'Lihat kecocokan jurnal dengan materi.',
          'Gunakan jurnal untuk evaluasi proses belajar.',
        ],
        actionNotes: const [
          'Cek jurnal terbaru sebelum evaluasi rutin.',
          'Tandai kelas yang butuh perhatian akademik.',
        ],
        extraHighlightSections: [
          KepalaSekolahHighlightSection(
            title: 'Ringkasan Aktivitas Jurnal',
            icon: Icons.menu_book_rounded,
            items: [
              KepalaSekolahHighlight(
                title: '$totalJurnal jurnal sudah tercatat',
                description:
                    'Total jurnal membantu melihat konsistensi dokumentasi pembelajaran guru di kelas.',
                badge: 'Jurnal',
              ),
              KepalaSekolahHighlight(
                title: '$avgAttendance rata-rata hadir',
                description:
                    'Rata-rata kehadiran per jurnal dapat dipakai untuk membaca stabilitas partisipasi siswa.',
                badge: 'Kehadiran',
              ),
              KepalaSekolahHighlight(
                title: '$sinkronMateri% sinkron dengan materi',
                description:
                    'Perbandingan jurnal dan materi memberi gambaran apakah aktivitas belajar sudah terdokumentasi seimbang.',
                badge: 'Sinkron',
              ),
              KepalaSekolahHighlight(
                title: '${navData.totalKelasJurnal} kelas tercatat di jurnal',
                description:
                    'Jumlah kelas yang muncul pada jurnal membantu melihat sebaran dokumentasi pembelajaran antar kelas.',
                badge: 'Kelas',
              ),
            ],
          ),
        ],
        detailSection: KepalaSekolahDetailSection(
          title: 'Data Sumber Jurnal',
          icon: Icons.receipt_long_rounded,
          searchHint: 'Cari judul, mapel, kelas, atau tanggal jurnal...',
          entries: journalEntries,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: KepsekBottomNav(
            currentIndex: 5,
            onTap: (index) => _onBottomNavTap(context, index),
          ),
        ),
      ),
    );
  }
}
