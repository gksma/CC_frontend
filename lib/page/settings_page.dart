import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isCurtainCallOn = false; // 커튼콜 초기 상태

  @override
  void initState() {
    super.initState();
    _loadCurtainCallState();
  }

  Future<void> _loadCurtainCallState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCurtainCallOn = prefs.getBool('isCurtainCallOn') ?? false;
    });
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
    // 권한을 직접 취소하는 방법은 없지만, 내부적으로 상태를 취소된 것으로 처리
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '설정',
            style: TextStyle(color: Colors.black),
          ),
        ),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 15), // 높이를 키움
            Center(
              child: Column(
                children: const [
                  Icon(Icons.person, size: 75), // 크기를 키움
                  SizedBox(height: 10), // 간격 추가
                  Text('홍길동', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // 폰트 크기를 키움
                  Text('010-1234-5678', style: TextStyle(fontSize: 13)), // 폰트 크기를 키움
                ],
              ),
            ),
            const SizedBox(height: 30), // 높이를 키움
            Card(
              color: Colors.grey[100], // 색상 설정
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12.0), // 패딩을 키움
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('커튼콜 ON / OFF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), // 폰트 크기를 키움
                        Text('커튼콜 기능 켜고 끄기\n(ON으로 설정 시, 시스템 전화 요청)', style: TextStyle(fontSize: 10)), // 폰트 크기를 키움
                      ],
                    ),
                    Switch(
                      value: _isCurtainCallOn, // 초기값 설정
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
                      activeColor: Colors.green, // 스위치 활성 색상 설정
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                Navigator.pushNamed(context, '/add_contact');
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
                // 현재 설정 페이지이므로 아무 작업도 수행하지 않음
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
