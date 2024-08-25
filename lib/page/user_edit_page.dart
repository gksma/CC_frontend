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

    final url = Uri.parse('https://your-api-endpoint.com/authorization/send-one?phoneNumber=$phoneNumber');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'SMS로 인증번호가 발송되었습니다.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        );
        setState(() {
          _showVerificationCodeField = true;
          _isPhoneNumberEditable = true;
        });
      } else {
        Fluttertoast.showToast(
          msg: '인증번호 발송에 실패했습니다.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: '네트워크 오류가 발생했습니다.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

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
                              decoration: const InputDecoration(
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
                              controller: _phoneController,
                              enabled: _isPhoneNumberEditable, // 전화번호 비활성화 설정
                              decoration: const InputDecoration(
                                border: InputBorder.none,
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
