import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'common_navigation_bar.dart';  // 통일된 하단 네비게이션 import
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';

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
      bottomNavigationBar: CommonBottomNavigationBar(currentIndex: 0), // 연락처 페이지가 선택된 상태로 설정
    );
  }

    Future<void> requestPhonePermission() async {
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        await Permission.phone.request();
      }
    }

  Future<void> _makePhoneCall(String phoneNumber) async {
    await requestPhonePermission();  // 권한 요청
    bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    if (res == null || !res) {
      throw 'Could not make the call to $phoneNumber';
    }
  }
}
