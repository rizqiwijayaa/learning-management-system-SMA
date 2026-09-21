import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lms_guru/roles/guru/models/user_profile.dart';
import 'package:lms_guru/roles/guru/screens/auth/login_page.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _role = 'Guru';
  String _email = '';
  String _phone = '';
  String _nip = '';
  Uint8List? _avatarBytes;
  bool _isEditing = false;
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _nipController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final LmsApiService _api = LmsApiService();
  final ProfileStore _profileStore = ProfileStore.instance;
  bool _isSaving = false;

  String get _initial {
    final currentName = _nameController.text.trim();
    if (currentName.isEmpty) return 'G';
    return currentName.substring(0, 1).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _name);
    _roleController = TextEditingController(text: _role);
    _nipController = TextEditingController(text: _nip);
    _emailController = TextEditingController(text: _email);
    _phoneController = TextEditingController(text: _phone);
    _profileStore.addListener(_handleProfileStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _profileStore.removeListener(_handleProfileStoreChanged);
    _nameController.dispose();
    _roleController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleProfileStoreChanged() {
    final profile = _profileStore.profile;
    if (!mounted || profile == null) return;

    if (_isEditing && !_isSaving) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyProfile(profile);
    });
  }

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first.bytes;
    if (picked == null) return;

    if (!mounted) return;
    setState(() {
      _avatarBytes = picked;
    });
  }

  Future<void> _loadProfile() async {
    try {
      await _profileStore.ensureLoaded(force: true);
      if (!mounted) return;
      final profile = _profileStore.profile;
      // Pembaruan UI akan ditangani secara otomatis oleh listener _handleProfileStoreChanged
      // sehingga pemanggilan _applyProfile di sini tidak lagi diperlukan dan mencegah error build.
    } catch (_) {}
  }

  void _applyProfile(UserProfile profile) {
    setState(() {
      _name = profile.name;
      _role = profile.role;
      _nip = profile.nip;
      _email = profile.email;
      _phone = profile.phone;
      _avatarBytes = profile.avatarBytes;
      _nameController.text = profile.name;
      _roleController.text = profile.role;
      _nipController.text = profile.nip;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
    });
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    final profile = _profileStore.profile;
    if (profile != null) {
      _applyProfile(profile);
    } else {
      _nameController.text = _name;
      _roleController.text = _role;
      _nipController.text = _nip;
      _emailController.text = _email;
      _phoneController.text = _phone;
    }
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveProfile() async {
    final current = _profileStore.profile;
    final nextProfile = UserProfile(
      id: current?.id ?? 1,
      name: _nameController.text.trim(),
      role: _roleController.text.trim(),
      nip: _nipController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      avatarBase64: _avatarBytes != null ? base64Encode(_avatarBytes!) : null,
    );

    if (nextProfile.name.isEmpty ||
        nextProfile.role.isEmpty ||
        nextProfile.nip.isEmpty ||
        nextProfile.email.isEmpty ||
        nextProfile.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua data profil wajib diisi.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final saved = await _profileStore.saveProfile(nextProfile);
      if (!mounted) return;

      // Setelah backend berhasil simpan, pakai nilai form yang baru saja
      // disimpan sebagai sumber tampilan langsung di halaman profil.
      final confirmedProfile = saved.copyWith(
        name: nextProfile.name,
        role: nextProfile.role,
        nip: nextProfile.nip,
        email: nextProfile.email,
        phone: nextProfile.phone,
        avatarBase64: nextProfile.avatarBase64,
      );

      _profileStore.setProfile(confirmedProfile);
      _applyProfile(confirmedProfile);

      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan.')),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _logout() {
    _profileStore.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWebLayout = kIsWeb;
    final compact = MediaQuery.of(context).size.width < 420;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileHeader(initial: _initial, avatarBytes: _avatarBytes),
        const SizedBox(height: 14),
        _ProfilePhotoCard(
          avatarBytes: _avatarBytes,
          initial: _initial,
          onPickPhoto: _pickProfilePhoto,
          showUploadButton: _isEditing,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E7F3)),
          ),
          child: Column(
            children: [
              _ProfileField(
                label: 'Nama',
                controller: _nameController,
                enabled: _isEditing,
              ),
              const SizedBox(height: 10),
              _ProfileField(
                label: 'Role',
                controller: _roleController,
                enabled: false,
              ),
              const SizedBox(height: 10),
              _ProfileField(
                label: 'NIP',
                controller: _nipController,
                enabled: false,
              ),
              const SizedBox(height: 10),
              _ProfileField(
                label: 'Email',
                controller: _emailController,
                enabled: false,
              ),
              const SizedBox(height: 10),
              _ProfileField(
                label: 'No. HP',
                controller: _phoneController,
                enabled: _isEditing,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A69FF), Color(0xFF2E4DE8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : (_isEditing ? _saveProfile : _startEditing),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
              ),
               child: Text(
                 _isSaving
                     ? 'Menyimpan...'
                     : (_isEditing ? 'Simpan Perubahan' : 'Edit Profil'),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                 style: const TextStyle(
                   fontWeight: FontWeight.w700,
                   fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        if (_isEditing) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: _isSaving ? null : _cancelEditing,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6A7491),
                side: const BorderSide(color: Color(0xFFD9DEEE)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _logout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text(
              'Log out',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDA4B63),
              side: const BorderSide(color: Color(0xFFF0B8C2)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(
        child: isWebLayout
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: content,
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: content,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String initial;
  final Uint8List? avatarBytes;

  const _ProfileHeader({required this.initial, required this.avatarBytes});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: compact ? 206 : 170,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2B3BFF), Color(0xFF2028D2)],
                ),
              ),
            ),
            const Positioned(
              left: -52,
              top: -36,
              child: _HeaderBubble(size: 170, color: Color(0x1EFFFFFF)),
            ),
            const Positioned(
              right: -48,
              top: 18,
              child: _HeaderBubble(size: 155, color: Color(0x1AFFFFFF)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _HeaderCurveClipper(),
                    child: Container(
                      height: 82,
                      color: const Color(0xFFF3F5FB),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Profil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 26 : 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Informasi akun dan data guru',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFE0E8FF),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ProfileAvatar(initial: initial, avatarBytes: avatarBytes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE4F4)),
      ),
      child: TextField(
        controller: controller,
        readOnly: !enabled,
        canRequestFocus: enabled,
        style: const TextStyle(
          color: Color(0xFF2A3040),
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF7A849E),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          isDense: true,
        ),
      ),
    );
  }
}

