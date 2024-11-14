import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_contacts/flutter_contacts.dart'; // 로컬 연락처 관리

import 'common_navigation_bar.dart';  // 통일된 하단 네비게이션 import
import 'token_util.dart';
import 'utill.dart';

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
    _loadStoredUserName(); // 저장된 사용자 이름 불러오기
    _loadCurtainCallState();
    _fetchUserProfileWithConnection();
  }

  // 저장된 사용자 이름 불러오는 함수
  Future<void> _loadStoredUserName() async {
    String? storedName = await _getStoredUserName(); // 저장된 이름 가져오기
    if (storedName != null) {
      setState(() {
        _userName = storedName; // _userName에 저장된 이름을 설정
      });
    }
  }

  // 저장된 사용자 이름 가져오기
  Future<String?> _getStoredUserName() async {
    try {
      final directory = await getApplicationDocumentsDirectory(); // 경로 수정
      final file = File(path.join(directory.path, 'user_name.txt'));
      // 파일이 존재하는지 확인하고, 파일이 있으면 내용을 읽음
      if (await file.exists()) {
        final userName = await file.readAsString();
        print('저장된 사용자 이름: $userName');
        return userName;
      } else {
        print("사용자 이름이 저장된 파일이 없습니다. 경로: ${file.path}");
        return null;
      }
    } catch (e) {
      print("파일 읽기 오류: $e");
      return null;
    }
  }


  Future<void> _loadCurtainCallState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCurtainCallOn = prefs.getBool('isCurtainCallOn') ?? false;
    });
  }

Future<void> _fetchUserProfileWithConnection() async {
  String? bearerToken = await getBearerTokenFromFile();

  if (bearerToken == null) {
    print('저장된 토큰이 없습니다.');
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/main/user'),
      headers: {
        'authorization': bearerToken,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _userPhone = data['phoneNumber'];
        _userName = data['nickName'];
        _isCurtainCallOn = data["isCurtainCallOnAndOff"];
      });
      print('사용자 정보 로드 성공: $_userPhone, $_userName, $_isCurtainCallOn');
    } else {
      print('사용자 정보 로드 실패. 상태 코드: ${response.statusCode}');
    }
  } catch (e) {
    print('사용자 정보를 불러오는 중 오류 발생: $e');
  }
}


  Future<void> _saveCurtainCallState(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCurtainCallOn', value);
  }

  // 전화번호부 커튼콜 전체 on (api 16번)
  Future<void> _setAllContactsOn() async {
    String? bearerToken = await getBearerTokenFromFile();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCurtainCallOn', true);

    if (bearerToken == null || bearerToken.isEmpty) {
      print("Bearer 토큰이 없습니다.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/main/user/setAllOn'),
        headers: {
          'authorization': bearerToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.body;
        if (data == '커튼콜 기능 일괄 활성화 되었습니다') {
          await _deleteAllLocalContactNames(); // 모든 로컬 연락처에서 이름 삭제
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isCurtainCallOn', true); // 상태 저장
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('모든 연락처가 커튼콜 ON으로 설정되었습니다.')),
          );
        } else {
          print('연락처 설정 오류: ${data}');
        }
      } else {
        print('Failed to set all contacts ON. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와의 연결에 문제가 발생했습니다.')),
      );
    }
  }

  // 전화번호부 커튼콜 전체 off (api 15번)
  Future<void> _rollbackUserData() async {
    String? bearerToken = await getBearerTokenFromFile();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCurtainCallOn', false);

    if (bearerToken == null || bearerToken.isEmpty) {
      print("Bearer 토큰이 없습니다.");
      return;
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/main/user/rollback'),
      headers: {
        'authorization': bearerToken,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> restoredContacts = data['response'][_userPhone];

      await _restoreAllLocalContactNames(restoredContacts); // 로컬 연락처에 복구된 이름들 반영
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isCurtainCallOn', false); // 상태 저장
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연락처 정보가 성공적으로 복구되었습니다.')),
      );
    } else {
      print('Failed to rollback user data. Status code: ${response.statusCode}');
    }
  }


  // **모든 로컬 연락처의 이름을 삭제하는 함수**
  Future<void> _deleteAllLocalContactNames() async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withAccounts: true,
        withPhoto: true,  // 사진 정보도 가져오도록 설정
      );

      for (var contact in contacts) {
        if (contact.phones.isNotEmpty) {
          contact.name.first = '';
          contact.name.last = '';
          await contact.update();
        }
      }
      print('모든 로컬 연락처 이름 삭제 완료');
    } catch (e) {
      print('모든 로컬 연락처 이름 삭제 중 오류 발생: $e');
    }
  }

  // **모든 로컬 연락처의 이름을 복구하는 함수**
  Future<void> _restoreAllLocalContactNames(List<dynamic> restoredContacts) async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withAccounts: true,
        withPhoto: true,  // 사진 정보도 가져오도록 설정
      );

      for (var restoredContact in restoredContacts) {
        for (var contact in contacts) {
          if (contact.phones.isNotEmpty && contact.phones.first.number == restoredContact['phoneNumber']) {
            contact.name.first = restoredContact['name'];
            contact.name.last = '';
            await contact.update();
          }
        }
      }
      print('모든 로컬 연락처 이름 복구 완료');
    } catch (e) {
      print('모든 로컬 연락처 이름 복구 중 오류 발생: $e');
    }
  }

  // 커튼콜 ON/OFF 알림 다이얼로그
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('예'),
              onPressed: () async {
                Navigator.of(context).pop();
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('예'),
              onPressed: () async {
                Navigator.of(context).pop();
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
