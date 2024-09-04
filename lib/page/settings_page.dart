import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _userName = ''; // 사용자 이름
  String _userPhone = ''; // 사용자 전화번호

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
    String userPhoneNumber = "01023326094"; // 실제 앱에서는 동적으로 받아와야 합니다.

    final response = await http.get(Uri.parse('http://10.0.2.2:8080/main/user?phoneNumber=$userPhoneNumber'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _userName = data['nickName'];
        _userPhone = userPhoneNumber;
        _isCurtainCallOn = data["isCurtainCallOnAndOff"];
      });
    } else {
      print('Failed to load user profile');
    }
  }

  Future<void> _saveCurtainCallState(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCurtainCallOn', value);
  }

 Future<void> _setAllContactsOn() async {
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/main/user/setAllOn?phoneNumber=$_userPhone'),
    );

    if (response.statusCode == 200) {
      final String message = response.body; // 메시지 자체가 본문으로 들어옴

      setState(() {
        // 모든 연락처가 CurtainCall ON 상태로 설정됨
        _isCurtainCallOn = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      });
    } else {
      print('Failed to set all contacts ON');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('커튼콜 기능 활성화에 실패했습니다.')),
      );
    }
  } catch (error) {
    print('Error: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('서버와의 연결에 문제가 발생했습니다.')),
    );
  }
}



  Future<void> _rollbackUserData() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/main/user/rollback?phoneNumber=$_userPhone'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final List<dynamic> restoredContacts = data['response'][_userPhone];

      // 복구된 데이터 처리 로직
      setState(() {
        _isCurtainCallOn = false; // 복구 후 CurtainCall은 기본적으로 OFF 상태로 설정
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연락처 정보가 성공적으로 복구되었습니다.')),
        );
      });
    } else {
      print('Failed to rollback user data');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연락처 정보 복구에 실패했습니다.')),
      );
    }
  }

  void _showConfirmationDialogForOn() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('확인'),
          content: const Text('정말 모든 연락처를 활성화 하시겠습니까?'),
          actions: [
            TextButton(
              child: const Text('아니오'),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
            TextButton(
              child: const Text('예'),
              onPressed: () async {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                await _setAllContactsOn(); // 모든 연락처 활성화
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialogForRollback() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('확인'),
          content: const Text('정말 연락처 정보를 원상복구 하시겠습니까?'),
          actions: [
            TextButton(
              child: const Text('아니오'),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
            TextButton(
              child: const Text('예'),
              onPressed: () async {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                await _rollbackUserData(); // 사용자 데이터 롤백
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.04;
    final double iconSize = screenSize.width * 0.2;
    final double fontSize = screenSize.width * 0.045;
    final double buttonFontSize = screenSize.width * 0.04;

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
                      Text(_userPhone, style: TextStyle(fontSize: buttonFontSize)),
                    ],
                  ),
                ),
                SizedBox(height: padding * 2),
                // 연락처 원상복구 카드
                Card(
                  color: Colors.grey[100],
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('연락처 원상복구', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                              Text('숨겨진 사용자의 정보들 원상복구', style: TextStyle(fontSize: buttonFontSize)),
                              Text('(앱 삭제 시 반드시 OFF 후 삭제)', style: TextStyle(fontSize: buttonFontSize, color: Colors.red)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _showConfirmationDialogForRollback, // 버튼을 누르면 확인 다이얼로그 표시
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: Text(
                            '복구',
                            style: TextStyle(color: Colors.red, fontSize: buttonFontSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey[100],
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('커튼콜 전체 ON', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                              Text('연락처 전체 기능 ON', style: TextStyle(fontSize: buttonFontSize)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _showConfirmationDialogForOn, // 버튼을 누르면 확인 다이얼로그 표시
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.green),
                          ),
                          child: Text(
                            'ON',
                            style: TextStyle(color: Colors.green, fontSize: buttonFontSize),
                          ),
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
      bottomNavigationBar: const CommonBottomNavigationBar(currentIndex: 3), // 설정 페이지가 선택된 상태로 설정
    );
  }
}
