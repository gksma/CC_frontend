import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON 처리용 패키지

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
  bool _showVerificationCodeField = false;
  String prePhoneNumber="01023326094";
  String _userName="";
  String _userPhone="";

  @override
  void initState() {
    super.initState();
    // _loadCurtainCallState();
    _isPhoneNumberEditable = false;
    _fetchUserProfileWithConnection();

  }

  // 인증 요청 API 호출 함수
  Future<void> _sendVerificationSMS() async {
    final String phoneNumber = _phoneController.text.replaceAll('-', '');

    if (phoneNumber.isEmpty) {
      Fluttertoast.showToast(
        msg: '전화번호를 입력하세요.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      return;
    }
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
        });
      } else {
        // 에러 처리
        print('Failed to load user profile');
      }
    }
    //현재 들어가 있는

  // 전화번호 인증 후 저장 로직
  void _verifyAndSavePhoneNumber() {
    final String verificationCode = _verificationCodeController.text;

    if (verificationCode.isNotEmpty) {
      // 인증번호가 맞으면 전화번호 저장 로직 추가
      print('Phone number updated: ${_phoneController.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('전화번호가 업데이트되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증번호를 입력하세요.'),
          duration: Duration(seconds: 2),
        ),
      );
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
                                labelText: _userName,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 5),
                              ),
                              style: TextStyle(fontSize: fontSize),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 16.0, thickness: 1),
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
                              // print("isPhe /+_isPhoneNumberEditable);
                              controller: _phoneController,
                              enabled: _isPhoneNumberEditable, // 전화번호 비활성화 설정
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                labelText: _userPhone,
                                contentPadding: EdgeInsets.symmetric(vertical: 5),
                              ),
                              style: TextStyle(fontSize: fontSize),
                              keyboardType: TextInputType.phone,
                              onChanged: _onPhoneChanged,
                            ),
                          ),
                        ],
                      ),
                      if (_showVerificationCodeField) ...[
                        Divider(height: 16.0, thickness: 1),
                        Row(
                          children: [
                            Text(
                              '인증번호 >',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _verificationCodeController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                                ),
                                style: TextStyle(fontSize: fontSize),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                  onPressed: _sendVerificationSMS,
                  child: Text('재인증', style: TextStyle(fontSize: fontSize)),
                ),
              ),
              SizedBox(height: padding), // 재인증 버튼 밑에 여백
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
