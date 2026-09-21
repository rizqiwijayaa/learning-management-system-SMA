import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kepala_sekolah/models/kepsek_nav_data.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/bottom_nav.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/kepala_sekolah_dashboard_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/humas/humas_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kesiswaan/kesiswaan_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kurikulum/kurikulum_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/absensi/absensi_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/widgets/kepala_sekolah_feature_page.dart';

class SarprasPage extends StatelessWidget {
  final int totalSarpras;
  final int sarprasRusak;
  final List<KepalaSekolahHighlight> highlights;
  final KepsekNavData navData;

  const SarprasPage({
    super.key,
    required this.totalSarpras,
    required this.sarprasRusak,
    required this.highlights,
    required this.navData,
  });

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 3) return;

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
    final sarprasAman = navData.sarprasAman;
    final persentaseRusak = navData.sarprasDamagePercentage;
    final highlightItems = highlights.isEmpty
        ? const [
            KepalaSekolahHighlight(
              title: 'Belum ada catatan sarpras terbaru',
              description: 'Update fasilitas dan kondisi sarpras akan muncul di panel ini.',
              badge: 'Kosong',
            ),
          ]
        : highlights;
    final sarprasEntries = navData.sarprasRecords
        .map(
          (item) => KepalaSekolahDetailEntry(
            title: item.itemName,
            subtitle: '${item.category} - ${item.location}',
            badge: item.itemCondition,
            fields: [
              KepalaSekolahDetailField(label: 'Kategori', value: item.category),
              KepalaSekolahDetailField(label: 'Lokasi', value: item.location),
              KepalaSekolahDetailField(label: 'Jumlah', value: '${item.quantity}'),
              KepalaSekolahDetailField(label: 'Kondisi', value: item.itemCondition),
            ],
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: KepalaSekolahFeaturePage(
        title: 'Sarpras',
        subtitle: 'Monitoring fasilitas dan sarana prasarana sekolah.',
        icon: Icons.inventory_2_rounded,
        accentColor: const Color(0xFFFF8A00),
        metrics: [
          KepalaSekolahMetric(
            label: 'Total Sarpras',
            value: '$totalSarpras',
            note: 'Inventaris tersedia',
          ),
          KepalaSekolahMetric(
            label: 'Rusak',
            value: '$sarprasRusak',
            note: 'Perlu perbaikan',
          ),
          KepalaSekolahMetric(
            label: 'Fasilitas Aman',
            value: '$sarprasAman',
            note: 'Siap Digunakan',
          ),
          KepalaSekolahMetric(
            label: 'Tingkat Rusak',
            value: '$persentaseRusak%',
            note: 'Dari Total',
          ),
        ],
        highlights: highlightItems,
        focusItems: const [
          'Dahulukan fasilitas yang berdampak langsung ke pembelajaran.',
          'Pantau daftar kerusakan aktif.',
          'Pastikan pengadaan dan perawatan berjalan.',
        ],
        actionNotes: const [
          'Tinjau item rusak sebelum akhir pekan.',
          'Susun prioritas perbaikan ringan dan berat.',
        ],
        extraHighlightSections: [
          KepalaSekolahHighlightSection(
            title: 'Ringkasan Kondisi Fasilitas',
            icon: Icons.home_repair_service_rounded,
            items: [
              KepalaSekolahHighlight(
                title: '$totalSarpras fasilitas tercatat',
                description:
                    'Total aset sarpras menjadi dasar pemantauan inventaris dan kesiapan fasilitas sekolah.',
                badge: 'Inventaris',
              ),
              KepalaSekolahHighlight(
                title: '$sarprasRusak fasilitas butuh perbaikan',
                description:
                    'Daftar fasilitas rusak dapat dipakai untuk menyusun prioritas kerja teknis dan pengadaan.',
                badge: 'Perbaikan',
              ),
              KepalaSekolahHighlight(
                title: '$sarprasAman fasilitas siap dipakai',
                description:
                    'Fasilitas yang aman dan siap digunakan mendukung kelancaran kegiatan belajar mengajar.',
                badge: 'Siap Pakai',
              ),
              KepalaSekolahHighlight(
                title: '$persentaseRusak% tingkat kerusakan',
                description:
                    'Persentase kerusakan membantu melihat beban perawatan dan urgensi tindak lanjut sarpras.',
                badge: 'Persentase',
              ),
            ],
          ),
        ],
        detailSection: KepalaSekolahDetailSection(
          title: 'Data Sumber Sarpras',
          icon: Icons.inventory_rounded,
          searchHint: 'Cari nama barang, kategori, lokasi, atau kondisi...',
          entries: sarprasEntries,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: KepsekBottomNav(
            currentIndex: 3,
            onTap: (index) => _onBottomNavTap(context, index),
          ),
        ),
      ),
    );
  }
}
