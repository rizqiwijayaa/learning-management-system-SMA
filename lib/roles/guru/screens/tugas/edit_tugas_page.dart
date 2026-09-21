import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/models/tugas_item.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';

class EditTugasPage extends StatefulWidget {
  final TugasItem item;

  const EditTugasPage({super.key, required this.item});

  @override
  State<EditTugasPage> createState() => _EditTugasPageState();
}

class _EditTugasPageState extends State<EditTugasPage> {
  final _formKey = GlobalKey<FormState>();
  final LmsApiService _api = LmsApiService();

  late final TextEditingController _titleController;
  late final TextEditingController _dateController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _attachmentController;
  late String _selectedSubject;
  Uint8List? _selectedFileBytes;
  String _selectedFileMimeType = '';
  int _durationMinutes = 90;
  bool _saving = false;

  List<String> _subjects = const [
    'Matematika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'IPA',
    'IPS',
    'PKN',
  ];

  bool get _isUjian => widget.item.type == 'ujian';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _dateController = TextEditingController(text: widget.item.date);
    _descriptionController = TextEditingController(
      text: widget.item.description.isEmpty
          ? (_isUjian
                ? 'Pastikan siswa membaca petunjuk pengerjaan sebelum memulai ujian.'
                : 'Silakan kerjakan tugas sesuai instruksi dan kumpulkan sebelum deadline.')
          : widget.item.description,
    );
    _attachmentController = TextEditingController(
      text: widget.item.attachmentName.isEmpty
          ? (_isUjian ? 'Soal_Ujian.pdf' : 'Lampiran_Tugas.pdf')
          : widget.item.attachmentName,
    );
    _selectedSubject = _subjects.contains(widget.item.subject)
        ? widget.item.subject
        : _subjects.first;
    _selectedFileMimeType = widget.item.attachmentMimeType;
    _durationMinutes = widget.item.durationMinutes ?? 90;
    _loadSubjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (selected == null) return;
    _dateController.text = _formatDateId(selected);
    if (mounted) setState(() {});
  }

  String _formatDateId(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() {
      _attachmentController.text = file.name;
      _selectedFileBytes = file.bytes;
      _selectedFileMimeType = _guessMimeType(file.name);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
    });

    await ProfileStore.instance.ensureLoaded();
    final profile = ProfileStore.instance.profile;
    final draft = TugasItem(
      id: widget.item.id,
      teacherId: widget.item.teacherId ?? profile?.id,
      teacherNip: widget.item.teacherNip.isNotEmpty
          ? widget.item.teacherNip
          : (profile?.nip ?? ''),
      teacherName: widget.item.teacherName.isNotEmpty
          ? widget.item.teacherName
          : (profile?.name ?? ''),
      title: _titleController.text.trim(),
      subject: _selectedSubject,
      date: _dateController.text.trim(),
      type: widget.item.type,
      description: _descriptionController.text.trim(),
      attachmentName: _attachmentController.text.trim(),
      attachmentData: _selectedFileBytes == null
          ? widget.item.attachmentData
          : base64Encode(_selectedFileBytes!),
      attachmentMimeType: _selectedFileBytes == null
          ? widget.item.attachmentMimeType
          : _selectedFileMimeType,
      durationMinutes: _isUjian ? _durationMinutes : null,
    );

    try {
      final updated = await _api.updateAssignment(draft);
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Gagal simpan perubahan ${widget.item.type}: $e',
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

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _api.getSubjects();
      if (!mounted || subjects.isEmpty) return;
      setState(() {
        _subjects = subjects;
        if (!_subjects.contains(_selectedSubject)) {
          _selectedSubject = _subjects.first;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = kIsWeb;
    final compact = MediaQuery.of(context).size.width < 420;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EditHeader(
          isUjian: _isUjian,
          title: _titleController.text.trim(),
          subject: _selectedSubject,
          date: _dateController.text.trim(),
          durationMinutes: _durationMinutes,
        ),
        const SizedBox(height: 14),
        Form(
          key: _formKey,
          child: _isUjian
              ? _UjianFormLayout(
                  titleController: _titleController,
                  selectedSubject: _selectedSubject,
                  subjects: _subjects,
                  durationMinutes: _durationMinutes,
                  onDurationChanged: (value) {
                    setState(() {
                      _durationMinutes = value;
                    });
                  },
                  onSubjectChanged: (value) {
                    setState(() {
                      _selectedSubject = value ?? _selectedSubject;
                    });
                  },
                  dateController: _dateController,
                  onPickDate: _pickDate,
                  descriptionController: _descriptionController,
                  attachmentController: _attachmentController,
                  onPickAttachment: _pickAttachment,
                )
              : _TugasFormLayout(
                  titleController: _titleController,
                  selectedSubject: _selectedSubject,
                  subjects: _subjects,
                  dateController: _dateController,
                  onPickDate: _pickDate,
                  descriptionController: _descriptionController,
                  attachmentController: _attachmentController,
                  onPickAttachment: _pickAttachment,
                  onSubjectChanged: (value) {
                    setState(() {
                      _selectedSubject = value ?? _selectedSubject;
                    });
                  },
                ),
        ),
        const SizedBox(height: 14),
        _ActionBar(
          compact: compact,
          saving: _saving,
          isUjian: _isUjian,
          onCancel: () => Navigator.of(context).maybePop(),
          onSave: _save,
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

class _EditHeader extends StatelessWidget {
  final bool isUjian;
  final String title;
  final String subject;
  final String date;
  final int durationMinutes;

  const _EditHeader({
    required this.isUjian,
    required this.title,
    required this.subject,
    required this.date,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: isUjian ? (compact ? 214 : 188) : 150,
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
              child: _HeaderBubble(size: 182, color: Color(0x1EFFFFFF)),
            ),
            const Positioned(
              right: -44,
              top: 22,
              child: _HeaderBubble(size: 155, color: Color(0x1AFFFFFF)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _HeaderCurveClipper(),
                    child: Container(
                      height: isUjian ? 78 : 70,
                      color: const Color(0xFFF3F5FB),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(20),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isUjian ? 'Edit Ujian' : 'Edit Tugas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isUjian ? 28 : 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isUjian
                        ? (title.isEmpty ? 'Perbarui informasi ujian dan file soal siswa.' : title)
                        : 'Perbarui tugas pembelajaran yang akan dibagikan kepada siswa.',
                    maxLines: isUjian ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFDCE4FF),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isUjian) ...[
                    const SizedBox(height: 16),
                    _HeaderExamMeta(
                      subject: subject,
                      date: date,
                      durationMinutes: durationMinutes,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UjianFormLayout extends StatelessWidget {
  final TextEditingController titleController;
  final String selectedSubject;
  final List<String> subjects;
  final int durationMinutes;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<String?> onSubjectChanged;
  final TextEditingController dateController;
  final VoidCallback onPickDate;
  final TextEditingController descriptionController;
  final TextEditingController attachmentController;
  final VoidCallback onPickAttachment;

  const _UjianFormLayout({
    required this.titleController,
    required this.selectedSubject,
    required this.subjects,
    required this.durationMinutes,
    required this.onDurationChanged,
    required this.onSubjectChanged,
    required this.dateController,
    required this.onPickDate,
    required this.descriptionController,
    required this.attachmentController,
    required this.onPickAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = _fieldDecoration;

    return Column(
      children: [
        _SectionCard(
          title: 'Informasi Ujian',
          icon: Icons.edit_note_rounded,
          child: Column(
            children: [
              _FieldBlock(
                label: 'Judul Ujian',
                child: TextFormField(
                  controller: titleController,
                  decoration: decoration('Masukkan judul ujian'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul wajib diisi';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FieldBlock(
                label: 'Mata Pelajaran',
                child: DropdownButtonFormField<String>(
                  value: subjects.contains(selectedSubject) ? selectedSubject : subjects.first,
                  decoration: decoration('Pilih mata pelajaran'),
                  items: subjects
                      .map((subject) => DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          ))
                      .toList(),
                  onChanged: onSubjectChanged,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FieldBlock(
                      label: 'Tanggal Ujian',
                      child: TextFormField(
                        controller: dateController,
                        readOnly: true,
                        decoration: decoration('Pilih tanggal').copyWith(
                          suffixIcon: IconButton(
                            onPressed: onPickDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                          ),
                        ),
                        onTap: onPickDate,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldBlock(
                      label: 'Durasi',
                      child: DropdownButtonFormField<int>(
                        value: durationMinutes,
                        decoration: decoration('Durasi'),
                        items: const [30, 45, 60, 90, 120]
                            .map((minutes) => DropdownMenuItem(
                                  value: minutes,
                                  child: Text('$minutes menit'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) onDurationChanged(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'File Soal',
          icon: Icons.attach_file_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: attachmentController,
                          readOnly: true,
                          decoration: decoration('Pilih file soal'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Unggah file PDF, Word, atau presentasi untuk soal ujian.',
                          style: TextStyle(
                            color: Color(0xFF7282A7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPickAttachment,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Ganti File Soal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E61F3),
                    side: const BorderSide(color: Color(0xFFD9E3FB)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Instruksi Ujian',
          icon: Icons.menu_book_outlined,
          accent: const Color(0xFF22C55E),
          accentBackground: const Color(0xFFE8FAEF),
          child: TextFormField(
            controller: descriptionController,
            maxLines: 6,
            decoration: decoration('Tuliskan instruksi ujian untuk siswa'),
          ),
        ),
      ],
    );
  }
}

class _TugasFormLayout extends StatelessWidget {
  final TextEditingController titleController;
  final String selectedSubject;
  final List<String> subjects;
  final TextEditingController dateController;
  final VoidCallback onPickDate;
  final TextEditingController descriptionController;
  final TextEditingController attachmentController;
  final VoidCallback onPickAttachment;
  final ValueChanged<String?> onSubjectChanged;

  const _TugasFormLayout({
    required this.titleController,
    required this.selectedSubject,
    required this.subjects,
    required this.dateController,
    required this.onPickDate,
    required this.descriptionController,
    required this.attachmentController,
    required this.onPickAttachment,
    required this.onSubjectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = _fieldDecoration;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: titleController,
            decoration: decoration('Masukkan judul tugas'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Judul wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: subjects.contains(selectedSubject) ? selectedSubject : subjects.first,
            decoration: decoration('Pilih mata pelajaran'),
            items: subjects
                .map(
                  (subject) => DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  ),
                )
                .toList(),
            onChanged: onSubjectChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: dateController,
            readOnly: true,
            decoration: decoration('Pilih deadline').copyWith(
              suffixIcon: IconButton(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_today_outlined),
              ),
            ),
            onTap: onPickDate,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descriptionController,
            maxLines: 5,
            decoration: decoration('Tuliskan instruksi tugas'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: attachmentController,
            readOnly: true,
            decoration: decoration('Pilih file lampiran').copyWith(
              suffixIcon: IconButton(
                onPressed: onPickAttachment,
                icon: const Icon(Icons.attach_file_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool compact;
  final bool saving;
  final bool isUjian;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _ActionBar({
    required this.compact,
    required this.saving,
    required this.isUjian,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (isUjian && compact) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E4DE8),
                side: const BorderSide(color: Color(0xFF2E4DE8)),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _PrimaryActionButton(
              label: saving
                  ? 'Menyimpan...'
                  : (isUjian ? 'Simpan Ujian' : 'Simpan Perubahan'),
              onPressed: saving ? null : onSave,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E4DE8),
              side: const BorderSide(color: Color(0xFF2E4DE8)),
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PrimaryActionButton(
            label: saving
                ? 'Menyimpan...'
                : (isUjian ? 'Simpan Ujian' : 'Simpan Perubahan'),
            onPressed: saving ? null : onSave,
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF3B60FF), Color(0xFF2E4DE8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _HeaderExamMeta extends StatelessWidget {
  final String subject;
  final String date;
  final int durationMinutes;

  const _HeaderExamMeta({
    required this.subject,
    required this.date,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${subject.isEmpty ? 'Mapel belum dipilih' : subject} • ${date.isEmpty ? 'Tanggal belum dipilih' : date}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$durationMinutes mnt',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color accent;
  final Color accentBackground;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.accent = const Color(0xFF2E61F3),
    this.accentBackground = const Color(0xFFEBF2FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E3161),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldBlock({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E3161),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

InputDecoration _fieldDecoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD9E0EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD9E0EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4A69FF)),
      ),
    );

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
    path.moveTo(0, 42);
    path.quadraticBezierTo(size.width * 0.2, 56, size.width * 0.44, 44);
    path.quadraticBezierTo(size.width * 0.72, 28, size.width, 56);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
