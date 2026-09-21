import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lms_guru/roles/guru/models/journal_entry.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';

class BuatJurnalPage extends StatefulWidget {
  final JournalEntry? initialEntry;

  const BuatJurnalPage({super.key, this.initialEntry});

  @override
  State<BuatJurnalPage> createState() => _BuatJurnalPageState();
}

class _BuatJurnalPageState extends State<BuatJurnalPage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _ringkasanController = TextEditingController();
  final TextEditingController _poin1Controller = TextEditingController();
  final TextEditingController _poin2Controller = TextEditingController();
  final TextEditingController _catatan1Controller = TextEditingController();
  final TextEditingController _catatan2Controller = TextEditingController();
  final TextEditingController _progressController = TextEditingController();
  final TextEditingController _tugasController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _hadirController = TextEditingController(
    text: '28',
  );

  final List<String> _subjects = const [
    'Matematika',
    'Fisika',
    'Biologi',
    'Bahasa Inggris',
  ];
  final List<String> _classes = const ['X IPA 1', 'X IPA 2', 'X IPA 3'];
  String _selectedSubject = 'Matematika';
  String _selectedClass = 'X IPA 1';
  DateTime _selectedDate = DateTime(2026, 3, 26);
  Uint8List? _selectedImageBytes;

  bool get _isEditMode => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    if (entry != null) {
      _judulController.text = entry.title;
      _ringkasanController.text = entry.materialSummary;
      if (entry.learningPoints.isNotEmpty) {
        _poin1Controller.text = entry.learningPoints.first;
      }
      if (entry.learningPoints.length > 1) {
        _poin2Controller.text = entry.learningPoints[1];
      }
      if (entry.summaryParagraphs.isNotEmpty) {
        _catatan1Controller.text = entry.summaryParagraphs.first;
      }
      if (entry.summaryParagraphs.length > 1) {
        _catatan2Controller.text = entry.summaryParagraphs[1];
      }
      _progressController.text = entry.progressNote;
      _tugasController.text = entry.taskTitle;
      _deadlineController.text = entry.taskDeadline;
      _hadirController.text = entry.attendanceCount.toString();
      _selectedSubject = entry.subject;
      _selectedClass = entry.className;
      _selectedDate = _parseDate(entry.dateLabel);
      _selectedImageBytes = entry.imageBytes;
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _ringkasanController.dispose();
    _poin1Controller.dispose();
    _poin2Controller.dispose();
    _catatan1Controller.dispose();
    _catatan2Controller.dispose();
    _progressController.dispose();
    _tugasController.dispose();
    _deadlineController.dispose();
    _hadirController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
      initialDate: _selectedDate,
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
  }

  String _formatDate(DateTime value) {
    const months = [
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
    return '${value.day} ${months[value.month]} ${value.year}';
  }

  DateTime _parseDate(String raw) {
    final parts = raw.split(' ');
    if (parts.length != 3) return _selectedDate;
    const months = {
      'Januari': 1,
      'Februari': 2,
      'Maret': 3,
      'April': 4,
      'Mei': 5,
      'Juni': 6,
      'Juli': 7,
      'Agustus': 8,
      'September': 9,
      'Oktober': 10,
      'November': 11,
      'Desember': 12,
    };
    final day = int.tryParse(parts[0]);
    final month = months[parts[1]];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return _selectedDate;
    return DateTime(year, month, day);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;
    setState(() {
      _selectedImageBytes = bytes;
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  void _save() {
    if (_judulController.text.trim().isEmpty ||
        _ringkasanController.text.trim().isEmpty ||
        _tugasController.text.trim().isEmpty) {
      return;
    }

    final title = _judulController.text.trim();
    final summary = _ringkasanController.text.trim();
    final attendance = int.tryParse(_hadirController.text.trim()) ?? 0;
    final learningPoints = [
      if (_poin1Controller.text.trim().isNotEmpty) _poin1Controller.text.trim(),
      if (_poin2Controller.text.trim().isNotEmpty) _poin2Controller.text.trim(),
    ];
    final notes = [
      if (_catatan1Controller.text.trim().isNotEmpty)
        _catatan1Controller.text.trim(),
      if (_catatan2Controller.text.trim().isNotEmpty)
        _catatan2Controller.text.trim(),
    ];

    final profile = ProfileStore.instance.profile;
    final draft = JournalEntry(
      teacherId: widget.initialEntry?.teacherId ?? profile?.id,
      teacherNip: widget.initialEntry?.teacherNip.isNotEmpty == true
          ? widget.initialEntry!.teacherNip
          : (profile?.nip ?? ''),
      teacherName: widget.initialEntry?.teacherName.isNotEmpty == true
          ? widget.initialEntry!.teacherName
          : (profile?.name ?? ''),
      dateLabel: _formatDate(_selectedDate),
      subject: _selectedSubject,
      title: title,
      materialSummary: summary,
      className: _selectedClass,
      attendanceCount: attendance,
      accentColor: widget.initialEntry?.accentColor ?? const Color(0xFF4D7CFF),
      learningPoints: learningPoints.isEmpty ? [summary] : learningPoints,
      summaryParagraphs: notes.isEmpty ? [summary] : notes,
      progressTitle: 'Progress Pembelajaran',
      progressNote: _progressController.text.trim().isEmpty
          ? 'Materi hari ini sudah disampaikan dengan baik.'
          : _progressController.text.trim(),
      taskTitle: _tugasController.text.trim(),
      taskDeadline: _deadlineController.text.trim().isEmpty
          ? 'Besok'
          : _deadlineController.text.trim(),
      imageBytes: _selectedImageBytes,
    );

    Navigator.of(context).pop(
      widget.initialEntry == null
          ? draft
          : widget.initialEntry!.copyWith(
              dateLabel: draft.dateLabel,
              subject: draft.subject,
              title: draft.title,
              materialSummary: draft.materialSummary,
              className: draft.className,
              attendanceCount: draft.attendanceCount,
              accentColor: draft.accentColor,
              learningPoints: draft.learningPoints,
              summaryParagraphs: draft.summaryParagraphs,
              progressTitle: draft.progressTitle,
              progressNote: draft.progressNote,
              taskTitle: draft.taskTitle,
              taskDeadline: draft.taskDeadline,
              imageBytes: draft.imageBytes,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(isEditMode: _isEditMode),
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
              const _SectionTitle('Judul Jurnal'),
              const SizedBox(height: 8),
              _InputField(
                hintText: 'Contoh: Pembelajaran Persamaan Linear',
                controller: _judulController,
              ),
              const SizedBox(height: 12),
              const _SectionTitle('Mapel'),
              const SizedBox(height: 8),
              _DropdownField(
                value: _selectedSubject,
                items: _subjects,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedSubject = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Kelas'),
                        const SizedBox(height: 8),
                        _DropdownField(
                          value: _selectedClass,
                          items: _classes,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedClass = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Tanggal'),
                        const SizedBox(height: 8),
                        _DateField(
                          label: _formatDate(_selectedDate),
                          onTap: _pickDate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _SectionTitle('Ringkasan Materi'),
              const SizedBox(height: 8),
              _InputField(
                hintText: 'Penjelasan singkat materi pembelajaran',
                controller: _ringkasanController,
              ),
              const SizedBox(height: 12),
              const _SectionTitle('Poin Pembelajaran'),
              const SizedBox(height: 8),
              _InputField(hintText: 'Poin 1', controller: _poin1Controller),
              const SizedBox(height: 8),
              _InputField(hintText: 'Poin 2', controller: _poin2Controller),
              const SizedBox(height: 12),
              const _SectionTitle('Catatan Materi'),
              const SizedBox(height: 8),
              _MultilineField(
                hintText: 'Catatan ringkasan 1',
                controller: _catatan1Controller,
              ),
              const SizedBox(height: 8),
              _MultilineField(
                hintText: 'Catatan ringkasan 2',
                controller: _catatan2Controller,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Jumlah Hadir'),
                        const SizedBox(height: 8),
                        _InputField(
                          hintText: '28',
                          controller: _hadirController,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Deadline Tugas'),
                        const SizedBox(height: 8),
                        _InputField(
                          hintText: 'Besok',
                          controller: _deadlineController,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _SectionTitle('Progress Pembelajaran'),
              const SizedBox(height: 8),
              _MultilineField(
                hintText: 'Catatan progres pembelajaran',
                controller: _progressController,
              ),
              const SizedBox(height: 12),
              const _SectionTitle('Foto Materi / Progress'),
              const SizedBox(height: 8),
              _ImagePickerCard(
                imageBytes: _selectedImageBytes,
                onPick: _pickImage,
                onRemove: _removeImage,
                isEditMode: _isEditMode,
              ),
              const SizedBox(height: 12),
              const _SectionTitle('Tugas Hari Ini'),
              const SizedBox(height: 8),
              _MultilineField(
                hintText: 'Tuliskan tugas yang harus dikerjakan siswa',
                controller: _tugasController,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4DE8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isEditMode ? 'Simpan Perubahan' : 'Simpan Jurnal',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final body = kIsWeb
        ? SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: content,
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: content,
                ),
              ),
            ),
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(child: body),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isEditMode;

  const _Header({required this.isEditMode});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 170,
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
              left: -50,
              top: -35,
              child: _Bubble(size: 170, color: Color(0x1EFFFFFF)),
            ),
            const Positioned(
              right: -35,
              top: 35,
              child: _Bubble(size: 150, color: Color(0x1AFFFFFF)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _CurveClipper(),
                    child: Container(
                      height: 85,
                      color: const Color(0xFFF3F5FB),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEditMode ? 'Edit Jurnal' : 'Tambah Jurnal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditMode
                              ? 'Perbarui catatan kegiatan pembelajaran'
                              : 'Buat catatan kegiatan pembelajaran',
                          style: const TextStyle(
                            color: Color(0xFFC8D3FF),
                            fontSize: 14,
                          ),
                        ),
                      ],
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E2433),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;

  const _InputField({required this.hintText, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE3F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE3F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E4DE8), width: 1.2),
        ),
      ),
    );
  }
}

class _MultilineField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;

  const _MultilineField({required this.hintText, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE3F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE3F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E4DE8), width: 1.2),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE3F2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(14),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final Uint8List? imageBytes;
  final Future<void> Function() onPick;
  final VoidCallback onRemove;
  final bool isEditMode;

  const _ImagePickerCard({
    required this.imageBytes,
    required this.onPick,
    required this.onRemove,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE3F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD5DEFA)),
              ),
              child: Column(
                children: [
                  if (imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        imageBytes!,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Icon(
                    Icons.file_upload,
                    size: 34,
                    color: Color(0xFF2E4DE8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    imageBytes == null
                        ? 'Unggah Foto atau Klik di sini...'
                        : (isEditMode
                              ? 'Foto berhasil dipilih, klik untuk edit lagi'
                              : 'Foto berhasil dipilih'),
                    style: TextStyle(
                      color: imageBytes == null
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
          const SizedBox(height: 8),
          const Text(
            'Format gambar umum seperti JPG, JPEG, atau PNG.',
            style: TextStyle(
              color: Color(0xFF7E879F),
              fontSize: 15,
              height: 1.3,
            ),
          ),
          if (imageBytes != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: onRemove,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6A7694),
                    side: const BorderSide(color: Color(0xFFD6DDED)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Hapus Foto',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ],
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
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE3F2)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            const Icon(Icons.calendar_today_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final Color color;

  const _Bubble({required this.size, required this.color});

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

class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 52);
    path.quadraticBezierTo(size.width * 0.3, 24, size.width * 0.62, 46);
    path.quadraticBezierTo(size.width * 0.84, 60, size.width, 30);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
