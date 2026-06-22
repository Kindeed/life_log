import 'package:flutter/material.dart';
import 'package:life_log/features/profile/presentation/profile_view.dart';

class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '我的',
      icon: const Icon(Icons.account_circle_outlined),
      onPressed: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const ProfileView()),
        );
      },
    );
  }
}
