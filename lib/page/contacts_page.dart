import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsPage extends StatelessWidget {
  final List<Map<String, String>> _contacts = [
    {"name": "김xx", "phone": "010-1234-5678"},
    {"name": "이xx", "phone": "010-2345-6789"},
    {"name": "박xx", "phone": "010-3456-7890"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '연락처',
            style: TextStyle(color: Colors.black),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double iconSize = constraints.maxWidth * 0.15; // 타이틀 아래 연락처 아이콘 크기
          double listIconSize = constraints.maxWidth * 0.07; // 리스트 아이콘 크기
          double padding = constraints.maxWidth * 0.04;
          double fontSize = constraints.maxWidth * 0.04;

          return Column(
            children: [
              SizedBox(height: padding),
              Icon(Icons.contacts, size: iconSize),
              SizedBox(height: padding),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(0.0),
                    padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
          );
        },
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
                Navigator.pushNamed(context, '/add_contact');
              },
            ),
            const Spacer(),
            BottomIconButton(
              icon: Icons.person,
              label: '연락처',
              onPressed: () {},
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 20),
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
