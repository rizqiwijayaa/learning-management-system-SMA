import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/guru_dashboard_page.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kesiswaan_dashboard_page.dart';
import 'package:lms_guru/roles/kepala_sekolah/screens/dashboard/kepala_sekolah_dashboard_page.dart';

class DashboardPage extends RoleHomePage {
  const DashboardPage({super.key});
}

class RoleHomePage extends StatelessWidget {
  const RoleHomePage({super.key});

  String _normalizeRole(String role) {
    return role.trim().toLowerCase();
  }

  bool _isKesiswaanRole(String role) => _normalizeRole(role) == 'kesiswaan';

  bool _isKepalaSekolahRole(String role) {
    final normalizedRole = _normalizeRole(role);
    return normalizedRole == 'kepala sekolah' ||
        normalizedRole == 'kepalasekolah' ||
        normalizedRole == 'kepala_sekolah';
  }

  @override
  Widget build(BuildContext context) {
    final store = ProfileStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final role = store.profile?.role ?? 'Guru';
        if (_isKepalaSekolahRole(role)) {
          return const KepalaSekolahDashboardPage();
        }
        if (_isKesiswaanRole(role)) {
          return const KesiswaanDashboardPage();
        }
        return const GuruDashboardPage();
      },
    );
  }
}
