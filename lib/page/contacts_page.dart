import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsPage extends StatelessWidget {
  final List<Map<String, String>> _contacts = [
    {"name": "김xx", "phone": "010-1234-5678"},
    {"name": "이xx", "phone": "010-2345-6789"},
    {"name": "박xx", "phone": "010-3456-7890"},
  ];

  ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double iconSize = screenSize.width * 0.15; // 타이틀 아래 연락처 아이콘 크기
    final double listIconSize = screenSize.width * 0.07; // 리스트 아이콘 크기
    final double padding = screenSize.width * 0.04;
    final double fontSize = screenSize.width * 0.04;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '연락처',
            style: TextStyle(color: Colors.black, fontSize: fontSize * 1.5),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          SizedBox(height: padding),
          Icon(Icons.contacts, size: iconSize),
          SizedBox(height: padding),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32 * (screenSize.width / 375)),
                  topRight: Radius.circular(32 * (screenSize.width / 375)),
                ),
              ),
              child: Container(
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16 * (screenSize.width / 375)),
                ),
                child: ListView.separated(
                  itemCount: _contacts.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey[300],
                    thickness: 1,
                  ),
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return ListTile(
                      title: Text(contact['name']!, style: TextStyle(fontSize: fontSize)),
                      subtitle: Text(contact['phone']!, style: TextStyle(fontSize: fontSize)),
                      leading: Icon(Icons.person, size: listIconSize),
                      trailing: IconButton(
                        icon: Icon(Icons.call, size: listIconSize),
                        onPressed: () {
                          _makePhoneCall(contact['phone']!);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Spacer(),
            BottomIconButton(
              icon: Icons.add,
              label: '연락처 추가',
              onPressed: () {
                Navigator.pushNamed(context, '/add_contact');
              },
            ),
            Spacer(),
            BottomIconButton(
              icon: Icons.person,
              label: '연락처',
              onPressed: () {},
            ),
            Spacer(),
            BottomIconButton(
              icon: Icons.dialpad,
              label: '키패드',
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
            ),
            Spacer(),
            BottomIconButton(
              icon: Icons.history,
              label: '최근 기록',
              onPressed: () {
                Navigator.pushNamed(context, '/recent_calls');
              },
            ),
            Spacer(),
            BottomIconButton(
              icon: Icons.settings,
              label: '설정',
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class BottomIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const BottomIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = MediaQuery.of(context).size.width * 0.025;
    final double iconSize = MediaQuery.of(context).size.width * 0.06;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: iconSize),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(fontSize: fontSize),
        ),
      ],
    );
  }
}
