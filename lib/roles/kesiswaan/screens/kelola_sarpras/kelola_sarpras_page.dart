import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kesiswaan/models/sarpras_record.dart';
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

class KelolaSarprasPage extends StatefulWidget {
  const KelolaSarprasPage({super.key});

  @override
  State<KelolaSarprasPage> createState() => _KelolaSarprasPageState();
}

class _KelolaSarprasPageState extends State<KelolaSarprasPage> {
  static const List<String> _conditionOptions = [
    'Semua Kondisi',
    'Baik',
    'Rusak Ringan',
    'Rusak',
  ];

  final ProfileStore _profileStore = ProfileStore.instance;
  final LmsApiService _api = LmsApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<SarprasRecord> _items = [];

  bool _isLoading = false;
  String? _errorText;
  String _selectedCondition = 'Semua Kondisi';
  String _selectedCategory = 'Semua Kategori';

  @override
  void initState() {
    super.initState();
    _profileStore.addListener(_handleProfileChanged);
    _profileStore.ensureLoaded();
    _searchController.addListener(_handleSearchChanged);
    _loadSarpras();
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

  List<SarprasRecord> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.itemName.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      final matchesCondition = _selectedCondition == 'Semua Kondisi' ||
          item.itemCondition == _selectedCondition;
      final matchesCategory =
          _selectedCategory == 'Semua Kategori' || item.category == _selectedCategory;
      return matchesQuery && matchesCondition && matchesCategory;
    }).toList(growable: false);
  }

  int get _totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  int get _totalLocations =>
      _items.map((item) => item.location.trim()).where((item) => item.isNotEmpty).toSet().length;
  int get _damagedCount => _items
      .where((item) => item.itemCondition == 'Rusak' || item.itemCondition == 'Rusak Ringan')
      .length;
  int get _criticalCount =>
      _items.where((item) => item.itemCondition == 'Rusak').length;

  Future<void> _loadSarpras() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final items = await _api.getSarpras();
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
      setState(() {
        _errorText = '$error';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _showSarprasForm({SarprasRecord? item}) async {
    final result = await showDialog<SarprasRecord>(
      context: context,
      builder: (context) => _SarprasFormDialog(item: item),
    );

    if (result == null) return;

    try {
      if (item == null) {
        final created = await _api.createSarpras(result);
        if (!mounted) return;
        setState(() {
          _items.insert(0, created);
        });
      } else {
        final updated = await _api.updateSarpras(result);
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

  Future<void> _confirmDelete(SarprasRecord item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Sarpras'),
        content: Text('Hapus ${item.itemName} dari daftar sarpras?'),
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
      await _api.deleteSarpras(item.id);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((entry) => entry.id == item.id);
      });
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
                              'Kelola Sarpras',
                              style: TextStyle(
                                color: Color(0xFF1A2A61),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pantau inventaris, kondisi barang, dan lokasi sarana prasarana sekolah.',
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
                                onPressed: () => _showSarprasForm(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E61F3),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Tambah Sarpras'),
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
                          children: [
                            const Text(
                              'Kelola Sarpras',
                              style: TextStyle(
                                color: Color(0xFF1A2A61),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pantau inventaris, kondisi barang, dan lokasi sarana prasarana sekolah.',
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
                        onPressed: () => _showSarprasForm(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E61F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah Sarpras'),
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
                        title: 'Total Barang',
                        value: '$_totalQuantity',
                        note: 'Akumulasi seluruh inventaris',
                        icon: Icons.inventory_2_rounded,
                        iconColor: const Color(0xFF7C4DFF),
                        iconBackground: const Color(0xFFF1EAFF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Perlu Perbaikan',
                        value: '$_damagedCount',
                        note: 'Rusak ringan dan rusak',
                        icon: Icons.build_circle_rounded,
                        iconColor: const Color(0xFFF28A1B),
                        iconBackground: const Color(0xFFFFF3E6),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Rusak Berat',
                        value: '$_criticalCount',
                        note: 'Prioritas tindak lanjut',
                        icon: Icons.warning_amber_rounded,
                        iconColor: const Color(0xFFE84D67),
                        iconBackground: const Color(0xFFFFEDF1),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 310,
                        title: 'Lokasi Aktif',
                        value: '$_totalLocations',
                        note: 'Ruang/area terdata',
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFF1DB56B),
                        iconBackground: const Color(0xFFEAF8EF),
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
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: compact ? double.infinity : 320,
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
                                value: _selectedCondition,
                                items: _conditionOptions,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _selectedCondition = value);
                                },
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _loadSarpras,
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
                          _LoadErrorState(message: _errorText!, onRetry: _loadSarpras)
                        else if (filtered.isEmpty)
                          const _EmptyState()
                        else
                          _SarprasTable(
                            items: filtered,
                            onEdit: (item) => _showSarprasForm(item: item),
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
          colors: [Color(0xFF2E61F3), Color(0xFF2B45D7)],
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
                  innerColor: const Color(0xFF2953E3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Kelola Sarpras',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manajemen sarana prasarana kesiswaan',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Color(0xFFDDE5FF), fontWeight: FontWeight.w600),
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
                  'Kelola Sarpras',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Manajemen sarana prasarana kesiswaan',
                  style: TextStyle(color: Color(0xFFDDE5FF), fontWeight: FontWeight.w600),
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
                  innerColor: const Color(0xFF2953E3),
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
        hintText: 'Cari barang, kategori, atau lokasi...',
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
          borderSide: const BorderSide(color: Color(0xFF345DF4), width: 1.3),
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
          borderSide: const BorderSide(color: Color(0xFF345DF4), width: 1.3),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SarprasTable extends StatelessWidget {
  final List<SarprasRecord> items;
  final ValueChanged<SarprasRecord> onEdit;
  final ValueChanged<SarprasRecord> onDelete;

  const _SarprasTable({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFF)),
        columns: const [
          DataColumn(label: Text('Barang')),
          DataColumn(label: Text('Kategori')),
          DataColumn(label: Text('Kondisi')),
          DataColumn(label: Text('Lokasi')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  item.itemName,
                  style: const TextStyle(
                    color: Color(0xFF1A2A61),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DataCell(Text(item.category)),
              DataCell(_ConditionBadge(condition: item.itemCondition)),
              DataCell(Text(item.location)),
              DataCell(Text('${item.quantity}')),
              DataCell(
                Row(
                  children: [
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

class _ConditionBadge extends StatelessWidget {
  final String condition;

  const _ConditionBadge({required this.condition});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color color;
    switch (condition) {
      case 'Baik':
        bg = const Color(0xFFEAF8EF);
        color = const Color(0xFF1DB56B);
        break;
      case 'Rusak Ringan':
        bg = const Color(0xFFFFF3E6);
        color = const Color(0xFFF28A1B);
        break;
      default:
        bg = const Color(0xFFFFEDF1);
        color = const Color(0xFFE84D67);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
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
          color: danger ? const Color(0xFFFFEEF1) : const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: danger ? const Color(0xFFE84D67) : const Color(0xFF2E61F3),
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
            Icon(Icons.inventory_2_rounded, size: 42, color: Color(0xFF91A0C7)),
            SizedBox(height: 10),
            Text(
              'Data sarpras tidak ditemukan',
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

class _SarprasFormDialog extends StatefulWidget {
  final SarprasRecord? item;

  const _SarprasFormDialog({this.item});

  @override
  State<_SarprasFormDialog> createState() => _SarprasFormDialogState();
}

class _SarprasFormDialogState extends State<_SarprasFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _locationController;
  late final TextEditingController _quantityController;
  late String _condition;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.itemName ?? '');
    _categoryController = TextEditingController(text: widget.item?.category ?? '');
    _locationController = TextEditingController(text: widget.item?.location ?? '');
    _quantityController = TextEditingController(
      text: widget.item != null ? '${widget.item!.quantity}' : '1',
    );
    _condition = widget.item?.itemCondition ?? 'Baik';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(isEdit ? 'Edit Sarpras' : 'Tambah Sarpras'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormField(controller: _nameController, label: 'Nama Barang'),
                const SizedBox(height: 12),
                _FormField(controller: _categoryController, label: 'Kategori'),
                const SizedBox(height: 12),
                _FormField(controller: _locationController, label: 'Lokasi'),
                const SizedBox(height: 12),
                _FormField(
                  controller: _quantityController,
                  label: 'Jumlah',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _condition,
                  decoration: InputDecoration(
                    labelText: 'Kondisi',
                    filled: true,
                    fillColor: const Color(0xFFFDFEFF),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD9E2F7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E61F3)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Baik', child: Text('Baik')),
                    DropdownMenuItem(
                      value: 'Rusak Ringan',
                      child: Text('Rusak Ringan'),
                    ),
                    DropdownMenuItem(value: 'Rusak', child: Text('Rusak')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _condition = value);
                  },
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
            backgroundColor: const Color(0xFF2E61F3),
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) return;

    Navigator.of(context).pop(
      SarprasRecord(
        id: widget.item?.id ?? 0,
        itemName: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        itemCondition: _condition,
        location: _locationController.text.trim(),
        quantity: quantity,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
          borderSide: const BorderSide(color: Color(0xFF2E61F3)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        if (label == 'Jumlah') {
          final quantity = int.tryParse(value.trim());
          if (quantity == null || quantity <= 0) {
            return 'Jumlah harus lebih dari 0';
          }
        }
        return null;
      },
    );
  }
}
