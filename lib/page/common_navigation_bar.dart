import 'package:flutter/material.dart';

class CommonBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const CommonBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      // case 0:
      //   Navigator.pushNamed(context, '/add_contact');
      //   break;
      case 0:
        Navigator.pushNamed(context, '/contacts');
        break;
      case 1:
        Navigator.pushNamed(context, '/');
        break;
      case 2:
        Navigator.pushNamed(context, '/recent_calls');
        break;
      case 3:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black.withOpacity(0.5),
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.add),
        //   label: '연락처 추가',
        // ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '연락처',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dialpad),
          label: '키패드',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: '최근 기록',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: '설정',
        ),
      ],
    );
  }
}
