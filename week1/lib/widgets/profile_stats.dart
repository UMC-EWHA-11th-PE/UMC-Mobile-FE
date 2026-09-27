import 'package:flutter/material.dart';

import 'stat_item.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        StatItem(
          label: '본 영화',
          value: '24',
        ),
        StatItem(
          label: '평점',
          value: '18',
        ),
        StatItem(
          label: '즐겨찾기',
          value: '7',
        ),
      ],
    );
  }
}