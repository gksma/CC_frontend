import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON 처리용 패키지
import 'package:path/path.dart' as path;

import 'utill.dart';

class UserEditPage extends StatefulWidget {
  const UserEditPage({super.key});

  @override
  _UserEditPageState createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  bool _isPhoneNumberEditable = false;
  final bool _showVerificationCodeField = false;
  String prePhoneNumber = "01023326094";
  String _userName = "";
  String _userPhone = "";

  @override
  void initState() {
    super.initState();
    _isPhoneNumberEditable = false;
    _fetchUserProfileWithConnection();
  }

  Future<String> _getNativeFilePath() async {
    return '/data/data/com.example.curtaincall/files';
  }

  Future<String?> _getStoredPhoneNumber() async {
    try {
      final nativeDirectory = await _getNativeFilePath();
      final file = File(path.join(nativeDirectory, 'phone_number.txt'));
      if (await file.exists()) {
        final phoneNumber = await file.readAsString();
        print('저장된 전화번호: $phoneNumber');
        return phoneNumber;
      } else {
        print("전화번호가 저장된 파일이 없습니다. 경로: ${file.path}");
        return null;
      }
    } catch (e) {
      print("파일 읽기 오류: $e");
      return null;
    }
  }

  // 이름을 저장된 파일에서 가져오는 함수
  Future<String?> _getStoredUserName() async {
    try {
      final nativeDirectory = await _getNativeFilePath();
      final file = File(path.join(nativeDirectory, 'user_name.txt'));
      if (await file.exists()) {
        final userName = await file.readAsString();
        print('저장된 사용자 이름: $userName');
        return userName;
      } else {
        print("사용자 이름이 저장된 파일이 없습니다.");
        return null;
      }
    } catch (e) {
      print("파일 읽기 오류: $e");
      return null;
    }
  }

  Future<void> _fetchUserProfileWithConnection() async {
    String? userPhoneNumber = await _getStoredPhoneNumber();
    userPhoneNumber = toUrlNumber(userPhoneNumber!);

    // 백엔드 API 호출하여 유저 정보 가져오기
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/main/user?phoneNumber=$userPhoneNumber'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _userName = data['nickName'];
        _userPhone = userPhoneNumber!;
      });
    } else {
      print('Failed to load user profile');
    }

    // 로컬 파일에서 저장된 사용자 이름을 가져와 _userName에 저장
    String? storedName = await _getStoredUserName();
    if (storedName != null) {
      setState(() {
        _userName = storedName; // _userName에 저장된 이름을 설정
      });
    }
  }

  // 이름 저장 로직
  void _saveNameOnly() {
    final String name = _nameController.text;

    if (name.isNotEmpty) {
      // 이름 저장 로직
      print('Name saved: $name');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름이 저장되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름을 입력하세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onPhoneChanged(String value) {
    String formattedNumber = _formatPhoneNumber(value.replaceAll('-', ''));
    _phoneController.value = TextEditingValue(
      text: formattedNumber,
      selection: TextSelection.collapsed(offset: formattedNumber.length),
    );
  }

  String _formatPhoneNumber(String number) {
    if (number.startsWith('010')) {
      if (number.length > 3 && number.length <= 7) {
        return '${number.substring(0, 3)}-${number.substring(3)}';
      } else if (number.length > 7) {
        return '${number.substring(0, 3)}-${number.substring(3, 7)}-${number.substring(7)}';
      }
    } else if (number.startsWith('02')) {
      if (number.length == 9) {
        return '${number.substring(0, 2)}-${number.substring(2, 5)}-${number.substring(5)}';
      } else if (number.length == 10) {
        return '${number.substring(0, 2)}-${number.substring(2, 6)}-${number.substring(6)}';
      } else if (number.length > 2 && number.length < 9) {
        return '${number.substring(0, 2)}-${number.substring(2)}';
      }
    } else {
      if (number.length > 3 && number.length <= 6) {
        return '${number.substring(0, 3)}-${number.substring(3)}';
      } else if (number.length > 6) {
        return '${number.substring(0, 3)}-${number.substring(3, 6)}-${number.substring(6)}';
      }
    }
    return number;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.04;
    final double margin = screenSize.width * 0.02;
    final double iconSize = screenSize.width * 0.15;
    final double fontSize = screenSize.width * 0.045;
    final double buttonHeight = screenSize.height * 0.07;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '내 정보 편집',
            style: TextStyle(color: Colors.black, fontSize: fontSize * 1.2),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              SizedBox(height: padding),
              Icon(Icons.person_add, size: iconSize),
              SizedBox(height: padding),
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: padding, horizontal: margin),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '이름 >',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: _userName, // 파일에서 불러온 이름을 표시
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                              ),
                              style: TextStyle(fontSize: fontSize),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16.0, thickness: 1),
                      Row(
                        children: [
                          Text(
                            '전화번호 >',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              enabled: _isPhoneNumberEditable,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                labelText: _userPhone,
                                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                              ),
                              style: TextStyle(fontSize: fontSize),
                              keyboardType: TextInputType.phone,
                              onChanged: _onPhoneChanged,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ),
              SizedBox(height: padding),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _saveNameOnly,
                  child: Text('저장', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