class _ProfilePhotoCard extends StatelessWidget {
  final Uint8List? avatarBytes;
  final String initial;
  final VoidCallback onPickPhoto;
  final bool showUploadButton;

  const _ProfilePhotoCard({
    required this.avatarBytes,
    required this.initial,
    required this.onPickPhoto,
    required this.showUploadButton,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E7F3)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ProfileAvatar(
                      initial: initial,
                      avatarBytes: avatarBytes,
                      radius: 34,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Foto Profil',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF54607A),
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (showUploadButton) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onPickPhoto,
                      icon: const Icon(Icons.upload, size: 16),
                      label: const Text('Upload'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E4DE8),
                        side: const BorderSide(color: Color(0xFFB8C6F2)),
                      ),
                    ),
                  ),
                ],
              ],
            )
          : Row(
              children: [
                _ProfileAvatar(
                  initial: initial,
                  avatarBytes: avatarBytes,
                  radius: 34,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Foto Profil',
                    style: TextStyle(
                      color: Color(0xFF54607A),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (showUploadButton)
                  OutlinedButton.icon(
                    onPressed: onPickPhoto,
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('Upload'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E4DE8),
                      side: const BorderSide(color: Color(0xFFB8C6F2)),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String initial;
  final Uint8List? avatarBytes;
  final double radius;

  const _ProfileAvatar({
    required this.initial,
    required this.avatarBytes,
    this.radius = 21,
  });

  @override
  Widget build(BuildContext context) {
    final innerRadius = radius - 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: innerRadius,
        backgroundColor: const Color(0xFF3554F2),
        backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes!) : null,
        child: avatarBytes == null
            ? Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: radius * 0.85,
                ),
              )
            : null,
      ),
    );
  }
}

class _HeaderBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _HeaderBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
          radius: 0.92,
        ),
      ),
    );
  }
}

class _HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 56);
    path.quadraticBezierTo(size.width * 0.32, 22, size.width * 0.65, 44);
    path.quadraticBezierTo(size.width * 0.9, 58, size.width, 32);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
