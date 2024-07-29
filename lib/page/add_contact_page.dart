import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddContactPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '연락처 추가',
            style: TextStyle(color: Colors.black),
          ),
        ),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text('연락처 추가 페이지 내용'),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
            BottomIconButton(
              icon: Icons.add,
              label: '연락처 추가',
              onPressed: () {
                // 현재 페이지
              },
            ),
            const Spacer(),
            BottomIconButton(
              icon: Icons.person,
              label: '연락처',
              onPressed: () {
                Navigator.pushNamed(context, '/contacts');
              },
            ),
            const Spacer(),
            BottomIconButton(
              icon: Icons.dialpad,
              label: '키패드',
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
            ),
            const Spacer(),
            BottomIconButton(
              icon: Icons.history,
              label: '최근 기록',
              onPressed: () {
                Navigator.pushNamed(context, '/recent_calls');
              },
            ),
            const Spacer(),
            BottomIconButton(
              icon: Icons.settings,
              label: '설정',
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class BottomIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const BottomIconButton({super.key, 
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
