import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/models/attendance_record.dart';
import 'package:lms_guru/roles/guru/models/daily_attendance_record.dart';

class EditAbsensiPage extends StatefulWidget {
  final AttendanceRecord student;
  final DailyAttendanceRecord entry;

  const EditAbsensiPage({
    super.key,
    required this.student,
    required this.entry,
  });

  @override
  State<EditAbsensiPage> createState() => _EditAbsensiPageState();
}

class _EditAbsensiPageState extends State<EditAbsensiPage> {
  late DailyAttendanceStatus _selectedStatus;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.entry.status;
    _noteController = TextEditingController(text: widget.entry.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      DailyAttendanceEditResult.save(
        widget.entry.copyWith(
          status: _selectedStatus,
          note: _noteController.text.trim(),
        ),
      ),
    );
  }

  void _delete() {
    Navigator.of(context).pop(
      DailyAttendanceEditResult.delete(widget.entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        const _Hero(),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _StudentCard(student: widget.student, dateLabel: widget.entry.dateLabel),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _EditorCard(
                  selectedStatus: _selectedStatus,
                  noteController: _noteController,
                  onStatusChanged: (status) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: const Color(0xFF5D6885),
                          side: const BorderSide(color: Color(0xFFDCE3F6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (widget.entry.id != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _delete,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            foregroundColor: const Color(0xFFC53A3A),
                            side: const BorderSide(color: Color(0xFFFFC7C7)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Hapus',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: const Color(0xFF2F4FE8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
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
                child: content,
              ),
            ),
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(child: body),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 172,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2B3BFF), Color(0xFF2028D2)],
                ),
              ),
            ),
            const Positioned(
              left: -40,
              top: -28,
              child: _Bubble(size: 150, color: Color(0x1EFFFFFF)),
            ),
            const Positioned(
              right: -24,
              top: 34,
              child: _Bubble(size: 128, color: Color(0x18FFFFFF)),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _CurveClipper(),
                    child: Container(
                      height: 78,
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
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(18),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 2),
                        Text(
                          'Edit Absensi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Ubah status kehadiran siswa',
                          style: TextStyle(
                            color: Color(0xFFC7D2FF),
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
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final AttendanceRecord student;
  final String dateLabel;

  const _StudentCard({required this.student, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08283974),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: student.accent,
            child: Text(
              student.initial,
              style: const TextStyle(
                color: Color(0xFF3546AF),
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentName,
                  style: const TextStyle(
                    color: Color(0xFF1F2433),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelas: ${student.className}',
                  style: const TextStyle(
                    color: Color(0xFF70789A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Color(0xFF3559E0),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _EditorCard extends StatelessWidget {
  final DailyAttendanceStatus selectedStatus;
  final TextEditingController noteController;
  final ValueChanged<DailyAttendanceStatus> onStatusChanged;

  const _EditorCard({
    required this.selectedStatus,
    required this.noteController,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08283974),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Kehadiran',
            style: TextStyle(
              color: Color(0xFF1F2433),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: DailyAttendanceStatus.values
                .map(
                  (status) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: status == DailyAttendanceStatus.values.last ? 0 : 10,
                      ),
                      child: _StatusButton(
                        status: status,
                        selected: selectedStatus == status,
                        onTap: () => onStatusChanged(status),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          const Text(
            'Catatan',
            style: TextStyle(
              color: Color(0xFF1F2433),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteController,
            minLines: 4,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan absensi jika diperlukan',
              filled: true,
              fillColor: const Color(0xFFF7F9FF),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE3F6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDCE3F6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF3559E0), width: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final DailyAttendanceStatus status;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? status.color.withOpacity(0.12) : const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? status.color : const Color(0xFFDCE3F6),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(status.icon, color: status.color, size: 22),
            const SizedBox(height: 6),
            Text(
              status.label,
              style: TextStyle(
                color: selected ? status.color : const Color(0xFF5B6786),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
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
    path.moveTo(0, 42);
    path.quadraticBezierTo(size.width * 0.24, 16, size.width * 0.58, 44);
    path.quadraticBezierTo(size.width * 0.84, 68, size.width, 28);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
