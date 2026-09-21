import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kesiswaan/models/humas_record.dart';
import 'package:lms_guru/roles/kesiswaan/screens/auth/login_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kesiswaan_dashboard_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_jurnal/kelola_jurnal_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/profile/profile_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/rekap_absensi/rekap_absensi_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/users/kelola_user_page.dart';
import 'package:lms_guru/roles/kesiswaan/services/lms_api_service.dart';
import 'package:lms_guru/roles/kesiswaan/state/profile_store.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/kesiswaan_bottom_nav_bar.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/profile_avatar_button.dart';

class KelolaHumasPage extends StatefulWidget {
  const KelolaHumasPage({super.key});

  @override
  State<KelolaHumasPage> createState() => _KelolaHumasPageState();
}

class _KelolaHumasPageState extends State<KelolaHumasPage> {
  static const List<String> _statusOptions = [
    'Semua Status',
    'Terjadwal',
    'Berjalan',
    'Selesai',
    'Dibatalkan',
  ];

  final ProfileStore _profileStore = ProfileStore.instance;
  final LmsApiService _api = LmsApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<HumasRecord> _items = [];

  bool _isLoading = false;
  String? _errorText;
  String _selectedCategory = 'Semua Kategori';
  String _selectedStatus = 'Semua Status';

  @override
  void initState() {
    super.initState();
    _profileStore.addListener(_handleProfileChanged);
    _profileStore.ensureLoaded();
    _searchController.addListener(_handleSearchChanged);
    _loadHumas();
  }

  @override
  void dispose() {
    _profileStore.removeListener(_handleProfileChanged);
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleProfileChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String get _name => (_profileStore.profile?.name.trim().isNotEmpty ?? false)
      ? _profileStore.profile!.name.trim()
      : 'Profil Kesiswaan';

  String get _role => (_profileStore.profile?.role.trim().isNotEmpty ?? false)
      ? _profileStore.profile!.role.trim()
      : 'Kesiswaan';

  String get _initial => _name.substring(0, 1).toUpperCase();
  Uint8List? get _avatarBytes => _profileStore.profile?.avatarBytes;

  List<String> get _categoryOptions => [
    'Semua Kategori',
    ..._items
        .map((item) => item.category.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  List<HumasRecord> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.partner.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.scheduleDate.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'Semua Kategori' || item.category == _selectedCategory;
      final matchesStatus =
          _selectedStatus == 'Semua Status' || item.status == _selectedStatus;
      return matchesQuery && matchesCategory && matchesStatus;
    }).toList(growable: false);
  }

