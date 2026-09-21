import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/absensi_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/jurnal_page.dart';
import 'package:lms_guru/roles/guru/screens/dashboard/nilai_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/edit_materi_page.dart';
import 'package:lms_guru/roles/guru/screens/materi/materi_item.dart';
import 'package:lms_guru/roles/guru/screens/tugas/tugas_page.dart';
import 'package:lms_guru/roles/guru/services/lms_api_service.dart';
import 'package:lms_guru/roles/guru/widgets/guru_bottom_nav_bar.dart';
import 'package:lms_guru/roles/guru/widgets/profile_avatar_button.dart';
import 'package:lms_guru/roles/role_home_page.dart';
import 'package:lms_guru/utils/file_download.dart';

class MateriDetailPage extends StatefulWidget {
  final MateriItem item;

  const MateriDetailPage({super.key, required this.item});

  @override
  State<MateriDetailPage> createState() => _MateriDetailPageState();
}

class _MateriDetailPageState extends State<MateriDetailPage> {
  int _currentTab = 1;
  late MateriItem _item;
  final LmsApiService _api = LmsApiService();
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  List<_AttachmentItem> get _attachments {
    return _item.attachments
        .map(
          (item) => _AttachmentItem(
            typeLabel: _extensionLabel(item.name),
            fileName: item.name,
            size: _formatBytes(item.sizeBytes),
            accent: _attachmentAccent(item.name),
            attachment: item,
          ),
        )
        .toList(growable: false);
  }

  String _extensionLabel(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return 'FILE';
    return parts.last.toUpperCase();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }

  Color _attachmentAccent(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return const Color(0xFFEF4F4F);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFFF9A3E);
      case 'mp4':
      case 'mov':
      case 'avi':
        return const Color(0xFF7A62FF);
      case 'doc':
      case 'docx':
        return const Color(0xFF2E61F3);
      default:
        return const Color(0xFF6F84B7);
    }
  }

  Future<void> _openEditMateri() async {
    final result = await Navigator.of(context).push<MateriItem>(
      MaterialPageRoute(builder: (_) => EditMateriPage(item: _item)),
    );
    if (result != null) {
      setState(() {
        _item = result;
      });
    }
  }

  Future<void> _deleteMateri() async {
    if (_item.id == null || _deleting) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Materi'),
        content: const Text('Yakin ingin menghapus materi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD83A3A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() {
      _deleting = true;
    });
    try {
      await _api.deleteMateri(_item.id!);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus materi: $e',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  Future<void> _downloadAttachment(_AttachmentItem attachment) async {
    if (!attachment.attachment.hasData) {
      _showAttachmentError('File download tidak tersedia.');
      return;
    }
    try {
      final savedPath = await downloadBase64File(
        fileName: attachment.attachment.name,
        base64Data: attachment.attachment.base64Data,
        mimeType: attachment.attachment.mimeType,
      );
      if (!mounted) return;
      _showAttachmentError(
        kIsWeb
            ? 'Download dimulai untuk ${attachment.attachment.name}.'
            : 'File tersimpan: $savedPath',
      );
    } catch (error) {
      _showAttachmentError('Download gagal: $error');
    }
  }

  void _showAttachmentError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (route) => false,
      );
      return;
    }

    if (index == 1) {
      Navigator.of(context).pop(_item);
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TugasPage()),
      );
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NilaiPage()),
      );
      return;
    }
    if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AbsensiPage()),
      );
      return;
    }
    if (index == 5) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const JurnalPage()),
      );
      return;
    }

    setState(() {
      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 980;
    final mobile = width < 680;
    final title = _item.title.trim().isEmpty ? 'Materi' : _item.title.trim();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroHeader(
          title: title,
          subject: _item.subject,
          onBack: () => Navigator.of(context).pop(_item),
        ),
        const SizedBox(height: 18),
        _SummaryCard(
          title: title,
          subject: _item.subject,
          uploadDate: _item.uploadDate,
          attachmentCount: _attachments.length,
          compact: compact,
          onEdit: _openEditMateri,
          onDelete: _deleteMateri,
          deleting: _deleting,
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Apa Itu Persamaan Linear?',
          icon: Icons.menu_book_rounded,
          text: _item.description.isEmpty
              ? 'Deskripsi materi belum diisi.'
              : _item.description,
          highlighted: true,
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Contoh Penyelesaian',
          icon: Icons.science_rounded,
          text: _item.content.isEmpty
              ? 'Isi konten materi belum diisi.'
              : _item.content,
          highlighted: true,
        ),
        const SizedBox(height: 18),
        _AttachmentSection(
          attachments: _attachments,
          mobile: mobile,
          onDownload: _downloadAttachment,
        ),
        const SizedBox(height: 18),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 18 : 12,
            vertical: 12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: content,
            ),
          ),
        ),
      ),
      bottomNavigationBar: kIsWeb
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: GuruBottomNavBar(
                  currentIndex: _currentTab,
                  onChanged: _onBottomNavTap,
                  includeNilai: true,
                  compact: true,
                  mobile: true,
                ),
              ),
            ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String title;
  final String subject;
  final VoidCallback onBack;

  const _HeroHeader({
    required this.title,
    required this.subject,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 146,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF2F61F4), Color(0xFF5D88FF)],
                ),
              ),
            ),
            const Positioned(
              right: 286,
              top: 18,
              child: _SoftBubble(size: 82, color: Color(0x14FFFFFF)),
            ),
            const Positioned(
              right: 36,
              top: 12,
              child: _SoftBubble(size: 126, color: Color(0x10FFFFFF)),
            ),
            Positioned(
              right: 500,
              top: 54,
              child: Row(
                children: List.generate(
                  4,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x55FFFFFF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: onBack,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Materi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.menu_book_outlined,
                              color: Color(0xFFE4EDFF),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$subject - $title',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFE7EEFF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const ProfileAvatarButton(),
                    ],
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String subject;
  final String uploadDate;
  final int attachmentCount;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool deleting;

  const _SummaryCard({
    required this.title,
    required this.subject,
    required this.uploadDate,
    required this.attachmentCount,
    required this.compact,
    required this.onEdit,
    required this.onDelete,
    required this.deleting,
  });

  @override
  Widget build(BuildContext context) {
    final actions = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Edit Materi'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9C6415),
            side: const BorderSide(color: Color(0xFFF1D5AA)),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: deleting ? null : onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: Text(deleting ? 'Menghapus...' : 'Hapus'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE44848),
            side: const BorderSide(color: Color(0xFFF4C9C9)),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6ECF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B20356B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _IllustrationCard(),
                const SizedBox(height: 18),
                _SummaryContent(
                  title: title,
                  subject: subject,
                  uploadDate: uploadDate,
                  attachmentCount: attachmentCount,
                ),
                const SizedBox(height: 18),
                actions,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _IllustrationCard(),
                const SizedBox(width: 22),
                Expanded(
                  child: _SummaryContent(
                    title: title,
                    subject: subject,
                    uploadDate: uploadDate,
                    attachmentCount: attachmentCount,
                  ),
                ),
                const SizedBox(width: 20),
                actions,
              ],
            ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF2FF), Color(0xFFF7FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: Color(0xFF3463F4),
          size: 54,
        ),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final String title;
  final String subject;
  final String uploadDate;
  final int attachmentCount;

  const _SummaryContent({
    required this.title,
    required this.subject,
    required this.uploadDate,
    required this.attachmentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF2E61F3),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            subject,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1E3161),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 22,
          runSpacing: 10,
          children: [
            _MetaItem(
              icon: Icons.person_outline_rounded,
              text: 'Diunggah oleh: Bu Rani',
            ),
            _MetaItem(
              icon: Icons.calendar_month_rounded,
              text: uploadDate,
            ),
            _MetaItem(
              icon: Icons.folder_open_rounded,
              text: '$attachmentCount Lampiran',
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF7083AB), size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF61759E),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String text;
  final bool highlighted;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.text,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: highlighted
            ? const LinearGradient(
                colors: [Color(0xFFF6FAFF), Color(0xFFEFF5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlighted ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE6EEFF), Color(0xFFDCE7FF)],
              ),
              borderRadius: BorderRadius.circular(29),
            ),
            child: Icon(icon, color: const Color(0xFF4470F4), size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF214AA9),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF546A96),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.55,
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

