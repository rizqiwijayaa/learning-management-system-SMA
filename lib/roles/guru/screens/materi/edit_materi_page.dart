import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_item.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';

class EditMateriPage extends StatefulWidget {
  final MateriItem item;

  const EditMateriPage({super.key, required this.item});

  @override
  State<EditMateriPage> createState() => _EditMateriPageState();
}

class _EditMateriPageState extends State<EditMateriPage> {
  final _formKey = GlobalKey<FormState>();
  final LmsApiService _api = LmsApiService();

  late final TextEditingController _titleController;
  late final TextEditingController _uploadDateController;
  late final TextEditingController _summaryController;
  late final TextEditingController _contentController;
  late String _selectedSubject;
  bool _saving = false;
  List<String> _subjects = const [
    'Matematika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'IPA',
    'IPS',
    'PKN',
  ];
  late List<MateriAttachment> _attachments;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _selectedSubject = widget.item.subject;
    _uploadDateController = TextEditingController(text: widget.item.uploadDate);
    _summaryController = TextEditingController(
      text: widget.item.description.isEmpty
          ? 'Materi ini membahas topik utama secara ringkas dan mudah dipahami siswa.'
          : widget.item.description,
    );
    _contentController = TextEditingController(
      text: widget.item.content,
    );
    _attachments = List<MateriAttachment>.from(widget.item.attachments);
    _loadSubjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _uploadDateController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
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

  Future<void> _pickUploadDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (selected == null) return;
    _uploadDateController.text = _formatDateId(selected);
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