  int get _totalAgenda => _items.length;
  int get _activeAgenda => _items
      .where((item) => item.status == 'Terjadwal' || item.status == 'Berjalan')
      .length;
  int get _partnerCount => _items
      .map((item) => item.partner.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .length;
  int get _doneAgenda => _items.where((item) => item.status == 'Selesai').length;

  Future<void> _loadHumas() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final items = await _api.getHumasRecords();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        if (!_categoryOptions.contains(_selectedCategory)) {
          _selectedCategory = 'Semua Kategori';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorText = '$error');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const KesiswaanDashboardPage()),
    );
  }

  void _openUsers() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KelolaUserPage()),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  void _logout() {
    _profileStore.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _openBottomNav(int index) {
    if (index == 2) return;
    if (index == 0) {
      _openDashboard();
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KelolaJurnalPage()),
      );
      return;
    }
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RekapAbsensiPage()),
      );
      return;
    }
    if (index == 4) {
      _openProfile();
      return;
    }
  }

  Future<void> _showMessageDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHumasDetail(HumasRecord item) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(item.title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kategori: ${item.category}'),
              const SizedBox(height: 8),
              Text('Mitra: ${item.partner}'),
              const SizedBox(height: 8),
              Text('Lokasi: ${item.location}'),
              const SizedBox(height: 8),
              Text('Tanggal: ${item.scheduleDate}'),
              const SizedBox(height: 8),
              Text('Status: ${item.status}'),
              const SizedBox(height: 12),
              Text(item.description.isEmpty ? '-' : item.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHumasForm({HumasRecord? item}) async {
    final result = await showDialog<HumasRecord>(
      context: context,
      builder: (context) => _HumasFormDialog(item: item),
    );

    if (result == null) return;

    try {
      if (item == null) {
        final created = await _api.createHumasRecord(result);
        if (!mounted) return;
        setState(() => _items.insert(0, created));
      } else {
        final updated = await _api.updateHumasRecord(result);
        if (!mounted) return;
        final index = _items.indexWhere((entry) => entry.id == updated.id);
        setState(() {
          if (index != -1) {
            _items[index] = updated;
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog('Simpan Gagal', '$error');
    }
  }

  Future<void> _confirmDelete(HumasRecord item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Agenda Humas'),
        content: Text('Hapus "${item.title}" dari daftar humas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE84D67),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.deleteHumasRecord(item.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((entry) => entry.id == item.id));
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog('Hapus Gagal', '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1120;
    final mobile = width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroHeader(
                    name: _name,
                    role: _role,
                    initial: _initial,
                    avatarBytes: _avatarBytes,
                    onBackTap: _openDashboard,
                    onProfileTap: _openProfile,
                    onLogoutTap: _logout,
                  ),
                  const SizedBox(height: 28),
                  mobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kelola Humas',
                              style: TextStyle(
                                color: Color(0xFF1A2A61),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Kelola agenda, kemitraan, publikasi, dan kegiatan humas sekolah.',
                              style: TextStyle(
                                color: Color(0xFF7D89AA),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showHumasForm(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE84D67),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Tambah Agenda'),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Kelola Humas',
                                    style: TextStyle(
                                      color: Color(0xFF1A2A61),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Kelola agenda, kemitraan, publikasi, dan kegiatan humas sekolah.',
                                    style: TextStyle(
                                      color: Color(0xFF7D89AA),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showHumasForm(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE84D67),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Tambah Agenda'),
                            ),
                          ],
                        ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Total Agenda',
                        value: '$_totalAgenda',
                        note: 'Seluruh agenda humas',
                        icon: Icons.event_note_rounded,
                        iconColor: const Color(0xFFE84D67),
                        iconBackground: const Color(0xFFFFEDF1),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Agenda Aktif',
                        value: '$_activeAgenda',
                        note: 'Terjadwal dan berjalan',
                        icon: Icons.schedule_rounded,
                        iconColor: const Color(0xFF2E61F3),
                        iconBackground: const Color(0xFFEAF0FF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Mitra Terlibat',
                        value: '$_partnerCount',
                        note: 'Relasi kolaborasi aktif',
                        icon: Icons.handshake_rounded,
                        iconColor: const Color(0xFF1DB56B),
                        iconBackground: const Color(0xFFEAF8EF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Agenda Selesai',
                        value: '$_doneAgenda',
                        note: 'Kegiatan terdokumentasi',
                        icon: Icons.task_alt_rounded,
                        iconColor: const Color(0xFF7C4DFF),
                        iconBackground: const Color(0xFFF1EAFF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE8ECF7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: compact ? double.infinity : 340,
                              child: _SearchField(controller: _searchController),
                            ),
                            SizedBox(
                              width: compact ? double.infinity : 220,
                              child: _FilterDropdown(
                                value: _selectedCategory,
                                items: _categoryOptions,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedCategory = value);
                                },
                              ),
                            ),
                            SizedBox(
                              width: compact ? double.infinity : 220,
                              child: _FilterDropdown(
                                value: _selectedStatus,
                                items: _statusOptions,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedStatus = value);
                                },
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _loadHumas,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Muat Ulang'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 56),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_errorText != null)
                          _LoadErrorState(message: _errorText!, onRetry: _loadHumas)
                        else if (filtered.isEmpty)
                          const _EmptyState()
                        else
                          _HumasTable(
                            items: filtered,
                            onView: _showHumasDetail,
                            onEdit: (item) => _showHumasForm(item: item),
                            onDelete: _confirmDelete,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: KesiswaanBottomNavBar(
            currentIndex: 2,
            onTap: _openBottomNav,
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String name;
  final String role;
  final String initial;
  final Uint8List? avatarBytes;
  final VoidCallback onBackTap;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  const _HeroHeader({
    required this.name,
    required this.role,
    required this.initial,
    required this.avatarBytes,
    required this.onBackTap,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20, vertical: compact ? 16 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE84D67), Color(0xFFC93E7A)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: compact ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBackTap,
                borderRadius: BorderRadius.circular(18),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(24),
                child: KesiswaanHeaderAvatar(
                  initial: initial,
                  avatarBytes: avatarBytes,
                  radius: 20,
                  outerColor: Colors.white,
                  innerColor: const Color(0xFFC93E7A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Kelola Humas',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manajemen agenda dan relasi humas',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Color(0xFFFFE3EB), fontWeight: FontWeight.w600),
          ),
        ],
      ) : Row(
        children: [
          InkWell(
            onTap: onBackTap,
            borderRadius: BorderRadius.circular(18),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Humas',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Manajemen agenda dan relasi humas',
                  style: TextStyle(color: Color(0xFFFFE3EB), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                KesiswaanHeaderAvatar(
                  initial: initial,
                  avatarBytes: avatarBytes,
                  radius: 18,
                  outerColor: Colors.white,
                  innerColor: const Color(0xFFC93E7A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _StatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9EEF9)),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF57668E),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1B2B68),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  note,
                  style: const TextStyle(
                    color: Color(0xFF8694B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Cari agenda, mitra, lokasi, atau tanggal...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCE5F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE84D67), width: 1.3),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCE5F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE84D67), width: 1.3),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
          .toList(growable: false),
    );
  }
}

class _HumasTable extends StatelessWidget {
  final List<HumasRecord> items;
  final ValueChanged<HumasRecord> onView;
  final ValueChanged<HumasRecord> onEdit;
  final ValueChanged<HumasRecord> onDelete;

  const _HumasTable({
    required this.items,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFFFF7FA)),
        columns: const [
          DataColumn(label: Text('Judul')),
          DataColumn(label: Text('Kategori')),
          DataColumn(label: Text('Mitra')),
          DataColumn(label: Text('Lokasi')),
          DataColumn(label: Text('Tanggal')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF1A2A61),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DataCell(Text(item.category)),
              DataCell(Text(item.partner)),
              DataCell(Text(item.location)),
              DataCell(Text(item.scheduleDate)),
              DataCell(_StatusBadge(status: item.status)),
              DataCell(
                Row(
                  children: [
                    _MiniAction(
                      icon: Icons.visibility_outlined,
                      onTap: () => onView(item),
                    ),
                    const SizedBox(width: 8),
                    _MiniAction(
                      icon: Icons.edit_outlined,
                      onTap: () => onEdit(item),
                    ),
                    const SizedBox(width: 8),
                    _MiniAction(
                      icon: Icons.delete_outline_rounded,
                      danger: true,
                      onTap: () => onDelete(item),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color color;
    switch (status) {
      case 'Berjalan':
        bg = const Color(0xFFEAF8EF);
        color = const Color(0xFF1DB56B);
        break;
      case 'Selesai':
        bg = const Color(0xFFEAF0FF);
        color = const Color(0xFF2E61F3);
        break;
      case 'Dibatalkan':
        bg = const Color(0xFFFFEDF1);
        color = const Color(0xFFE84D67);
        break;
      default:
        bg = const Color(0xFFFFF3E6);
        color = const Color(0xFFF28A1B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final bool danger;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFFFEEF1) : const Color(0xFFFFF0F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: danger ? const Color(0xFFE84D67) : const Color(0xFFC93E7A),
        ),
      ),
    );
  }
}

class _LoadErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _LoadErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB42318),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.campaign_rounded, size: 42, color: Color(0xFF91A0C7)),
            SizedBox(height: 10),
            Text(
              'Data humas tidak ditemukan',
              style: TextStyle(
                color: Color(0xFF5E6D94),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HumasFormDialog extends StatefulWidget {
  final HumasRecord? item;

  const _HumasFormDialog({this.item});

  @override
  State<_HumasFormDialog> createState() => _HumasFormDialogState();
}

class _HumasFormDialogState extends State<_HumasFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _partnerController;
  late final TextEditingController _locationController;
  late final TextEditingController _scheduleController;
  late final TextEditingController _descriptionController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _categoryController = TextEditingController(text: widget.item?.category ?? '');
    _partnerController = TextEditingController(text: widget.item?.partner ?? '');
    _locationController = TextEditingController(text: widget.item?.location ?? '');
    _scheduleController = TextEditingController(text: widget.item?.scheduleDate ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _status = widget.item?.status ?? 'Terjadwal';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _partnerController.dispose();
    _locationController.dispose();
    _scheduleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.item == null ? 'Tambah Agenda Humas' : 'Edit Agenda Humas'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormField(controller: _titleController, label: 'Judul Agenda'),
                const SizedBox(height: 12),
                _FormField(controller: _categoryController, label: 'Kategori'),
                const SizedBox(height: 12),
                _FormField(controller: _partnerController, label: 'Mitra/Relasi'),
                const SizedBox(height: 12),
                _FormField(controller: _locationController, label: 'Lokasi'),
                const SizedBox(height: 12),
                _FormField(controller: _scheduleController, label: 'Tanggal Kegiatan'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: _inputDecoration('Status'),
                  items: const [
                    DropdownMenuItem(value: 'Terjadwal', child: Text('Terjadwal')),
                    DropdownMenuItem(value: 'Berjalan', child: Text('Berjalan')),
                    DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                    DropdownMenuItem(value: 'Dibatalkan', child: Text('Dibatalkan')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: _inputDecoration('Deskripsi'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE84D67),
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFDFEFF),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD9E2F7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE84D67)),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      HumasRecord(
        id: widget.item?.id ?? 0,
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        partner: _partnerController.text.trim(),
        location: _locationController.text.trim(),
        scheduleDate: _scheduleController.text.trim(),
        status: _status,
        description: _descriptionController.text.trim(),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _FormField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFDFEFF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E2F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE84D67)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
    );
  }
}
