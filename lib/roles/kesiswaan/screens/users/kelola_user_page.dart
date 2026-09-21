import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lms_guru/roles/kesiswaan/screens/auth/login_page.dart';
import 'package:lms_guru/roles/kesiswaan/models/managed_user.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kelola_menu_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/dashboard/kesiswaan_dashboard_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/kelola_jurnal/kelola_jurnal_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/profile/profile_page.dart';
import 'package:lms_guru/roles/kesiswaan/screens/rekap_absensi/rekap_absensi_page.dart';
import 'package:lms_guru/roles/kesiswaan/services/lms_api_service.dart';
import 'package:lms_guru/roles/kesiswaan/state/profile_store.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/kesiswaan_bottom_nav_bar.dart';
import 'package:lms_guru/roles/kesiswaan/widgets/profile_avatar_button.dart';

class KelolaUserPage extends StatefulWidget {
  const KelolaUserPage({super.key});

  @override
  State<KelolaUserPage> createState() => _KelolaUserPageState();
}

class _KelolaUserPageState extends State<KelolaUserPage> {
  static const int _pageSize = 6;

  final ProfileStore _profileStore = ProfileStore.instance;
  final LmsApiService _api = LmsApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<ManagedUser> _users = [];

  String _selectedRole = 'Semua Role';
  String _selectedStatus = 'Semua Status';
  int _currentPage = 1;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _profileStore.addListener(_handleProfileChanged);
    _profileStore.ensureLoaded();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _currentPage = 1;
      });
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _profileStore.removeListener(_handleProfileChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleProfileChanged() {
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

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final users = await _api.getManagedUsers();
      if (!mounted) return;
      setState(() {
        _users
          ..clear()
          ..addAll(users);
        _currentPage = 1;
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

  List<ManagedUser> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return _users.where((user) {
      final matchQuery =
          query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
      final matchRole =
          _selectedRole == 'Semua Role' || user.role == _selectedRole;
      final matchStatus =
          _selectedStatus == 'Semua Status' || user.status == _selectedStatus;
      return matchQuery && matchRole && matchStatus;
    }).toList(growable: false);
  }

  List<ManagedUser> get _pagedUsers {
    final filtered = _filteredUsers;
    if (filtered.isEmpty) return const [];
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages {
    final total = (_filteredUsers.length / _pageSize).ceil();
    return total <= 0 ? 1 : total;
  }

  int get _totalUsers => _users.length;
  int get _activeTeachers =>
      _users.where((user) => user.role == 'Guru' && user.status == 'Aktif').length;
  int get _principalUsers =>
      _users.where((user) => user.role == 'Kepala Sekolah').length;
  int get _inactiveUsers =>
      _users.where((user) => user.status == 'Nonaktif').length;

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
  }

  void _backToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const KesiswaanDashboardPage()),
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
    if (index == 0 || index == 2) {
      if (index == 0) {
        _backToDashboard();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KelolaMenuPage()),
        );
      }
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

  Future<void> _showNewAccountInfo(ManagedUser user) {
    return _showMessageDialog(
      'Akun Berhasil Dibuat',
      'Akun ${user.role.toLowerCase()} untuk ${user.name} sudah dibuat.\n\n'
      'Login gunakan:\n'
      'Email: ${user.email}\n'
      'Password default: 123456\n\n'
      'Jika role-nya Guru, akun ini akan masuk ke tampilan role guru saat login.',
    );
  }

  Future<void> _showUserDetails(ManagedUser user) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Detail User'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Nama', value: user.name),
              _DetailRow(label: 'Username', value: user.username),
              _DetailRow(label: 'Email', value: user.email),
              _DetailRow(label: 'Role', value: user.role),
              _DetailRow(label: 'Status', value: user.status),
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

  Future<void> _showUserForm({ManagedUser? user}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name ?? '');
    final usernameController = TextEditingController(text: user?.username ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    String role = user?.role ?? 'Guru';
    String status = user?.status ?? 'Aktif';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(user == null ? 'Tambah User' : 'Edit User'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FormField(
                        controller: nameController,
                        label: 'Nama',
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: usernameController,
                        label: 'Username',
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        controller: emailController,
                        label: 'Email',
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Email wajib diisi';
                          if (!text.contains('@')) return 'Format email belum valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _FilterDropdown(
                        value: role,
                        items: const ['Guru', 'Kepala Sekolah', 'Kesiswaan'],
                        onChanged: (value) {
                          if (value == null) return;
                          setLocalState(() => role = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _FilterDropdown(
                        value: status,
                        items: const ['Aktif', 'Nonaktif'],
                        onChanged: (value) {
                          if (value == null) return;
                          setLocalState(() => status = value);
                        },
                      ),
                      if (user == null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F8FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD9E2F7)),
                          ),
                          child: const Text(
                            'Password default akun baru: 123456',
                            style: TextStyle(
                              color: Color(0xFF42517A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.of(dialogContext).pop(true);
                },
                child: Text(user == null ? 'Simpan' : 'Update'),
              ),
            ],
          ),
        );
      },
    );

    if (saved != true) return;

    try {
      if (user == null) {
        final created = await _api.createManagedUser(
          ManagedUser(
            id: 0,
            name: nameController.text.trim(),
            username: usernameController.text.trim(),
            email: emailController.text.trim(),
            role: role,
            status: status,
          ),
        );
        if (!mounted) return;
        setState(() {
          _users.insert(0, created);
          _currentPage = 1;
        });
        await _showNewAccountInfo(created);
      } else {
        final updated = await _api.updateManagedUser(
          user.copyWith(
            name: nameController.text.trim(),
            username: usernameController.text.trim(),
            email: emailController.text.trim(),
            role: role,
            status: status,
          ),
        );
        if (!mounted) return;
        final index = _users.indexWhere((item) => item.id == updated.id);
        setState(() {
          if (index != -1) {
            _users[index] = updated;
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog(
        'Simpan Gagal',
        '$error',
      );
    }
  }

  Future<void> _confirmDelete(ManagedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus User'),
        content: Text('Hapus akun ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE94F64),
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
      await _api.deleteManagedUser(user.id);
      if (!mounted) return;
      setState(() {
        _users.removeWhere((item) => item.id == user.id);
        if (_currentPage > _totalPages) {
          _currentPage = _totalPages;
        }
      });
    } catch (error) {
      if (!mounted) return;
      await _showMessageDialog(
        'Hapus Gagal',
        '$error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 900;
    final filtered = _filteredUsers;
    final paged = _pagedUsers;
    final start = filtered.isEmpty ? 0 : ((_currentPage - 1) * _pageSize) + 1;
    final end = filtered.isEmpty ? 0 : start + paged.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                children: [
                  _UserHeader(
                    name: _name,
                    role: _role,
                    initial: _initial,
                    avatarBytes: _avatarBytes,
                    onBackTap: _backToDashboard,
                    onProfileTap: _openProfile,
                    onLogoutTap: _logout,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatCard(
                        width: compact ? double.infinity : 330,
                        title: 'Total User',
                        value: '$_totalUsers',
                        note: 'Semua akun terdaftar',
                        icon: Icons.groups_rounded,
                        iconColor: const Color(0xFF2E61F3),
                        iconBackground: const Color(0xFFEBF1FF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 330,
                        title: 'Guru Aktif',
                        value: '$_activeTeachers',
                        note: 'Akun guru aktif',
                        icon: Icons.verified_user_rounded,
                        iconColor: const Color(0xFF19B66A),
                        iconBackground: const Color(0xFFEAF9F0),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 330,
                        title: 'Kepala Sekolah',
                        value: '$_principalUsers',
                        note: 'Akun kepala sekolah',
                        icon: Icons.person_rounded,
                        iconColor: const Color(0xFF7B4DFF),
                        iconBackground: const Color(0xFFF0EAFF),
                      ),
                      _StatCard(
                        width: compact ? double.infinity : 330,
                        title: 'Nonaktif',
                        value: '$_inactiveUsers',
                        note: 'Akun tidak aktif',
                        icon: Icons.not_interested_rounded,
                        iconColor: const Color(0xFFFF8A1F),
                        iconBackground: const Color(0xFFFFF1E3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE9EEF9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        width < 700
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kelola User',
                                    style: TextStyle(
                                      color: Color(0xFF1B2B68),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Kesiswaan  >  Kelola User',
                                    style: TextStyle(
                                      color: Color(0xFF7E8AAE),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _showUserForm,
                                      icon: const Icon(Icons.add_rounded, size: 18),
                                      label: const Text('Tambah User'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E61F3),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
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
                                        Text(
                                          'Kelola User',
                                          style: TextStyle(
                                            color: Color(0xFF1B2B68),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Kesiswaan  >  Kelola User',
                                          style: TextStyle(
                                            color: Color(0xFF7E8AAE),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _showUserForm,
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Tambah User'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E61F3),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: compact ? double.infinity : 420,
                              child: _SearchField(controller: _searchController),
                            ),
                            SizedBox(
                              width: compact ? double.infinity : 210,
                              child: _FilterDropdown(
                                value: _selectedRole,
                                items: const ['Semua Role', 'Guru', 'Kepala Sekolah', 'Kesiswaan'],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedRole = value;
                                    _currentPage = 1;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: compact ? double.infinity : 210,
                              child: _FilterDropdown(
                                value: _selectedStatus,
                                items: const ['Semua Status', 'Aktif', 'Nonaktif'],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedStatus = value;
                                    _currentPage = 1;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_errorText != null)
                          _LoadErrorState(
                            message: _errorText!,
                            onRetry: _loadUsers,
                          )
                        else if (paged.isEmpty)
                          const _EmptyState()
                        else
                          _UserTable(
                            users: paged,
                            startNumber: start,
                            onView: _showUserDetails,
                            onEdit: (user) => _showUserForm(user: user),
                            onDelete: _confirmDelete,
                          ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              filtered.isEmpty
                                  ? 'Belum ada data user'
                                  : 'Menampilkan $start - $end dari ${filtered.length} data',
                              style: const TextStyle(
                                color: Color(0xFF7080A8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            _PaginationButton(
                              icon: Icons.chevron_left_rounded,
                              enabled: _currentPage > 1,
                              onTap: () => _goToPage(_currentPage - 1),
                            ),
                            ...List.generate(
                              _totalPages,
                              (index) => _PaginationNumber(
                                label: '${index + 1}',
                                active: index + 1 == _currentPage,
                                onTap: () => _goToPage(index + 1),
                              ),
                            ),
                            _PaginationButton(
                              icon: Icons.chevron_right_rounded,
                              enabled: _currentPage < _totalPages,
                              onTap: () => _goToPage(_currentPage + 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: KesiswaanBottomNavBar(
          currentIndex: 2,
          onTap: _openBottomNav,
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field wajib diisi';
    }
    return null;
  }
}

class _UserHeader extends StatelessWidget {
  final String name;
  final String role;
  final String initial;
  final Uint8List? avatarBytes;
  final VoidCallback onBackTap;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  const _UserHeader({
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
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(compact ? 18 : 28, compact ? 16 : 18, compact ? 18 : 24, compact ? 18 : 26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2953E3), Color(0xFF1D39B9)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Material(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: onBackTap,
                            borderRadius: BorderRadius.circular(14),
                            child: const SizedBox(
                              width: 42,
                              height: 42,
                              child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                            ),
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
                      'Kelola User',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manajemen akun pengguna kesiswaan',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFFDDE5FF), fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Material(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: onBackTap,
                              borderRadius: BorderRadius.circular(14),
                              child: const SizedBox(
                                width: 42,
                                height: 42,
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kelola User',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Manajemen akun pengguna kesiswaan',
                                  style: TextStyle(
                                    color: Color(0xFFDDE5FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9EEF9)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF42517A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1B2B68),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: const TextStyle(
                    color: Color(0xFF7E8AAE),
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
        hintText: 'Cari nama, username, atau email...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E2F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E61F3)),
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
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E2F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E61F3)),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
          .toList(),
    );
  }
}

class _UserTable extends StatelessWidget {
  final List<ManagedUser> users;
  final int startNumber;
  final ValueChanged<ManagedUser> onView;
  final ValueChanged<ManagedUser> onEdit;
  final ValueChanged<ManagedUser> onDelete;

  const _UserTable({
    required this.users,
    required this.startNumber,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7EDFA)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FBFF)),
            columns: const [
              DataColumn(label: Text('No')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Username')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: users.asMap().entries.map((entry) {
              final number = startNumber + entry.key;
              final user = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text('$number')),
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: user.avatarBackground,
                          child: Text(
                            user.initials,
                            style: TextStyle(
                              color: user.avatarTextColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(user.name),
                      ],
                    ),
                  ),
                  DataCell(Text(user.username)),
                  DataCell(Text(user.email)),
                  DataCell(_RoleChip(role: user.role)),
                  DataCell(_StatusChip(status: user.status)),
                  DataCell(
                    Row(
                      children: [
                        _ActionIcon(
                          icon: Icons.visibility_outlined,
                          color: const Color(0xFF2E61F3),
                          background: const Color(0xFFEAF1FF),
                          onTap: () => onView(user),
                        ),
                        const SizedBox(width: 8),
                        _ActionIcon(
                          icon: Icons.edit_outlined,
                          color: const Color(0xFF2E61F3),
                          background: const Color(0xFFEAF1FF),
                          onTap: () => onEdit(user),
                        ),
                        const SizedBox(width: 8),
                        _ActionIcon(
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFE94F64),
                          background: const Color(0xFFFFEEF1),
                          onTap: () => onDelete(user),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final teacher = role == 'Guru';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: teacher ? const Color(0xFFEAF1FF) : const Color(0xFFF2EAFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: teacher ? const Color(0xFF2E61F3) : const Color(0xFF7B4DFF),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == 'Aktif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEAF9F0) : const Color(0xFFFFEEF1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: active ? const Color(0xFF19B66A) : const Color(0xFFE94F64),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8E2F7)),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF2B3C73) : const Color(0xFFB6C0DA),
        ),
      ),
    );
  }
}

class _PaginationNumber extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PaginationNumber({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2E61F3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF2E61F3) : const Color(0xFFD8E2F7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF2B3C73),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7E8AAE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1B2B68),
                fontWeight: FontWeight.w700,
              ),
            ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EDFA)),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_search_rounded, size: 42, color: Color(0xFF91A0C7)),
          SizedBox(height: 10),
          Text(
            'User tidak ditemukan',
            style: TextStyle(
              color: Color(0xFF5E6D94),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),
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

extension on ManagedUser {
  String get initials {
    final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.length < 2) return name.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color get avatarBackground {
    const palette = [
      Color(0xFFE8EEFF),
      Color(0xFFF1E9FF),
      Color(0xFFE7F8EE),
      Color(0xFFFFEEE6),
      Color(0xFFEFF7FF),
      Color(0xFFFFECF8),
    ];
    return palette[id % palette.length];
  }

  Color get avatarTextColor {
    const palette = [
      Color(0xFF3564F2),
      Color(0xFF7B4DFF),
      Color(0xFF18A860),
      Color(0xFFF97316),
      Color(0xFF0891B2),
      Color(0xFFDB2777),
    ];
    return palette[id % palette.length];
  }
}