  void _removeAttachment(MateriAttachment attachment) {
    setState(() {
      _attachments.remove(attachment);
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }

  String _typeLabel(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return 'FILE';
    return parts.last.toUpperCase();
  }

  Color _typeColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return const Color(0xFFEF4444);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFF59E0B);
      case 'mp4':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF2563EB);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
    });

    await ProfileStore.instance.ensureLoaded();
    final profile = ProfileStore.instance.profile;
    final draft = MateriItem(
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
      uploadDate: _uploadDateController.text.trim(),
      description: _summaryController.text.trim(),
      content: _contentController.text.trim(),
      attachments: _attachments,
    );

    try {
      final updated = await _api.updateMateri(draft);
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal simpan perubahan materi: $e',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    final compact = !kIsWeb && MediaQuery.of(context).size.width < 980;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 16 : 12,
            vertical: 12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _EditHeader(),
                  const SizedBox(height: 18),
                  compact
                      ? Column(
                          children: [
                            _buildFormPanel(compact),
                            const SizedBox(height: 18),
                            _buildAttachmentPanel(compact),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _buildFormPanel(compact)),
                            const SizedBox(width: 20),
                            Expanded(flex: 5, child: _buildAttachmentPanel(compact)),
                          ],
                        ),
                  const SizedBox(height: 18),
                  compact
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Batal'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF20356B),
                                  side: const BorderSide(color: Color(0xFFD7E1F5)),
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: const Icon(Icons.save_outlined),
                                label: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E61F3),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Batal'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF20356B),
                                  side: const BorderSide(color: Color(0xFFD7E1F5)),
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: const Icon(Icons.save_outlined),
                                label: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E61F3),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormPanel(bool compact) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.edit_note_rounded,
              title: 'Informasi Materi',
            ),
            const SizedBox(height: 20),
            _Label('Judul Materi *'),
            const _Hint('Masukkan judul materi yang akan ditampilkan kepada siswa.'),
            const SizedBox(height: 8),
            _CounterInput(
              controller: _titleController,
              maxLength: 100,
              child: TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Judul wajib diisi'
                    : null,
              ),
            ),
            const SizedBox(height: 18),
            _Label('Mapel *'),
            const _Hint('Pilih mata pelajaran yang sesuai.'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _subjects.contains(_selectedSubject) ? _selectedSubject : null,
              items: _subjects
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedSubject = value);
              },
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 18),
            _Label('Tanggal Upload *'),
            const _Hint('Tanggal materi diunggah ke sistem.'),
            const SizedBox(height: 8),
            SizedBox(
              width: compact ? double.infinity : 290,
              child: TextFormField(
                controller: _uploadDateController,
                readOnly: true,
                onTap: _pickUploadDate,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Tanggal wajib diisi'
                    : null,
                decoration: _inputDecoration().copyWith(
                  suffixIcon: const Icon(Icons.calendar_today_rounded),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _Label('Deskripsi Singkat *'),
            const _Hint('Jelaskan secara singkat tentang materi ini.'),
            const SizedBox(height: 8),
            _CounterInput(
              controller: _summaryController,
              maxLength: 500,
              child: TextFormField(
                controller: _summaryController,
                maxLines: 4,
                decoration: _inputDecoration(),
              ),
            ),
            const SizedBox(height: 18),
            const _Label('Konten Materi (Opsional)'),
            const _Hint('Tambahkan konten atau ringkasan materi (opsional).'),
            const SizedBox(height: 8),
            _CounterInput(
              controller: _contentController,
              maxLength: 2000,
              child: TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: _inputDecoration(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPanel(bool compact) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.attach_file_rounded,
            title: 'Lampiran Materi',
          ),
          const SizedBox(height: 8),
          const _Hint('Kelola file pendukung untuk materi ini.'),
          const SizedBox(height: 18),
          InkWell(
            onTap: _pickAttachments,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFEFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD8E2F5)),
              ),
              child: compact
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFF2E61F3),
                          size: 34,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Klik untuk upload',
                          style: TextStyle(
                            color: Color(0xFF2E61F3),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Maks. ukuran 50MB per file',
                          style: TextStyle(
                            color: Color(0xFF6E80A8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFF2E61F3),
                          size: 34,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Klik untuk upload',
                                style: TextStyle(
                                  color: Color(0xFF2E61F3),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Maks. ukuran 50MB per file',
                                style: TextStyle(
                                  color: Color(0xFF6E80A8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'File Terlampir (${_attachments.length})',
            style: const TextStyle(
              color: Color(0xFF1E3161),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (_attachments.isEmpty)
            const Text(
              'Belum ada lampiran materi.',
              style: TextStyle(
                color: Color(0xFF7A89AB),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ..._attachments.map(
              (attachment) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE4EAF7)),
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _typeColor(attachment.name),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    _typeLabel(attachment.name),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attachment.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF2D3F6F),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatBytes(attachment.sizeBytes),
                                      style: const TextStyle(
                                        color: Color(0xFF7A89AB),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: () => _removeAttachment(attachment),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFD64A4A),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 42,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _typeColor(attachment.name),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _typeLabel(attachment.name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attachment.name,
                                  style: const TextStyle(
                                    color: Color(0xFF2D3F6F),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatBytes(attachment.sizeBytes),
                                  style: const TextStyle(
                                    color: Color(0xFF7A89AB),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeAttachment(attachment),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFD64A4A),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF3E6EFF),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ukuran maksimal 50MB per file.',
                  style: TextStyle(
                    color: Color(0xFF6E80A8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: const Color(0xFFFBFCFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD8E2F5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2E61F3)),
    ),
  );
}

class _EditHeader extends StatelessWidget {
  const _EditHeader();

  @override
  Widget build(BuildContext context) {
    final compact = !kIsWeb && MediaQuery.of(context).size.width < 420;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: compact ? 148 : 128,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2F61F4), Color(0xFF1547DA)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(18),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Edit Materi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 22 : 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Perbarui informasi materi yang akan dibagikan kepada siswa.',
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFE2EBFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'R',
                  style: TextStyle(
                    color: Color(0xFF2F61F4),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E61F3), size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1E3161),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF20356B),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6E80A8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CounterInput extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;
  final Widget child;

  const _CounterInput({
    required this.controller,
    required this.maxLength,
    required this.child,
  });

  @override
  State<_CounterInput> createState() => _CounterInputState();
}

class _CounterInputState extends State<_CounterInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.controller.text.characters.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        widget.child,
        const SizedBox(height: 6),
        Text(
          '$count / ${widget.maxLength}',
          style: const TextStyle(
            color: Color(0xFF6E80A8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
