import 'package:curtaincall/page/user_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'common_navigation_bar.dart';  // 통일된 하단 네비게이션 import

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isCurtainCallOn = false; // 커튼콜 초기 상태
  String _userName='';// 사용자 이름
  String _userPhone = ''; // 사용자 전화번호
  bool _isCurtainCallOnAndOff=false;

  @override
  void initState() {
    super.initState();
    _loadCurtainCallState();
    _fetchUserProfileWithConnection();
  }

  Future<void> _loadCurtainCallState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCurtainCallOn = prefs.getBool('isCurtainCallOn') ?? false;
    });
  }

  Future<void> _fetchUserProfileWithConnection() async {
    //참고1 현재는 임의의 값으로 되어 있지만, 어플 사용자의 전화번호를 찾아서 setting을 해줘야함.
    String userPhoneNumber="01023326094";

    //참고2 현재는 android emulator의 로컬 주소로 되어있지만 실제로 배포하게 되면 백엔드 단에서 넘겨준
    //인스턴스의 주소를 사용해야함.
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/main/user?phoneNumber=$userPhoneNumber'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _userName = data['nickName'];
        _userPhone=userPhoneNumber;
        _isCurtainCallOnAndOff=data["isCurtainCallOnAndOff"];
      });
    } else {
      // 에러 처리
      print('Failed to load user profile');
    }
  }
  Future<void> _saveCurtainCallState(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCurtainCallOn', value);
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.contacts,
      Permission.camera,
      Permission.microphone,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('권한 거부됨'),
          content: const Text('필수 권한을 모두 동의해야 앱을 사용할 수 있습니다.'),
          actions: [
            TextButton(
              child: const Text('종료'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _isCurtainCallOn = true;
      });
      await _saveCurtainCallState(true);
    }
  }

  Future<void> _revokePermissions() async {
    await _saveCurtainCallState(false);
    setState(() {
      _isCurtainCallOn = false;
    });
  }

  Future<void> _checkAndRequestPermissions() async {
    bool phoneGranted = await Permission.phone.isGranted;
    bool contactsGranted = await Permission.contacts.isGranted;
    bool cameraGranted = await Permission.camera.isGranted;
    bool microphoneGranted = await Permission.microphone.isGranted;

    if (!phoneGranted || !contactsGranted || !cameraGranted || !microphoneGranted) {
      await _requestPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.04;
    final double iconSize = screenSize.width * 0.2;
    final double fontSize = screenSize.width * 0.045;
    final double switchFontSize = screenSize.width * 0.035;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '설정',
            style: TextStyle(color: Colors.black, fontSize: fontSize * 1.2),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.black, size: iconSize * 0.4),
            onPressed: () {
              Navigator.pushNamed(context, '/user_edit');
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                SizedBox(height: padding),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.person, size: iconSize),
                      SizedBox(height: padding),
                      Text(_userName, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                      Text(_userPhone, style: TextStyle(fontSize: switchFontSize)),
                    ],
                  ),
                ),
                SizedBox(height: padding * 2),
                Card(
                  color: Colors.grey[100],
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('커튼콜 ON / OFF', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                            Text('커튼콜 기능 켜고 끄기\n(ON으로 설정 시, 시스템 전화 요청)', style: TextStyle(fontSize: switchFontSize)),
                          ],
                        ),
                        Switch(
                          value: _isCurtainCallOnAndOff,
                          onChanged: (value) async {
                            if (value) {
                              await _checkAndRequestPermissions();
                            } else {
                              await _revokePermissions();
                            }
                            setState(() {
                              _isCurtainCallOn = value;
                            });
                            await _saveCurtainCallState(value);
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: CommonBottomNavigationBar(currentIndex: 3), // 설정 페이지가 선택된 상태로 설정
    );
  }
}
