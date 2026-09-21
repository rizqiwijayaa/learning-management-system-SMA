import 'dart:typed_data';

import 'package:flutter/material.dart';

class KesiswaanHeaderAvatar extends StatelessWidget {
  const KesiswaanHeaderAvatar({
    super.key,
    required this.initial,
    this.avatarBytes,
    this.radius = 20,
    this.outerColor = Colors.white,
    this.innerColor = const Color(0xFF2953E3),
    this.textColor = Colors.white,
  });

  final String initial;
  final Uint8List? avatarBytes;
  final double radius;
  final Color outerColor;
  final Color innerColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final outerRadius = radius;
    final innerRadius = radius - 2;

    return CircleAvatar(
      radius: outerRadius,
      backgroundColor: outerColor,
      child: CircleAvatar(
        radius: innerRadius > 0 ? innerRadius : radius,
        backgroundColor: innerColor,
        backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes!) : null,
        child: avatarBytes == null
            ? Text(
                initial,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: radius * 0.8,
                ),
              )
            : null,
      ),
    );
  }
}
