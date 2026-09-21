import 'package:flutter/material.dart';
import 'package:lms_guru/roles/guru/screens/profile/profile_page.dart';
import 'package:lms_guru/roles/guru/state/profile_store.dart';

class ProfileAvatarButton extends StatefulWidget {
  const ProfileAvatarButton({super.key});

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProfileStore.instance.ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ProfileStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final profile = store.profile;
        final avatarBytes = profile?.avatarBytes;
        final initial = profile?.initial ?? 'G';
        final nip = profile?.nip.trim().isNotEmpty == true ? profile!.nip : '-';

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 2),
                const Text(
                  'NIP',
                  style: TextStyle(
                    color: Color(0xFFDCE4FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(0xFF3554F2),
                    backgroundImage:
                        avatarBytes != null ? MemoryImage(avatarBytes) : null,
                    child: avatarBytes == null
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