class _AttachmentSection extends StatelessWidget {
  final List<_AttachmentItem> attachments;
  final bool mobile;
  final ValueChanged<_AttachmentItem> onDownload;

  const _AttachmentSection({
    required this.attachments,
    required this.mobile,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6ECF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5EDFF), Color(0xFFF5F8FF)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  color: Color(0xFF2E61F3),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lampiran Materi',
                      style: TextStyle(
                        color: Color(0xFF214AA9),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'File pendukung untuk materi ini',
                      style: TextStyle(
                        color: Color(0xFF687DA6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE6ECF8)),
            ),
            child: Column(
              children: List.generate(
                attachments.length,
                (index) {
                  final item = attachments[index];
                  final isLast = index == attachments.length - 1;
                  return _AttachmentRow(
                    item: item,
                    mobile: mobile,
                    isLast: isLast,
                    onDownload: () => onDownload(item),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                  'Klik Download untuk menyimpan file ke perangkat Anda.',
                  style: TextStyle(
                    color: Color(0xFF687DA6),
                    fontSize: 14,
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

class _AttachmentRow extends StatelessWidget {
  final _AttachmentItem item;
  final bool mobile;
  final bool isLast;
  final VoidCallback onDownload;

  const _AttachmentRow({
    required this.item,
    required this.mobile,
    required this.isLast,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final buttonRow = Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        _OutlineActionButton(
          icon: Icons.download_rounded,
          label: 'Download',
          onTap: onDownload,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE8EEFA)),
              ),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AttachmentMainInfo(item: item),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      item.size,
                      style: const TextStyle(
                        color: Color(0xFF5A6D95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                buttonRow,
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _AttachmentMainInfo(item: item),
                ),
                Expanded(
                  child: Text(
                    item.size,
                    style: const TextStyle(
                      color: Color(0xFF5A6D95),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                buttonRow,
              ],
            ),
    );
  }
}

class _AttachmentMainInfo extends StatelessWidget {
  final _AttachmentItem item;

  const _AttachmentMainInfo({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 48,
          decoration: BoxDecoration(
            color: item.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              item.typeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            item.fileName,
            style: const TextStyle(
              color: Color(0xFF485E88),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2E61F3),
        side: const BorderSide(color: Color(0xFFD8E3FB)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _SoftBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftBubble({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
        ),
      ),
    );
  }
}

class _AttachmentItem {
  final String typeLabel;
  final String fileName;
  final String size;
  final Color accent;
  final MateriAttachment attachment;

  const _AttachmentItem({
    required this.typeLabel,
    required this.fileName,
    required this.size,
    required this.accent,
    required this.attachment,
  });
}
