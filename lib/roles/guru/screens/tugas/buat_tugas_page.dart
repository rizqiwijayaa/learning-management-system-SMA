import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:lms_guru/roles/guru/models/tugas_item.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';

class BuatTugasPage extends StatefulWidget {
  final String mode;

  const BuatTugasPage({super.key, this.mode = 'tugas'});

  @override
  State<BuatTugasPage> createState() => _BuatTugasPageState();
}

class _BuatTugasPageState extends State<BuatTugasPage> {
  final LmsApiService _api = LmsApiService();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  String? _selectedMapel;
  DateTime? _selectedDate;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  String? _selectedFileMimeType;
  int _selectedDuration = 90;
  bool _dragging = false;
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
    _linkController.dispose();
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

  String _dateLabel() {
    if (_selectedDate == null) {
      return 'Pilih Tanggal';
    }

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
    final d = _selectedDate!;
    return '${d.day} ${monthNames[d.month]} ${d.year}';
  }

  String get _headerTitle => widget.mode == 'ujian' ? 'Upload Ujian' : 'Buat Tugas';
  String get _headerSubtitle =>
      widget.mode == 'ujian' ? 'Unggah soal ujian untuk siswa' : 'Buat tugas pembelajaran';
  String get _dateText => widget.mode == 'ujian' ? 'Tanggal Ujian' : 'Deadline';
  String get _hintTitle => widget.mode == 'ujian'
      ? 'Ujian Akhir Semester Genap - Matematika'
      : 'Masukkan judul tugas...';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    setState(() {
      _selectedFileName = file.name;
      _selectedFileBytes = file.bytes;
      _selectedFileMimeType = _guessMimeType(file.name);
    });
  }

  Future<void> _handleDroppedFiles(List<dynamic> files) async {
    if (files.isEmpty) {
      return;
    }
    String fileName = 'file_terpilih';
    Uint8List? bytes;
    try {
      final dynamic firstFile = files.first;
      final dynamic rawName = firstFile.name;
      if (rawName != null && rawName.toString().isNotEmpty) {
        fileName = rawName.toString();
      }
      final dynamic rawBytes = await firstFile.readAsBytes();
      if (rawBytes is Uint8List) {
        bytes = rawBytes;
      } else if (rawBytes is List<int>) {
        bytes = Uint8List.fromList(rawBytes);
      }
    } catch (_) {}
    setState(() {
      _selectedFileName = fileName;
      _selectedFileBytes = bytes;
      _selectedFileMimeType = _guessMimeType(fileName);
      _dragging = false;
    });
  }

  String _guessMimeType(String name) {
    final extension = name.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _save() async {
    if (_judulController.text.trim().isEmpty || _selectedMapel == null || _selectedDate == null) {
      return;
    }

    await ProfileStore.instance.ensureLoaded();
    final profile = ProfileStore.instance.profile;
    final draft = TugasItem(
      teacherId: profile?.id,
      teacherNip: profile?.nip ?? '',
      teacherName: profile?.name ?? '',
      title: _judulController.text.trim(),
      subject: _selectedMapel!,
      date: _dateLabel(),
      type: widget.mode,
      description: _deskripsiController.text.trim(),
      attachmentName: _selectedFileName ?? '',
      attachmentData:
          _selectedFileBytes == null ? '' : base64Encode(_selectedFileBytes!),
      attachmentMimeType: _selectedFileMimeType ?? '',
      durationMinutes: widget.mode == 'ujian' ? _selectedDuration : null,
    );

    setState(() {
      _saving = true;
    });
    try {
      final created = await _api.createAssignment(draft);
      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Gagal simpan ${widget.mode}: $e',
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
        _BuatTugasHeader(title: _headerTitle, subtitle: _headerSubtitle),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E7F3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1021336C),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mode == 'ujian' ? 'Judul Ujian' : 'Judul',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2433),
                ),
              ),
              const SizedBox(height: 8),
              _InputField(
                hintText: _hintTitle,
                controller: _judulController,
              ),
              const SizedBox(height: 12),
              const Text(
                'Mapel',
                  style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2433),
                ),
              ),
              const SizedBox(height: 8),
              _MapelDropdown(
                value: _selectedMapel,
                items: _mapelList,
                onChanged: (value) {
                  setState(() {
                    _selectedMapel = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (widget.mode == 'ujian')
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dateText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2433),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DateField(
                            label: _dateLabel(),
                            onTap: _pickDate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Durasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2433),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DurationField(
                            value: _selectedDuration,
                            onChanged: (value) {
                              setState(() {
                                _selectedDuration = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                Text(
                  _dateText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2433),
                  ),
                ),
                const SizedBox(height: 8),
                _DateField(
                  label: _dateLabel(),
                  onTap: _pickDate,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.description, color: Color(0xFF2E4DE8), size: 22),
                  const SizedBox(width: 6),
                  Text(
                    widget.mode == 'ujian' ? 'Deskripsi (Opsional)' : 'Deskripsi',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2433),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _InputField(
                hintText: widget.mode == 'ujian'
                    ? 'Kerjakan semua soal dengan teliti. Waktu pengerjaan 90 menit.'
                    : 'Masukkan deskripsi atau instruksi tugas...',
                controller: _deskripsiController,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.attach_file, color: Color(0xFF2E4DE8), size: 22),
                  const SizedBox(width: 6),
                  Text(
                    widget.mode == 'ujian' ? 'File Soal Ujian' : 'Lampiran File',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2433),
                    ),
                  ),
                  if (widget.mode != 'ujian') ...[
                    const SizedBox(width: 6),
                    const Text(
                      '(Opsional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7A849E),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              DropTarget(
                onDragDone: (details) => _handleDroppedFiles(details.files),
                onDragEntered: (_) {
                  setState(() {
                    _dragging = true;
                  });
                },
                onDragExited: (_) {
                  setState(() {
                    _dragging = false;
                  });
                },
                child: InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: _dragging ? const Color(0xFFEAF0FF) : const Color(0xFFF5F8FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _dragging
                            ? const Color(0xFF5C78FF)
                            : const Color(0xFFD5DEFA),
                        width: _dragging ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.file_upload, size: 34, color: Color(0xFF2E4DE8)),
                        const SizedBox(height: 4),
                        Text(
                          _selectedFileName == null
                              ? (widget.mode == 'ujian'
                                    ? 'Pilih File Soal'
                                    : 'Unggah File atau Seret ke sini...')
                              : _selectedFileName!,
                          style: TextStyle(
                            color: _selectedFileName == null
                                ? const Color(0xFF53618A)
                                : const Color(0xFF2E4DE8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.mode == 'ujian'
                    ? 'PDF, DOC, atau gambar (Maks. 10MB)'
                    : 'Ukuran maksimal 20MB. Jenis file yang diizinkan: PDF, DOC, DOCX, PPT, PPTX.',
                style: const TextStyle(
                  color: Color(0xFF7E879F),
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              if (widget.mode == 'ujian') ...[
                const SizedBox(height: 12),
                const Text(
                  'Link Tambahan (Opsional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2433),
                  ),
                ),
                const SizedBox(height: 8),
                _InputField(
                  hintText: 'https://drive.google.com/soal-uas-mtk',
                  controller: _linkController,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF616A84),
                          side: const BorderSide(color: Color(0xFFD5DBEC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4768FF), Color(0xFF2E4DE8)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Text(
                            widget.mode == 'ujian' ? 'Upload Ujian' : 'Simpan',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: content,
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

class _BuatTugasHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BuatTugasHeader({required this.title, required this.subtitle});

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
            const Positioned(
              left: -56,
              top: -36,
              child: _HeaderBubble(size: 160, color: Color(0x1EFFFFFF)),
            ),
            const Positioned(
              right: -34,
              top: 18,
              child: _HeaderBubble(size: 130, color: Color(0x1AFFFFFF)),
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
                      child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFDCE4FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const ProfileAvatarButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final int maxLines;

  const _InputField({
    required this.hintText,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFA2ABC4), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFFAFBFE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

class _MapelDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _MapelDropdown({
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
                    style: const TextStyle(fontSize: 14, color: Color(0xFF2E3444)),
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
            const Icon(Icons.event, color: Color(0xFF4A66F2), size: 24),
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

class _DurationField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DurationField({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const values = [30, 45, 60, 90, 120];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6DDEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.expand_more, color: Color(0xFF8D97B3)),
          items: values
              .map(
                (minutes) => DropdownMenuItem<int>(
                  value: minutes,
                  child: Text(
                    '$minutes menit',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF2E3444)),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
