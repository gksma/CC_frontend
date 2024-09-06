import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'keypad_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  bool _showVerificationField = false;
  bool _isLoading = false;
  bool _isUser = false; // 사용자인지 여부를 나타내는 변수

  @override
  void initState() {
    super.initState();
    // 페이지가 로드되자마자 API 호출
    _checkIfUser();
  }

  // 사용자인지 확인하는 API 호출
  Future<void> _checkIfUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // SharedPreferences에서 저장된 전화번호 가져오기
      final String? phoneNumber = await _getStoredPhoneNumber();

      if (phoneNumber == null || phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장된 전화번호가 없습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('http://10.0.2.2:8080/authorization/configUser?phoneNumber=$phoneNumber');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (response.body == 'true') {
          setState(() {
            _isUser = true;
          });

          // 사용자가 맞으면 다른 페이지로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const KeypadPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('사용자 인증을 해주세요!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isUser = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('네트워크 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // SharedPreferences에서 저장된 전화번호 가져오기
  Future<String?> _getStoredPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone_number'); // 'phone_number' 키로 저장된 번호를 가져옴
  }

  // 전화번호로 인증번호 발송 API 호출
  Future<void> _sendVerificationCode(String phoneNumber) async {
    final url = Uri.parse('http://10.0.2.2:8080/authorization/send-one?phoneNumber=$phoneNumber');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증번호가 전송되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _showVerificationField = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증번호 전송에 실패했습니다. 다시 시도해주세요.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('네트워크 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 인증번호 확인 API 호출
  Future<void> _verifyCode(String phoneNumber, String verificationCode) async {
    final url = Uri.parse('http://10.0.2.2:8080/authorization/configNumber?phoneNumber=$phoneNumber&configNumber=$verificationCode');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body=="true") {
        // 인증에 성공한 경우 사용자 정보 저장
        await _saveUserInfo();
        // 전화번호부 정보 저장
        await _savePhoneBookInfo();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증이 완료되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const KeypadPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증번호가 일치하지 않습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('네트워크 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 사용자 정보를 저장하는 API 호출
  Future<void> _saveUserInfo() async {
    final url = Uri.parse('http://10.0.2.2:8080/main/user');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "phoneNumber": _phoneController.text,
        "nickName": _nameController.text,
        "isCurtainCall": false
      }),
    );

    if (response.statusCode == 200) {
      print('User information saved successfully');
    } else {
      print('Failed to save user information');
    }
  }

  // 전화번호부 정보를 저장하는 API 호출 (로컬 연락처 가져오기)
  Future<void> _savePhoneBookInfo() async {
    final url = Uri.parse('http://10.0.2.2:8080/main/user/phoneAddressBookInfo');

    // 연락처 권한 요청
    if (await FlutterContacts.requestPermission()) {
      // 로컬 연락처 가져오기
      List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);

      // API 프로토콜에 맞게 전화번호부 데이터를 구성
      final Map<String, List<Map<String, dynamic>>> phoneBookData = {
        _phoneController.text: contacts.map((contact) {
          return {
            "name": contact.displayName ?? '', // 이름이 없으면 빈 문자열
            "phoneNumber": contact.phones.isNotEmpty ? contact.phones.first.number : '', // 전화번호가 없으면 빈 문자열
            "isCurtainCallOnAndOff": false // 기본값 설정
          };
        }).toList()
      };

      // POST 요청을 통해 데이터를 서버로 전송
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(phoneBookData),
        );

        if (response.statusCode == 200) {
          print('Phone book information saved successfully');
        } else {
          print('Failed to save phone book information: ${response.statusCode}');
        }
      } catch (e) {
        print('Error saving phone book information: $e');
      }
    } else {
      print('Contacts permission denied');
    }
  }

  void _saveContact() {
    final String name = _nameController.text;
    final String phoneNumber = _phoneController.text;

    if (name.isNotEmpty && phoneNumber.isNotEmpty) {
      _sendVerificationCode(phoneNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름과 전화번호를 입력하세요.'),
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
    final double fontSize = screenSize.width * 0.045; // 글꼴 크기 조정
    final double buttonHeight = screenSize.height * 0.07;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '내 정보 인증',
            style: TextStyle(color: Colors.black, fontSize: fontSize * 1.2),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      const SizedBox(height: 8.0),
                      if (_showVerificationField)
                        Column(
                          children: [
                            const Divider(height: 16.0, thickness: 1),
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
                            const SizedBox(height: 8.0),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: padding), // 아래쪽 여백 추가
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _showVerificationField
                      ? () => _verifyCode(_phoneController.text, _verificationCodeController.text)
                      : _saveContact,
                  child: Text(_showVerificationField ? '확인' : '인증', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


