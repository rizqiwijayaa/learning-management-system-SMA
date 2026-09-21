import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_item.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';

class BuatMateriPage extends StatefulWidget {
  const BuatMateriPage({super.key});

  @override
  State<BuatMateriPage> createState() => _BuatMateriPageState();
}

class _BuatMateriPageState extends State<BuatMateriPage> {
  final LmsApiService _api = LmsApiService();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _kontenController = TextEditingController();
  String? _selectedMapel;
  DateTime? _selectedDate;
  List<MateriAttachment> _attachments = const [];
  bool _saving = false;

  List<String> _mapelList = [
    'Matematika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'IPA',
    'IPS',
    'PKN',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMapel = _mapelList.first;
    _selectedDate = DateTime.now();
    _loadSubjects();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _kontenController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _api.getSubjects();
      if (!mounted || subjects.isEmpty) return;
      setState(() {
        _mapelList = subjects;
        if (_selectedMapel == null || !_mapelList.contains(_selectedMapel)) {
          _selectedMapel = _mapelList.first;
        }
      });
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: _selectedDate ?? now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Pilih Tanggal';
    const monthNames = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${d.day} ${monthNames[d.month]} ${d.year}';
  }

  String _guessMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'mp4':
        return 'video/mp4';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'ppt',
        'pptx',
        'doc',
        'docx',
        'mp4',
        'png',
        'jpg',
        'jpeg',
      ],
    );
    if (result == null || result.files.isEmpty) return;

    final picked = <MateriAttachment>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) continue;
      picked.add(
        MateriAttachment(
          name: file.name,
          mimeType: _guessMimeType(file.name),
          base64Data: base64Encode(bytes),
          sizeBytes: bytes.length,
        ),
      );
    }
    if (picked.isEmpty) return;

    setState(() {
      final merged = [..._attachments];
      for (final attachment in picked) {
        merged.removeWhere((item) => item.name == attachment.name);
        merged.add(attachment);
      }
      _attachments = merged;
    });
  }

  Future<void> _saveMateri() async {
    if (_judulController.text.trim().isEmpty ||
        _selectedMapel == null ||
        _selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Lengkapi judul, mapel, dan tanggal upload dulu.',
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.white,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      await ProfileStore.instance.ensureLoaded();
      final profile = ProfileStore.instance.profile;
      final created = await _api.createMateri(
        MateriItem(
          teacherId: profile?.id,
          teacherNip: profile?.nip ?? '',
          teacherName: profile?.name ?? '',
          title: _judulController.text.trim(),
          subject: _selectedMapel!,
          uploadDate: _formatDate(_selectedDate),
          description: _deskripsiController.text.trim(),
          content: _kontenController.text.trim(),
          attachments: _attachments,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Gagal simpan materi: $e',
                style: const TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.white,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWebLayout = kIsWeb;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E7F3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Judul Materi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _Field(
                controller: _judulController,
                hint: 'Masukkan judul materi...',
              ),
              const SizedBox(height: 12),
              const Text(
                'Mapel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _MapelField(
                value: _selectedMapel,
                items: _mapelList,
                onChanged: (v) => setState(() => _selectedMapel = v),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tanggal Upload',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _DateField(label: _formatDate(_selectedDate), onTap: _pickDate),
              const SizedBox(height: 12),
              const Text(
                'Deskripsi Singkat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _Field(
                controller: _deskripsiController,
                hint: 'Masukkan deskripsi materi...',
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              const Text(
                'Konten Materi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _Field(
                controller: _kontenController,
                hint: 'Masukkan konten materi...',
                maxLines: 6,
              ),
              const SizedBox(height: 12),
              const Text(
                'Lampiran Materi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickAttachments,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    _attachments.isEmpty
                        ? 'Pilih Lampiran'
                        : '${_attachments.length} file dipilih',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5E6680),
                          side: const BorderSide(color: Color(0xFFD8DEEF)),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A69FF), Color(0xFF2E4DE8)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveMateri,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text(
                            'Simpan',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 120,
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
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(18),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Buat Materi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA2ABC4), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFFAFBFE),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD6DDEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF5C78FF)),
        ),
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF2E3444)),
    );
  }
}

class _MapelField extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _MapelField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6DDEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: const Text(
            'Pilih Mapel',
            style: TextStyle(color: Color(0xFFA2ABC4), fontSize: 14),
          ),
          icon: const Icon(Icons.chevron_right, color: Color(0xFF8D97B3)),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2E3444),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD6DDEE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: Color(0xFF4A66F2), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: label == 'Pilih Tanggal'
                      ? const Color(0xFFA2ABC4)
                      : const Color(0xFF2E3444),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF8D97B3)),
          ],
        ),
      ),
    );
  }
}
