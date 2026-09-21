import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kepala_sekolah/models/kepsek_nav_data.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/bottom_nav.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/kepala_sekolah_dashboard_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kesiswaan/kesiswaan_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/kurikulum/kurikulum_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/sarpras/sarpras_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/absensi/absensi_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/widgets/kepala_sekolah_feature_page.dart';

class HumasPage extends StatelessWidget {
  final List<KepalaSekolahHighlight> highlights;
  final KepsekNavData navData;

  const HumasPage({
    super.key,
    required this.highlights,
    required this.navData,
  });

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 4) return;

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
    final agendaAktif = navData.totalHumasAgenda;
    final mitraAktif = navData.humasPartnerCount;
    final kegiatanTerjadwal = navData.humasScheduledCount;
    final statusLain = navData.humasOtherStatusCount;
    final highlightItems = highlights.isEmpty
        ? const [
            KepalaSekolahHighlight(
              title: 'Belum ada agenda humas terbaru',
              description: 'Kegiatan eksternal, publikasi, dan kolaborasi akan tampil di panel ini.',
              badge: 'Kosong',
            ),
          ]
        : highlights;
    final humasEntries = navData.humasRecords
        .map(
          (item) => KepalaSekolahDetailEntry(
            title: item.title,
            subtitle: '${item.scheduleDate} - ${item.location}',
            badge: item.status,
            fields: [
              KepalaSekolahDetailField(label: 'Kategori', value: item.category),
              KepalaSekolahDetailField(label: 'Mitra', value: item.partner),
              KepalaSekolahDetailField(label: 'Lokasi', value: item.location),
              KepalaSekolahDetailField(label: 'Jadwal', value: item.scheduleDate),
              KepalaSekolahDetailField(label: 'Status', value: item.status),
              KepalaSekolahDetailField(label: 'Deskripsi', value: item.description),
            ],
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: KepalaSekolahFeaturePage(
        title: 'Humas',
        subtitle: 'Hubungan masyarakat dan kegiatan eksternal sekolah.',
        icon: Icons.campaign_rounded,
        accentColor: const Color(0xFF8B52E8),
        metrics: [
          KepalaSekolahMetric(
            label: 'Agenda',
            value: '$agendaAktif',
            note: 'Kegiatan aktif',
          ),
          KepalaSekolahMetric(
            label: 'Mitra',
            value: '$mitraAktif',
            note: 'Relasi berjalan',
          ),
          KepalaSekolahMetric(
            label: 'Terjadwal',
            value: '$kegiatanTerjadwal',
            note: 'Siap dijalankan',
          ),
          KepalaSekolahMetric(
            label: 'Selesai/Status',
            value: '$statusLain',
            note: 'Perlu dipantau',
          ),
        ],
        highlights: highlightItems,
        focusItems: const [
          'Jaga komunikasi publik sekolah.',
          'Pantau agenda kolaborasi dan publikasi.',
          'Gunakan kegiatan sekolah untuk membangun citra positif.',
        ],
        actionNotes: const [
          'Pastikan dokumentasi agenda utama tersedia.',
          'Perbarui kalender humas bulanan.',
        ],
        extraHighlightSections: [
          KepalaSekolahHighlightSection(
            title: 'Ringkasan Agenda Humas',
            icon: Icons.diversity_3_rounded,
            items: [
              KepalaSekolahHighlight(
                title: '$agendaAktif agenda humas tercatat',
                description:
                    'Agenda yang tercatat membantu sekolah menjaga kontinuitas komunikasi dengan publik dan mitra.',
                badge: 'Agenda',
              ),
              KepalaSekolahHighlight(
                title: '$mitraAktif relasi aktif terpantau',
                description:
                    'Relasi aktif bisa menjadi indikator kerja sama eksternal yang masih berjalan dan perlu dirawat.',
                badge: 'Mitra',
              ),
              KepalaSekolahHighlight(
                title: '$kegiatanTerjadwal agenda berstatus terjadwal',
                description:
                    'Agenda terjadwal membantu kepala sekolah membaca kesiapan kegiatan humas yang akan berjalan.',
                badge: 'Terjadwal',
              ),
              KepalaSekolahHighlight(
                title: '$statusLain agenda di luar status terjadwal',
                description:
                    'Status agenda selain terjadwal membantu memantau progres kegiatan humas yang sudah berjalan atau selesai.',
                badge: 'Status',
              ),
            ],
          ),
        ],
        detailSection: KepalaSekolahDetailSection(
          title: 'Data Sumber Humas',
          icon: Icons.campaign_rounded,
          searchHint: 'Cari agenda, mitra, lokasi, atau status humas...',
          entries: humasEntries,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: KepsekBottomNav(
            currentIndex: 4,
            onTap: (index) => _onBottomNavTap(context, index),
          ),
        ),
      ),
    );
  }
}
